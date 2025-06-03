# Dockerfile from scratch

The objective of this approach is to create a dockerfile that runs starpu from scratch.
`

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

RUN ./autogen.sh && mkdir build
WORKDIR /root/starpu/build

RUN pip3 install joblib && \
    pip3 install cloudpickle && \
    pip3 install numpy && \
    pip3 install invoke

RUN ../configure --enable-starpupy --enable-blocking-drivers --prefix=/root/usr/starpu&& \
    make && \
    make install

WORKDIR /root/usr/starpu
CMD . ./bin/starpu_env && exec bash
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
5. `starpu_machine_display -w CUDA -notopology` - ❌
### Output
```
[starpu][check_bus_config_file] No performance model for the bus, calibrating...
[starpu][benchmark_all_memory_nodes] CUDA 0...
[starpu][measure_bandwidth_between_host_and_dev] with NUMA 0...
[starpu][benchmark_all_memory_nodes] OpenCL 0...
[starpu][measure_bandwidth_between_host_and_dev] with NUMA 0...
*** stack smashing detected ***: terminated
Aborted (core dumped)
```

## Next steps:
Add CUDA-Q to this docker image.