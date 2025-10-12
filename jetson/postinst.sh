#!/bin/sh
arch=$(dpkg --print-architecture)

# Run ldconfig to update the library cache
ldconfig

# Trigger udev rules
udevadm control --reload-rules && udevadm trigger

# Enable and start zed_media_server_cli.service and modify argus daemon on Jetson
if [ "$arch" = "arm64" ]; then
    if command -v systemctl >/dev/null && systemctl list-units >/dev/null 2>&1; then
        # Modify argus daemon to avoid timeout when using multiple cameras
        if [ -f "/etc/systemd/system/nvargus-daemon.service" ]; then
            # Check if the line already exists to avoid duplicate entries
            if ! grep -q "enableCamInfiniteTimeout=1" /etc/systemd/system/nvargus-daemon.service; then
                sed -i '/^\[Service\]$/ a Environment="enableCamInfiniteTimeout=1"' /etc/systemd/system/nvargus-daemon.service
                systemctl daemon-reload
            fi
        fi

	systemctl daemon-reload
	systemctl enable zed_media_server_cli.service
	systemctl restart zed_media_server_cli.service
    fi

    # Display warning about libv4l-dev
    echo ''
    echo '⚠️  WARNING: Installing the "libv4l-dev" package on Jetson devices will break hardware'
    echo '   encoding/decoding support. This package has been configured to conflict with libv4l-dev.'
    echo ''
fi

echo 'ZED SDK installation complete. To use the SDK, add your user to the video group with:'
echo '  sudo usermod -a -G video $(whoami)'
echo 'and then log out and back in.'
echo ''
echo 'To download all AI models and optimize them,'
echo '  zed_download_ai_models'
