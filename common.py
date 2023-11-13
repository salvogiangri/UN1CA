# Copyright (C) 2008 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from __future__ import print_function

import base64
import collections
import copy
import datetime
import errno
import fnmatch
import getopt
import getpass
import gzip
import imp
import json
import logging
import logging.config
import os
import platform
import re
import shlex
import shutil
import subprocess
import stat
import sys
import tempfile
import threading
import time
import zipfile
from dataclasses import dataclass
from genericpath import isdir
from hashlib import sha1, sha256

import images
import rangelib
import sparse_img
from blockimgdiff import BlockImageDiff

logger = logging.getLogger(__name__)


class Options(object):

  def __init__(self):
    # Set up search path, in order to find framework/ and lib64/. At the time of
    # running this function, user-supplied search path (`--path`) hasn't been
    # available. So the value set here is the default, which might be overridden
    # by commandline flag later.
    exec_path = os.path.realpath(sys.argv[0])
    if exec_path.endswith('.py'):
      script_name = os.path.basename(exec_path)
      # logger hasn't been initialized yet at this point. Use print to output
      # warnings.
      print(
          'Warning: releasetools script should be invoked as hermetic Python '
          'executable -- build and run `{}` directly.'.format(
              script_name[:-3]),
          file=sys.stderr)
    self.search_path = os.path.dirname(os.path.dirname(exec_path))

    self.signapk_path = "framework/signapk.jar"  # Relative to search_path
    if not os.path.exists(os.path.join(self.search_path, self.signapk_path)):
      if "ANDROID_HOST_OUT" in os.environ:
        self.search_path = os.environ["ANDROID_HOST_OUT"]
    self.signapk_shared_library_path = "lib64"   # Relative to search_path
    self.extra_signapk_args = []
    self.aapt2_path = "aapt2"
    self.java_path = "java"  # Use the one on the path by default.
    self.java_args = ["-Xmx4096m"]  # The default JVM args.
    self.android_jar_path = None
    self.public_key_suffix = ".x509.pem"
    self.private_key_suffix = ".pk8"
    # use otatools built boot_signer by default
    self.verbose = False
    self.tempfiles = []
    self.device_specific = None
    self.extras = {}
    self.info_dict = None
    self.source_info_dict = None
    self.target_info_dict = None
    self.worker_threads = None
    # Stash size cannot exceed cache_size * threshold.
    self.cache_size = None
    self.stash_threshold = 0.8
    self.logfile = None


OPTIONS = Options()

# The block size that's used across the releasetools scripts.
BLOCK_SIZE = 4096

# Values for "certificate" in apkcerts that mean special things.
SPECIAL_CERT_STRINGS = ("PRESIGNED", "EXTERNAL")

# The partitions allowed to be signed by AVB (Android Verified Boot 2.0). Note
# that system_other is not in the list because we don't want to include its
# descriptor into vbmeta.img. When adding a new entry here, the
# AVB_FOOTER_ARGS_BY_PARTITION in sign_target_files_apks need to be updated
# accordingly.
AVB_PARTITIONS = ('boot', 'init_boot', 'dtbo', 'odm', 'product', 'pvmfw',
                  'recovery', 'system', 'system_ext', 'vendor', 'vendor_boot',
                  'vendor_kernel_boot', 'vendor_dlkm', 'odm_dlkm',
                  'system_dlkm')

# Chained VBMeta partitions.
AVB_VBMETA_PARTITIONS = ('vbmeta_system', 'vbmeta_vendor')

# avbtool arguments name
AVB_ARG_NAME_INCLUDE_DESC_FROM_IMG = '--include_descriptors_from_image'
AVB_ARG_NAME_CHAIN_PARTITION = '--chain_partition'

# Partitions that should have their care_map added to META/care_map.pb
PARTITIONS_WITH_CARE_MAP = [
    'system',
    'vendor',
    'product',
    'system_ext',
    'odm',
    'vendor_dlkm',
    'odm_dlkm',
    'system_dlkm',
]

# Partitions with a build.prop file
PARTITIONS_WITH_BUILD_PROP = PARTITIONS_WITH_CARE_MAP + ['boot', 'init_boot']

# See sysprop.mk. If file is moved, add new search paths here; don't remove
# existing search paths.
RAMDISK_BUILD_PROP_REL_PATHS = ['system/etc/ramdisk/build.prop']


@dataclass
class AvbChainedPartitionArg:
  """The required arguments for avbtool --chain_partition."""
  partition: str
  rollback_index_location: int
  pubkey_path: str

  def to_string(self):
    """Convert to string command arguments."""
    return '{}:{}:{}'.format(
        self.partition, self.rollback_index_location, self.pubkey_path)


class ErrorCode(object):
  """Define error_codes for failures that happen during the actual
  update package installation.

  Error codes 0-999 are reserved for failures before the package
  installation (i.e. low battery, package verification failure).
  Detailed code in 'bootable/recovery/error_code.h' """

  SYSTEM_VERIFICATION_FAILURE = 1000
  SYSTEM_UPDATE_FAILURE = 1001
  SYSTEM_UNEXPECTED_CONTENTS = 1002
  SYSTEM_NONZERO_CONTENTS = 1003
  SYSTEM_RECOVER_FAILURE = 1004
  VENDOR_VERIFICATION_FAILURE = 2000
  VENDOR_UPDATE_FAILURE = 2001
  VENDOR_UNEXPECTED_CONTENTS = 2002
  VENDOR_NONZERO_CONTENTS = 2003
  VENDOR_RECOVER_FAILURE = 2004
  OEM_PROP_MISMATCH = 3000
  FINGERPRINT_MISMATCH = 3001
  THUMBPRINT_MISMATCH = 3002
  OLDER_BUILD = 3003
  DEVICE_MISMATCH = 3004
  BAD_PATCH_FILE = 3005
  INSUFFICIENT_CACHE_SPACE = 3006
  TUNE_PARTITION_FAILURE = 3007
  APPLY_PATCH_FAILURE = 3008


class ExternalError(RuntimeError):
  pass


def InitLogging():
  DEFAULT_LOGGING_CONFIG = {
      'version': 1,
      'disable_existing_loggers': False,
      'formatters': {
          'standard': {
              'format':
                  '%(asctime)s - %(filename)s - %(levelname)-8s: %(message)s',
              'datefmt': '%Y-%m-%d %H:%M:%S',
          },
      },
      'handlers': {
          'default': {
              'class': 'logging.StreamHandler',
              'formatter': 'standard',
              'level': 'WARNING',
          },
      },
      'loggers': {
          '': {
              'handlers': ['default'],
              'propagate': True,
              'level': 'NOTSET',
          }
      }
  }
  env_config = os.getenv('LOGGING_CONFIG')
  if env_config:
    with open(env_config) as f:
      config = json.load(f)
  else:
    config = DEFAULT_LOGGING_CONFIG

    # Increase the logging level for verbose mode.
    if OPTIONS.verbose:
      config = copy.deepcopy(config)
      config['handlers']['default']['level'] = 'INFO'

    if OPTIONS.logfile:
      config = copy.deepcopy(config)
      config['handlers']['logfile'] = {
          'class': 'logging.FileHandler',
          'formatter': 'standard',
          'level': 'INFO',
          'mode': 'w',
          'filename': OPTIONS.logfile,
      }
      config['loggers']['']['handlers'].append('logfile')

  logging.config.dictConfig(config)


def FindHostToolPath(tool_name):
  """Finds the path to the host tool.

  Args:
    tool_name: name of the tool to find
  Returns:
    path to the tool if found under the same directory as this binary is located at. If not found,
    tool_name is returned.
  """
  my_dir = os.path.dirname(os.path.realpath(sys.argv[0]))
  tool_path = os.path.join(my_dir, tool_name)
  if os.path.exists(tool_path):
    return tool_path

  return tool_name


def Run(args, verbose=None, **kwargs):
  """Creates and returns a subprocess.Popen object.

  Args:
    args: The command represented as a list of strings.
    verbose: Whether the commands should be shown. Default to the global
        verbosity if unspecified.
    kwargs: Any additional args to be passed to subprocess.Popen(), such as env,
        stdin, etc. stdout and stderr will default to subprocess.PIPE and
        subprocess.STDOUT respectively unless caller specifies any of them.
        universal_newlines will default to True, as most of the users in
        releasetools expect string output.

  Returns:
    A subprocess.Popen object.
  """
  if 'stdout' not in kwargs and 'stderr' not in kwargs:
    kwargs['stdout'] = subprocess.PIPE
    kwargs['stderr'] = subprocess.STDOUT
  if 'universal_newlines' not in kwargs:
    kwargs['universal_newlines'] = True

  if args:
    # Make a copy of args in case client relies on the content of args later.
    args = args[:]
    args[0] = FindHostToolPath(args[0])

  if verbose is None:
    verbose = OPTIONS.verbose

  # Don't log any if caller explicitly says so.
  if verbose:
    logger.info("  Running: \"%s\"", " ".join(args))
  return subprocess.Popen(args, **kwargs)


def RunAndCheckOutput(args, verbose=None, **kwargs):
  """Runs the given command and returns the output.

  Args:
    args: The command represented as a list of strings.
    verbose: Whether the commands should be shown. Default to the global
        verbosity if unspecified.
    kwargs: Any additional args to be passed to subprocess.Popen(), such as env,
        stdin, etc. stdout and stderr will default to subprocess.PIPE and
        subprocess.STDOUT respectively unless caller specifies any of them.

  Returns:
    The output string.

  Raises:
    ExternalError: On non-zero exit from the command.
  """
  if verbose is None:
    verbose = OPTIONS.verbose
  proc = Run(args, verbose=verbose, **kwargs)
  output, _ = proc.communicate()
  if output is None:
    output = ""
  # Don't log any if caller explicitly says so.
  if verbose:
    logger.info("%s", output.rstrip())
  if proc.returncode != 0:
    raise ExternalError(
        "Failed to run command '{}' (exit code {}):\n{}".format(
            args, proc.returncode, output))
  return output


def RoundUpTo4K(value):
  rounded_up = value + 4095
  return rounded_up - (rounded_up % 4096)


def CloseInheritedPipes():
  """ Gmake in MAC OS has file descriptor (PIPE) leak. We close those fds
  before doing other work."""
  if platform.system() != "Darwin":
    return
  for d in range(3, 1025):
    try:
      stat = os.fstat(d)
      if stat is not None:
        pipebit = stat[0] & 0x1000
        if pipebit != 0:
          os.close(d)
    except OSError:
      pass


class BuildInfo(object):
  """A class that holds the information for a given build.

  This class wraps up the property querying for a given source or target build.
  It abstracts away the logic of handling OEM-specific properties, and caches
  the commonly used properties such as fingerprint.

  There are two types of info dicts: a) build-time info dict, which is generated
  at build time (i.e. included in a target_files zip); b) OEM info dict that is
  specified at package generation time (via command line argument
  '--oem_settings'). If a build doesn't use OEM-specific properties (i.e. not
  having "oem_fingerprint_properties" in build-time info dict), all the queries
  would be answered based on build-time info dict only. Otherwise if using
  OEM-specific properties, some of them will be calculated from two info dicts.

  Users can query properties similarly as using a dict() (e.g. info['fstab']),
  or to query build properties via GetBuildProp() or GetPartitionBuildProp().

  Attributes:
    info_dict: The build-time info dict.
    is_ab: Whether it's a build that uses A/B OTA.
    oem_dicts: A list of OEM dicts.
    oem_props: A list of OEM properties that should be read from OEM dicts; None
        if the build doesn't use any OEM-specific property.
    fingerprint: The fingerprint of the build, which would be calculated based
        on OEM properties if applicable.
    device: The device name, which could come from OEM dicts if applicable.
  """

  _RO_PRODUCT_RESOLVE_PROPS = ["ro.product.brand", "ro.product.device",
                               "ro.product.manufacturer", "ro.product.model",
                               "ro.product.name"]
  _RO_PRODUCT_PROPS_DEFAULT_SOURCE_ORDER_CURRENT = [
      "product", "odm", "vendor", "system_ext", "system"]
  _RO_PRODUCT_PROPS_DEFAULT_SOURCE_ORDER_ANDROID_10 = [
      "product", "product_services", "odm", "vendor", "system"]
  _RO_PRODUCT_PROPS_DEFAULT_SOURCE_ORDER_LEGACY = []

  # The length of vbmeta digest to append to the fingerprint
  _VBMETA_DIGEST_SIZE_USED = 8

  def __init__(self, info_dict, oem_dicts=None, use_legacy_id=False):
    """Initializes a BuildInfo instance with the given dicts.

    Note that it only wraps up the given dicts, without making copies.

    Arguments:
      info_dict: The build-time info dict.
      oem_dicts: A list of OEM dicts (which is parsed from --oem_settings). Note
          that it always uses the first dict to calculate the fingerprint or the
          device name. The rest would be used for asserting OEM properties only
          (e.g. one package can be installed on one of these devices).
      use_legacy_id: Use the legacy build id to construct the fingerprint. This
          is used when we need a BuildInfo class, while the vbmeta digest is
          unavailable.

    Raises:
      ValueError: On invalid inputs.
    """
    self.info_dict = info_dict
    self.oem_dicts = oem_dicts

    self._is_ab = info_dict.get("ab_update") == "true"
    self.use_legacy_id = use_legacy_id

    # Skip _oem_props if oem_dicts is None to use BuildInfo in
    # sign_target_files_apks
    if self.oem_dicts:
      self._oem_props = info_dict.get("oem_fingerprint_properties")
    else:
      self._oem_props = None

    def check_fingerprint(fingerprint):
      if (" " in fingerprint or any(ord(ch) > 127 for ch in fingerprint)):
        raise ValueError(
            'Invalid build fingerprint: "{}". See the requirement in Android CDD '
            "3.2.2. Build Parameters.".format(fingerprint))

    self._partition_fingerprints = {}
    for partition in PARTITIONS_WITH_BUILD_PROP:
      try:
        fingerprint = self.CalculatePartitionFingerprint(partition)
        check_fingerprint(fingerprint)
        self._partition_fingerprints[partition] = fingerprint
      except ExternalError:
        continue
    if "system" in self._partition_fingerprints:
      # system_other is not included in PARTITIONS_WITH_BUILD_PROP, but does
      # need a fingerprint when creating the image.
      self._partition_fingerprints[
          "system_other"] = self._partition_fingerprints["system"]

    # These two should be computed only after setting self._oem_props.
    self._device = self.GetOemProperty("ro.product.device")
    self._fingerprint = self.CalculateFingerprint()
    check_fingerprint(self._fingerprint)

  @property
  def is_ab(self):
    return self._is_ab

  @property
  def device(self):
    return self._device

  @property
  def fingerprint(self):
    return self._fingerprint

  @property
  def is_vabc(self):
    return self.info_dict.get("virtual_ab_compression") == "true"

  @property
  def is_android_r(self):
    system_prop = self.info_dict.get("system.build.prop")
    return system_prop and system_prop.GetProp("ro.build.version.release") == "11"

  @property
  def is_release_key(self):
    system_prop = self.info_dict.get("build.prop")
    return system_prop and system_prop.GetProp("ro.build.tags") == "release-key"

  @property
  def vabc_compression_param(self):
    return self.get("virtual_ab_compression_method", "")

  @property
  def vendor_api_level(self):
    vendor_prop = self.info_dict.get("vendor.build.prop")
    if not vendor_prop:
      return -1

    props = [
        "ro.board.api_level",
        "ro.board.first_api_level",
        "ro.product.first_api_level",
    ]
    for prop in props:
      value = vendor_prop.GetProp(prop)
      try:
        return int(value)
      except:
        pass
    return -1

  @property
  def is_vabc_xor(self):
    vendor_prop = self.info_dict.get("vendor.build.prop")
    vabc_xor_enabled = vendor_prop and \
        vendor_prop.GetProp("ro.virtual_ab.compression.xor.enabled") == "true"
    return vabc_xor_enabled

  @property
  def vendor_suppressed_vabc(self):
    vendor_prop = self.info_dict.get("vendor.build.prop")
    vabc_suppressed = vendor_prop and \
        vendor_prop.GetProp("ro.vendor.build.dont_use_vabc")
    return vabc_suppressed and vabc_suppressed.lower() == "true"

  @property
  def oem_props(self):
    return self._oem_props

  def __getitem__(self, key):
    return self.info_dict[key]

  def __setitem__(self, key, value):
    self.info_dict[key] = value

  def get(self, key, default=None):
    return self.info_dict.get(key, default)

  def items(self):
    return self.info_dict.items()

  def _GetRawBuildProp(self, prop, partition):
    prop_file = '{}.build.prop'.format(
        partition) if partition else 'build.prop'
    partition_props = self.info_dict.get(prop_file)
    if not partition_props:
      return None
    return partition_props.GetProp(prop)

  def GetPartitionBuildProp(self, prop, partition):
    """Returns the inquired build property for the provided partition."""

    # Boot image and init_boot image uses ro.[product.]bootimage instead of boot.
    # This comes from the generic ramdisk
    prop_partition = "bootimage" if partition == "boot" or partition == "init_boot" else partition

    # If provided a partition for this property, only look within that
    # partition's build.prop.
    if prop in BuildInfo._RO_PRODUCT_RESOLVE_PROPS:
      prop = prop.replace("ro.product", "ro.product.{}".format(prop_partition))
    else:
      prop = prop.replace("ro.", "ro.{}.".format(prop_partition))

    prop_val = self._GetRawBuildProp(prop, partition)
    if prop_val is not None:
      return prop_val
    raise ExternalError("couldn't find %s in %s.build.prop" %
                        (prop, partition))

  def GetBuildProp(self, prop):
    """Returns the inquired build property from the standard build.prop file."""
    if prop in BuildInfo._RO_PRODUCT_RESOLVE_PROPS:
      return self._ResolveRoProductBuildProp(prop)

    if prop == "ro.build.id":
      return self._GetBuildId()

    prop_val = self._GetRawBuildProp(prop, None)
    if prop_val is not None:
      return prop_val

    raise ExternalError("couldn't find %s in build.prop" % (prop,))

  def _ResolveRoProductBuildProp(self, prop):
    """Resolves the inquired ro.product.* build property"""
    prop_val = self._GetRawBuildProp(prop, None)
    if prop_val:
      return prop_val

    default_source_order = self._GetRoProductPropsDefaultSourceOrder()
    source_order_val = self._GetRawBuildProp(
        "ro.product.property_source_order", None)
    if source_order_val:
      source_order = source_order_val.split(",")
    else:
      source_order = default_source_order

    # Check that all sources in ro.product.property_source_order are valid
    if any([x not in default_source_order for x in source_order]):
      raise ExternalError(
          "Invalid ro.product.property_source_order '{}'".format(source_order))

    for source_partition in source_order:
      source_prop = prop.replace(
          "ro.product", "ro.product.{}".format(source_partition), 1)
      prop_val = self._GetRawBuildProp(source_prop, source_partition)
      if prop_val:
        return prop_val

    raise ExternalError("couldn't resolve {}".format(prop))

  def _GetRoProductPropsDefaultSourceOrder(self):
    # NOTE: refer to CDDs and android.os.Build.VERSION for the definition and
    # values of these properties for each Android release.
    android_codename = self._GetRawBuildProp("ro.build.version.codename", None)
    if android_codename == "REL":
      android_version = self._GetRawBuildProp("ro.build.version.release", None)
      if android_version == "10":
        return BuildInfo._RO_PRODUCT_PROPS_DEFAULT_SOURCE_ORDER_ANDROID_10
      # NOTE: float() conversion of android_version will have rounding error.
      # We are checking for "9" or less, and using "< 10" is well outside of
      # possible floating point rounding.
      try:
        android_version_val = float(android_version)
      except ValueError:
        android_version_val = 0
      if android_version_val < 10:
        return BuildInfo._RO_PRODUCT_PROPS_DEFAULT_SOURCE_ORDER_LEGACY
    return BuildInfo._RO_PRODUCT_PROPS_DEFAULT_SOURCE_ORDER_CURRENT

  def _GetPlatformVersion(self):
    version_sdk = self.GetBuildProp("ro.build.version.sdk")
    # init code switches to version_release_or_codename (see b/158483506). After
    # API finalization, release_or_codename will be the same as release. This
    # is the best effort to support pre-S dev stage builds.
    if int(version_sdk) >= 30:
      try:
        return self.GetBuildProp("ro.build.version.release_or_codename")
      except ExternalError:
        logger.warning('Failed to find ro.build.version.release_or_codename')

    return self.GetBuildProp("ro.build.version.release")

  def _GetBuildId(self):
    build_id = self._GetRawBuildProp("ro.build.id", None)
    if build_id:
      return build_id

    legacy_build_id = self.GetBuildProp("ro.build.legacy.id")
    if not legacy_build_id:
      raise ExternalError("Couldn't find build id in property file")

    if self.use_legacy_id:
      return legacy_build_id

    # Append the top 8 chars of vbmeta digest to the existing build id. The
    # logic needs to match the one in init, so that OTA can deliver correctly.
    avb_enable = self.info_dict.get("avb_enable") == "true"
    if not avb_enable:
      raise ExternalError("AVB isn't enabled when using legacy build id")

    vbmeta_digest = self.info_dict.get("vbmeta_digest")
    if not vbmeta_digest:
      raise ExternalError("Vbmeta digest isn't provided when using legacy build"
                          " id")
    if len(vbmeta_digest) < self._VBMETA_DIGEST_SIZE_USED:
      raise ExternalError("Invalid vbmeta digest " + vbmeta_digest)

    digest_prefix = vbmeta_digest[:self._VBMETA_DIGEST_SIZE_USED]
    return legacy_build_id + '.' + digest_prefix

  def _GetPartitionPlatformVersion(self, partition):
    try:
      return self.GetPartitionBuildProp("ro.build.version.release_or_codename",
                                        partition)
    except ExternalError:
      return self.GetPartitionBuildProp("ro.build.version.release",
                                        partition)

  def GetOemProperty(self, key):
    if self.oem_props is not None and key in self.oem_props:
      return self.oem_dicts[0][key]
    return self.GetBuildProp(key)

  def GetPartitionFingerprint(self, partition):
    return self._partition_fingerprints.get(partition, None)

  def CalculatePartitionFingerprint(self, partition):
    try:
      return self.GetPartitionBuildProp("ro.build.fingerprint", partition)
    except ExternalError:
      return "{}/{}/{}:{}/{}/{}:{}/{}".format(
          self.GetPartitionBuildProp("ro.product.brand", partition),
          self.GetPartitionBuildProp("ro.product.name", partition),
          self.GetPartitionBuildProp("ro.product.device", partition),
          self._GetPartitionPlatformVersion(partition),
          self.GetPartitionBuildProp("ro.build.id", partition),
          self.GetPartitionBuildProp(
              "ro.build.version.incremental", partition),
          self.GetPartitionBuildProp("ro.build.type", partition),
          self.GetPartitionBuildProp("ro.build.tags", partition))

  def CalculateFingerprint(self):
    if self.oem_props is None:
      try:
        return self.GetBuildProp("ro.build.fingerprint")
      except ExternalError:
        return "{}/{}/{}:{}/{}/{}:{}/{}".format(
            self.GetBuildProp("ro.product.brand"),
            self.GetBuildProp("ro.product.name"),
            self.GetBuildProp("ro.product.device"),
            self._GetPlatformVersion(),
            self.GetBuildProp("ro.build.id"),
            self.GetBuildProp("ro.build.version.incremental"),
            self.GetBuildProp("ro.build.type"),
            self.GetBuildProp("ro.build.tags"))
    return "%s/%s/%s:%s" % (
        self.GetOemProperty("ro.product.brand"),
        self.GetOemProperty("ro.product.name"),
        self.GetOemProperty("ro.product.device"),
        self.GetBuildProp("ro.build.thumbprint"))

  def WriteMountOemScript(self, script):
    assert self.oem_props is not None
    recovery_mount_options = self.info_dict.get("recovery_mount_options")
    script.Mount("/oem", recovery_mount_options)

  def WriteDeviceAssertions(self, script, oem_no_mount):
    # Read the property directly if not using OEM properties.
    if not self.oem_props:
      script.AssertDevice(self.device)
      return

    # Otherwise assert OEM properties.
    if not self.oem_dicts:
      raise ExternalError(
          "No OEM file provided to answer expected assertions")

    for prop in self.oem_props.split():
      values = []
      for oem_dict in self.oem_dicts:
        if prop in oem_dict:
          values.append(oem_dict[prop])
      if not values:
        raise ExternalError(
            "The OEM file is missing the property %s" % (prop,))
      script.AssertOemProperty(prop, values, oem_no_mount)


