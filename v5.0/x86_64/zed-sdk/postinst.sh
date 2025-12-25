#!/bin/sh
# ZED SDK x86_64 post-installation script

# Run ldconfig to update the library cache
ldconfig

# Trigger udev rules
udevadm control --reload-rules && udevadm trigger

# Create zed group if it doesn't exist
if ! getent group zed > /dev/null 2>&1; then
    groupadd --system zed
    echo "Created 'zed' group for multi-user ZED SDK access"
fi

# Set proper group ownership and permissions for /usr/local/zed
chgrp -R zed /usr/local/zed
chmod -R 775 /usr/local/zed

# Add current user to zed and video groups if not root
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    # Running under sudo, add the actual user
    usermod -aG zed "$SUDO_USER" 2>/dev/null || true
    usermod -aG video "$SUDO_USER" 2>/dev/null || true
    echo "Added user '$SUDO_USER' to 'zed' and 'video' groups"
elif [ "$(id -u)" != "0" ]; then
    # Running as non-root user directly
    USER_NAME="$(whoami)"
    usermod -aG zed "$USER_NAME" 2>/dev/null || true
    usermod -aG video "$USER_NAME" 2>/dev/null || true
    echo "Added user '$USER_NAME' to 'zed' and 'video' groups"
fi

echo ''
echo 'ZED SDK installation complete.'
echo ''
echo 'IMPORTANT: You have been added to the "zed" and "video" groups.'
echo 'You must log out and log back in for group membership to take effect.'
echo ''
echo 'Other users can be added to the zed group with:'
echo '  sudo usermod -aG zed USERNAME'
echo ''
echo 'To download all AI models and optimize them, run:'
echo '  zed_download_ai_models'
echo ''
