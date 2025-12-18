FROM ubuntu:20.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    libssl-dev \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

# Build for Ultra96 (aarch64) without libgpiod
RUN mkdir -p build && cd build && \
    cmake .. \
        -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
        -DUSE_LIBGPIOD=OFF \
        -DBUILD_FOR_ULTRA96=ON && \
    make

# Create output directory for artifacts
RUN mkdir -p /output && cp build/libtrustm.* /output/

