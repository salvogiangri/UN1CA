# Blob Updates for dm2q/sm8550

## Summary
This document details the blob additions made to fix errors identified in the dm2q (Samsung Galaxy S23) device logs running on the sm8550 (Snapdragon 8 Gen 2) platform.

## Log Analysis
Source: [dm2q log](https://gist.githubusercontent.com/Eduardob3677/719f0e0773047bb96befee3d43267585/raw/1f287a6a254e2efa0674571b93d643117081c079/log.txt)

### Critical Errors Identified

1. **VaultKeeper TA (Trusted Application) Not Found**
   - Error: `QSEECOMPAT: lookupTA(vaultkeeper) returned 23`
   - Impact: VaultKeeper service fails to initialize, affecting Samsung secure storage features
   - Occurrence: Multiple instances throughout the log

2. **VaultKeeper Service Errors**
   - Error: `VaultKeeper_COMMON: Occured Error into TA side(-10032//vendor/bin/vaultkeeperd/VK)`
   - Error: `vaultkeeper: VaultKeeper service preparation is failed`
   - Impact: Secure storage and authentication features unavailable

3. **Process Authenticator Config Missing**
   - Error: `PA_DAEMON: [ReadConfig:343] Cannot read config file.`
   - Impact: Process authentication and integrity verification may be compromised

### Non-Critical Errors (Not Addressed)
- **libpenguin.so missing**: This is a third-party Instagram/Facebook library, not a system component
- **Phenotype API errors**: Google Play Services related, not device-specific
- **imsupdate.json not found**: Carrier-specific IMS configuration, not critical

## Files Modified

### platform/sm8550/patches/blobs/customize.sh
Added three new blob sections to fix the identified errors:

#### 1. QSEECOM Blobs (Lines 36-57)
**Purpose**: Qualcomm Secure Execution Environment Communication - Required for TEE (Trusted Execution Environment)

**Binaries Added:**
- `vendor/bin/qseecomd` - QSEE daemon that manages communication with the Trusted Execution Environment
- `vendor/bin/hw/vendor.qti.hardware.qseecom@1.0-service` - HIDL service for QSEECOM HAL

**Vendor Libraries (32-bit and 64-bit):**
- `libQSEEComAPI.so` - Core API for QSEE communication
- `com.qti.qseeaon.so` - Always-on QSEE utilities
- `com.qti.qseeutils.so` - QSEE utility functions
- `vendor.qti.hardware.qseecom@1.0.so` - HIDL interface library
- `hw/vendor.qti.hardware.qseecom@1.0-impl.so` - HIDL implementation

**System_ext Libraries (32-bit and 64-bit):**
- `libQSEEComAPI_system.so` - System-side QSEE API
- `vendor.qti.hardware.qseecom@1.0.so` - System-side HIDL interface
- `vendor.qti.hardware.qseecom-V1-ndk.so` - NDK version of QSEECOM interface

**Configuration Files:**
- `vendor/etc/init/qseecomd.rc` - Init script to start qseecomd daemon
- `vendor/etc/init/vendor.qti.hardware.qseecom@1.0-service.rc` - Init script for QSEECOM service

**Reasoning**: QSEECOM is the foundation for all secure operations on Qualcomm platforms. Without it, VaultKeeper and other secure services cannot access the Trusted Execution Environment.

#### 2. VaultKeeper Blobs (Lines 59-67)
**Purpose**: Samsung's secure storage service for sensitive data

**Binaries Added:**
- `vendor/bin/vaultkeeperd` - VaultKeeper daemon
- `vendor/bin/vendor.samsung.hardware.security.vaultkeeper@2.0-service` - HIDL service for VaultKeeper HAL

**Vendor Libraries:**
- `vendor/lib64/vendor.samsung.hardware.security.vaultkeeper@2.0.so` - HIDL interface library (64-bit only)

**System Libraries (32-bit and 64-bit):**
- `system/lib/vendor.samsung.hardware.security.vaultkeeper@2.0.so` - System-side VaultKeeper library
- `system/lib64/vendor.samsung.hardware.security.vaultkeeper@2.0.so` - System-side VaultKeeper library (64-bit)

**Configuration Files:**
- `vendor/etc/init/vaultkeeper_common.rc` - Init script to start VaultKeeper services
- `vendor/etc/vintf/manifest/vaultkeeper_manifest.xml` - VINTF manifest for VaultKeeper HAL

**Reasoning**: VaultKeeper provides secure storage for Samsung-specific security features including Knox, Samsung Pass, and secure folder functionality. The log errors show it's failing to initialize due to missing TA and supporting infrastructure.

#### 3. Process Authenticator Blobs (Lines 69-72)
**Purpose**: Samsung's process integrity verification system

**Binaries Added:**
- `vendor/bin/vendor.samsung.hardware.security.proca@2.0-service` - Process Authenticator service

**Configuration Files:**
- `vendor/etc/init/pa_daemon_qsee.rc` - Init script for Process Authenticator

**Reasoning**: Process Authenticator (PROCA) verifies the integrity of running processes and works with VaultKeeper. The log shows PA_DAEMON errors related to missing configuration, which is resolved by adding the proper service and init files.

## SELinux Contexts Used

- Binaries (executables): 755 permissions with appropriate exec contexts
  - `u:object_r:tee_exec:s0` for qseecomd
  - `u:object_r:hal_drm_default_exec:s0` for QSEECOM service
  - `u:object_r:vaultkeeper_exec:s0` for vaultkeeperd
  - `u:object_r:hal_vaultkeeper_default_exec:s0` for VaultKeeper service
  - `u:object_r:hal_proca_default_exec:s0` for PROCA service

- Libraries: 644 permissions
  - `u:object_r:vendor_file:s0` for vendor partition libraries
  - `u:object_r:system_lib_file:s0` for system/system_ext partition libraries

- Configuration files: 644 permissions
  - `u:object_r:vendor_configs_file:s0` for all vendor config files

## Device/Platform Scope
- **Device**: dm2q (Samsung Galaxy S23)
- **Platform**: sm8550 (Qualcomm Snapdragon 8 Gen 2)
- **Other devices**: Not affected - changes are isolated to `platform/sm8550/patches/blobs/`

## Testing Recommendations
1. Verify VaultKeeper service starts successfully
2. Check for absence of QSEECOMPAT errors in logcat
3. Verify Samsung secure features (Knox, Samsung Pass) function properly
4. Ensure Process Authenticator daemon starts without config errors

## References
- Log source: https://gist.githubusercontent.com/Eduardob3677/719f0e0773047bb96befee3d43267585/raw/1f287a6a254e2efa0674571b93d643117081c079/log.txt
- Dump location: `/dump` directory in repository
- Platform: Qualcomm Snapdragon 8 Gen 2 (sm8550/kalama)
