# build install starpu
FROM ubuntu:22.04 AS starpu

# install dependencies
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
        && rm -rf /var/lib/apt/lists/*

WORKDIR /root
RUN git clone https://gitlab.inria.fr/starpu/starpu.git

# build and install starpu
WORKDIR /root/starpu

RUN ./autogen.sh && mkdir build
WORKDIR /root/starpu/build

RUN pip3 install joblib && \
    pip3 install cloudpickle && \
    pip3 install numpy

RUN ../configure --enable-starpupy --enable-blocking-drivers --prefix=/root/usr/starpu&& \
    make && \
    make install

WORKDIR /root/usr/starpu
CMD . ./bin/starpu_env && exec bash