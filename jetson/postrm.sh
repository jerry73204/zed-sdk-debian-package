#!/bin/sh
# ZED SDK Jetson post-removal script

# Run ldconfig to update the library cache
ldconfig

# Trigger udev rules
udevadm control --reload-rules && udevadm trigger

# Reload systemd daemon
if command -v systemctl >/dev/null && systemctl list-units >/dev/null 2>&1; then
    systemctl daemon-reload
fi

# Note: We don't remove the zed group as other users might still need it
# If you want to remove it manually: groupdel zed