def DoesInputFileContain(input_file, fn):
  """Check whether the input target_files.zip contain an entry `fn`"""
  if isinstance(input_file, zipfile.ZipFile):
    return fn in input_file.namelist()
  elif zipfile.is_zipfile(input_file):
    with zipfile.ZipFile(input_file, "r", allowZip64=True) as zfp:
      return fn in zfp.namelist()
  else:
    if not os.path.isdir(input_file):
      raise ValueError(
          "Invalid input_file, accepted inputs are ZipFile object, path to .zip file on disk, or path to extracted directory. Actual: " + input_file)
    path = os.path.join(input_file, *fn.split("/"))
    return os.path.exists(path)


def ReadBytesFromInputFile(input_file, fn):
  """Reads the bytes of fn from input zipfile or directory."""
  if isinstance(input_file, zipfile.ZipFile):
    return input_file.read(fn)
  elif zipfile.is_zipfile(input_file):
    with zipfile.ZipFile(input_file, "r", allowZip64=True) as zfp:
      return zfp.read(fn)
  else:
    if not os.path.isdir(input_file):
      raise ValueError(
          "Invalid input_file, accepted inputs are ZipFile object, path to .zip file on disk, or path to extracted directory. Actual: " + input_file)
    path = os.path.join(input_file, *fn.split("/"))
    try:
      with open(path, "rb") as f:
        return f.read()
    except IOError as e:
      if e.errno == errno.ENOENT:
        raise KeyError(fn)


def ReadFromInputFile(input_file, fn):
  """Reads the str contents of fn from input zipfile or directory."""
  return ReadBytesFromInputFile(input_file, fn).decode()


def WriteBytesToInputFile(input_file, fn, data):
  """Write bytes |data| contents to fn of input zipfile or directory."""
  if isinstance(input_file, zipfile.ZipFile):
    with input_file.open(fn, "w") as entry_fp:
      return entry_fp.write(data)
  elif zipfile.is_zipfile(input_file):
    with zipfile.ZipFile(input_file, "r", allowZip64=True) as zfp:
      with zfp.open(fn, "w") as entry_fp:
        return entry_fp.write(data)
  else:
    if not os.path.isdir(input_file):
      raise ValueError(
          "Invalid input_file, accepted inputs are ZipFile object, path to .zip file on disk, or path to extracted directory. Actual: " + input_file)
    path = os.path.join(input_file, *fn.split("/"))
    try:
      with open(path, "wb") as f:
        return f.write(data)
    except IOError as e:
      if e.errno == errno.ENOENT:
        raise KeyError(fn)


def WriteToInputFile(input_file, fn, str: str):
  """Write str content to fn of input file or directory"""
  return WriteBytesToInputFile(input_file, fn, str.encode())


def ExtractFromInputFile(input_file, fn):
  """Extracts the contents of fn from input zipfile or directory into a file."""
  if isinstance(input_file, zipfile.ZipFile):
    tmp_file = MakeTempFile(os.path.basename(fn))
    with open(tmp_file, 'wb') as f:
      f.write(input_file.read(fn))
    return tmp_file
  elif zipfile.is_zipfile(input_file):
    with zipfile.ZipFile(input_file, "r", allowZip64=True) as zfp:
      tmp_file = MakeTempFile(os.path.basename(fn))
      with open(tmp_file, "wb") as fp:
        fp.write(zfp.read(fn))
      return tmp_file
  else:
    if not os.path.isdir(input_file):
      raise ValueError(
          "Invalid input_file, accepted inputs are ZipFile object, path to .zip file on disk, or path to extracted directory. Actual: " + input_file)
    file = os.path.join(input_file, *fn.split("/"))
    if not os.path.exists(file):
      raise KeyError(fn)
    return file


class RamdiskFormat(object):
  LZ4 = 1
  GZ = 2


def GetRamdiskFormat(info_dict):
  if info_dict.get('lz4_ramdisks') == 'true':
    ramdisk_format = RamdiskFormat.LZ4
  else:
    ramdisk_format = RamdiskFormat.GZ
  return ramdisk_format


def LoadInfoDict(input_file, repacking=False):
  """Loads the key/value pairs from the given input target_files.

  It reads `META/misc_info.txt` file in the target_files input, does validation
  checks and returns the parsed key/value pairs for to the given build. It's
  usually called early when working on input target_files files, e.g. when
  generating OTAs, or signing builds. Note that the function may be called
  against an old target_files file (i.e. from past dessert releases). So the
  property parsing needs to be backward compatible.

  In a `META/misc_info.txt`, a few properties are stored as links to the files
  in the PRODUCT_OUT directory. It works fine with the build system. However,
  they are no longer available when (re)generating images from target_files zip.
  When `repacking` is True, redirect these properties to the actual files in the
  unzipped directory.

  Args:
    input_file: The input target_files file, which could be an open
        zipfile.ZipFile instance, or a str for the dir that contains the files
        unzipped from a target_files file.
    repacking: Whether it's trying repack an target_files file after loading the
        info dict (default: False). If so, it will rewrite a few loaded
        properties (e.g. selinux_fc, root_dir) to point to the actual files in
        target_files file. When doing repacking, `input_file` must be a dir.

  Returns:
    A dict that contains the parsed key/value pairs.

  Raises:
    AssertionError: On invalid input arguments.
    ValueError: On malformed input values.
  """
  if repacking:
    assert isinstance(input_file, str), \
        "input_file must be a path str when doing repacking"

  def read_helper(fn):
    return ReadFromInputFile(input_file, fn)

  try:
    d = LoadDictionaryFromLines(read_helper("META/misc_info.txt").split("\n"))
  except KeyError:
    raise ValueError("Failed to find META/misc_info.txt in input target-files")

  if "recovery_api_version" not in d:
    raise ValueError("Failed to find 'recovery_api_version'")
  if "fstab_version" not in d:
    raise ValueError("Failed to find 'fstab_version'")

  if repacking:
    # "selinux_fc" properties should point to the file_contexts files
    # (file_contexts.bin) under META/.
    for key in d:
      if key.endswith("selinux_fc"):
        fc_basename = os.path.basename(d[key])
        fc_config = os.path.join(input_file, "META", fc_basename)
        assert os.path.exists(fc_config)

        d[key] = fc_config

    # Similarly we need to redirect "root_dir", and "root_fs_config".
    d["root_dir"] = os.path.join(input_file, "ROOT")
    d["root_fs_config"] = os.path.join(
        input_file, "META", "root_filesystem_config.txt")

    # Redirect {partition}_base_fs_file for each of the named partitions.
    for part_name in ["system", "vendor", "system_ext", "product", "odm",
                      "vendor_dlkm", "odm_dlkm", "system_dlkm"]:
      key_name = part_name + "_base_fs_file"
      if key_name not in d:
        continue
      basename = os.path.basename(d[key_name])
      base_fs_file = os.path.join(input_file, "META", basename)
      if os.path.exists(base_fs_file):
        d[key_name] = base_fs_file
      else:
        logger.warning(
            "Failed to find %s base fs file: %s", part_name, base_fs_file)
        del d[key_name]

  def makeint(key):
    if key in d:
      d[key] = int(d[key], 0)

  makeint("recovery_api_version")
  makeint("blocksize")
  makeint("system_size")
  makeint("vendor_size")
  makeint("userdata_size")
  makeint("cache_size")
  makeint("recovery_size")
  makeint("fstab_version")

  boot_images = "boot.img"
  if "boot_images" in d:
    boot_images = d["boot_images"]
  for b in boot_images.split():
    makeint(b.replace(".img", "_size"))

  # Load recovery fstab if applicable.
  d["fstab"] = _FindAndLoadRecoveryFstab(d, input_file, read_helper)
  ramdisk_format = GetRamdiskFormat(d)

  # Tries to load the build props for all partitions with care_map, including
  # system and vendor.
  for partition in PARTITIONS_WITH_BUILD_PROP:
    partition_prop = "{}.build.prop".format(partition)
    d[partition_prop] = PartitionBuildProps.FromInputFile(
        input_file, partition, ramdisk_format=ramdisk_format)
  d["build.prop"] = d["system.build.prop"]

  if d.get("avb_enable") == "true":
    # Set the vbmeta digest if exists
    try:
      d["vbmeta_digest"] = read_helper("META/vbmeta_digest.txt").rstrip()
    except KeyError:
      pass

  try:
    d["ab_partitions"] = read_helper("META/ab_partitions.txt").split("\n")
  except KeyError:
    logger.warning("Can't find META/ab_partitions.txt")
  return d


def LoadListFromFile(file_path):
  with open(file_path) as f:
    return f.read().splitlines()


def LoadDictionaryFromFile(file_path):
  lines = LoadListFromFile(file_path)
  return LoadDictionaryFromLines(lines)


def LoadDictionaryFromLines(lines):
  d = {}
  for line in lines:
    line = line.strip()
    if not line or line.startswith("#"):
      continue
    if "=" in line:
      name, value = line.split("=", 1)
      d[name] = value
  return d


class PartitionBuildProps(object):
  """The class holds the build prop of a particular partition.

  This class loads the build.prop and holds the build properties for a given
  partition. It also partially recognizes the 'import' statement in the
  build.prop; and calculates alternative values of some specific build
  properties during runtime.

  Attributes:
    input_file: a zipped target-file or an unzipped target-file directory.
    partition: name of the partition.
    props_allow_override: a list of build properties to search for the
        alternative values during runtime.
    build_props: a dict of build properties for the given partition.
    prop_overrides: a set of props that are overridden by import.
    placeholder_values: A dict of runtime variables' values to replace the
        placeholders in the build.prop file. We expect exactly one value for
        each of the variables.
    ramdisk_format: If name is "boot", the format of ramdisk inside the
        boot image. Otherwise, its value is ignored.
        Use lz4 to decompress by default. If its value is gzip, use gzip.
  """

  def __init__(self, input_file, name, placeholder_values=None):
    self.input_file = input_file
    self.partition = name
    self.props_allow_override = [props.format(name) for props in [
        'ro.product.{}.brand', 'ro.product.{}.name', 'ro.product.{}.device']]
    self.build_props = {}
    self.prop_overrides = set()
    self.placeholder_values = {}
    if placeholder_values:
      self.placeholder_values = copy.deepcopy(placeholder_values)

  @staticmethod
  def FromDictionary(name, build_props):
    """Constructs an instance from a build prop dictionary."""

    props = PartitionBuildProps("unknown", name)
    props.build_props = build_props.copy()
    return props

  @staticmethod
  def FromInputFile(input_file, name, placeholder_values=None, ramdisk_format=RamdiskFormat.LZ4):
    """Loads the build.prop file and builds the attributes."""

    if name in ("boot", "init_boot"):
      data = PartitionBuildProps._ReadBootPropFile(
          input_file, name, ramdisk_format=ramdisk_format)
    else:
      data = PartitionBuildProps._ReadPartitionPropFile(input_file, name)

    props = PartitionBuildProps(input_file, name, placeholder_values)
    props._LoadBuildProp(data)
    return props

  @staticmethod
  def _ReadBootPropFile(input_file, partition_name, ramdisk_format):
    """
    Read build.prop for boot image from input_file.
    Return empty string if not found.
    """
    image_path = 'IMAGES/' + partition_name + '.img'
    try:
      boot_img = ExtractFromInputFile(input_file, image_path)
    except KeyError:
      logger.warning('Failed to read %s', image_path)
      return ''
    prop_file = GetBootImageBuildProp(boot_img, ramdisk_format=ramdisk_format)
    if prop_file is None:
      return ''
    with open(prop_file, "r") as f:
      return f.read()

  @staticmethod
  def _ReadPartitionPropFile(input_file, name):
    """
    Read build.prop for name from input_file.
    Return empty string if not found.
    """
    data = ''
    for prop_file in ['{}/etc/build.prop'.format(name.upper()),
                      '{}/build.prop'.format(name.upper())]:
      try:
        data = ReadFromInputFile(input_file, prop_file)
        break
      except KeyError:
        logger.warning('Failed to read %s', prop_file)
    if data == '':
      logger.warning("Failed to read build.prop for partition {}".format(name))
    return data

  @staticmethod
  def FromBuildPropFile(name, build_prop_file):
    """Constructs an instance from a build prop file."""

    props = PartitionBuildProps("unknown", name)
    with open(build_prop_file) as f:
      props._LoadBuildProp(f.read())
    return props

  def _LoadBuildProp(self, data):
    for line in data.split('\n'):
      line = line.strip()
      if not line or line.startswith("#"):
        continue
      if line.startswith("import"):
        overrides = self._ImportParser(line)
        duplicates = self.prop_overrides.intersection(overrides.keys())
        if duplicates:
          raise ValueError('prop {} is overridden multiple times'.format(
              ','.join(duplicates)))
        self.prop_overrides = self.prop_overrides.union(overrides.keys())
        self.build_props.update(overrides)
      elif "=" in line:
        name, value = line.split("=", 1)
        if name in self.prop_overrides:
          raise ValueError('prop {} is set again after overridden by import '
                           'statement'.format(name))
        self.build_props[name] = value

  def _ImportParser(self, line):
    """Parses the build prop in a given import statement."""

    tokens = line.split()
    if tokens[0] != 'import' or (len(tokens) != 2 and len(tokens) != 3):
      raise ValueError('Unrecognized import statement {}'.format(line))

    if len(tokens) == 3:
      logger.info("Import %s from %s, skip", tokens[2], tokens[1])
      return {}

    import_path = tokens[1]
    if not re.match(r'^/{}/.*\.prop$'.format(self.partition), import_path):
      logger.warn('Unrecognized import path {}'.format(line))
      return {}

    # We only recognize a subset of import statement that the init process
    # supports. And we can loose the restriction based on how the dynamic
    # fingerprint is used in practice. The placeholder format should be
    # ${placeholder}, and its value should be provided by the caller through
    # the placeholder_values.
    for prop, value in self.placeholder_values.items():
      prop_place_holder = '${{{}}}'.format(prop)
      if prop_place_holder in import_path:
        import_path = import_path.replace(prop_place_holder, value)
    if '$' in import_path:
      logger.info('Unresolved place holder in import path %s', import_path)
      return {}

    import_path = import_path.replace('/{}'.format(self.partition),
                                      self.partition.upper())
    logger.info('Parsing build props override from %s', import_path)

    lines = ReadFromInputFile(self.input_file, import_path).split('\n')
    d = LoadDictionaryFromLines(lines)
    return {key: val for key, val in d.items()
            if key in self.props_allow_override}

  def __getstate__(self):
    state = self.__dict__.copy()
    # Don't pickle baz
    if "input_file" in state and isinstance(state["input_file"], zipfile.ZipFile):
      state["input_file"] = state["input_file"].filename
    return state

  def GetProp(self, prop):
    return self.build_props.get(prop)


