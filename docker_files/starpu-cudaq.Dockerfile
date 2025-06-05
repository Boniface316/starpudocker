FROM nvcr.io/nvidia/quantum/cuda-quantum:cu12-0.10.0

USER root
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
RUN git clone https://gitlab.inria.fr/starpu/starpu.git
WORKDIR /root/starpu
RUN git fetch --all --tags --prune
RUN git checkout tags/starpu-1.4.7

RUN ./autogen.sh && mkdir build
WORKDIR /root/starpu/build

RUN pip3 install joblib==1.2.0 && \
    pip3 install cloudpickle==2.2.0 && \
    pip3 install numpy==1.25.0 && \
    pip3 install invoke==1.7.0

RUN ../configure --enable-starpupy --enable-blocking-drivers --prefix=/root/usr/starpu && \
    make && \
    make install

RUN mv /home/cudaq /root/cudaq && \
    echo ". /root/usr/starpu/bin/starpu_env" >> /root/.bashrc

ENV PATH="/root/usr/starpu/bin:$PATH"
WORKDIR /workspace
