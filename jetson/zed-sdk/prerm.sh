#!/bin/sh
# ZED SDK Jetson pre-removal script

# Disable and stop ZED Media Server service
if command -v systemctl >/dev/null && systemctl list-units >/dev/null 2>&1; then
    systemctl disable zed_media_server_cli.service
    systemctl stop zed_media_server_cli.service
fi