def LoadRecoveryFSTab(read_helper, fstab_version, recovery_fstab_path,
                      system_root_image=False):
  class Partition(object):
    def __init__(self, mount_point, fs_type, device, length, context, slotselect):
      self.mount_point = mount_point
      self.fs_type = fs_type
      self.device = device
      self.length = length
      self.context = context
      self.slotselect = slotselect

  try:
    data = read_helper(recovery_fstab_path)
  except KeyError:
    logger.warning("Failed to find %s", recovery_fstab_path)
    data = ""

  assert fstab_version == 2

  d = {}
  for line in data.split("\n"):
    line = line.strip()
    if not line or line.startswith("#"):
      continue

    # <src> <mnt_point> <type> <mnt_flags and options> <fs_mgr_flags>
    pieces = line.split()
    if len(pieces) != 5:
      raise ValueError("malformed recovery.fstab line: \"%s\"" % (line,))

    # Ignore entries that are managed by vold.
    options = pieces[4]
    if "voldmanaged=" in options:
      continue

    # It's a good line, parse it.
    length = 0
    slotselect = False
    options = options.split(",")
    for i in options:
      if i.startswith("length="):
        length = int(i[7:])
      elif i == "slotselect":
        slotselect = True
      else:
        # Ignore all unknown options in the unified fstab.
        continue

    mount_flags = pieces[3]
    # Honor the SELinux context if present.
    context = None
    for i in mount_flags.split(","):
      if i.startswith("context="):
        context = i

    mount_point = pieces[1]
    d[mount_point] = Partition(mount_point=mount_point, fs_type=pieces[2],
                               device=pieces[0], length=length, context=context,
                               slotselect=slotselect)

  # / is used for the system mount point when the root directory is included in
  # system. Other areas assume system is always at "/system" so point /system
  # at /.
  if system_root_image:
    assert '/system' not in d and '/' in d
    d["/system"] = d["/"]
  return d


def _FindAndLoadRecoveryFstab(info_dict, input_file, read_helper):
  """Finds the path to recovery fstab and loads its contents."""
  # recovery fstab is only meaningful when installing an update via recovery
  # (i.e. non-A/B OTA). Skip loading fstab if device used A/B OTA.
  if info_dict.get('ab_update') == 'true' and \
     info_dict.get("allow_non_ab") != "true":
    return None

  # We changed recovery.fstab path in Q, from ../RAMDISK/etc/recovery.fstab to
  # ../RAMDISK/system/etc/recovery.fstab. This function has to handle both
  # cases, since it may load the info_dict from an old build (e.g. when
  # generating incremental OTAs from that build).
  system_root_image = info_dict.get('system_root_image') == 'true'
  if info_dict.get('no_recovery') != 'true':
    recovery_fstab_path = 'RECOVERY/RAMDISK/system/etc/recovery.fstab'
    if not DoesInputFileContain(input_file, recovery_fstab_path):
      recovery_fstab_path = 'RECOVERY/RAMDISK/etc/recovery.fstab'
    return LoadRecoveryFSTab(
        read_helper, info_dict['fstab_version'], recovery_fstab_path,
        system_root_image)

  if info_dict.get('recovery_as_boot') == 'true':
    recovery_fstab_path = 'BOOT/RAMDISK/system/etc/recovery.fstab'
    if not DoesInputFileContain(input_file, recovery_fstab_path):
      recovery_fstab_path = 'BOOT/RAMDISK/etc/recovery.fstab'
    return LoadRecoveryFSTab(
        read_helper, info_dict['fstab_version'], recovery_fstab_path,
        system_root_image)

  return None


def DumpInfoDict(d):
  for k, v in sorted(d.items()):
    logger.info("%-25s = (%s) %s", k, type(v).__name__, v)


def MergeDynamicPartitionInfoDicts(framework_dict, vendor_dict):
  """Merges dynamic partition info variables.

  Args:
    framework_dict: The dictionary of dynamic partition info variables from the
      partial framework target files.
    vendor_dict: The dictionary of dynamic partition info variables from the
      partial vendor target files.

  Returns:
    The merged dynamic partition info dictionary.
  """

  def uniq_concat(a, b):
    combined = set(a.split())
    combined.update(set(b.split()))
    combined = [item.strip() for item in combined if item.strip()]
    return " ".join(sorted(combined))

  if (framework_dict.get("use_dynamic_partitions") !=
          "true") or (vendor_dict.get("use_dynamic_partitions") != "true"):
    raise ValueError("Both dictionaries must have use_dynamic_partitions=true")

  merged_dict = {"use_dynamic_partitions": "true"}
  # For keys-value pairs that are the same, copy to merged dict
  for key in vendor_dict.keys():
    if key in framework_dict and framework_dict[key] == vendor_dict[key]:
      merged_dict[key] = vendor_dict[key]

  merged_dict["dynamic_partition_list"] = uniq_concat(
      framework_dict.get("dynamic_partition_list", ""),
      vendor_dict.get("dynamic_partition_list", ""))

  # Super block devices are defined by the vendor dict.
  if "super_block_devices" in vendor_dict:
    merged_dict["super_block_devices"] = vendor_dict["super_block_devices"]
    for block_device in merged_dict["super_block_devices"].split():
      key = "super_%s_device_size" % block_device
      if key not in vendor_dict:
        raise ValueError("Vendor dict does not contain required key %s." % key)
      merged_dict[key] = vendor_dict[key]

  # Partition groups and group sizes are defined by the vendor dict because
  # these values may vary for each board that uses a shared system image.
  merged_dict["super_partition_groups"] = vendor_dict["super_partition_groups"]
  for partition_group in merged_dict["super_partition_groups"].split():
    # Set the partition group's size using the value from the vendor dict.
    key = "super_%s_group_size" % partition_group
    if key not in vendor_dict:
      raise ValueError("Vendor dict does not contain required key %s." % key)
    merged_dict[key] = vendor_dict[key]

    # Set the partition group's partition list using a concatenation of the
    # framework and vendor partition lists.
    key = "super_%s_partition_list" % partition_group
    merged_dict[key] = uniq_concat(
        framework_dict.get(key, ""), vendor_dict.get(key, ""))

  # Various other flags should be copied from the vendor dict, if defined.
  for key in ("virtual_ab", "virtual_ab_retrofit", "lpmake",
              "super_metadata_device", "super_partition_error_limit",
              "super_partition_size"):
    if key in vendor_dict.keys():
      merged_dict[key] = vendor_dict[key]

  return merged_dict


def PartitionMapFromTargetFiles(target_files_dir):
  """Builds a map from partition -> path within an extracted target files directory."""
  # Keep possible_subdirs in sync with build/make/core/board_config.mk.
  possible_subdirs = {
      "system": ["SYSTEM"],
      "vendor": ["VENDOR", "SYSTEM/vendor"],
      "product": ["PRODUCT", "SYSTEM/product"],
      "system_ext": ["SYSTEM_EXT", "SYSTEM/system_ext"],
      "odm": ["ODM", "VENDOR/odm", "SYSTEM/vendor/odm"],
      "vendor_dlkm": [
          "VENDOR_DLKM", "VENDOR/vendor_dlkm", "SYSTEM/vendor/vendor_dlkm"
      ],
      "odm_dlkm": ["ODM_DLKM", "VENDOR/odm_dlkm", "SYSTEM/vendor/odm_dlkm"],
      "system_dlkm": ["SYSTEM_DLKM", "SYSTEM/system_dlkm"],
  }
  partition_map = {}
  for partition, subdirs in possible_subdirs.items():
    for subdir in subdirs:
      if os.path.exists(os.path.join(target_files_dir, subdir)):
        partition_map[partition] = subdir
        break
  return partition_map


def SharedUidPartitionViolations(uid_dict, partition_groups):
  """Checks for APK sharedUserIds that cross partition group boundaries.

  This uses a single or merged build's shareduid_violation_modules.json
  output file, as generated by find_shareduid_violation.py or
  core/tasks/find-shareduid-violation.mk.

  An error is defined as a sharedUserId that is found in a set of partitions
  that span more than one partition group.

  Args:
    uid_dict: A dictionary created by using the standard json module to read a
      complete shareduid_violation_modules.json file.
    partition_groups: A list of groups, where each group is a list of
      partitions.

  Returns:
    A list of error messages.
  """
  errors = []
  for uid, partitions in uid_dict.items():
    found_in_groups = [
        group for group in partition_groups
        if set(partitions.keys()) & set(group)
    ]
    if len(found_in_groups) > 1:
      errors.append(
          "APK sharedUserId \"%s\" found across partition groups in partitions \"%s\""
          % (uid, ",".join(sorted(partitions.keys()))))
  return errors


def RunHostInitVerifier(product_out, partition_map):
  """Runs host_init_verifier on the init rc files within partitions.

  host_init_verifier searches the etc/init path within each partition.

  Args:
    product_out: PRODUCT_OUT directory, containing partition directories.
    partition_map: A map of partition name -> relative path within product_out.
  """
  allowed_partitions = ("system", "system_ext", "product", "vendor", "odm")
  cmd = ["host_init_verifier"]
  for partition, path in partition_map.items():
    if partition not in allowed_partitions:
      raise ExternalError("Unable to call host_init_verifier for partition %s" %
                          partition)
    cmd.extend(["--out_%s" % partition, os.path.join(product_out, path)])
    # Add --property-contexts if the file exists on the partition.
    property_contexts = "%s_property_contexts" % (
        "plat" if partition == "system" else partition)
    property_contexts_path = os.path.join(product_out, path, "etc", "selinux",
                                          property_contexts)
    if os.path.exists(property_contexts_path):
      cmd.append("--property-contexts=%s" % property_contexts_path)
    # Add the passwd file if the file exists on the partition.
    passwd_path = os.path.join(product_out, path, "etc", "passwd")
    if os.path.exists(passwd_path):
      cmd.extend(["-p", passwd_path])
  return RunAndCheckOutput(cmd)


def AppendAVBSigningArgs(cmd, partition, avb_salt=None):
  """Append signing arguments for avbtool."""
  # e.g., "--key path/to/signing_key --algorithm SHA256_RSA4096"
  key_path = ResolveAVBSigningPathArgs(
      OPTIONS.info_dict.get("avb_" + partition + "_key_path"))
  algorithm = OPTIONS.info_dict.get("avb_" + partition + "_algorithm")
  if key_path and algorithm:
    cmd.extend(["--key", key_path, "--algorithm", algorithm])
  if avb_salt is None:
    avb_salt = OPTIONS.info_dict.get("avb_salt")
  # make_vbmeta_image doesn't like "--salt" (and it's not needed).
  if avb_salt and not partition.startswith("vbmeta"):
    cmd.extend(["--salt", avb_salt])


def ResolveAVBSigningPathArgs(split_args):

  def ResolveBinaryPath(path):
    if os.path.exists(path):
      return path
    if OPTIONS.search_path:
      new_path = os.path.join(OPTIONS.search_path, path)
      if os.path.exists(new_path):
        return new_path
    raise ExternalError(
        "Failed to find {}".format(path))

  if not split_args:
    return split_args

  if isinstance(split_args, list):
    for index, arg in enumerate(split_args[:-1]):
      if arg == '--signing_helper':
        signing_helper_path = split_args[index + 1]
        split_args[index + 1] = ResolveBinaryPath(signing_helper_path)
        break
  elif isinstance(split_args, str):
    split_args = ResolveBinaryPath(split_args)

  return split_args


def GetAvbPartitionArg(partition, image, info_dict=None):
  """Returns the VBMeta arguments for one partition.

  It sets up the VBMeta argument by including the partition descriptor from the
  given 'image', or by configuring the partition as a chained partition.

  Args:
    partition: The name of the partition (e.g. "system").
    image: The path to the partition image.
    info_dict: A dict returned by common.LoadInfoDict(). Will use
        OPTIONS.info_dict if None has been given.

  Returns:
    A list of VBMeta arguments for one partition.
  """
  if info_dict is None:
    info_dict = OPTIONS.info_dict

  # Check if chain partition is used.
  key_path = info_dict.get("avb_" + partition + "_key_path")
  if not key_path:
    return [AVB_ARG_NAME_INCLUDE_DESC_FROM_IMG, image]

  # For a non-A/B device, we don't chain /recovery nor include its descriptor
  # into vbmeta.img. The recovery image will be configured on an independent
  # boot chain, to be verified with AVB_SLOT_VERIFY_FLAGS_NO_VBMETA_PARTITION.
  # See details at
  # https://android.googlesource.com/platform/external/avb/+/master/README.md#booting-into-recovery.
  if info_dict.get("ab_update") != "true" and partition == "recovery":
    return []

  # Otherwise chain the partition into vbmeta.
  chained_partition_arg = GetAvbChainedPartitionArg(partition, info_dict)
  return [AVB_ARG_NAME_CHAIN_PARTITION, chained_partition_arg]


def GetAvbPartitionsArg(partitions,
                        resolve_rollback_index_location_conflict=False,
                        info_dict=None):
  """Returns the VBMeta arguments for all AVB partitions.

  It sets up the VBMeta argument by calling GetAvbPartitionArg of all
  partitions.

  Args:
    partitions: A dict of all AVB partitions.
    resolve_rollback_index_location_conflict: If true, resolve conflicting avb
        rollback index locations by assigning the smallest unused value.
    info_dict: A dict returned by common.LoadInfoDict().

  Returns:
    A list of VBMeta arguments for all partitions.
  """
  # An AVB partition will be linked into a vbmeta partition by either
  # AVB_ARG_NAME_INCLUDE_DESC_FROM_IMG or AVB_ARG_NAME_CHAIN_PARTITION, there
  # should be no other cases.
  valid_args = {
      AVB_ARG_NAME_INCLUDE_DESC_FROM_IMG: [],
      AVB_ARG_NAME_CHAIN_PARTITION: []
  }

  for partition, path in partitions.items():
    avb_partition_arg = GetAvbPartitionArg(partition, path, info_dict)
    if not avb_partition_arg:
      continue
    arg_name, arg_value = avb_partition_arg
    assert arg_name in valid_args
    valid_args[arg_name].append(arg_value)

  # Copy the arguments for non-chained AVB partitions directly without
  # intervention.
  avb_args = []
  for image in valid_args[AVB_ARG_NAME_INCLUDE_DESC_FROM_IMG]:
    avb_args.extend([AVB_ARG_NAME_INCLUDE_DESC_FROM_IMG, image])

  # Handle chained AVB partitions. The rollback index location might be
  # adjusted if two partitions use the same value. This may happen when mixing
  # a shared system image with other vendor images.
  used_index_loc = set()
  for chained_partition_arg in valid_args[AVB_ARG_NAME_CHAIN_PARTITION]:
    if resolve_rollback_index_location_conflict:
      while chained_partition_arg.rollback_index_location in used_index_loc:
        chained_partition_arg.rollback_index_location += 1

    used_index_loc.add(chained_partition_arg.rollback_index_location)
    avb_args.extend([AVB_ARG_NAME_CHAIN_PARTITION,
                     chained_partition_arg.to_string()])

  return avb_args


def GetAvbChainedPartitionArg(partition, info_dict, key=None):
  """Constructs and returns the arg to build or verify a chained partition.

  Args:
    partition: The partition name.
    info_dict: The info dict to look up the key info and rollback index
        location.
    key: The key to be used for building or verifying the partition. Defaults to
        the key listed in info_dict.

  Returns:
    An AvbChainedPartitionArg object with rollback_index_location and
    pubkey_path that can be used to build or verify vbmeta image.
  """
  if key is None:
    key = info_dict["avb_" + partition + "_key_path"]
  key = ResolveAVBSigningPathArgs(key)
  pubkey_path = ExtractAvbPublicKey(info_dict["avb_avbtool"], key)
  rollback_index_location = info_dict[
      "avb_" + partition + "_rollback_index_location"]
  return AvbChainedPartitionArg(
      partition=partition,
      rollback_index_location=int(rollback_index_location),
      pubkey_path=pubkey_path)


def _HasGkiCertificationArgs():
  return ("gki_signing_key_path" in OPTIONS.info_dict and
          "gki_signing_algorithm" in OPTIONS.info_dict)


def _GenerateGkiCertificate(image, image_name):
  key_path = OPTIONS.info_dict.get("gki_signing_key_path")
  algorithm = OPTIONS.info_dict.get("gki_signing_algorithm")

  key_path = ResolveAVBSigningPathArgs(key_path)

  # Checks key_path exists, before processing --gki_signing_* args.
  if not os.path.exists(key_path):
    raise ExternalError(
        'gki_signing_key_path: "{}" not found'.format(key_path))

  output_certificate = tempfile.NamedTemporaryFile()
  cmd = [
      "generate_gki_certificate",
      "--name", image_name,
      "--algorithm", algorithm,
      "--key", key_path,
      "--output", output_certificate.name,
      image,
  ]

  signature_args = OPTIONS.info_dict.get("gki_signing_signature_args", "")
  signature_args = signature_args.strip()
  if signature_args:
    cmd.extend(["--additional_avb_args", signature_args])

  args = OPTIONS.info_dict.get("avb_boot_add_hash_footer_args", "")
  args = args.strip()
  if args:
    cmd.extend(["--additional_avb_args", args])

  RunAndCheckOutput(cmd)

  output_certificate.seek(os.SEEK_SET, 0)
  data = output_certificate.read()
  output_certificate.close()
  return data


