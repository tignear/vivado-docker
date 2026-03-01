# syntax=docker/dockerfile:1
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# Vivado/Vitis runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    locales \
    libncurses5 \
    libtinfo5 \
    libncursesw5 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libfreetype6 \
    libfontconfig1 \
    libglib2.0-0 \
    libsm6 \
    libice6 \
    libxrandr2 \
    libxcursor1 \
    libxinerama1 \
    libxft2 \
    libc6-i386 \
    lib32stdc++6 \
    graphviz \
    make \
    net-tools \
    unzip \
    xvfb \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Workaround: Vivado's libtbbmalloc_proxy conflicts with libudev in containers
# https://adaptivesupport.amd.com/s/article/000034450
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libudev.so.1

# Install Vivado/Vitis in batch mode.
# - bind mount: installer .bin stays out of image layers
# - secret mount: auth token never appears in build logs or layers
RUN --mount=type=bind,target=/mnt/build \
    --mount=type=secret,id=auth_token,target=/root/.Xilinx/wi_authentication_key,required=true \
    set -e \
    && echo "=== Searching for installer ===" \
    && installer="$(find /mnt/build -maxdepth 1 -name '*.bin' -type f | head -1)" \
    && if [ -z "$installer" ]; then \
         echo "ERROR: No .bin installer found in build context"; exit 1; \
       fi \
    && echo "=== Found: $installer ===" \
    && echo "=== Extracting installer ===" \
    && bash "$installer" --keep --noexec --target /tmp/xilinx_unified \
    && echo "=== Running batch install ===" \
    && /tmp/xilinx_unified/xsetup \
        -b Install \
        -a XilinxEULA,3rdPartyEULA \
        -c /mnt/build/install_config.txt \
    && echo "=== Cleaning up ===" \
    && rm -rf /tmp/xilinx_unified

# Source Vivado/Vitis settings on every login shell
RUN printf '[ -f /opt/Xilinx/2025.2/Vivado/settings64.sh ] && . /opt/Xilinx/2025.2/Vivado/settings64.sh\n[ -f /opt/Xilinx/2025.2/Vitis/settings64.sh ] && . /opt/Xilinx/2025.2/Vitis/settings64.sh\n' > /etc/profile.d/vivado.sh

WORKDIR /workspace
CMD ["/bin/bash", "-l"]
