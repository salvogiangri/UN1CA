sed -i '\|^(genfscon proc "/sys/kernel/firmware_config" (u object_r proc_fmw ((s0) (s0))))|d' \
$WORK_DIR/system/system/system_ext/etc/selinux/system_ext_sepolicy.cil