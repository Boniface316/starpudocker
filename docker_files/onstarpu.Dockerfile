FROM registry.gitlab.inria.fr/starpu/starpu-docker/starpu:1.4.7

ENV FORCE_UNSAFE_CONFIGURE=1
ENV DEBIAN_FRONTEND noninteractive

USER root

WORKDIR /root
RUN git clone https://gitlab.inria.fr/starpu/starpu.git

WORKDIR /root/starpu

RUN ./autogen.sh && mkdir build
WORKDIR /root/starpu/build

RUN apt-get update && apt-get install -y --fix-missing \
    python3 \
    python3-pip 

RUN pip3 install joblib && \
    pip3 install cloudpickle && \
    pip3 install numpy && \
    pip3 install invoke

RUN ../configure --enable-starpupy --enable-blocking-drivers --prefix=/root/usr/starpu&& \
    make && \
    make install

RUN starpu_machine_display -w CUDA -n

WORKDIR /root/workspace