def BuildVBMeta(image_path, partitions, name, needed_partitions,
                resolve_rollback_index_location_conflict=False):
  """Creates a VBMeta image.

  It generates the requested VBMeta image. The requested image could be for
  top-level or chained VBMeta image, which is determined based on the name.

  Args:
    image_path: The output path for the new VBMeta image.
    partitions: A dict that's keyed by partition names with image paths as
        values. Only valid partition names are accepted, as partitions listed
        in common.AVB_PARTITIONS and custom partitions listed in
        OPTIONS.info_dict.get("avb_custom_images_partition_list")
    name: Name of the VBMeta partition, e.g. 'vbmeta', 'vbmeta_system'.
    needed_partitions: Partitions whose descriptors should be included into the
        generated VBMeta image.
    resolve_rollback_index_location_conflict: If true, resolve conflicting avb
        rollback index locations by assigning the smallest unused value.

  Raises:
    AssertionError: On invalid input args.
  """
  avbtool = OPTIONS.info_dict["avb_avbtool"]
  cmd = [avbtool, "make_vbmeta_image", "--output", image_path]
  AppendAVBSigningArgs(cmd, name)

  custom_partitions = OPTIONS.info_dict.get(
      "avb_custom_images_partition_list", "").strip().split()
  custom_avb_partitions = ["vbmeta_" + part for part in OPTIONS.info_dict.get(
      "avb_custom_vbmeta_images_partition_list", "").strip().split()]

  avb_partitions = {}
  for partition, path in partitions.items():
    if partition not in needed_partitions:
      continue
    assert (partition in AVB_PARTITIONS or
            partition in AVB_VBMETA_PARTITIONS or
            partition in custom_avb_partitions or
            partition in custom_partitions), \
        'Unknown partition: {}'.format(partition)
    assert os.path.exists(path), \
        'Failed to find {} for {}'.format(path, partition)
    avb_partitions[partition] = path
  cmd.extend(GetAvbPartitionsArg(avb_partitions,
                                 resolve_rollback_index_location_conflict))

  args = OPTIONS.info_dict.get("avb_{}_args".format(name))
  if args and args.strip():
    split_args = shlex.split(args)
    for index, arg in enumerate(split_args[:-1]):
      # Check that the image file exists. Some images might be defined
      # as a path relative to source tree, which may not be available at the
      # same location when running this script (we have the input target_files
      # zip only). For such cases, we additionally scan other locations (e.g.
      # IMAGES/, RADIO/, etc) before bailing out.
      if arg == AVB_ARG_NAME_INCLUDE_DESC_FROM_IMG:
        chained_image = split_args[index + 1]
        if os.path.exists(chained_image):
          continue
        found = False
        for dir_name in ['IMAGES', 'RADIO', 'PREBUILT_IMAGES']:
          alt_path = os.path.join(
              OPTIONS.input_tmp, dir_name, os.path.basename(chained_image))
          if os.path.exists(alt_path):
            split_args[index + 1] = alt_path
            found = True
            break
        assert found, 'Failed to find {}'.format(chained_image)

    split_args = ResolveAVBSigningPathArgs(split_args)
    cmd.extend(split_args)

  RunAndCheckOutput(cmd)


def _MakeRamdisk(sourcedir, fs_config_file=None,
                 dev_node_file=None,
                 ramdisk_format=RamdiskFormat.GZ):
  ramdisk_img = tempfile.NamedTemporaryFile()

  cmd = ["mkbootfs"]

  if fs_config_file and os.access(fs_config_file, os.F_OK):
    cmd.extend(["-f", fs_config_file])

  if dev_node_file and os.access(dev_node_file, os.F_OK):
    cmd.extend(["-n", dev_node_file])

  cmd.append(os.path.join(sourcedir, "RAMDISK"))

  p1 = Run(cmd, stdout=subprocess.PIPE)
  if ramdisk_format == RamdiskFormat.LZ4:
    p2 = Run(["lz4", "-l", "-12", "--favor-decSpeed"], stdin=p1.stdout,
             stdout=ramdisk_img.file.fileno())
  elif ramdisk_format == RamdiskFormat.GZ:
    p2 = Run(["gzip"], stdin=p1.stdout, stdout=ramdisk_img.file.fileno())
  else:
    raise ValueError("Only support lz4 or gzip ramdisk format.")

  p2.wait()
  p1.wait()
  assert p1.returncode == 0, "mkbootfs of %s ramdisk failed" % (sourcedir,)
  assert p2.returncode == 0, "compression of %s ramdisk failed" % (sourcedir,)

  return ramdisk_img


def _BuildBootableImage(image_name, sourcedir, fs_config_file,
                        dev_node_file=None, info_dict=None,
                        has_ramdisk=False, two_step_image=False):
  """Build a bootable image from the specified sourcedir.

  Take a kernel, cmdline, and optionally a ramdisk directory from the input (in
  'sourcedir'), and turn them into a boot image. 'two_step_image' indicates if
  we are building a two-step special image (i.e. building a recovery image to
  be loaded into /boot in two-step OTAs).

  Return the image data, or None if sourcedir does not appear to contains files
  for building the requested image.
  """

  if info_dict is None:
    info_dict = OPTIONS.info_dict

  # "boot" or "recovery", without extension.
  partition_name = os.path.basename(sourcedir).lower()

  kernel = None
  if partition_name == "recovery":
    if info_dict.get("exclude_kernel_from_recovery_image") == "true":
      logger.info("Excluded kernel binary from recovery image.")
    else:
      kernel = "kernel"
  elif partition_name == "init_boot":
    pass
  else:
    kernel = image_name.replace("boot", "kernel")
    kernel = kernel.replace(".img", "")
  if kernel and not os.access(os.path.join(sourcedir, kernel), os.F_OK):
    return None

  kernel_path = os.path.join(sourcedir, kernel) if kernel else None

  if has_ramdisk and not os.access(os.path.join(sourcedir, "RAMDISK"), os.F_OK):
    return None

  img = tempfile.NamedTemporaryFile()

  if has_ramdisk:
    ramdisk_format = GetRamdiskFormat(info_dict)
    ramdisk_img = _MakeRamdisk(sourcedir, fs_config_file, dev_node_file,
                               ramdisk_format=ramdisk_format)

  # use MKBOOTIMG from environ, or "mkbootimg" if empty or not set
  mkbootimg = os.getenv('MKBOOTIMG') or "mkbootimg"

  cmd = [mkbootimg]
  if kernel_path is not None:
    cmd.extend(["--kernel", kernel_path])

  fn = os.path.join(sourcedir, "second")
  if os.access(fn, os.F_OK):
    cmd.append("--second")
    cmd.append(fn)

  fn = os.path.join(sourcedir, "dtb")
  if os.access(fn, os.F_OK):
    cmd.append("--dtb")
    cmd.append(fn)

  fn = os.path.join(sourcedir, "cmdline")
  if os.access(fn, os.F_OK):
    cmd.append("--cmdline")
    cmd.append(open(fn).read().rstrip("\n"))

  fn = os.path.join(sourcedir, "base")
  if os.access(fn, os.F_OK):
    cmd.append("--base")
    cmd.append(open(fn).read().rstrip("\n"))

  fn = os.path.join(sourcedir, "pagesize")
  if os.access(fn, os.F_OK):
    cmd.append("--pagesize")
    cmd.append(open(fn).read().rstrip("\n"))

  if partition_name == "recovery":
    args = info_dict.get("recovery_mkbootimg_args")
    if not args:
      # Fall back to "mkbootimg_args" for recovery image
      # in case "recovery_mkbootimg_args" is not set.
      args = info_dict.get("mkbootimg_args")
  elif partition_name == "init_boot":
    args = info_dict.get("mkbootimg_init_args")
  else:
    args = info_dict.get("mkbootimg_args")
  if args and args.strip():
    cmd.extend(shlex.split(args))

  args = info_dict.get("mkbootimg_version_args")
  if args and args.strip():
    cmd.extend(shlex.split(args))

  if has_ramdisk:
    cmd.extend(["--ramdisk", ramdisk_img.name])

  img_unsigned = None
  if info_dict.get("vboot"):
    img_unsigned = tempfile.NamedTemporaryFile()
    cmd.extend(["--output", img_unsigned.name])
  else:
    cmd.extend(["--output", img.name])

  if partition_name == "recovery":
    if info_dict.get("include_recovery_dtbo") == "true":
      fn = os.path.join(sourcedir, "recovery_dtbo")
      cmd.extend(["--recovery_dtbo", fn])
    if info_dict.get("include_recovery_acpio") == "true":
      fn = os.path.join(sourcedir, "recovery_acpio")
      cmd.extend(["--recovery_acpio", fn])

  RunAndCheckOutput(cmd)

  if _HasGkiCertificationArgs():
    if not os.path.exists(img.name):
      raise ValueError("Cannot find GKI boot.img")
    if kernel_path is None or not os.path.exists(kernel_path):
      raise ValueError("Cannot find GKI kernel.img")

    # Certify GKI images.
    boot_signature_bytes = b''
    boot_signature_bytes += _GenerateGkiCertificate(img.name, "boot")
    boot_signature_bytes += _GenerateGkiCertificate(
        kernel_path, "generic_kernel")

    BOOT_SIGNATURE_SIZE = 16 * 1024
    if len(boot_signature_bytes) > BOOT_SIGNATURE_SIZE:
      raise ValueError(
          f"GKI boot_signature size must be <= {BOOT_SIGNATURE_SIZE}")
    boot_signature_bytes += (
        b'\0' * (BOOT_SIGNATURE_SIZE - len(boot_signature_bytes)))
    assert len(boot_signature_bytes) == BOOT_SIGNATURE_SIZE

    with open(img.name, 'ab') as f:
      f.write(boot_signature_bytes)

  # Sign the image if vboot is non-empty.
  if info_dict.get("vboot"):
    path = "/" + partition_name
    img_keyblock = tempfile.NamedTemporaryFile()
    # We have switched from the prebuilt futility binary to using the tool
    # (futility-host) built from the source. Override the setting in the old
    # TF.zip.
    futility = info_dict["futility"]
    if futility.startswith("prebuilts/"):
      futility = "futility-host"
    cmd = [info_dict["vboot_signer_cmd"], futility,
           img_unsigned.name, info_dict["vboot_key"] + ".vbpubk",
           info_dict["vboot_key"] + ".vbprivk",
           info_dict["vboot_subkey"] + ".vbprivk",
           img_keyblock.name,
           img.name]
    RunAndCheckOutput(cmd)

    # Clean up the temp files.
    img_unsigned.close()
    img_keyblock.close()

  # AVB: if enabled, calculate and add hash to boot.img or recovery.img.
  if info_dict.get("avb_enable") == "true":
    avbtool = info_dict["avb_avbtool"]
    if partition_name == "recovery":
      part_size = info_dict["recovery_size"]
    else:
      part_size = info_dict[image_name.replace(".img", "_size")]
    cmd = [avbtool, "add_hash_footer", "--image", img.name,
           "--partition_size", str(part_size), "--partition_name",
           partition_name]
    salt = None
    if kernel_path is not None:
      with open(kernel_path, "rb") as fp:
        salt = sha256(fp.read()).hexdigest()
    AppendAVBSigningArgs(cmd, partition_name, salt)
    args = info_dict.get("avb_" + partition_name + "_add_hash_footer_args")
    if args and args.strip():
      split_args = ResolveAVBSigningPathArgs(shlex.split(args))
      cmd.extend(split_args)
    RunAndCheckOutput(cmd)

  img.seek(os.SEEK_SET, 0)
  data = img.read()

  if has_ramdisk:
    ramdisk_img.close()
  img.close()

  return data


def _SignBootableImage(image_path, prebuilt_name, partition_name,
                       info_dict=None):
  """Performs AVB signing for a prebuilt boot.img.

  Args:
    image_path: The full path of the image, e.g., /path/to/boot.img.
    prebuilt_name: The prebuilt image name, e.g., boot.img, boot-5.4-gz.img,
        boot-5.10.img, recovery.img or init_boot.img.
    partition_name: The partition name, e.g., 'boot', 'init_boot' or 'recovery'.
    info_dict: The information dict read from misc_info.txt.
  """
  if info_dict is None:
    info_dict = OPTIONS.info_dict

  # AVB: if enabled, calculate and add hash to boot.img or recovery.img.
  if info_dict.get("avb_enable") == "true":
    avbtool = info_dict["avb_avbtool"]
    if partition_name == "recovery":
      part_size = info_dict["recovery_size"]
    else:
      part_size = info_dict[prebuilt_name.replace(".img", "_size")]

    cmd = [avbtool, "add_hash_footer", "--image", image_path,
           "--partition_size", str(part_size), "--partition_name",
           partition_name]
    # Use sha256 of the kernel as salt for reproducible builds
    with tempfile.TemporaryDirectory() as tmpdir:
      RunAndCheckOutput(["unpack_bootimg", "--boot_img", image_path, "--out", tmpdir])
      for filename in ["kernel", "ramdisk", "vendor_ramdisk00"]:
        path = os.path.join(tmpdir, filename)
        if os.path.exists(path) and os.path.getsize(path):
          print("Using {} as salt for avb footer of {}".format(
              filename, partition_name))
          with open(path, "rb") as fp:
            salt = sha256(fp.read()).hexdigest()
            break
    AppendAVBSigningArgs(cmd, partition_name, salt)
    args = info_dict.get("avb_" + partition_name + "_add_hash_footer_args")
    if args and args.strip():
      split_args = ResolveAVBSigningPathArgs(shlex.split(args))
      cmd.extend(split_args)
    RunAndCheckOutput(cmd)


def HasRamdisk(partition_name, info_dict=None):
  """Returns true/false to see if a bootable image should have a ramdisk.

  Args:
    partition_name: The partition name, e.g., 'boot', 'init_boot' or 'recovery'.
    info_dict: The information dict read from misc_info.txt.
  """
  if info_dict is None:
    info_dict = OPTIONS.info_dict

  if partition_name != "boot":
    return True  # init_boot.img or recovery.img has a ramdisk.

  if info_dict.get("recovery_as_boot") == "true":
    return True  # the recovery-as-boot boot.img has a RECOVERY ramdisk.

  if info_dict.get("gki_boot_image_without_ramdisk") == "true":
    return False  # A GKI boot.img has no ramdisk since Android-13.

  if info_dict.get("system_root_image") == "true":
    # The ramdisk content is merged into the system.img, so there is NO
    # ramdisk in the boot.img or boot-<kernel version>.img.
    return False

  if info_dict.get("init_boot") == "true":
    # The ramdisk is moved to the init_boot.img, so there is NO
    # ramdisk in the boot.img or boot-<kernel version>.img.
    return False

  return True


def GetBootableImage(name, prebuilt_name, unpack_dir, tree_subdir,
                     info_dict=None, two_step_image=False,
                     dev_nodes=False):
  """Return a File object with the desired bootable image.

  Look for it in 'unpack_dir'/BOOTABLE_IMAGES under the name 'prebuilt_name',
  otherwise look for it under 'unpack_dir'/IMAGES, otherwise construct it from
  the source files in 'unpack_dir'/'tree_subdir'."""

  if info_dict is None:
    info_dict = OPTIONS.info_dict

  prebuilt_path = os.path.join(unpack_dir, "BOOTABLE_IMAGES", prebuilt_name)
  if os.path.exists(prebuilt_path):
    logger.info("using prebuilt %s from BOOTABLE_IMAGES...", prebuilt_name)
    return File.FromLocalFile(name, prebuilt_path)

  prebuilt_path = os.path.join(unpack_dir, "IMAGES", prebuilt_name)
  if os.path.exists(prebuilt_path):
    logger.info("using prebuilt %s from IMAGES...", prebuilt_name)
    return File.FromLocalFile(name, prebuilt_path)

  partition_name = tree_subdir.lower()
  prebuilt_path = os.path.join(unpack_dir, "PREBUILT_IMAGES", prebuilt_name)
  if os.path.exists(prebuilt_path):
    logger.info("Re-signing prebuilt %s from PREBUILT_IMAGES...", prebuilt_name)
    signed_img = MakeTempFile()
    shutil.copy(prebuilt_path, signed_img)
    _SignBootableImage(signed_img, prebuilt_name, partition_name, info_dict)
    return File.FromLocalFile(name, signed_img)

  logger.info("building image from target_files %s...", tree_subdir)

  has_ramdisk = HasRamdisk(partition_name, info_dict)

  fs_config = "META/" + tree_subdir.lower() + "_filesystem_config.txt"
  data = _BuildBootableImage(prebuilt_name, os.path.join(unpack_dir, tree_subdir),
                             os.path.join(unpack_dir, fs_config),
                             os.path.join(unpack_dir, 'META/ramdisk_node_list')
                             if dev_nodes else None,
                             info_dict, has_ramdisk, two_step_image)
  if data:
    return File(name, data)
  return None


def _BuildVendorBootImage(sourcedir, partition_name, info_dict=None):
  """Build a vendor boot image from the specified sourcedir.

  Take a ramdisk, dtb, and vendor_cmdline from the input (in 'sourcedir'), and
  turn them into a vendor boot image.

  Return the image data, or None if sourcedir does not appear to contains files
  for building the requested image.
  """

  if info_dict is None:
    info_dict = OPTIONS.info_dict

  img = tempfile.NamedTemporaryFile()

  ramdisk_format = GetRamdiskFormat(info_dict)
  ramdisk_img = _MakeRamdisk(sourcedir, ramdisk_format=ramdisk_format)

  # use MKBOOTIMG from environ, or "mkbootimg" if empty or not set
  mkbootimg = os.getenv('MKBOOTIMG') or "mkbootimg"

  cmd = [mkbootimg]

  fn = os.path.join(sourcedir, "dtb")
  if os.access(fn, os.F_OK):
    has_vendor_kernel_boot = (info_dict.get(
        "vendor_kernel_boot", "").lower() == "true")

    # Pack dtb into vendor_kernel_boot if building vendor_kernel_boot.
    # Otherwise pack dtb into vendor_boot.
    if not has_vendor_kernel_boot or partition_name == "vendor_kernel_boot":
      cmd.append("--dtb")
      cmd.append(fn)

  fn = os.path.join(sourcedir, "vendor_cmdline")
  if os.access(fn, os.F_OK):
    cmd.append("--vendor_cmdline")
    cmd.append(open(fn).read().rstrip("\n"))

  fn = os.path.join(sourcedir, "base")
  if os.access(fn, os.F_OK):
    cmd.append("--base")
    cmd.append(open(fn).read().rstrip("\n"))

  fn = os.path.join(sourcedir, "pagesize")
  if os.access(fn, os.F_OK):
    cmd.append("--pagesize")
    cmd.append(open(fn).read().rstrip("\n"))

  args = info_dict.get("mkbootimg_args")
  if args and args.strip():
    cmd.extend(shlex.split(args))

  args = info_dict.get("mkbootimg_version_args")
  if args and args.strip():
    cmd.extend(shlex.split(args))

  cmd.extend(["--vendor_ramdisk", ramdisk_img.name])
  cmd.extend(["--vendor_boot", img.name])

  fn = os.path.join(sourcedir, "vendor_bootconfig")
  if os.access(fn, os.F_OK):
    cmd.append("--vendor_bootconfig")
    cmd.append(fn)

  ramdisk_fragment_imgs = []
  fn = os.path.join(sourcedir, "vendor_ramdisk_fragments")
  if os.access(fn, os.F_OK):
    ramdisk_fragments = shlex.split(open(fn).read().rstrip("\n"))
    for ramdisk_fragment in ramdisk_fragments:
      fn = os.path.join(sourcedir, "RAMDISK_FRAGMENTS",
                        ramdisk_fragment, "mkbootimg_args")
      cmd.extend(shlex.split(open(fn).read().rstrip("\n")))
      fn = os.path.join(sourcedir, "RAMDISK_FRAGMENTS",
                        ramdisk_fragment, "prebuilt_ramdisk")
      # Use prebuilt image if found, else create ramdisk from supplied files.
      if os.access(fn, os.F_OK):
        ramdisk_fragment_pathname = fn
      else:
        ramdisk_fragment_root = os.path.join(
            sourcedir, "RAMDISK_FRAGMENTS", ramdisk_fragment)
        ramdisk_fragment_img = _MakeRamdisk(ramdisk_fragment_root,
                                            ramdisk_format=ramdisk_format)
        ramdisk_fragment_imgs.append(ramdisk_fragment_img)
        ramdisk_fragment_pathname = ramdisk_fragment_img.name
      cmd.extend(["--vendor_ramdisk_fragment", ramdisk_fragment_pathname])

  RunAndCheckOutput(cmd)

  # AVB: if enabled, calculate and add hash.
  if info_dict.get("avb_enable") == "true":
    avbtool = info_dict["avb_avbtool"]
    part_size = info_dict[f'{partition_name}_size']
    cmd = [avbtool, "add_hash_footer", "--image", img.name,
           "--partition_size", str(part_size), "--partition_name", partition_name]
    AppendAVBSigningArgs(cmd, partition_name)
    args = info_dict.get(f'avb_{partition_name}_add_hash_footer_args')
    if args and args.strip():
      split_args = ResolveAVBSigningPathArgs(shlex.split(args))
      cmd.extend(split_args)
    RunAndCheckOutput(cmd)

  img.seek(os.SEEK_SET, 0)
  data = img.read()

  for f in ramdisk_fragment_imgs:
    f.close()
  ramdisk_img.close()
  img.close()

  return data


