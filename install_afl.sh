#!/bin/bash
# setup/install_afl.sh - Install AFL++ fuzzer

set -e

echo "=== Installing AFL++ ==="

# Update system
apt-get update

# Install dependencies
echo "[*] Installing build dependencies..."
apt-get install -y \
    build-essential \
    python3-pip \
    python3-dev \
    python3-setuptools \
    gcc \
    g++ \
    make \
    cmake \
    git \
    wget \
    llvm \
    clang \
    libglib2.0-dev \
    libpixman-1-dev \
    automake \
    libtool \
    libgcc-9-dev \
    pkg-config

# Clone and build AFL++
echo "[*] Cloning AFL++..."
cd /tmp
if [ -d "AFLplusplus" ]; then
    rm -rf AFLplusplus
fi

git clone https://github.com/AFLplusplus/AFLplusplus
cd AFLplusplus

echo "[*] Building AFL++..."
make distrib
make install

echo "[*] Verifying installation..."
if command -v afl-fuzz &> /dev/null; then
    echo "✓ AFL++ installed successfully!"
    afl-fuzz -h 2>&1 | head -n 1
else
    echo "✗ AFL++ installation failed!"
    exit 1
fi

# Setup environment variables
echo "[*] Setting up environment..."
echo "" >> ~/.bashrc
echo "# AFL++ Configuration" >> ~/.bashrc
echo "export AFL_SKIP_CPUFREQ=1" >> ~/.bashrc
echo "export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1" >> ~/.bashrc

echo "=== AFL++ Installation Complete ==="