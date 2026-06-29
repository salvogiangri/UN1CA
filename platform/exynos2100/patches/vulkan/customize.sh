LOG "- Patching SBWC compression for Vulkan compatibility in /vendor/build.prop"

EVAL "if grep -q '^vendor.debug.c2.sbwc.enable=' \"$WORK_DIR/vendor/build.prop\"; then \
        sed -i 's/^vendor.debug.c2.sbwc.enable=.*/vendor.debug.c2.sbwc.enable=false/g' \"$WORK_DIR/vendor/build.prop\"; \
      else \
        echo 'vendor.debug.c2.sbwc.enable=false' >> \"$WORK_DIR/vendor/build.prop\"; \
      fi"