def GetVendorBootImage(name, prebuilt_name, unpack_dir, tree_subdir,
                       info_dict=None):
  """Return a File object with the desired vendor boot image.

  Look for it under 'unpack_dir'/IMAGES, otherwise construct it from
  the source files in 'unpack_dir'/'tree_subdir'."""

  prebuilt_path = os.path.join(unpack_dir, "IMAGES", prebuilt_name)
  if os.path.exists(prebuilt_path):
    logger.info("using prebuilt %s from IMAGES...", prebuilt_name)
    return File.FromLocalFile(name, prebuilt_path)

  logger.info("building image from target_files %s...", tree_subdir)

  if info_dict is None:
    info_dict = OPTIONS.info_dict

  data = _BuildVendorBootImage(
      os.path.join(unpack_dir, tree_subdir), "vendor_boot", info_dict)
  if data:
    return File(name, data)
  return None


def GetVendorKernelBootImage(name, prebuilt_name, unpack_dir, tree_subdir,
                             info_dict=None):
  """Return a File object with the desired vendor kernel boot image.

  Look for it under 'unpack_dir'/IMAGES, otherwise construct it from
  the source files in 'unpack_dir'/'tree_subdir'."""

  prebuilt_path = os.path.join(unpack_dir, "IMAGES", prebuilt_name)
  if os.path.exists(prebuilt_path):
    logger.info("using prebuilt %s from IMAGES...", prebuilt_name)
    return File.FromLocalFile(name, prebuilt_path)

  logger.info("building image from target_files %s...", tree_subdir)

  if info_dict is None:
    info_dict = OPTIONS.info_dict

  data = _BuildVendorBootImage(
      os.path.join(unpack_dir, tree_subdir), "vendor_kernel_boot", info_dict)
  if data:
    return File(name, data)
  return None


def Gunzip(in_filename, out_filename):
  """Gunzips the given gzip compressed file to a given output file."""
  with gzip.open(in_filename, "rb") as in_file, \
          open(out_filename, "wb") as out_file:
    shutil.copyfileobj(in_file, out_file)


def UnzipSingleFile(input_zip: zipfile.ZipFile, info: zipfile.ZipInfo, dirname: str):
  # According to https://stackoverflow.com/questions/434641/how-do-i-set-permissions-attributes-on-a-file-in-a-zip-file-using-pythons-zip/6297838#6297838
  # higher bits of |external_attr| are unix file permission and types
  unix_filetype = info.external_attr >> 16
  file_perm = unix_filetype & 0o777

  def CheckMask(a, mask):
    return (a & mask) == mask

  def IsSymlink(a):
    return CheckMask(a, stat.S_IFLNK)

  def IsDir(a):
    return CheckMask(a, stat.S_IFDIR)
  # python3.11 zipfile implementation doesn't handle symlink correctly
  if not IsSymlink(unix_filetype):
    target = input_zip.extract(info, dirname)
    # We want to ensure that the file is at least read/writable by owner and readable by all users
    if IsDir(unix_filetype):
      os.chmod(target, file_perm | 0o755)
    else:
      os.chmod(target, file_perm | 0o644)
    return target
  if dirname is None:
    dirname = os.getcwd()
  target = os.path.join(dirname, info.filename)
  os.makedirs(os.path.dirname(target), exist_ok=True)
  if os.path.exists(target):
    os.unlink(target)
  os.symlink(input_zip.read(info).decode(), target)
  return target


def UnzipToDir(filename, dirname, patterns=None):
  """Unzips the archive to the given directory.

  Args:
    filename: The name of the zip file to unzip.
    dirname: Where the unziped files will land.
    patterns: Files to unzip from the archive. If omitted, will unzip the entire
        archvie. Non-matching patterns will be filtered out. If there's no match
        after the filtering, no file will be unzipped.
  """
  with zipfile.ZipFile(filename, allowZip64=True, mode="r") as input_zip:
    # Filter out non-matching patterns. unzip will complain otherwise.
    entries = input_zip.infolist()
    # b/283033491
    # Per https://en.wikipedia.org/wiki/ZIP_(file_format)#Central_directory_file_header
    # In zip64 mode, central directory record's header_offset field might be
    # set to 0xFFFFFFFF if header offset is > 2^32. In this case, the extra
    # fields will contain an 8 byte little endian integer at offset 20
    # to indicate the actual local header offset.
    # As of python3.11, python does not handle zip64 central directories
    # correctly, so we will manually do the parsing here.

    # ZIP64 central directory extra field has two required fields:
    # 2 bytes header ID and 2 bytes size field. Thes two require fields have
    # a total size of 4 bytes. Then it has three other 8 bytes field, followed
    # by a 4 byte disk number field. The last disk number field is not required
    # to be present, but if it is present, the total size of extra field will be
    # divisible by 8(because 2+2+4+8*n is always going to be multiple of 8)
    # Most extra fields are optional, but when they appear, their must appear
    # in the order defined by zip64 spec. Since file header offset is the 2nd
    # to last field in zip64 spec, it will only be at last 8 bytes or last 12-4
    # bytes, depending on whether disk number is present.
    for entry in entries:
      if entry.header_offset == 0xFFFFFFFF:
        if len(entry.extra) % 8 == 0:
          entry.header_offset = int.from_bytes(entry.extra[-12:-4], "little")
        else:
          entry.header_offset = int.from_bytes(entry.extra[-8:], "little")
    if patterns is not None:
      filtered = [info for info in entries if any(
          [fnmatch.fnmatch(info.filename, p) for p in patterns])]

      # There isn't any matching files. Don't unzip anything.
      if not filtered:
        return
      for info in filtered:
        UnzipSingleFile(input_zip, info, dirname)
    else:
      for info in entries:
        UnzipSingleFile(input_zip, info, dirname)


def UnzipTemp(filename, patterns=None):
  """Unzips the given archive into a temporary directory and returns the name.

  Args:
    filename: If filename is of the form "foo.zip+bar.zip", unzip foo.zip into
    a temp dir, then unzip bar.zip into that_dir/BOOTABLE_IMAGES.

    patterns: Files to unzip from the archive. If omitted, will unzip the entire
    archvie.

  Returns:
    The name of the temporary directory.
  """

  tmp = MakeTempDir(prefix="targetfiles-")
  m = re.match(r"^(.*[.]zip)\+(.*[.]zip)$", filename, re.IGNORECASE)
  if m:
    UnzipToDir(m.group(1), tmp, patterns)
    UnzipToDir(m.group(2), os.path.join(tmp, "BOOTABLE_IMAGES"), patterns)
    filename = m.group(1)
  else:
    UnzipToDir(filename, tmp, patterns)

  return tmp


def GetUserImage(which, tmpdir, input_zip,
                 info_dict=None,
                 allow_shared_blocks=None,
                 reset_file_map=False):
  """Returns an Image object suitable for passing to BlockImageDiff.

  This function loads the specified image from the given path. If the specified
  image is sparse, it also performs additional processing for OTA purpose. For
  example, it always adds block 0 to clobbered blocks list. It also detects
  files that cannot be reconstructed from the block list, for whom we should
  avoid applying imgdiff.

  Args:
    which: The partition name.
    tmpdir: The directory that contains the prebuilt image and block map file.
    input_zip: The target-files ZIP archive.
    info_dict: The dict to be looked up for relevant info.
    allow_shared_blocks: If image is sparse, whether having shared blocks is
        allowed. If none, it is looked up from info_dict.
    reset_file_map: If true and image is sparse, reset file map before returning
        the image.
  Returns:
    A Image object. If it is a sparse image and reset_file_map is False, the
    image will have file_map info loaded.
  """
  if info_dict is None:
    info_dict = LoadInfoDict(input_zip)

  is_sparse = IsSparseImage(os.path.join(tmpdir, "IMAGES", which + ".img"))

  # When target uses 'BOARD_EXT4_SHARE_DUP_BLOCKS := true', images may contain
  # shared blocks (i.e. some blocks will show up in multiple files' block
  # list). We can only allocate such shared blocks to the first "owner", and
  # disable imgdiff for all later occurrences.
  if allow_shared_blocks is None:
    allow_shared_blocks = info_dict.get("ext4_share_dup_blocks") == "true"

  if is_sparse:
    img = GetSparseImage(which, tmpdir, input_zip, allow_shared_blocks)
    if reset_file_map:
      img.ResetFileMap()
    return img
  return GetNonSparseImage(which, tmpdir)


def GetNonSparseImage(which, tmpdir):
  """Returns a Image object suitable for passing to BlockImageDiff.

  This function loads the specified non-sparse image from the given path.

  Args:
    which: The partition name.
    tmpdir: The directory that contains the prebuilt image and block map file.
  Returns:
    A Image object.
  """
  path = os.path.join(tmpdir, "IMAGES", which + ".img")
  mappath = os.path.join(tmpdir, "IMAGES", which + ".map")

  # The image and map files must have been created prior to calling
  # ota_from_target_files.py (since LMP).
  assert os.path.exists(path) and os.path.exists(mappath)

  return images.FileImage(path)


def GetSparseImage(which, tmpdir, input_zip, allow_shared_blocks):
  """Returns a SparseImage object suitable for passing to BlockImageDiff.

  This function loads the specified sparse image from the given path, and
  performs additional processing for OTA purpose. For example, it always adds
  block 0 to clobbered blocks list. It also detects files that cannot be
  reconstructed from the block list, for whom we should avoid applying imgdiff.

  Args:
    which: The partition name, e.g. "system", "vendor".
    tmpdir: The directory that contains the prebuilt image and block map file.
    input_zip: The target-files ZIP archive.
    allow_shared_blocks: Whether having shared blocks is allowed.
  Returns:
    A SparseImage object, with file_map info loaded.
  """
  path = os.path.join(tmpdir, "IMAGES", which + ".img")
  mappath = os.path.join(tmpdir, "IMAGES", which + ".map")

  # The image and map files must have been created prior to calling
  # ota_from_target_files.py (since LMP).
  assert os.path.exists(path) and os.path.exists(mappath)

  # In ext4 filesystems, block 0 might be changed even being mounted R/O. We add
  # it to clobbered_blocks so that it will be written to the target
  # unconditionally. Note that they are still part of care_map. (Bug: 20939131)
  clobbered_blocks = "0"

  image = sparse_img.SparseImage(
      path, mappath, clobbered_blocks, allow_shared_blocks=allow_shared_blocks)

  # block.map may contain less blocks, because mke2fs may skip allocating blocks
  # if they contain all zeros. We can't reconstruct such a file from its block
  # list. Tag such entries accordingly. (Bug: 65213616)
  for entry in image.file_map:
    # Skip artificial names, such as "__ZERO", "__NONZERO-1".
    if not entry.startswith('/'):
      continue

    # "/system/framework/am.jar" => "SYSTEM/framework/am.jar". Note that the
    # filename listed in system.map may contain an additional leading slash
    # (i.e. "//system/framework/am.jar"). Using lstrip to get consistent
    # results.
    # And handle another special case, where files not under /system
    # (e.g. "/sbin/charger") are packed under ROOT/ in a target_files.zip.
    arcname = entry.lstrip('/')
    if which == 'system' and not arcname.startswith('system'):
      arcname = 'ROOT/' + arcname
    else:
      arcname = arcname.replace(which, which.upper(), 1)

    assert arcname in input_zip.namelist(), \
        "Failed to find the ZIP entry for {}".format(entry)

    info = input_zip.getinfo(arcname)
    ranges = image.file_map[entry]

    # If a RangeSet has been tagged as using shared blocks while loading the
    # image, check the original block list to determine its completeness. Note
    # that the 'incomplete' flag would be tagged to the original RangeSet only.
    if ranges.extra.get('uses_shared_blocks'):
      ranges = ranges.extra['uses_shared_blocks']

    if RoundUpTo4K(info.file_size) > ranges.size() * 4096:
      ranges.extra['incomplete'] = True

  return image


def GetKeyPasswords(keylist):
  """Given a list of keys, prompt the user to enter passwords for
  those which require them.  Return a {key: password} dict.  password
  will be None if the key has no password."""

  no_passwords = []
  need_passwords = []
  key_passwords = {}
  devnull = open("/dev/null", "w+b")

  # sorted() can't compare strings to None, so convert Nones to strings
  for k in sorted(keylist, key=lambda x: x if x is not None else ""):
    # We don't need a password for things that aren't really keys.
    if k in SPECIAL_CERT_STRINGS or k is None:
      no_passwords.append(k)
      continue

    p = Run(["openssl", "pkcs8", "-in", k+OPTIONS.private_key_suffix,
             "-inform", "DER", "-nocrypt"],
            stdin=devnull.fileno(),
            stdout=devnull.fileno(),
            stderr=subprocess.STDOUT)
    p.communicate()
    if p.returncode == 0:
      # Definitely an unencrypted key.
      no_passwords.append(k)
    else:
      p = Run(["openssl", "pkcs8", "-in", k+OPTIONS.private_key_suffix,
               "-inform", "DER", "-passin", "pass:"],
              stdin=devnull.fileno(),
              stdout=devnull.fileno(),
              stderr=subprocess.PIPE)
      _, stderr = p.communicate()
      if p.returncode == 0:
        # Encrypted key with empty string as password.
        key_passwords[k] = ''
      elif stderr.startswith('Error decrypting key'):
        # Definitely encrypted key.
        # It would have said "Error reading key" if it didn't parse correctly.
        need_passwords.append(k)
      else:
        # Potentially, a type of key that openssl doesn't understand.
        # We'll let the routines in signapk.jar handle it.
        no_passwords.append(k)
  devnull.close()

  key_passwords.update(PasswordManager().GetPasswords(need_passwords))
  key_passwords.update(dict.fromkeys(no_passwords))
  return key_passwords


def GetMinSdkVersion(apk_name):
  """Gets the minSdkVersion declared in the APK.

  It calls OPTIONS.aapt2_path to query the embedded minSdkVersion from the given
  APK file. This can be both a decimal number (API Level) or a codename.

  Args:
    apk_name: The APK filename.

  Returns:
    The parsed SDK version string.

  Raises:
    ExternalError: On failing to obtain the min SDK version.
  """
  proc = Run(
      [OPTIONS.aapt2_path, "dump", "badging", apk_name], stdout=subprocess.PIPE,
      stderr=subprocess.PIPE)
  stdoutdata, stderrdata = proc.communicate()
  if proc.returncode != 0:
    raise ExternalError(
        "Failed to obtain minSdkVersion for {}: aapt2 return code {}:\n{}\n{}".format(
            apk_name, proc.returncode, stdoutdata, stderrdata))

  for line in stdoutdata.split("\n"):
    # Due to ag/24161708, looking for lines such as minSdkVersion:'23',minSdkVersion:'M'
    # or sdkVersion:'23', sdkVersion:'M'.
    m = re.match(r'(?:minSdkVersion|sdkVersion):\'([^\']*)\'', line)
    if m:
      return m.group(1)
  raise ExternalError("No minSdkVersion returned by aapt2")


def GetMinSdkVersionInt(apk_name, codename_to_api_level_map):
  """Returns the minSdkVersion declared in the APK as a number (API Level).

  If minSdkVersion is set to a codename, it is translated to a number using the
  provided map.

  Args:
    apk_name: The APK filename.

  Returns:
    The parsed SDK version number.

  Raises:
    ExternalError: On failing to get the min SDK version number.
  """
  version = GetMinSdkVersion(apk_name)
  try:
    return int(version)
  except ValueError:
    # Not a decimal number.
    #
    # It could be either a straight codename, e.g.
    #     UpsideDownCake
    #
    # Or a codename with API fingerprint SHA, e.g.
    #     UpsideDownCake.e7d3947f14eb9dc4fec25ff6c5f8563e
    #
    # Extract the codename and try and map it to a version number.
    split = version.split(".")
    codename = split[0]
    if codename in codename_to_api_level_map:
      return codename_to_api_level_map[codename]
    raise ExternalError(
        "Unknown codename: '{}' from minSdkVersion: '{}'. Known codenames: {}".format(
            codename, version, codename_to_api_level_map))


def SignFile(input_name, output_name, key, password, min_api_level=None,
             codename_to_api_level_map=None, whole_file=False,
             extra_signapk_args=None):
  """Sign the input_name zip/jar/apk, producing output_name.  Use the
  given key and password (the latter may be None if the key does not
  have a password.

  If whole_file is true, use the "-w" option to SignApk to embed a
  signature that covers the whole file in the archive comment of the
  zip file.

  min_api_level is the API Level (int) of the oldest platform this file may end
  up on. If not specified for an APK, the API Level is obtained by interpreting
  the minSdkVersion attribute of the APK's AndroidManifest.xml.

  codename_to_api_level_map is needed to translate the codename which may be
  encountered as the APK's minSdkVersion.

  Caller may optionally specify extra args to be passed to SignApk, which
  defaults to OPTIONS.extra_signapk_args if omitted.
  """
  if codename_to_api_level_map is None:
    codename_to_api_level_map = {}
  if extra_signapk_args is None:
    extra_signapk_args = OPTIONS.extra_signapk_args

  java_library_path = os.path.join(
      OPTIONS.search_path, OPTIONS.signapk_shared_library_path)

  cmd = ([OPTIONS.java_path] + OPTIONS.java_args +
         ["-Djava.library.path=" + java_library_path,
          "-jar", os.path.join(OPTIONS.search_path, OPTIONS.signapk_path)] +
         extra_signapk_args)
  if whole_file:
    cmd.append("-w")

  min_sdk_version = min_api_level
  if min_sdk_version is None:
    if not whole_file:
      min_sdk_version = GetMinSdkVersionInt(
          input_name, codename_to_api_level_map)
  if min_sdk_version is not None:
    cmd.extend(["--min-sdk-version", str(min_sdk_version)])

  cmd.extend([key + OPTIONS.public_key_suffix,
              key + OPTIONS.private_key_suffix,
              input_name, output_name])

  proc = Run(cmd, stdin=subprocess.PIPE)
  if password is not None:
    password += "\n"
  stdoutdata, _ = proc.communicate(password)
  if proc.returncode != 0:
    raise ExternalError(
        "Failed to run {}: return code {}:\n{}".format(cmd,
                                                       proc.returncode, stdoutdata))


