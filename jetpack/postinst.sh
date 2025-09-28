#!/bin/sh
# postinst script for zed-sdk-jetpack (NVIDIA Jetson)

set -e

# Create zed group if it doesn't exist
if ! getent group zed > /dev/null 2>&1; then
    echo "Creating 'zed' group..."
    groupadd zed
fi

# Set group ownership on ZED SDK directory
if [ -d "/usr/local/zed" ]; then
    chgrp -R zed /usr/local/zed
    chmod g+rX /usr/local/zed
fi

# Run ldconfig to update the library cache
ldconfig

# Trigger udev rules
udevadm control --reload-rules && udevadm trigger

# Jetson-specific: Modify argus daemon to avoid timeout when using multiple cameras
if command -v systemctl >/dev/null && systemctl list-units >/dev/null 2>&1; then
    if [ -f "/etc/systemd/system/nvargus-daemon.service" ]; then
        # Check if the line already exists to avoid duplicate entries
        if ! grep -q "enableCamInfiniteTimeout=1" /etc/systemd/system/nvargus-daemon.service; then
            sed -i '/^\[Service\]$/ a Environment="enableCamInfiniteTimeout=1"' /etc/systemd/system/nvargus-daemon.service
            systemctl daemon-reload
        fi
    fi
    
    # Enable and start ZED Media Server service
    if [ -f "/etc/systemd/system/zed_media_server_cli.service" ]; then
        systemctl daemon-reload
        systemctl enable zed_media_server_cli.service
        systemctl restart zed_media_server_cli.service
    fi
fi

echo ''
echo '⚠️  WARNING: Installing the "libv4l-dev" package on Jetson devices will break hardware'
echo '   encoding/decoding support. This package has been configured to conflict with libv4l-dev.'
echo ''

echo '════════════════════════════════════════════════════════════════════'
echo '           ZED SDK for NVIDIA Jetson Installation Complete!'
echo '════════════════════════════════════════════════════════════════════'
echo ''
echo '► To use the SDK, add your user to the video group:'
echo '  sudo usermod -a -G video $(whoami)'
echo '  (then log out and back in)'
echo ''
echo '► To enable AI features (optimized for Jetson NPU):'
echo '  sudo zed_ai_optimizer'
echo ''
echo '  This will download and optimize AI models for your Jetson device.'
echo '  Models will be optimized for NPU/DLA hardware acceleration when available.'
echo '  ⚠ Note: Optimization can take 30-60 minutes but only needs to be done once.'
echo ''
echo '► ZED Media Server is now running (for streaming capabilities)'
echo '  Check status: systemctl status zed_media_server_cli'
echo ''
echo '► For more options, run:'
echo '  zed_ai_optimizer --help'
echo ''
echo '════════════════════════════════════════════════════════════════════'

exit 0