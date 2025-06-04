# starpudocker

The goal of this repo is to create docker file that can run StarPU and CUDA-Q. Image registry.gitlab.inria.fr/starpu/starpu-docker/starpu:1.4.7 will be merged with nvcr.io/nvidia/quantum/cuda-quantum:cu12-0.11.0

StarPU docker repo: https://gitlab.inria.fr/starpu/starpu-docker

## Success criteria

This container is considered a success, after achieve all these objectives:

1. `nvidia-smi` works
2. run `python3 -c "import starpu; import cudaq"`
3. run https://github.com/starpu-runtime/starpu/blob/master/starpupy/examples/starpu_py.py
4. run `python3 -c "import cudaq; print(cudaq.num_available_gpus())`
5. run `starpu_machine_display -w CUDA -notopology` and returns the name of the GPU

## History
Every approaches that were made will be tracked through docs folder.

