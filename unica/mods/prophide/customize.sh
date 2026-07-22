# [
PUB_KEY_ADDR_EXTRACT() {
    local FILE="$1"

    local HEADER="256" AUTH_SZ="12" PK_OFF="64" PK_SIZE="72"

    # read 8-byte big-endian integer at offset
    READ_BE64() {
        local OFF="$1"
        local HEX
        HEX="$(dd if="$FILE" bs=1 skip="$OFF" count=8 2> /dev/null | xxd -p -c 8)"
        printf "%d" "0x$HEX"
    }

    local SKP CNT
    SKP="$((HEADER + $(READ_BE64 $AUTH_SZ) + $(READ_BE64 $PK_OFF)))"
    CNT="$(READ_BE64 $PK_SIZE)"

    echo "$SKP $CNT"
}
# ]

VBIMG="$FW_DIR/$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")/avb/vbmeta.img"
if [ ! -f "$VBIMG" ]; then
    ABORT "File not found: ${VBIMG//$SRC_DIR\//}"
fi

AVBINFO="$(avbtool info_image --image "$VBIMG")"
AVBSIZE="$(awk '/Block:/ {sum+=$3} END {print sum}' <<< "$AVBINFO")"
read -r PK_OFFSET PK_SIZE < <(PUB_KEY_ADDR_EXTRACT "$VBIMG")

sed -i \
    -e "s|VB_SIZE|$AVBSIZE|g" \
    -e "s|PK_OFFSET|$PK_OFFSET|g" \
    -e "s|PK_SIZE|$PK_SIZE|g" \
    "$WORK_DIR/system/system/bin/prophide.sh"

SEPOLICY="$WORK_DIR/system/system/etc/selinux/plat_sepolicy.cil"

sed -i \
    -e "/^(allow init init_exec\b/ s/)))/ execute_no_trans)))/" \
    -e "/^(typeattributeset exec_type\b/ s/))/prophide_exec ))/" \
    -e "/^(typeattributeset file_type\b/ s/))/prophide_exec ))/" \
    -e "/^(typeattributeset system_file_type\b/ s/))/prophide_exec ))/" \
    -e "/^(typeattributeset domain\b/ s/))/prophide ))/" \
    "$SEPOLICY"

# process (init) -> /system/bin/prophide.sh (prophide_exec) -> process (prophide)  |
# A                                                                                V
# | /system/bin/rezetprop (init_exec) <- /system/bin/toybox (prophide) <- /system/bin/sh (prophide)
cat <<'EOF' >> "$SEPOLICY"
; Added by unica/mods/prophide/customize.sh
; types
(type prophide)
(roletype object_r prophide)
(type prophide_exec)
(roletype object_r prophide_exec)
; init -> prophide_exec -> prophide
(typetransition init prophide_exec process prophide)
(allow init prophide (process (transition)))
(allow init prophide (process (noatsecure rlimitinh siginh)))
(allow init prophide (fd (use)))
; prophide -> init_exec -> init
(typetransition prophide init_exec process init)
(allow prophide init (process (transition)))
(allow prophide init (process (noatsecure rlimitinh siginh)))
; block access
(allow prophide block_device (blk_file (read open getattr ioctl)))
(allow prophide emmcblk_device (blk_file (read open getattr ioctl)))
; allow calling init_exec by escalating when needed
(allow init prophide_exec (file (read open execute getattr map)))
(allow prophide init_exec (file (read open execute getattr map)))
; allow calling system binaries without domain change
(allow prophide shell_exec (file (read open execute getattr map execute_no_trans)))
(allow prophide system_file (file (read open execute getattr map execute_no_trans)))
(allow prophide toolbox_exec (file (read open execute getattr map execute_no_trans)))
(allow prophide prophide_exec (file (entrypoint read open execute getattr map)))
EOF

unset VBIMG AVBINFO AVBSIZE PK_OFFSET PK_SIZE SEPOLICY
unset -f PUB_KEY_ADDR_EXTRACT