def CheckSize(data, target, info_dict):
  """Checks the data string passed against the max size limit.

  For non-AVB images, raise exception if the data is too big. Print a warning
  if the data is nearing the maximum size.

  For AVB images, the actual image size should be identical to the limit.

  Args:
    data: A string that contains all the data for the partition.
    target: The partition name. The ".img" suffix is optional.
    info_dict: The dict to be looked up for relevant info.
  """
  if target.endswith(".img"):
    target = target[:-4]
  mount_point = "/" + target

  fs_type = None
  limit = None
  if info_dict["fstab"]:
    if mount_point == "/userdata":
      mount_point = "/data"
    p = info_dict["fstab"][mount_point]
    fs_type = p.fs_type
    device = p.device
    if "/" in device:
      device = device[device.rfind("/")+1:]
    limit = info_dict.get(device + "_size", 0)
    if isinstance(limit, str):
      limit = int(limit, 0)
  if not fs_type or not limit:
    return

  size = len(data)
  # target could be 'userdata' or 'cache'. They should follow the non-AVB image
  # path.
  if info_dict.get("avb_enable") == "true" and target in AVB_PARTITIONS:
    if size != limit:
      raise ExternalError(
          "Mismatching image size for %s: expected %d actual %d" % (
              target, limit, size))
  else:
    pct = float(size) * 100.0 / limit
    msg = "%s size (%d) is %.2f%% of limit (%d)" % (target, size, pct, limit)
    if pct >= 99.0:
      raise ExternalError(msg)

    if pct >= 95.0:
      logger.warning("\n  WARNING: %s\n", msg)
    else:
      logger.info("  %s", msg)


def ReadApkCerts(tf_zip):
  """Parses the APK certs info from a given target-files zip.

  Given a target-files ZipFile, parses the META/apkcerts.txt entry and returns a
  tuple with the following elements: (1) a dictionary that maps packages to
  certs (based on the "certificate" and "private_key" attributes in the file;
  (2) a string representing the extension of compressed APKs in the target files
  (e.g ".gz", ".bro").

  Args:
    tf_zip: The input target_files ZipFile (already open).

  Returns:
    (certmap, ext): certmap is a dictionary that maps packages to certs; ext is
        the extension string of compressed APKs (e.g. ".gz"), or None if there's
        no compressed APKs.
  """
  certmap = {}
  compressed_extension = None

  # META/apkcerts.txt contains the info for _all_ the packages known at build
  # time. Filter out the ones that are not installed.
  installed_files = set()
  for name in tf_zip.namelist():
    basename = os.path.basename(name)
    if basename:
      installed_files.add(basename)

  for line in tf_zip.read('META/apkcerts.txt').decode().split('\n'):
    line = line.strip()
    if not line:
      continue
    m = re.match(
        r'^name="(?P<NAME>.*)"\s+certificate="(?P<CERT>.*)"\s+'
        r'private_key="(?P<PRIVKEY>.*?)"(\s+compressed="(?P<COMPRESSED>.*?)")?'
        r'(\s+partition="(?P<PARTITION>.*?)")?$',
        line)
    if not m:
      continue

    matches = m.groupdict()
    cert = matches["CERT"]
    privkey = matches["PRIVKEY"]
    name = matches["NAME"]
    this_compressed_extension = matches["COMPRESSED"]

    public_key_suffix_len = len(OPTIONS.public_key_suffix)
    private_key_suffix_len = len(OPTIONS.private_key_suffix)
    if cert in SPECIAL_CERT_STRINGS and not privkey:
      certmap[name] = cert
    elif (cert.endswith(OPTIONS.public_key_suffix) and
          privkey.endswith(OPTIONS.private_key_suffix) and
          cert[:-public_key_suffix_len] == privkey[:-private_key_suffix_len]):
      certmap[name] = cert[:-public_key_suffix_len]
    else:
      raise ValueError("Failed to parse line from apkcerts.txt:\n" + line)

    if not this_compressed_extension:
      continue

    # Only count the installed files.
    filename = name + '.' + this_compressed_extension
    if filename not in installed_files:
      continue

    # Make sure that all the values in the compression map have the same
    # extension. We don't support multiple compression methods in the same
    # system image.
    if compressed_extension:
      if this_compressed_extension != compressed_extension:
        raise ValueError(
            "Multiple compressed extensions: {} vs {}".format(
                compressed_extension, this_compressed_extension))
    else:
      compressed_extension = this_compressed_extension

  return (certmap,
          ("." + compressed_extension) if compressed_extension else None)


COMMON_DOCSTRING = """
Global options

  -p  (--path) <dir>
      Prepend <dir>/bin to the list of places to search for binaries run by this
      script, and expect to find jars in <dir>/framework.

  -s  (--device_specific) <file>
      Path to the Python module containing device-specific releasetools code.

  -x  (--extra) <key=value>
      Add a key/value pair to the 'extras' dict, which device-specific extension
      code may look at.

  -v  (--verbose)
      Show command lines being executed.

  -h  (--help)
      Display this usage message and exit.

  --logfile <file>
      Put verbose logs to specified file (regardless of --verbose option.)
"""


def Usage(docstring):
  print(docstring.rstrip("\n"))
  print(COMMON_DOCSTRING)


def ParseOptions(argv,
                 docstring,
                 extra_opts="", extra_long_opts=(),
                 extra_option_handler=None):
  """Parse the options in argv and return any arguments that aren't
  flags.  docstring is the calling module's docstring, to be displayed
  for errors and -h.  extra_opts and extra_long_opts are for flags
  defined by the caller, which are processed by passing them to
  extra_option_handler."""

  try:
    opts, args = getopt.getopt(
        argv, "hvp:s:x:" + extra_opts,
        ["help", "verbose", "path=", "signapk_path=",
         "signapk_shared_library_path=", "extra_signapk_args=", "aapt2_path=",
         "java_path=", "java_args=", "android_jar_path=", "public_key_suffix=",
         "private_key_suffix=", "boot_signer_path=", "boot_signer_args=",
         "verity_signer_path=", "verity_signer_args=", "device_specific=",
         "extra=", "logfile="] + list(extra_long_opts))
  except getopt.GetoptError as err:
    Usage(docstring)
    print("**", str(err), "**")
    sys.exit(2)

  for o, a in opts:
    if o in ("-h", "--help"):
      Usage(docstring)
      sys.exit()
    elif o in ("-v", "--verbose"):
      OPTIONS.verbose = True
    elif o in ("-p", "--path"):
      OPTIONS.search_path = a
    elif o in ("--signapk_path",):
      OPTIONS.signapk_path = a
    elif o in ("--signapk_shared_library_path",):
      OPTIONS.signapk_shared_library_path = a
    elif o in ("--extra_signapk_args",):
      OPTIONS.extra_signapk_args = shlex.split(a)
    elif o in ("--aapt2_path",):
      OPTIONS.aapt2_path = a
    elif o in ("--java_path",):
      OPTIONS.java_path = a
    elif o in ("--java_args",):
      OPTIONS.java_args = shlex.split(a)
    elif o in ("--android_jar_path",):
      OPTIONS.android_jar_path = a
    elif o in ("--public_key_suffix",):
      OPTIONS.public_key_suffix = a
    elif o in ("--private_key_suffix",):
      OPTIONS.private_key_suffix = a
    elif o in ("--boot_signer_path",):
      raise ValueError(
          "--boot_signer_path is no longer supported, please switch to AVB")
    elif o in ("--boot_signer_args",):
      raise ValueError(
          "--boot_signer_args is no longer supported, please switch to AVB")
    elif o in ("--verity_signer_path",):
      raise ValueError(
          "--verity_signer_path is no longer supported, please switch to AVB")
    elif o in ("--verity_signer_args",):
      raise ValueError(
          "--verity_signer_args is no longer supported, please switch to AVB")
    elif o in ("-s", "--device_specific"):
      OPTIONS.device_specific = a
    elif o in ("-x", "--extra"):
      key, value = a.split("=", 1)
      OPTIONS.extras[key] = value
    elif o in ("--logfile",):
      OPTIONS.logfile = a
    else:
      if extra_option_handler is None or not extra_option_handler(o, a):
        assert False, "unknown option \"%s\"" % (o,)

  if OPTIONS.search_path:
    os.environ["PATH"] = (os.path.join(OPTIONS.search_path, "bin") +
                          os.pathsep + os.environ["PATH"])

  return args


def MakeTempFile(prefix='tmp', suffix=''):
  """Make a temp file and add it to the list of things to be deleted
  when Cleanup() is called.  Return the filename."""
  fd, fn = tempfile.mkstemp(prefix=prefix, suffix=suffix)
  os.close(fd)
  OPTIONS.tempfiles.append(fn)
  return fn


def MakeTempDir(prefix='tmp', suffix=''):
  """Makes a temporary dir that will be cleaned up with a call to Cleanup().

  Returns:
    The absolute pathname of the new directory.
  """
  dir_name = tempfile.mkdtemp(suffix=suffix, prefix=prefix)
  OPTIONS.tempfiles.append(dir_name)
  return dir_name


def Cleanup():
  for i in OPTIONS.tempfiles:
    if not os.path.exists(i):
      continue
    if os.path.isdir(i):
      shutil.rmtree(i, ignore_errors=True)
    else:
      os.remove(i)
  del OPTIONS.tempfiles[:]


class PasswordManager(object):
  def __init__(self):
    self.editor = os.getenv("EDITOR")
    self.pwfile = os.getenv("ANDROID_PW_FILE")

  def GetPasswords(self, items):
    """Get passwords corresponding to each string in 'items',
    returning a dict.  (The dict may have keys in addition to the
    values in 'items'.)

    Uses the passwords in $ANDROID_PW_FILE if available, letting the
    user edit that file to add more needed passwords.  If no editor is
    available, or $ANDROID_PW_FILE isn't define, prompts the user
    interactively in the ordinary way.
    """

    current = self.ReadFile()

    first = True
    while True:
      missing = []
      for i in items:
        if i not in current or not current[i]:
          missing.append(i)
      # Are all the passwords already in the file?
      if not missing:
        return current

      for i in missing:
        current[i] = ""

      if not first:
        print("key file %s still missing some passwords." % (self.pwfile,))
        if sys.version_info[0] >= 3:
          raw_input = input  # pylint: disable=redefined-builtin
        answer = raw_input("try to edit again? [y]> ").strip()
        if answer and answer[0] not in 'yY':
          raise RuntimeError("key passwords unavailable")
      first = False

      current = self.UpdateAndReadFile(current)

  def PromptResult(self, current):  # pylint: disable=no-self-use
    """Prompt the user to enter a value (password) for each key in
    'current' whose value is fales.  Returns a new dict with all the
    values.
    """
    result = {}
    for k, v in sorted(current.items()):
      if v:
        result[k] = v
      else:
        while True:
          result[k] = getpass.getpass(
              "Enter password for %s key> " % k).strip()
          if result[k]:
            break
    return result

  def UpdateAndReadFile(self, current):
    if not self.editor or not self.pwfile:
      return self.PromptResult(current)

    f = open(self.pwfile, "w")
    os.chmod(self.pwfile, 0o600)
    f.write("# Enter key passwords between the [[[ ]]] brackets.\n")
    f.write("# (Additional spaces are harmless.)\n\n")

    first_line = None
    sorted_list = sorted([(not v, k, v) for (k, v) in current.items()])
    for i, (_, k, v) in enumerate(sorted_list):
      f.write("[[[  %s  ]]] %s\n" % (v, k))
      if not v and first_line is None:
        # position cursor on first line with no password.
        first_line = i + 4
    f.close()

    RunAndCheckOutput([self.editor, "+%d" % (first_line,), self.pwfile])

    return self.ReadFile()

  def ReadFile(self):
    result = {}
    if self.pwfile is None:
      return result
    try:
      f = open(self.pwfile, "r")
      for line in f:
        line = line.strip()
        if not line or line[0] == '#':
          continue
        m = re.match(r"^\[\[\[\s*(.*?)\s*\]\]\]\s*(\S+)$", line)
        if not m:
          logger.warning("Failed to parse password file: %s", line)
        else:
          result[m.group(2)] = m.group(1)
      f.close()
    except IOError as e:
      if e.errno != errno.ENOENT:
        logger.exception("Error reading password file:")
    return result


def ZipWrite(zip_file, filename, arcname=None, perms=0o644,
             compress_type=None):

  # http://b/18015246
  # Python 2.7's zipfile implementation wrongly thinks that zip64 is required
  # for files larger than 2GiB. We can work around this by adjusting their
  # limit. Note that `zipfile.writestr()` will not work for strings larger than
  # 2GiB. The Python interpreter sometimes rejects strings that large (though
  # it isn't clear to me exactly what circumstances cause this).
  # `zipfile.write()` must be used directly to work around this.
  #
  # This mess can be avoided if we port to python3.
  saved_zip64_limit = zipfile.ZIP64_LIMIT
  zipfile.ZIP64_LIMIT = (1 << 32) - 1

  if compress_type is None:
    compress_type = zip_file.compression
  if arcname is None:
    arcname = filename

  saved_stat = os.stat(filename)

  try:
    # `zipfile.write()` doesn't allow us to pass ZipInfo, so just modify the
    # file to be zipped and reset it when we're done.
    os.chmod(filename, perms)

    # Use a fixed timestamp so the output is repeatable.
    # Note: Use of fromtimestamp rather than utcfromtimestamp here is
    # intentional. zip stores datetimes in local time without a time zone
    # attached, so we need "epoch" but in the local time zone to get 2009/01/01
    # in the zip archive.
    local_epoch = datetime.datetime.fromtimestamp(0)
    timestamp = (datetime.datetime(2009, 1, 1) - local_epoch).total_seconds()
    os.utime(filename, (timestamp, timestamp))

    zip_file.write(filename, arcname=arcname, compress_type=compress_type)
  finally:
    os.chmod(filename, saved_stat.st_mode)
    os.utime(filename, (saved_stat.st_atime, saved_stat.st_mtime))
    zipfile.ZIP64_LIMIT = saved_zip64_limit


def ZipWriteStr(zip_file, zinfo_or_arcname, data, perms=None,
                compress_type=None):
  """Wrap zipfile.writestr() function to work around the zip64 limit.

  Even with the ZIP64_LIMIT workaround, it won't allow writing a string
  longer than 2GiB. It gives 'OverflowError: size does not fit in an int'
  when calling crc32(bytes).

  But it still works fine to write a shorter string into a large zip file.
  We should use ZipWrite() whenever possible, and only use ZipWriteStr()
  when we know the string won't be too long.
  """

  saved_zip64_limit = zipfile.ZIP64_LIMIT
  zipfile.ZIP64_LIMIT = (1 << 32) - 1

  if not isinstance(zinfo_or_arcname, zipfile.ZipInfo):
    zinfo = zipfile.ZipInfo(filename=zinfo_or_arcname)
    zinfo.compress_type = zip_file.compression
    if perms is None:
      perms = 0o100644
  else:
    zinfo = zinfo_or_arcname
    # Python 2 and 3 behave differently when calling ZipFile.writestr() with
    # zinfo.external_attr being 0. Python 3 uses `0o600 << 16` as the value for
    # such a case (since
    # https://github.com/python/cpython/commit/18ee29d0b870caddc0806916ca2c823254f1a1f9),
    # which seems to make more sense. Otherwise the entry will have 0o000 as the
    # permission bits. We follow the logic in Python 3 to get consistent
    # behavior between using the two versions.
    if not zinfo.external_attr:
      zinfo.external_attr = 0o600 << 16

  # If compress_type is given, it overrides the value in zinfo.
  if compress_type is not None:
    zinfo.compress_type = compress_type

  # If perms is given, it has a priority.
  if perms is not None:
    # If perms doesn't set the file type, mark it as a regular file.
    if perms & 0o770000 == 0:
      perms |= 0o100000
    zinfo.external_attr = perms << 16

  # Use a fixed timestamp so the output is repeatable.
  zinfo.date_time = (2009, 1, 1, 0, 0, 0)

  zip_file.writestr(zinfo, data)
  zipfile.ZIP64_LIMIT = saved_zip64_limit


def ZipDelete(zip_filename, entries, force=False):
  """Deletes entries from a ZIP file.

  Args:
    zip_filename: The name of the ZIP file.
    entries: The name of the entry, or the list of names to be deleted.
  """
  if isinstance(entries, str):
    entries = [entries]
  # If list is empty, nothing to do
  if not entries:
    return

  with zipfile.ZipFile(zip_filename, 'r') as zin:
    if not force and len(set(zin.namelist()).intersection(entries)) == 0:
      raise ExternalError(
          "Failed to delete zip entries, name not matched: %s" % entries)

    fd, new_zipfile = tempfile.mkstemp(dir=os.path.dirname(zip_filename))
    os.close(fd)
    cmd = ["zip2zip", "-i", zip_filename, "-o", new_zipfile]
    for entry in entries:
      cmd.append("-x")
      cmd.append(entry)
    RunAndCheckOutput(cmd)

  os.replace(new_zipfile, zip_filename)


def ZipClose(zip_file):
  # http://b/18015246
  # zipfile also refers to ZIP64_LIMIT during close() when it writes out the
  # central directory.
  saved_zip64_limit = zipfile.ZIP64_LIMIT
  zipfile.ZIP64_LIMIT = (1 << 32) - 1

  zip_file.close()

  zipfile.ZIP64_LIMIT = saved_zip64_limit


