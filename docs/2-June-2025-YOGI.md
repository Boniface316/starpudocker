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