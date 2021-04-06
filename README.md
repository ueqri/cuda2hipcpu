# CUDA To HIP-CPU

[![Build Status](https://dev.azure.com/ueqri-ci/cuda2hipcpu/_apis/build/status/cuda2hipcpu-CI?branchName=main)](https://dev.azure.com/ueqri-ci/cuda2hipcpu/_build/latest?definitionId=2&branchName=main)

`cuda2hipcpu` provides necessary environments to allow CPU to run CUDA code. You don't need a GPU plugged in.

It uses [ROCm-HIP toolkits](https://github.com/ROCm-Developer-Tools) to port CUDA code to HIP-capable code, then build it with HIP-CPU runtime to run on completely CPU platform.

The related tools are [HIPIFY](https://github.com/ROCm-Developer-Tools/HIPIFY), [Intel TBB](https://github.com/oneapi-src/oneTBB), [HIP-CPU runtime library](https://github.com/ROCm-Developer-Tools/HIP-CPU).

Now the Dockerfile is based on CUDA 10.1 image, the version >= 11.0 is not supported yet due to the [conflicts between clang and CUDA11+](https://bugs.llvm.org/show_bug.cgi?id=47332).

You can use the command blow to start a container with enough tools easily:

```bash
docker run --rm -it \
       --name cuda2hipcpu \
       ueqri/cuda2hipcpu:latest
```

or build from Dockerfile:

```bash
git clone https://github.com/ueqri/cuda2hipcpu.git
docker build -t cuda2hipcpu:latest .
docker run --rm -it \
       --name cuda2hipcpu \
       cuda2hipcpu:latest
```

## Usage

A CUDA vector addition sample is provided as `sample/vectorAdd.cu` and the generic CMakeLists.txt is in the same directory.

Note that, the CMakeLists.txt is **not** prepare for CUDA code, but **for HIP-CPU capable code** with file suffix `.cpp`.

So, just follow the steps below to run a CUDA project in CPU:

1. change to a CUDA source directory
2. run `convertAllCuda` to port all CUDA codes in the directory (non-recursive) to HIP-CPU capable code
3. copy the CMakeLists.txt to the directory, and optimize it to meet your demand
3. use that CMakeLists.txt to build code with HIP-CPU runtime library

```bash
cd /path/to/
convertAllCuda
mkdir build
cd build
# make sure CMakeLists.txt exists
cmake ..
cmake --build .
# run the target with a default name
./test-HIP
```

## Test
If you want to run the official test of HIP-CPU, just execute `cd /hip-cpu/build && make test` in the container, 

or you can run `docker run -it cuda2hipcpu:latest sh -c "cd /hip-cpu/build && make test"` in the host.

## Utilities

Here are some useful utilities of cuda2hipcpu:

### convertAllCuda

Usage:
1. `convertAllCuda` (non-recursive) only deals with the *.cu in current directory
2. `convertAllCuda -r` deals with all *.cu recursively. Use it carefully
3. `convertAllCuda SINGLE_FILE` deals with the certain CUDA code

Note:
A symbolic link of this script was created to /usr/bin/convertAllCuda during the docker build, so just use `convertAllCuda` for convenience.

### more...

TODO