class DeviceSpecificParams(object):
  module = None

  def __init__(self, **kwargs):
    """Keyword arguments to the constructor become attributes of this
    object, which is passed to all functions in the device-specific
    module."""
    for k, v in kwargs.items():
      setattr(self, k, v)
    self.extras = OPTIONS.extras

    if self.module is None:
      path = OPTIONS.device_specific
      if not path:
        return
      try:
        if os.path.isdir(path):
          info = imp.find_module("releasetools", [path])
        else:
          d, f = os.path.split(path)
          b, x = os.path.splitext(f)
          if x == ".py":
            f = b
          info = imp.find_module(f, [d])
        logger.info("loaded device-specific extensions from %s", path)
        self.module = imp.load_module("device_specific", *info)
      except ImportError:
        logger.info("unable to load device-specific module; assuming none")

  def _DoCall(self, function_name, *args, **kwargs):
    """Call the named function in the device-specific module, passing
    the given args and kwargs.  The first argument to the call will be
    the DeviceSpecific object itself.  If there is no module, or the
    module does not define the function, return the value of the
    'default' kwarg (which itself defaults to None)."""
    if self.module is None or not hasattr(self.module, function_name):
      return kwargs.get("default")
    return getattr(self.module, function_name)(*((self,) + args), **kwargs)

  def FullOTA_Assertions(self):
    """Called after emitting the block of assertions at the top of a
    full OTA package.  Implementations can add whatever additional
    assertions they like."""
    return self._DoCall("FullOTA_Assertions")

  def FullOTA_InstallBegin(self):
    """Called at the start of full OTA installation."""
    return self._DoCall("FullOTA_InstallBegin")

  def FullOTA_GetBlockDifferences(self):
    """Called during full OTA installation and verification.
    Implementation should return a list of BlockDifference objects describing
    the update on each additional partitions.
    """
    return self._DoCall("FullOTA_GetBlockDifferences")

  def FullOTA_InstallEnd(self):
    """Called at the end of full OTA installation; typically this is
    used to install the image for the device's baseband processor."""
    return self._DoCall("FullOTA_InstallEnd")

  def IncrementalOTA_Assertions(self):
    """Called after emitting the block of assertions at the top of an
    incremental OTA package.  Implementations can add whatever
    additional assertions they like."""
    return self._DoCall("IncrementalOTA_Assertions")

  def IncrementalOTA_VerifyBegin(self):
    """Called at the start of the verification phase of incremental
    OTA installation; additional checks can be placed here to abort
    the script before any changes are made."""
    return self._DoCall("IncrementalOTA_VerifyBegin")

  def IncrementalOTA_VerifyEnd(self):
    """Called at the end of the verification phase of incremental OTA
    installation; additional checks can be placed here to abort the
    script before any changes are made."""
    return self._DoCall("IncrementalOTA_VerifyEnd")

  def IncrementalOTA_InstallBegin(self):
    """Called at the start of incremental OTA installation (after
    verification is complete)."""
    return self._DoCall("IncrementalOTA_InstallBegin")

  def IncrementalOTA_GetBlockDifferences(self):
    """Called during incremental OTA installation and verification.
    Implementation should return a list of BlockDifference objects describing
    the update on each additional partitions.
    """
    return self._DoCall("IncrementalOTA_GetBlockDifferences")

  def IncrementalOTA_InstallEnd(self):
    """Called at the end of incremental OTA installation; typically
    this is used to install the image for the device's baseband
    processor."""
    return self._DoCall("IncrementalOTA_InstallEnd")

  def VerifyOTA_Assertions(self):
    return self._DoCall("VerifyOTA_Assertions")


class File(object):
  def __init__(self, name, data, compress_size=None):
    self.name = name
    self.data = data
    self.size = len(data)
    self.compress_size = compress_size or self.size
    self.sha1 = sha1(data).hexdigest()

  @classmethod
  def FromLocalFile(cls, name, diskname):
    f = open(diskname, "rb")
    data = f.read()
    f.close()
    return File(name, data)

  def WriteToTemp(self):
    t = tempfile.NamedTemporaryFile()
    t.write(self.data)
    t.flush()
    return t

  def WriteToDir(self, d):
    with open(os.path.join(d, self.name), "wb") as fp:
      fp.write(self.data)

  def AddToZip(self, z, compression=None):
    ZipWriteStr(z, self.name, self.data, compress_type=compression)


DIFF_PROGRAM_BY_EXT = {
    ".gz": "imgdiff",
    ".zip": ["imgdiff", "-z"],
    ".jar": ["imgdiff", "-z"],
    ".apk": ["imgdiff", "-z"],
    ".img": "imgdiff",
}


class Difference(object):
  def __init__(self, tf, sf, diff_program=None):
    self.tf = tf
    self.sf = sf
    self.patch = None
    self.diff_program = diff_program

  def ComputePatch(self):
    """Compute the patch (as a string of data) needed to turn sf into
    tf.  Returns the same tuple as GetPatch()."""

    tf = self.tf
    sf = self.sf

    if self.diff_program:
      diff_program = self.diff_program
    else:
      ext = os.path.splitext(tf.name)[1]
      diff_program = DIFF_PROGRAM_BY_EXT.get(ext, "bsdiff")

    ttemp = tf.WriteToTemp()
    stemp = sf.WriteToTemp()

    ext = os.path.splitext(tf.name)[1]

    try:
      ptemp = tempfile.NamedTemporaryFile()
      if isinstance(diff_program, list):
        cmd = copy.copy(diff_program)
      else:
        cmd = [diff_program]
      cmd.append(stemp.name)
      cmd.append(ttemp.name)
      cmd.append(ptemp.name)
      p = Run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
      err = []

      def run():
        _, e = p.communicate()
        if e:
          err.append(e)
      th = threading.Thread(target=run)
      th.start()
      th.join(timeout=300)   # 5 mins
      if th.is_alive():
        logger.warning("diff command timed out")
        p.terminate()
        th.join(5)
        if th.is_alive():
          p.kill()
          th.join()

      if p.returncode != 0:
        logger.warning("Failure running %s:\n%s\n", cmd, "".join(err))
        self.patch = None
        return None, None, None
      diff = ptemp.read()
    finally:
      ptemp.close()
      stemp.close()
      ttemp.close()

    self.patch = diff
    return self.tf, self.sf, self.patch

  def GetPatch(self):
    """Returns a tuple of (target_file, source_file, patch_data).

    patch_data may be None if ComputePatch hasn't been called, or if
    computing the patch failed.
    """
    return self.tf, self.sf, self.patch


def ComputeDifferences(diffs):
  """Call ComputePatch on all the Difference objects in 'diffs'."""
  logger.info("%d diffs to compute", len(diffs))

  # Do the largest files first, to try and reduce the long-pole effect.
  by_size = [(i.tf.size, i) for i in diffs]
  by_size.sort(reverse=True)
  by_size = [i[1] for i in by_size]

  lock = threading.Lock()
  diff_iter = iter(by_size)   # accessed under lock

  def worker():
    try:
      lock.acquire()
      for d in diff_iter:
        lock.release()
        start = time.time()
        d.ComputePatch()
        dur = time.time() - start
        lock.acquire()

        tf, sf, patch = d.GetPatch()
        if sf.name == tf.name:
          name = tf.name
        else:
          name = "%s (%s)" % (tf.name, sf.name)
        if patch is None:
          logger.error("patching failed! %40s", name)
        else:
          logger.info(
              "%8.2f sec %8d / %8d bytes (%6.2f%%) %s", dur, len(patch),
              tf.size, 100.0 * len(patch) / tf.size, name)
      lock.release()
    except Exception:
      logger.exception("Failed to compute diff from worker")
      raise

  # start worker threads; wait for them all to finish.
  threads = [threading.Thread(target=worker)
             for i in range(OPTIONS.worker_threads)]
  for th in threads:
    th.start()
  while threads:
    threads.pop().join()


class BlockDifference(object):
  def __init__(self, partition, tgt, src=None, check_first_block=False,
               version=None, disable_imgdiff=False):
    self.tgt = tgt
    self.src = src
    self.partition = partition
    self.check_first_block = check_first_block
    self.disable_imgdiff = disable_imgdiff

    if version is None:
      version = max(
          int(i) for i in
          OPTIONS.info_dict.get("blockimgdiff_versions", "1").split(","))
    assert version >= 3
    self.version = version

    b = BlockImageDiff(tgt, src, threads=OPTIONS.worker_threads,
                       version=self.version,
                       disable_imgdiff=self.disable_imgdiff)
    self.path = os.path.join(MakeTempDir(), partition)
    b.Compute(self.path)
    self._required_cache = b.max_stashed_size
    self.touched_src_ranges = b.touched_src_ranges
    self.touched_src_sha1 = b.touched_src_sha1

    # On devices with dynamic partitions, for new partitions,
    # src is None but OPTIONS.source_info_dict is not.
    if OPTIONS.source_info_dict is None:
      is_dynamic_build = OPTIONS.info_dict.get(
          "use_dynamic_partitions") == "true"
      is_dynamic_source = False
    else:
      is_dynamic_build = OPTIONS.source_info_dict.get(
          "use_dynamic_partitions") == "true"
      is_dynamic_source = partition in shlex.split(
          OPTIONS.source_info_dict.get("dynamic_partition_list", "").strip())

    is_dynamic_target = partition in shlex.split(
        OPTIONS.info_dict.get("dynamic_partition_list", "").strip())

    # For dynamic partitions builds, check partition list in both source
    # and target build because new partitions may be added, and existing
    # partitions may be removed.
    is_dynamic = is_dynamic_build and (is_dynamic_source or is_dynamic_target)

    if is_dynamic:
      self.device = 'map_partition("%s")' % partition
    else:
      if OPTIONS.source_info_dict is None:
        _, device_expr = GetTypeAndDeviceExpr("/" + partition,
                                              OPTIONS.info_dict)
      else:
        _, device_expr = GetTypeAndDeviceExpr("/" + partition,
                                              OPTIONS.source_info_dict)
      self.device = device_expr

  @property
  def required_cache(self):
    return self._required_cache

  def WriteScript(self, script, output_zip, progress=None,
                  write_verify_script=False):
    if not self.src:
      # write the output unconditionally
      script.Print("Patching %s image unconditionally..." % (self.partition,))
    else:
      script.Print("Patching %s image after verification." % (self.partition,))

    if progress:
      script.ShowProgress(progress, 0)
    self._WriteUpdate(script, output_zip)

    if write_verify_script:
      self.WritePostInstallVerifyScript(script)

  def WriteStrictVerifyScript(self, script):
    """Verify all the blocks in the care_map, including clobbered blocks.

    This differs from the WriteVerifyScript() function: a) it prints different
    error messages; b) it doesn't allow half-way updated images to pass the
    verification."""

    partition = self.partition
    script.Print("Verifying %s..." % (partition,))
    ranges = self.tgt.care_map
    ranges_str = ranges.to_string_raw()
    script.AppendExtra(
        'range_sha1(%s, "%s") == "%s" && ui_print("    Verified.") || '
        'ui_print("%s has unexpected contents.");' % (
            self.device, ranges_str,
            self.tgt.TotalSha1(include_clobbered_blocks=True),
            self.partition))
    script.AppendExtra("")

  def WriteVerifyScript(self, script, touched_blocks_only=False):
    partition = self.partition

    # full OTA
    if not self.src:
      script.Print("Image %s will be patched unconditionally." % (partition,))

    # incremental OTA
    else:
      if touched_blocks_only:
        ranges = self.touched_src_ranges
        expected_sha1 = self.touched_src_sha1
      else:
        ranges = self.src.care_map.subtract(self.src.clobbered_blocks)
        expected_sha1 = self.src.TotalSha1()

      # No blocks to be checked, skipping.
      if not ranges:
        return

      ranges_str = ranges.to_string_raw()
      script.AppendExtra(
          'if (range_sha1(%s, "%s") == "%s" || block_image_verify(%s, '
          'package_extract_file("%s.transfer.list"), "%s.new.dat", '
          '"%s.patch.dat")) then' % (
              self.device, ranges_str, expected_sha1,
              self.device, partition, partition, partition))
      script.Print('Verified %s image...' % (partition,))
      script.AppendExtra('else')

      if self.version >= 4:

        # Bug: 21124327
        # When generating incrementals for the system and vendor partitions in
        # version 4 or newer, explicitly check the first block (which contains
        # the superblock) of the partition to see if it's what we expect. If
        # this check fails, give an explicit log message about the partition
        # having been remounted R/W (the most likely explanation).
        if self.check_first_block:
          script.AppendExtra('check_first_block(%s);' % (self.device,))

        # If version >= 4, try block recovery before abort update
        if partition == "system":
          code = ErrorCode.SYSTEM_RECOVER_FAILURE
        else:
          code = ErrorCode.VENDOR_RECOVER_FAILURE
        script.AppendExtra((
            'ifelse (block_image_recover({device}, "{ranges}") && '
            'block_image_verify({device}, '
            'package_extract_file("{partition}.transfer.list"), '
            '"{partition}.new.dat", "{partition}.patch.dat"), '
            'ui_print("{partition} recovered successfully."), '
            'abort("E{code}: {partition} partition fails to recover"));\n'
            'endif;').format(device=self.device, ranges=ranges_str,
                             partition=partition, code=code))

      # Abort the OTA update. Note that the incremental OTA cannot be applied
      # even if it may match the checksum of the target partition.
      # a) If version < 3, operations like move and erase will make changes
      #    unconditionally and damage the partition.
      # b) If version >= 3, it won't even reach here.
      else:
        if partition == "system":
          code = ErrorCode.SYSTEM_VERIFICATION_FAILURE
        else:
          code = ErrorCode.VENDOR_VERIFICATION_FAILURE
        script.AppendExtra((
            'abort("E%d: %s partition has unexpected contents");\n'
            'endif;') % (code, partition))

  def WritePostInstallVerifyScript(self, script):
    partition = self.partition
    script.Print('Verifying the updated %s image...' % (partition,))
    # Unlike pre-install verification, clobbered_blocks should not be ignored.
    ranges = self.tgt.care_map
    ranges_str = ranges.to_string_raw()
    script.AppendExtra(
        'if range_sha1(%s, "%s") == "%s" then' % (
            self.device, ranges_str,
            self.tgt.TotalSha1(include_clobbered_blocks=True)))

    # Bug: 20881595
    # Verify that extended blocks are really zeroed out.
    if self.tgt.extended:
      ranges_str = self.tgt.extended.to_string_raw()
      script.AppendExtra(
          'if range_sha1(%s, "%s") == "%s" then' % (
              self.device, ranges_str,
              self._HashZeroBlocks(self.tgt.extended.size())))
      script.Print('Verified the updated %s image.' % (partition,))
      if partition == "system":
        code = ErrorCode.SYSTEM_NONZERO_CONTENTS
      else:
        code = ErrorCode.VENDOR_NONZERO_CONTENTS
      script.AppendExtra(
          'else\n'
          '  abort("E%d: %s partition has unexpected non-zero contents after '
          'OTA update");\n'
          'endif;' % (code, partition))
    else:
      script.Print('Verified the updated %s image.' % (partition,))

    if partition == "system":
      code = ErrorCode.SYSTEM_UNEXPECTED_CONTENTS
    else:
      code = ErrorCode.VENDOR_UNEXPECTED_CONTENTS

    script.AppendExtra(
        'else\n'
        '  abort("E%d: %s partition has unexpected contents after OTA '
        'update");\n'
        'endif;' % (code, partition))

  def _WriteUpdate(self, script, output_zip):
    ZipWrite(output_zip,
             '{}.transfer.list'.format(self.path),
             '{}.transfer.list'.format(self.partition))

    # For full OTA, compress the new.dat with brotli with quality 6 to reduce
    # its size. Quailty 9 almost triples the compression time but doesn't
    # further reduce the size too much. For a typical 1.8G system.new.dat
    #                       zip  | brotli(quality 6)  | brotli(quality 9)
    #   compressed_size:    942M | 869M (~8% reduced) | 854M
    #   compression_time:   75s  | 265s               | 719s
    #   decompression_time: 15s  | 25s                | 25s

    if not self.src:
      brotli_cmd = ['brotli', '--quality=6',
                    '--output={}.new.dat.br'.format(self.path),
                    '{}.new.dat'.format(self.path)]
      print("Compressing {}.new.dat with brotli".format(self.partition))
      RunAndCheckOutput(brotli_cmd)

      new_data_name = '{}.new.dat.br'.format(self.partition)
      ZipWrite(output_zip,
               '{}.new.dat.br'.format(self.path),
               new_data_name,
               compress_type=zipfile.ZIP_STORED)
    else:
      new_data_name = '{}.new.dat'.format(self.partition)
      ZipWrite(output_zip, '{}.new.dat'.format(self.path), new_data_name)

    ZipWrite(output_zip,
             '{}.patch.dat'.format(self.path),
             '{}.patch.dat'.format(self.partition),
             compress_type=zipfile.ZIP_STORED)

    if self.partition == "system":
      code = ErrorCode.SYSTEM_UPDATE_FAILURE
    else:
      code = ErrorCode.VENDOR_UPDATE_FAILURE

    call = ('block_image_update({device}, '
            'package_extract_file("{partition}.transfer.list"), '
            '"{new_data_name}", "{partition}.patch.dat") ||\n'
            '  abort("E{code}: Failed to update {partition} image.");'.format(
                device=self.device, partition=self.partition,
                new_data_name=new_data_name, code=code))
    script.AppendExtra(script.WordWrap(call))

  def _HashBlocks(self, source, ranges):  # pylint: disable=no-self-use
    data = source.ReadRangeSet(ranges)
    ctx = sha1()

    for p in data:
      ctx.update(p)

    return ctx.hexdigest()

  def _HashZeroBlocks(self, num_blocks):  # pylint: disable=no-self-use
    """Return the hash value for all zero blocks."""
    zero_block = '\x00' * 4096
    ctx = sha1()
    for _ in range(num_blocks):
      ctx.update(zero_block)

    return ctx.hexdigest()


# Expose these two classes to support vendor-specific scripts
DataImage = images.DataImage
EmptyImage = images.EmptyImage


# map recovery.fstab's fs_types to mount/format "partition types"
PARTITION_TYPES = {
    "ext4": "EMMC",
    "emmc": "EMMC",
    "f2fs": "EMMC",
    "squashfs": "EMMC",
    "erofs": "EMMC"
}


def GetTypeAndDevice(mount_point, info, check_no_slot=True):
  """
  Use GetTypeAndDeviceExpr whenever possible. This function is kept for
  backwards compatibility. It aborts if the fstab entry has slotselect option
  (unless check_no_slot is explicitly set to False).
  """
  fstab = info["fstab"]
  if fstab:
    if check_no_slot:
      assert not fstab[mount_point].slotselect, \
          "Use GetTypeAndDeviceExpr instead"
    return (PARTITION_TYPES[fstab[mount_point].fs_type],
            fstab[mount_point].device)
  raise KeyError


def GetTypeAndDeviceExpr(mount_point, info):
  """
  Return the filesystem of the partition, and an edify expression that evaluates
  to the device at runtime.
  """
  fstab = info["fstab"]
  if fstab:
    p = fstab[mount_point]
    device_expr = '"%s"' % fstab[mount_point].device
    if p.slotselect:
      device_expr = 'add_slot_suffix(%s)' % device_expr
    return (PARTITION_TYPES[fstab[mount_point].fs_type], device_expr)
  raise KeyError


def GetEntryForDevice(fstab, device):
  """
  Returns:
    The first entry in fstab whose device is the given value.
  """
  if not fstab:
    return None
  for mount_point in fstab:
    if fstab[mount_point].device == device:
      return fstab[mount_point]
  return None


def ParseCertificate(data):
  """Parses and converts a PEM-encoded certificate into DER-encoded.

  This gives the same result as `openssl x509 -in <filename> -outform DER`.

  Returns:
    The decoded certificate bytes.
  """
  cert_buffer = []
  save = False
  for line in data.split("\n"):
    if "--END CERTIFICATE--" in line:
      break
    if save:
      cert_buffer.append(line)
    if "--BEGIN CERTIFICATE--" in line:
      save = True
  cert = base64.b64decode("".join(cert_buffer))
  return cert


