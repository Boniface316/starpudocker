# Removing warnings

The objective of this modification is eliminate the warnings present in the StarPU CUDA-Q Docker image when running seemingly anything that involves StarPU.

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

RUN ../configure --enable-starpupy --enable-quick-check --prefix=/root/usr/starpu --without-hwloc && \
    make && \
    make install

RUN mv /home/cudaq /root/cudaq && \
    echo ". /root/usr/starpu/bin/starpu_env" >> /root/.bashrc

ENV PATH="/root/usr/starpu/bin:$PATH"
ENV STARPU_SCHED=dmda


WORKDIR /workspace
```

## Approach:
1. Use the provided Dockerfile
2. Build the image
3. `docker run --gpus all -it -v "$(pwd)":/workspace starpu-cudaq`

## Results:
1. `nvidia-smi` - ✅
2. `python3 -c "import starpu; import cudaq` - ✅
3. Run StarPUPY example - ✅
4. CUDA-Q gpu - ✅
5. `starpu_machine_display -w CUDA -notopology` - ✅
6. `python3 validation_script.py` ✅

## Note
In order to get rid of the warning `[starpu][_starpu_init_cuda_config] Warning: could not find location of CUDA0, do you have the hwloc CUDA plugin installed?`, I used the `--without-hwloc` option when configuring StarPU.\
This is a bad solution, since according to StarPU documentation, `hwloc` will make it run faster.\
It seems that the issue is that `hwloc` cannot detect the GPU. Running `lstopo -.txt` in the Docker container does not show the GPU, but running it outside of the container does show the GPU. I tried installing hwloc with the `--enable-cuda` configuration option in this container, and still got the warning. I tried doing the same in a separate container and still could not see the GPU when running `lstopo -.txt`. StarPU is able to detect the GPU, so the issue is solely with hwloc.

## Next steps:
Figure out why hwloc is not able to detect the GPU.
