#!/bin/bash
# Base dependencies script for ZED SDK Docker test containers
# Used by both runfile and deb installation methods

set -e

echo "Installing base dependencies for ZED SDK..."

# Update package lists
apt-get update

# Install essential build tools and utilities
apt-get install -y \
    curl \
    wget \
    unzip \
    zstd \
    tar \
    diffutils \
    tree \
    file \
    lsof \
    udev \
    systemd \
    sudo

# Install ZED SDK core dependencies
apt-get install -y \
    libjpeg-turbo8 \
    libturbojpeg \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    libopenblas-dev \
    libarchive-dev \
    libv4l-0 \
    zlib1g \
    mesa-utils \
    libpng-dev

# Install Qt dependencies for tools
apt-get install -y \
    qtbase5-dev \
    qtchooser \
    qt5-qmake \
    qtbase5-dev-tools \
    libqt5opengl5 \
    libqt5svg5

# Install OpenGL dependencies for samples
apt-get install -y \
    libglew-dev \
    freeglut3-dev

# Install Python dependencies
apt-get install -y \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-numpy \
    python3-requests \
    python3-pyqt5

# Create necessary directories
mkdir -p /usr/local/zed
mkdir -p /usr/local/bin
mkdir -p /etc/udev/rules.d
mkdir -p /etc/ld.so.conf.d

# Clean package cache to reduce image size
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Base dependencies installed successfully."