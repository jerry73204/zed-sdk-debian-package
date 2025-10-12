#!/bin/sh
# ZED SDK x86_64 post-installation script

# Run ldconfig to update the library cache
ldconfig

# Trigger udev rules
udevadm control --reload-rules && udevadm trigger

echo ''
echo 'ZED SDK installation complete.'
echo ''
echo 'To use the SDK, add your user to the video group with:'
echo '  sudo usermod -a -G video $(whoami)'
echo 'and then log out and back in.'
echo ''
echo 'To download all AI models and optimize them, run:'
echo '  zed_download_ai_models'
echo ''
