#!/bin/sh
# ZED SDK x86_64 post-removal script

# Run ldconfig to update the library cache
ldconfig

# Trigger udev rules
udevadm control --reload-rules && udevadm trigger

# Note: We don't remove the zed group as other users might still need it
# If you want to remove it manually: groupdel zed
