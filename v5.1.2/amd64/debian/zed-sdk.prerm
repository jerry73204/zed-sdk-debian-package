#!/bin/sh
# prerm script for zed-sdk
# This script runs BEFORE the package files are removed

set -e

arch=$(dpkg --print-architecture)

case "$1" in
    remove|upgrade|deconfigure)
        # Stop and disable services before removal
        if [ "$arch" = "arm64" ]; then
            if command -v systemctl >/dev/null && systemctl list-units >/dev/null 2>&1; then
                # Only stop/disable if service exists and is active
                if systemctl list-unit-files | grep -q zed_media_server_cli.service; then
                    echo "Stopping ZED Media Server service..."
                    systemctl stop zed_media_server_cli.service || true
                    systemctl disable zed_media_server_cli.service || true
                fi
            fi
        fi
        
        # Stop any running ZED applications gracefully
        # This gives applications time to close camera connections properly
        if command -v pkill >/dev/null; then
            pkill -TERM -f "ZED_" || true
            sleep 1
        fi
        ;;
        
    failed-upgrade)
        ;;
        
    *)
        echo "prerm called with unknown argument \`$1'" >&2
        exit 1
        ;;
esac

exit 0