def ExtractPublicKey(cert):
  """Extracts the public key (PEM-encoded) from the given certificate file.

  Args:
    cert: The certificate filename.

  Returns:
    The public key string.

  Raises:
    AssertionError: On non-zero return from 'openssl'.
  """
  # The behavior with '-out' is different between openssl 1.1 and openssl 1.0.
  # While openssl 1.1 writes the key into the given filename followed by '-out',
  # openssl 1.0 (both of 1.0.1 and 1.0.2) doesn't. So we collect the output from
  # stdout instead.
  cmd = ['openssl', 'x509', '-pubkey', '-noout', '-in', cert]
  proc = Run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  pubkey, stderrdata = proc.communicate()
  assert proc.returncode == 0, \
      'Failed to dump public key from certificate: %s\n%s' % (cert, stderrdata)
  return pubkey


def ExtractAvbPublicKey(avbtool, key):
  """Extracts the AVB public key from the given public or private key.

  Args:
    avbtool: The AVB tool to use.
    key: The input key file, which should be PEM-encoded public or private key.

  Returns:
    The path to the extracted AVB public key file.
  """
  output = MakeTempFile(prefix='avb-', suffix='.avbpubkey')
  RunAndCheckOutput(
      [avbtool, 'extract_public_key', "--key", key, "--output", output])
  return output


def MakeRecoveryPatch(input_dir, output_sink, recovery_img, boot_img,
                      info_dict=None):
  """Generates the recovery-from-boot patch and writes the script to output.

  Most of the space in the boot and recovery images is just the kernel, which is
  identical for the two, so the resulting patch should be efficient. Add it to
  the output zip, along with a shell script that is run from init.rc on first
  boot to actually do the patching and install the new recovery image.

  Args:
    input_dir: The top-level input directory of the target-files.zip.
    output_sink: The callback function that writes the result.
    recovery_img: File object for the recovery image.
    boot_img: File objects for the boot image.
    info_dict: A dict returned by common.LoadInfoDict() on the input
        target_files. Will use OPTIONS.info_dict if None has been given.
  """
  if info_dict is None:
    info_dict = OPTIONS.info_dict

  full_recovery_image = info_dict.get("full_recovery_image") == "true"
  board_uses_vendorimage = info_dict.get("board_uses_vendorimage") == "true"

  if board_uses_vendorimage:
    # In this case, the output sink is rooted at VENDOR
    recovery_img_path = "etc/recovery.img"
    recovery_resource_dat_path = "VENDOR/etc/recovery-resource.dat"
    sh_dir = "bin"
  else:
    # In this case the output sink is rooted at SYSTEM
    recovery_img_path = "vendor/etc/recovery.img"
    recovery_resource_dat_path = "SYSTEM/vendor/etc/recovery-resource.dat"
    sh_dir = "vendor/bin"

  if full_recovery_image:
    output_sink(recovery_img_path, recovery_img.data)

  else:
    system_root_image = info_dict.get("system_root_image") == "true"
    include_recovery_dtbo = info_dict.get("include_recovery_dtbo") == "true"
    include_recovery_acpio = info_dict.get("include_recovery_acpio") == "true"
    path = os.path.join(input_dir, recovery_resource_dat_path)
    # With system-root-image, boot and recovery images will have mismatching
    # entries (only recovery has the ramdisk entry) (Bug: 72731506). Use bsdiff
    # to handle such a case.
    if system_root_image or include_recovery_dtbo or include_recovery_acpio:
      diff_program = ["bsdiff"]
      bonus_args = ""
      assert not os.path.exists(path)
    else:
      diff_program = ["imgdiff"]
      if os.path.exists(path):
        diff_program.append("-b")
        diff_program.append(path)
        bonus_args = "--bonus /vendor/etc/recovery-resource.dat"
      else:
        bonus_args = ""

    d = Difference(recovery_img, boot_img, diff_program=diff_program)
    _, _, patch = d.ComputePatch()
    output_sink("recovery-from-boot.p", patch)

  try:
    # The following GetTypeAndDevice()s need to use the path in the target
    # info_dict instead of source_info_dict.
    boot_type, boot_device = GetTypeAndDevice("/boot", info_dict,
                                              check_no_slot=False)
    recovery_type, recovery_device = GetTypeAndDevice("/recovery", info_dict,
                                                      check_no_slot=False)
  except KeyError:
    return

  if full_recovery_image:

    # Note that we use /vendor to refer to the recovery resources. This will
    # work for a separate vendor partition mounted at /vendor or a
    # /system/vendor subdirectory on the system partition, for which init will
    # create a symlink from /vendor to /system/vendor.

    sh = """#!/vendor/bin/sh
if ! applypatch --check %(type)s:%(device)s:%(size)d:%(sha1)s; then
  applypatch \\
          --flash /vendor/etc/recovery.img \\
          --target %(type)s:%(device)s:%(size)d:%(sha1)s && \\
      log -t recovery "Installing new recovery image: succeeded" || \\
      log -t recovery "Installing new recovery image: failed"
else
  log -t recovery "Recovery image already installed"
fi
""" % {'type': recovery_type,
       'device': recovery_device,
       'sha1': recovery_img.sha1,
       'size': recovery_img.size}
  else:
    sh = """#!/vendor/bin/sh
if ! applypatch --check %(recovery_type)s:%(recovery_device)s:%(recovery_size)d:%(recovery_sha1)s; then
  applypatch %(bonus_args)s \\
          --patch /vendor/recovery-from-boot.p \\
          --source %(boot_type)s:%(boot_device)s:%(boot_size)d:%(boot_sha1)s \\
          --target %(recovery_type)s:%(recovery_device)s:%(recovery_size)d:%(recovery_sha1)s && \\
      log -t recovery "Installing new recovery image: succeeded" || \\
      log -t recovery "Installing new recovery image: failed"
else
  log -t recovery "Recovery image already installed"
fi
""" % {'boot_size': boot_img.size,
       'boot_sha1': boot_img.sha1,
       'recovery_size': recovery_img.size,
       'recovery_sha1': recovery_img.sha1,
       'boot_type': boot_type,
       'boot_device': boot_device + '$(getprop ro.boot.slot_suffix)',
       'recovery_type': recovery_type,
       'recovery_device': recovery_device + '$(getprop ro.boot.slot_suffix)',
       'bonus_args': bonus_args}

  # The install script location moved from /system/etc to /system/bin in the L
  # release. In the R release it is in VENDOR/bin or SYSTEM/vendor/bin.
  sh_location = os.path.join(sh_dir, "install-recovery.sh")

  logger.info("putting script in %s", sh_location)

  output_sink(sh_location, sh.encode())


class DynamicPartitionUpdate(object):
  def __init__(self, src_group=None, tgt_group=None, progress=None,
               block_difference=None):
    self.src_group = src_group
    self.tgt_group = tgt_group
    self.progress = progress
    self.block_difference = block_difference

  @property
  def src_size(self):
    if not self.block_difference:
      return 0
    return DynamicPartitionUpdate._GetSparseImageSize(self.block_difference.src)

  @property
  def tgt_size(self):
    if not self.block_difference:
      return 0
    return DynamicPartitionUpdate._GetSparseImageSize(self.block_difference.tgt)

  @staticmethod
  def _GetSparseImageSize(img):
    if not img:
      return 0
    return img.blocksize * img.total_blocks


class DynamicGroupUpdate(object):
  def __init__(self, src_size=None, tgt_size=None):
    # None: group does not exist. 0: no size limits.
    self.src_size = src_size
    self.tgt_size = tgt_size


class DynamicPartitionsDifference(object):
  def __init__(self, info_dict, block_diffs, progress_dict=None,
               source_info_dict=None):
    if progress_dict is None:
      progress_dict = {}

    self._remove_all_before_apply = False
    if source_info_dict is None:
      self._remove_all_before_apply = True
      source_info_dict = {}

    block_diff_dict = collections.OrderedDict(
        [(e.partition, e) for e in block_diffs])

    assert len(block_diff_dict) == len(block_diffs), \
        "Duplicated BlockDifference object for {}".format(
            [partition for partition, count in
             collections.Counter(e.partition for e in block_diffs).items()
             if count > 1])

    self._partition_updates = collections.OrderedDict()

    for p, block_diff in block_diff_dict.items():
      self._partition_updates[p] = DynamicPartitionUpdate()
      self._partition_updates[p].block_difference = block_diff

    for p, progress in progress_dict.items():
      if p in self._partition_updates:
        self._partition_updates[p].progress = progress

    tgt_groups = shlex.split(info_dict.get(
        "super_partition_groups", "").strip())
    src_groups = shlex.split(source_info_dict.get(
        "super_partition_groups", "").strip())

    for g in tgt_groups:
      for p in shlex.split(info_dict.get(
              "super_%s_partition_list" % g, "").strip()):
        assert p in self._partition_updates, \
            "{} is in target super_{}_partition_list but no BlockDifference " \
            "object is provided.".format(p, g)
        self._partition_updates[p].tgt_group = g

    for g in src_groups:
      for p in shlex.split(source_info_dict.get(
              "super_%s_partition_list" % g, "").strip()):
        assert p in self._partition_updates, \
            "{} is in source super_{}_partition_list but no BlockDifference " \
            "object is provided.".format(p, g)
        self._partition_updates[p].src_group = g

    target_dynamic_partitions = set(shlex.split(info_dict.get(
        "dynamic_partition_list", "").strip()))
    block_diffs_with_target = set(p for p, u in self._partition_updates.items()
                                  if u.tgt_size)
    assert block_diffs_with_target == target_dynamic_partitions, \
        "Target Dynamic partitions: {}, BlockDifference with target: {}".format(
            list(target_dynamic_partitions), list(block_diffs_with_target))

    source_dynamic_partitions = set(shlex.split(source_info_dict.get(
        "dynamic_partition_list", "").strip()))
    block_diffs_with_source = set(p for p, u in self._partition_updates.items()
                                  if u.src_size)
    assert block_diffs_with_source == source_dynamic_partitions, \
        "Source Dynamic partitions: {}, BlockDifference with source: {}".format(
            list(source_dynamic_partitions), list(block_diffs_with_source))

    if self._partition_updates:
      logger.info("Updating dynamic partitions %s",
                  self._partition_updates.keys())

    self._group_updates = collections.OrderedDict()

    for g in tgt_groups:
      self._group_updates[g] = DynamicGroupUpdate()
      self._group_updates[g].tgt_size = int(info_dict.get(
          "super_%s_group_size" % g, "0").strip())

    for g in src_groups:
      if g not in self._group_updates:
        self._group_updates[g] = DynamicGroupUpdate()
      self._group_updates[g].src_size = int(source_info_dict.get(
          "super_%s_group_size" % g, "0").strip())

    self._Compute()

  def WriteScript(self, script, output_zip, write_verify_script=False):
    script.Comment('--- Start patching dynamic partitions ---')
    for p, u in self._partition_updates.items():
      if u.src_size and u.tgt_size and u.src_size > u.tgt_size:
        script.Comment('Patch partition %s' % p)
        u.block_difference.WriteScript(script, output_zip, progress=u.progress,
                                       write_verify_script=False)

    op_list_path = MakeTempFile()
    with open(op_list_path, 'w') as f:
      for line in self._op_list:
        f.write('{}\n'.format(line))

    ZipWrite(output_zip, op_list_path, "dynamic_partitions_op_list")

    script.Comment('Update dynamic partition metadata')
    script.AppendExtra('assert(update_dynamic_partitions('
                       'package_extract_file("dynamic_partitions_op_list")));')

    if write_verify_script:
      for p, u in self._partition_updates.items():
        if u.src_size and u.tgt_size and u.src_size > u.tgt_size:
          u.block_difference.WritePostInstallVerifyScript(script)
          script.AppendExtra('unmap_partition("%s");' % p)  # ignore errors

    for p, u in self._partition_updates.items():
      if u.tgt_size and u.src_size <= u.tgt_size:
        script.Comment('Patch partition %s' % p)
        u.block_difference.WriteScript(script, output_zip, progress=u.progress,
                                       write_verify_script=write_verify_script)
        if write_verify_script:
          script.AppendExtra('unmap_partition("%s");' % p)  # ignore errors

    script.Comment('--- End patching dynamic partitions ---')

  def _Compute(self):
    self._op_list = list()

    def append(line):
      self._op_list.append(line)

    def comment(line):
      self._op_list.append("# %s" % line)

    if self._remove_all_before_apply:
      comment('Remove all existing dynamic partitions and groups before '
              'applying full OTA')
      append('remove_all_groups')

    for p, u in self._partition_updates.items():
      if u.src_group and not u.tgt_group:
        append('remove %s' % p)

    for p, u in self._partition_updates.items():
      if u.src_group and u.tgt_group and u.src_group != u.tgt_group:
        comment('Move partition %s from %s to default' % (p, u.src_group))
        append('move %s default' % p)

    for p, u in self._partition_updates.items():
      if u.src_size and u.tgt_size and u.src_size > u.tgt_size:
        comment('Shrink partition %s from %d to %d' %
                (p, u.src_size, u.tgt_size))
        append('resize %s %s' % (p, u.tgt_size))

    for g, u in self._group_updates.items():
      if u.src_size is not None and u.tgt_size is None:
        append('remove_group %s' % g)
      if (u.src_size is not None and u.tgt_size is not None and
              u.src_size > u.tgt_size):
        comment('Shrink group %s from %d to %d' % (g, u.src_size, u.tgt_size))
        append('resize_group %s %d' % (g, u.tgt_size))

    for g, u in self._group_updates.items():
      if u.src_size is None and u.tgt_size is not None:
        comment('Add group %s with maximum size %d' % (g, u.tgt_size))
        append('add_group %s %d' % (g, u.tgt_size))
      if (u.src_size is not None and u.tgt_size is not None and
              u.src_size < u.tgt_size):
        comment('Grow group %s from %d to %d' % (g, u.src_size, u.tgt_size))
        append('resize_group %s %d' % (g, u.tgt_size))

    for p, u in self._partition_updates.items():
      if u.tgt_group and not u.src_group:
        comment('Add partition %s to group %s' % (p, u.tgt_group))
        append('add %s %s' % (p, u.tgt_group))

    for p, u in self._partition_updates.items():
      if u.tgt_size and u.src_size < u.tgt_size:
        comment('Grow partition %s from %d to %d' %
                (p, u.src_size, u.tgt_size))
        append('resize %s %d' % (p, u.tgt_size))

    for p, u in self._partition_updates.items():
      if u.src_group and u.tgt_group and u.src_group != u.tgt_group:
        comment('Move partition %s from default to %s' %
                (p, u.tgt_group))
        append('move %s %s' % (p, u.tgt_group))


def GetBootImageBuildProp(boot_img, ramdisk_format=RamdiskFormat.LZ4):
  """
  Get build.prop from ramdisk within the boot image

  Args:
    boot_img: the boot image file. Ramdisk must be compressed with lz4 or gzip format.

  Return:
    An extracted file that stores properties in the boot image.
  """
  tmp_dir = MakeTempDir('boot_', suffix='.img')
  try:
    RunAndCheckOutput(['unpack_bootimg', '--boot_img',
                      boot_img, '--out', tmp_dir])
    ramdisk = os.path.join(tmp_dir, 'ramdisk')
    if not os.path.isfile(ramdisk):
      logger.warning('Unable to get boot image timestamp: no ramdisk in boot')
      return None
    uncompressed_ramdisk = os.path.join(tmp_dir, 'uncompressed_ramdisk')
    if ramdisk_format == RamdiskFormat.LZ4:
      RunAndCheckOutput(['lz4', '-d', ramdisk, uncompressed_ramdisk])
    elif ramdisk_format == RamdiskFormat.GZ:
      with open(ramdisk, 'rb') as input_stream:
        with open(uncompressed_ramdisk, 'wb') as output_stream:
          p2 = Run(['gzip', '-d'], stdin=input_stream.fileno(),
                   stdout=output_stream.fileno())
          p2.wait()
    else:
      logger.error('Only support lz4 or gzip ramdisk format.')
      return None

    abs_uncompressed_ramdisk = os.path.abspath(uncompressed_ramdisk)
    extracted_ramdisk = MakeTempDir('extracted_ramdisk')
    # Use "toybox cpio" instead of "cpio" because the latter invokes cpio from
    # the host environment.
    RunAndCheckOutput(['toybox', 'cpio', '-F', abs_uncompressed_ramdisk, '-i'],
                      cwd=extracted_ramdisk)

    for search_path in RAMDISK_BUILD_PROP_REL_PATHS:
      prop_file = os.path.join(extracted_ramdisk, search_path)
      if os.path.isfile(prop_file):
        return prop_file
      logger.warning(
          'Unable to get boot image timestamp: no %s in ramdisk', search_path)

    return None

  except ExternalError as e:
    logger.warning('Unable to get boot image build props: %s', e)
    return None


def GetBootImageTimestamp(boot_img):
  """
  Get timestamp from ramdisk within the boot image

  Args:
    boot_img: the boot image file. Ramdisk must be compressed with lz4 format.

  Return:
    An integer that corresponds to the timestamp of the boot image, or None
    if file has unknown format. Raise exception if an unexpected error has
    occurred.
  """
  prop_file = GetBootImageBuildProp(boot_img)
  if not prop_file:
    return None

  props = PartitionBuildProps.FromBuildPropFile('boot', prop_file)
  if props is None:
    return None

  try:
    timestamp = props.GetProp('ro.bootimage.build.date.utc')
    if timestamp:
      return int(timestamp)
    logger.warning(
        'Unable to get boot image timestamp: ro.bootimage.build.date.utc is undefined')
    return None

  except ExternalError as e:
    logger.warning('Unable to get boot image timestamp: %s', e)
    return None


def IsSparseImage(filepath):
  if not os.path.exists(filepath):
    return False
  with open(filepath, 'rb') as fp:
    # Magic for android sparse image format
    # https://source.android.com/devices/bootloader/images
    return fp.read(4) == b'\x3A\xFF\x26\xED'


def UnsparseImage(filepath, target_path=None):
  if not IsSparseImage(filepath):
    return
  if target_path is None:
    tmp_img = MakeTempFile(suffix=".img")
    RunAndCheckOutput(["simg2img", filepath, tmp_img])
    os.rename(tmp_img, filepath)
  else:
    RunAndCheckOutput(["simg2img", filepath, target_path])


def ParseUpdateEngineConfig(path: str):
  """Parse the update_engine config stored in file `path`
  Args
    path: Path to update_engine_config.txt file in target_files

  Returns
    A tuple of (major, minor) version number . E.g. (2, 8)
  """
  with open(path, "r") as fp:
    # update_engine_config.txt is only supposed to contain two lines,
    # PAYLOAD_MAJOR_VERSION and PAYLOAD_MINOR_VERSION. 1024 should be more than
    # sufficient. If the length is more than that, something is wrong.
    data = fp.read(1024)
    major = re.search(r"PAYLOAD_MAJOR_VERSION=(\d+)", data)
    if not major:
      raise ValueError(
          f"{path} is an invalid update_engine config, missing PAYLOAD_MAJOR_VERSION {data}")
    minor = re.search(r"PAYLOAD_MINOR_VERSION=(\d+)", data)
    if not minor:
      raise ValueError(
          f"{path} is an invalid update_engine config, missing PAYLOAD_MINOR_VERSION {data}")
    return (int(major.group(1)), int(minor.group(1)))
