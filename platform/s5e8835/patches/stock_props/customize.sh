LOG "- Adding \"bluetooth.profile.bap.unicast.client.enabled\" prop with \"true\" in /product/etc/build.prop"
EVAL "sed -i \"/clientidbase.tx/i bluetooth.profile.bap.unicast.client.enabled=true\" \"$WORK_DIR/product/etc/build.prop\""

LOG "- Adding \"bluetooth.profile.csip.set_coordinator.enabled\" prop with \"true\" in /product/etc/build.prop"
EVAL "sed -i \"/clientidbase.tx/i bluetooth.profile.csip.set_coordinator.enabled=true\" \"$WORK_DIR/product/etc/build.prop\""

LOG "- Adding \"bluetooth.profile.mcp.server.enabled\" prop with \"true\" in /product/etc/build.prop"
EVAL "sed -i \"/clientidbase.tx/i bluetooth.profile.mcp.server.enabled=true\" \"$WORK_DIR/product/etc/build.prop\""

LOG "- Adding \"bluetooth.profile.ccp.server.enabled\" prop with \"true\" in /product/etc/build.prop"
EVAL "sed -i \"/clientidbase.tx/i bluetooth.profile.ccp.server.enabled=true\" \"$WORK_DIR/product/etc/build.prop\""

LOG "- Adding \"bluetooth.profile.vcp.controller.enabled\" prop with \"true\" in /product/etc/build.prop"
EVAL "sed -i \"/clientidbase.tx/i bluetooth.profile.vcp.controller.enabled=true\" \"$WORK_DIR/product/etc/build.prop\""

LOG "- Adding \"bluetooth.profile.bap.broadcast.assist.enabled\" prop with \"true\" in /product/etc/build.prop"
EVAL "sed -i \"/clientidbase.tx/i bluetooth.profile.bap.broadcast.assist.enabled=true\" \"$WORK_DIR/product/etc/build.prop\""

LOG "- Adding \"ro.frp.pst\" prop with \"/dev/block/persistent\" in /product/etc/build.prop"
EVAL "sed -i \"/clientidbase.tx/i ro.frp.pst=/dev/block/persistent\" \"$WORK_DIR/product/etc/build.prop\""

LOG "- Adding \"persist.audio.deepbuffer_delay\" prop with \"33\" in /system/build.prop"
EVAL "sed -i \"/ro.netflix.bsp_rev/i persist.audio.deepbuffer_delay=33\" \"$WORK_DIR/system/system/build.prop\""