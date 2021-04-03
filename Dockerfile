# Usage:
# 
# This uses ROCm-HIP toolkits to port CUDA code to HIP-capable code,
# and build it with HIP-CPU runtime to run on completely CPU platform.

# docker run --rm -it \
# 	--name cuda2hipcpu \
# 	ueqri/cuda2hipcpu:latest
#

# Note:
# 
# If you want to run the official test of HIP-CPU, 
# just execute `cd /hip-cpu/build && make test`.

FROM nvidia/cuda:10.1-devel-ubuntu18.04
LABEL maintainer "Hang Yan <iyanhang@gmail.com>"

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# change to your local Ubuntu mirror
ARG UBUNTU_MIRROR=archive.ubuntu.com
RUN sed -i "s/archive.ubuntu.com/${UBUNTU_MIRROR}/g" /etc/apt/sources.list

RUN apt-get update -y ; exit 0
RUN \
  apt-get install -y apt-utils 2> >( grep -v 'debconf: delaying package configuration, since apt-utils is not installed' >&2 ) && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    clang-10 \
    llvm-10-dev \
    libclang-10-dev \
    zlib1g-dev \
    libssl-dev \
    wget

# update gcc to gcc-9, which is newer than the default in Ubuntu 18.04 LTS
RUN \
  apt-get dist-upgrade -y \
  && apt-get install build-essential software-properties-common -y \
  && add-apt-repository ppa:ubuntu-toolchain-r/test -y \
  && apt-get update -y \
  && apt-get install --no-install-recommends gcc-9 g++-9 -y \
  && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-9 \
  && update-alternatives --config gcc

RUN rm -rf /var/lib/apt/lists/*

# install cmake 3.16.3 which is not in bionic apt repository
ARG CMakeVersion=3.16
ARG CMakeBuild=3
RUN \
  mkdir /cmake && cd /cmake \
  && wget -qO- "https://cmake.org/files/v${CMakeVersion}/cmake-${CMakeVersion}.${CMakeBuild}-Linux-x86_64.tar.gz" | \
      tar --strip-components=1 -xz -C /usr/local \
  && cd / && rm -rf /cmake

# clone and build HIPIFY which converts CUDA to portable C++ code
ENV HIPIFY_VERSION rocm-4.1.0
ARG HIPIFY_GIT_REPO=https://github.com/ROCm-Developer-Tools/HIPIFY.git
RUN set -x \
  && git clone --depth 1 --branch "${HIPIFY_VERSION}" ${HIPIFY_GIT_REPO} /hipify \
  && cd /hipify \
  && mkdir build dist \
  && cd build \
  && cmake \
      -DCMAKE_INSTALL_PREFIX=../dist \
      -DCMAKE_BUILD_TYPE=Release \
      .. \
  && make -j$(nproc) install \
  && make clean \
  && ln -s  /hipify/dist/hipify-clang /usr/bin/hipify-clang

# install libtbb from Official Release in the GitHub, 
# due to the libtbb-dev in bionic apt repository is too old to build HIP-CPU runtime
ARG TBBVersion=2020.3
RUN \
  mkdir /tbb && cd /tbb \
  && wget \
    https://github.com/oneapi-src/oneTBB/releases/download/v${TBBVersion}/tbb-${TBBVersion}-lin.tgz \
  && TARBALL="$(find . -name "*tgz")" \
  && tar zxvf $TARBALL -C / \
  && rm -f $TARBALL
ENV CPATH /tbb/include
ENV LIBRARY_PATH /tbb/lib/intel64/gcc4.8
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:/tbb/lib/intel64/gcc4.8

# build HIP-CPU runtime
RUN \
  git clone --depth 1 https://github.com/ROCm-Developer-Tools/HIP-CPU.git /hip-cpu \
  && cd /hip-cpu \
  && mkdir build && cd build \
  && cmake .. \
  && cmake --build . --target install

# test HIPIFY & HIP-CPU using CUDA vector adding sample
RUN mkdir /root/test
ARG CudaSample=vectorAdd.cu
ADD https://raw.githubusercontent.com/ueqri/cuda2hipcpu/main/sample/${CudaSample} /root/test/${CudaSample}
ADD https://raw.githubusercontent.com/ueqri/cuda2hipcpu/main/sample/CMakeLists.txt /root/test/CMakeLists.txt
RUN \
  cd /root/test \
  && hipify-clang ${CudaSample} \
                  --cuda-path=/usr/local/cuda \
                  -I /usr/local/cuda/samples/common/inc \
                  -o sample.cpp \
  && mkdir build && cd build \
  && cmake .. \
  && cmake --build . \
  && ./test-HIP-CPU

