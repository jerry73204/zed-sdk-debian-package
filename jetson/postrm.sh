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

# Remove v4l2 symlink if it was created by us
if [ -L "/usr/lib/aarch64-linux-gnu/libv4l2.so" ]; then
    rm -f /usr/lib/aarch64-linux-gnu/libv4l2.so
fi

# On purge (complete removal), remove the zed group
# $1 is passed by dpkg: "purge" means complete removal, "remove" keeps config
if [ "$1" = "purge" ]; then
    # Only remove the group if it exists and has no members
    if getent group zed > /dev/null 2>&1; then
        # Get list of users in zed group
        zed_members=$(getent group zed | cut -d: -f4)

        if [ -z "$zed_members" ]; then
            groupdel zed 2>/dev/null || true
            echo "Removed empty 'zed' group"
        else
            echo "Note: 'zed' group not removed as it still has members: $zed_members"
            echo "To remove manually after removing all users: sudo groupdel zed"
        fi
    fi
fi
