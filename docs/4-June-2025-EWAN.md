# Dockerfile from scratch

The objective of this modification is to address the issues with StarPU reading the GPU present in my previous file by switching the StarPU version to 1.4.7 rather than using the master.

## Dockerfile

```Docker
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
RUN git clone https://gitlab.inria.fr/starpu/starpu.git
WORKDIR /root/starpu
RUN git fetch --all --tags --prune
RUN git checkout tags/starpu-1.4.7

RUN ./autogen.sh && mkdir build
WORKDIR /root/starpu/build

RUN pip3 install joblib && \
    pip3 install cloudpickle && \
    pip3 install numpy && \
    pip3 install invoke

RUN ../configure --enable-starpupy --enable-blocking-drivers --prefix=/root/usr/starpu&& \
    make && \
    make install

WORKDIR /workspace
CMD . /root/usr/starpu/bin/starpu_env && exec bash && cd /workspace
```

## Approach:
1. Use the provided Dockerfile
2. Build the image
3. `docker run --gpus all -it -v "$(pwd)":/workspace starpuoriginal`

## Results:
1. `nvidia-smi` - ✅
2. `python3 -c "import starpu; import cudaq` - ❌
    * CUDA-Q not installed, importing starpu works
3. Run StarPUPY example - ✅
4. CUDA-Q gpu - ❌
    * CUDA-Q was not installed
5. `starpu_machine_display -w CUDA -notopology` - ✅

## Note
Running anything with starpu produces the following warnings:
```
[starpu][_starpu_init_cuda_config] Warning: could not find location of CUDA0, do you have the hwloc CUDA plugin installed?
[starpu][initialize_lws_policy] Warning: you are running the default lws scheduler, which is not a very smart scheduler, while the system has GPUs or several memory nodes. Make sure to read the StarPU documentation about adding performance models in order to be able to use the dmda or dmdas scheduler instead.
[starpu][_starpu_cuda_driver_init] Warning: reducing STARPU_CUDA_PIPELINE to 0 because blocking drivers are enabled (and simgrid is not enabled)
```

## Next steps:
Fix the warnings, then add CUDA-Q to this docker image.

# CUDA-Q and StarPU Dockerfile

The objective of this modification is to add CUDA-Q to the docker image.

## Dockerfile

```Docker
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
        nvidia-cuda-toolkit

WORKDIR /root

ENV STARPU_VERSION=1.4.7
WORKDIR /root
RUN git clone https://gitlab.inria.fr/starpu/starpu.git
WORKDIR /root/starpu
RUN git fetch --all --tags --prune
RUN git checkout tags/starpu-${STARPU_VERSION}

RUN ./autogen.sh && mkdir build
WORKDIR /root/starpu/build

RUN pip3 install joblib && \
    pip3 install cloudpickle && \
    pip3 install numpy && \
    pip3 install invoke

RUN ../configure --enable-starpupy --enable-blocking-drivers --prefix=/root/usr/starpu&& \
    make && \
    make install

RUN mv  /home/cudaq /root/cudaq

WORKDIR /workspace
```

## Approach:
1. Use the provided Dockerfile
2. Build the image
3. `docker run --gpus all -it -v "$(pwd)":/workspace starpu-cudaq`
4. In the container, `. /root/usr/starpu/bin/starpu_env`

## Results:
1. `nvidia-smi` - ✅
2. `python3 -c "import starpu; import cudaq` - ✅
3. Run StarPUPY example - ✅
4. CUDA-Q gpu - ✅
5. `starpu_machine_display -w CUDA -notopology` - ✅
6. `python3 validation_script.py` ✅

## Note
I was unable to run the `. /root/usr/starpu/bin/starpu_env` command as a CMD from within the dockerfile.
`CMD . /root/usr/starpu/bin/starpu_env` produces the following error: `/bin/bash: /bin/bash: cannot execute binary file`
`CMD ["/root/usr/starpu/bin/starpu_env"]` starts the StarPU environment within the container, but I was unable to find a way to keep the container open.
I am unsure what causes the difference in these approaches.

Additionally, running anything with StarPU still produces the following warnings:
```
[starpu][_starpu_init_cuda_config] Warning: could not find location of CUDA0, do you have the hwloc CUDA plugin installed?
[starpu][initialize_lws_policy] Warning: you are running the default lws scheduler, which is not a very smart scheduler, while the system has GPUs or several memory nodes. Make sure to read the StarPU documentation about adding performance models in order to be able to use the dmda or dmdas scheduler instead.
[starpu][_starpu_cuda_driver_init] Warning: reducing STARPU_CUDA_PIPELINE to 0 because blocking drivers are enabled (and simgrid is not enabled)
```

## Next steps:
Fix the warnings and try to find a way to start the StarPU environment from the dockerfile.