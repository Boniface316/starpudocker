FROM ubuntu:22.04
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    git \
    autoconf \
    automake \
    pkg-config \
    libtool libtool-bin \
    libhwloc-dev \
    libnuma-dev \
    python3 \
    python3-pip \
    nvidia-cuda-toolkit \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root
RUN git clone https://github.com/open-mpi/hwloc.git
WORKDIR /root/hwloc
RUN git fetch --all --tags --prune
RUN git checkout tags/hwloc-2.12.1
RUN ./autogen.sh
RUN ./configure --enable-cuda
RUN make
RUN make install