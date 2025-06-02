import starpu
import asyncio
from invoke import run
import cudaq


def func():
    return 12


async def main():
    # submit function "hello"
    fut = starpu.task_submit()(func)
    res = await fut

    assert res == 12, "The result should be 12"


def validate_nvidia_smi():
    try:
        res = run("nvidia-smi --query-gpu=gpu_name --format=csv,noheader", hide=True)
        GPU_NAME = res.stdout.strip()
        assert GPU_NAME, "No GPU detected by nvidia-smi"
    except Exception as e:
        print(f"Error executing nvidia-smi: {e}")
        raise


def cudaq_reading_GPUS():
    assert cudaq.num_available_gpus() > 0, "CUDAQ failed to detect any GPUs"


def starpu_reading_GPUS():
    try:
        res = run("starpu_machine_display -w CUDA -n", hide=True)
        number_of_GPUS = res.stdout.strip().split("\n")[1][0]
        assert int(number_of_GPUS) > 0, "No GPUs detected by StarPU"
    except Exception as e:
        print(f"Error executing starpu_machine_display: {e}")
        raise


if __name__ == "__main__":
    validate_nvidia_smi()
    cudaq_reading_GPUS()
    starpu_reading_GPUS()
    print("Validation script executed successfully.")
    starpu.init()
    asyncio.run(main())
    starpu.shutdown()
