# ============================================================================
# TOARUOS-ARNOLD DOCKER BUILD ENVIRONMENT
# "COME WITH ME IF YOU WANT TO BUILD"
# ============================================================================
#
# This Dockerfile creates a complete cross-compilation environment for
# building the ToaruOS-Arnold kernel on any platform.
#
# Usage:
#   docker build -t toaruos-arnold-builder .
#   docker run -v ${PWD}:/kernel toaruos-arnold-builder make
#   docker run -v ${PWD}:/kernel toaruos-arnold-builder make iso
#
# "I need your compiler, your linker, and your QEMU" - The Dockerfile
# ============================================================================

FROM ubuntu:22.04

LABEL maintainer="ToaruOS-Arnold Team"
LABEL description="Cross-compilation environment for ArnoldC kernel development"
LABEL version="1.0"

# "EVERYBODY CHILL" - Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ============================================================================
# INSTALL BUILD DEPENDENCIES - "I NEED YOUR CLOTHES YOUR BOOTS AND YOUR MOTORCYCLE"
# ============================================================================

RUN apt-get update && apt-get install -y \
    # Essential build tools
    build-essential \
    gcc \
    g++ \
    make \
    # Cross-compilation tools
    gcc-multilib \
    g++-multilib \
    # NASM assembler - "SPEAK TO THE MACHINE"
    nasm \
    # Java runtime for ArnoldC-Native
    openjdk-17-jre-headless \
    # GRUB tools for ISO creation
    grub-pc-bin \
    grub-common \
    grub2-common \
    xorriso \
    mtools \
    # Additional utilities
    wget \
    curl \
    git \
    file \
    # QEMU for testing (optional but useful)
    qemu-system-x86 \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# BUILD i686-elf CROSS-COMPILER - "THE TERMINATOR TOOLCHAIN"
# ============================================================================
# This creates a proper freestanding cross-compiler for 32-bit x86

ENV PREFIX=/opt/cross
ENV TARGET=i686-elf
ENV PATH="$PREFIX/bin:$PATH"

# Download and build binutils
WORKDIR /tmp/build

RUN wget -q https://ftp.gnu.org/gnu/binutils/binutils-2.41.tar.xz \
    && tar xf binutils-2.41.tar.xz \
    && mkdir binutils-build \
    && cd binutils-build \
    && ../binutils-2.41/configure \
        --target=$TARGET \
        --prefix="$PREFIX" \
        --with-sysroot \
        --disable-nls \
        --disable-werror \
    && make -j$(nproc) \
    && make install \
    && cd /tmp \
    && rm -rf /tmp/build/*

# Download and build GCC
RUN wget -q https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz \
    && tar xf gcc-13.2.0.tar.xz \
    && cd gcc-13.2.0 \
    && contrib/download_prerequisites \
    && cd /tmp/build \
    && mkdir gcc-build \
    && cd gcc-build \
    && ../gcc-13.2.0/configure \
        --target=$TARGET \
        --prefix="$PREFIX" \
        --disable-nls \
        --enable-languages=c,c++ \
        --without-headers \
    && make -j$(nproc) all-gcc \
    && make -j$(nproc) all-target-libgcc \
    && make install-gcc \
    && make install-target-libgcc \
    && cd /tmp \
    && rm -rf /tmp/build/* \
    && rm -rf gcc-13.2.0 gcc-13.2.0.tar.xz binutils-2.41 binutils-2.41.tar.xz

# ============================================================================
# SETUP WORKING DIRECTORY - "GET TO THE CHOPPER"
# ============================================================================

WORKDIR /kernel

# Default command - "DO IT NOW"
CMD ["make"]

# ============================================================================
# "HASTA LA VISTA, BABY" - End of Dockerfile
# ============================================================================
