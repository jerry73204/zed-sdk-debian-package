#!/bin/sh
# postinst script for zed-sdk (AMD64)

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

echo '════════════════════════════════════════════════════════════════════'
echo '                 ZED SDK Installation Complete!'
echo '════════════════════════════════════════════════════════════════════'
echo ''
echo '► To use the SDK, add your user to the video group:'
echo '  sudo usermod -a -G video $(whoami)'
echo '  (then log out and back in)'
echo ''
echo '► To enable AI features (object detection, body tracking, etc.):'
echo '  sudo zed_ai_optimizer'
echo ''
echo '  This will download and optimize AI models for your GPU.'
echo '  ⚠ Note: Optimization can take 30-60 minutes but only needs to be done once.'
echo ''
echo '► For more options, run:'
echo '  zed_ai_optimizer --help'
echo ''
echo '════════════════════════════════════════════════════════════════════'

exit 0