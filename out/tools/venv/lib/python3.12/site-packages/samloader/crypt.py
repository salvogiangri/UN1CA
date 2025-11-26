# SPDX-License-Identifier: GPL-3.0+
# Copyright (C) 2020 nlscc

""" Calculate keys and decrypt encrypted firmware packages. """

import hashlib
import xml.etree.ElementTree as ET
from Cryptodome.Cipher import AES
from tqdm import tqdm

from . import fusclient
from . import request
from . import versionfetch

# PKCS#7 unpad
unpad = lambda d: d[:-d[-1]]

def getv4key(version, model, region, imei):
    """ Retrieve the AES key for V4 encryption. """
    client = fusclient.FUSClient()
    version = versionfetch.normalizevercode(version)
    req = request.binaryinform(version, model, region, imei, client.nonce)
    resp = client.makereq("NF_DownloadBinaryInform.do", req)
    root = ET.fromstring(resp)
    fwver = root.find("./FUSBody/Results/LATEST_FW_VERSION/Data").text
    logicval = root.find("./FUSBody/Put/LOGIC_VALUE_FACTORY/Data").text
    deckey = request.getlogiccheck(fwver, logicval)
    return hashlib.md5(deckey.encode()).digest()

def getv2key(version, model, region):
    """ Calculate the AES key for V2 (legacy) encryption. """
    deckey = region + ":" + model + ":" + version
    return hashlib.md5(deckey.encode()).digest()

def decrypt_progress(inf, outf, key, length):
    """ Decrypt a stream of data while showing a progress bar. """
    cipher = AES.new(key, AES.MODE_ECB)
    if length % 16 != 0:
        raise Exception("invalid input block size")
    chunks = length//4096+1
    pbar = tqdm(total=length, unit="B", unit_scale=True)
    for i in range(chunks):
        block = inf.read(4096)
        if not block:
            break
        decblock = cipher.decrypt(block)
        if i == chunks - 1:
            outf.write(unpad(decblock))
        else:
            outf.write(decblock)
        pbar.update(4096)
