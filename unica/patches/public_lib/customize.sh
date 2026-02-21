ALLOWED_SYSTEM_LIBS=(
    "libQmageDecoder.so"
)

PUBLIC_SYSTEM_LIB_TXT="$WORK_DIR/system/system/etc/public.libraries.txt"
for lib in "${ALLOWED_SYSTEM_LIBS[@]}"; do
    LOG "Adding $lib to system public.libraries.txt"
    echo "$lib" >> "$PUBLIC_SYSTEM_LIB_TXT"
    done