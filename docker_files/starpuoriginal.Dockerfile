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


WORKDIR /home/starpu

# CMD ["starpu_machine_display -w CUDA -n"]