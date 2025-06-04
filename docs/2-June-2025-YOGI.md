# Replicating starpu 

The objective of this approach is to replicate `registry.gitlab.inria.fr/starpu/starpu-docker/starpu:1.4.7
`

## Dockerfile

```Docker
FROM registry.gitlab.inria.fr/starpu/starpu-docker/ci
ARG version=master

# Installing as root: docker images are usually set up as root.
# Since some autotools scripts might complain about this being unsafe, we set
# FORCE_UNSAFE_CONFIGURE=1 to avoid configure errors.
ENV FORCE_UNSAFE_CONFIGURE=1

RUN git clone --depth 1 https://gitlab.inria.fr/starpu/starpu.git starpu.git -b $version
WORKDIR /home/starpu/starpu.git
RUN ./autogen.sh && mkdir build
WORKDIR /home/starpu/starpu.git/build
RUN ../configure --enable-maxcpus=20 --prefix=/usr/local --enable-quick-check --disable-mpi-check
RUN make && STARPU_MICROBENCHS_DISABLED=1 make check
RUN sudo make install && sudo ldconfig

RUN mkdir /home/starpu/starpu.git/build_simgrid
WORKDIR /home/starpu/starpu.git/build_simgrid
RUN ../configure --enable-maxcpus=20 --prefix=/usr/local/starpu-simgrid --enable-quick-check --disable-mpi-check --enable-simgrid
RUN make && STARPU_MICROBENCHS_DISABLED=1 make check
RUN sudo make install

COPY tutorial /home/starpu/tutorial
RUN sudo chown -R starpu:starpu /home/starpu/tutorial

WORKDIR /home/starpu


```

## Approach:
1. Use the file from `https://gitlab.inria.fr/starpu/starpu-docker/-/blob/main/Dockerfile-starpu`
2. Build the image
3. `docker run --gpus all -it -v "$(pwd)":/workspace starpuoriginal`

## Results:
1. `nvidia-smi` - ✅
2. CUDA-Q gpu - ❌
    
    * CUDA-Q was not installed
3. StarPU reading GPU - ❌

```
### Error output

```shell
starpu@210afb96d925:~$ starpu_machine_display -w CUDA -n
[starpu][210afb96d925][check_bus_config_file] No performance model for the bus, calibrating...
[starpu][210afb96d925][benchmark_all_memory_nodes] CUDA 0...
[starpu][210afb96d925][measure_bandwidth_between_host_and_dev] with NUMA 0...
[starpu][210afb96d925][benchmark_all_memory_nodes] OpenCL 0...
[starpu][210afb96d925][measure_bandwidth_between_host_and_dev] with NUMA 0...
*** stack smashing detected ***: terminated
Aborted (core dumped)
```
4. Run StarPUPY example - ❌

    * Python version was not installed

## Next approach:
Take an Ubuntu image and install StarPU and run the script. Then install CUDA-Q.

# Mashing Ewan's code with StarPU image that works

`registry.gitlab.inria.fr/starpu/starpu-docker/starpu:1.4.7` is known to work for `starpu_machine_display -w CUDA -n`. The approach is to see what happens if we install the python version on top of it.

## Dockerfile

```Docker
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

```

## Approach
1. Use registry.gitlab.inria.fr/starpu/starpu-docker/starpu:1.4.7
2. Include code from Ewan's push on Python addition
3. Build the image
4. Run the image with GPUs enabled
5. run `starpu_machine_display -w CUDA -n`
6. Goto root and run `. ./usr/starpu/bin/starpu_env`
7. run `python3 -c "import starpu"

## Results

1. `nvidia-smi` - ✅
2. CUDA-Q gpu - ❌
    
    * CUDA-Q was not installed
3. StarPU reading GPU - ✅
4. Run StarPUPY example - ✅

### Observation
If the `. ./usr/starpu/bin/starpu_env` was run before `starpu_machine_display -w CUDA -n`, then we will recieve `Aborted (core dumped)` message. If its done the opposite way, then no issues. 

## Next
See if this can be replicated on CUDA-Q container