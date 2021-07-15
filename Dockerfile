
# defaul TAG is dev
ARG TAG=dev
# Default release is 18.04
ARG BASE_IMAGE_RELEASE=21.04
# Default base image 
ARG BASE_IMAGE=abcdesktopio/oc.user.21.04
# Default CUDA version
ARG CUDA_VERSION=11.2.0
# nvidia repo path
ARG BASE_NVIDIA_IMAGE=ubuntu1804
# arch
ARG ARCH=x86_64
FROM $BASE_IMAGE:$TAG

# pass ARG to ENV
ENV CUDA_VERSION=$CUDA_VERSION

# change user to root
USER 0

# from https://gitlab.com/nvidia/container-images/cuda/blob/master/dist/11.3.0/ubuntu18.04-x86_64/base/Dockerfile
# FROM ubuntu:18.04
# LABEL maintainer "NVIDIA CORPORATION <cudatools@nvidia.com>"

RUN echo "https://developer.download.nvidia.com/compute/cuda/repos/$BASE_NVIDIA_IMAGE/ $ARCH"

RUN apt-get update && apt-get install -y zlib1g-dev \
    libjpeg-dev \
    libpixman-1-dev \
    gettext

RUN apt-get install -y --no-install-recommends \
    gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos//ubuntu2004/x86_64/7fa2af80.pub | apt-key add - && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos//ubuntu2004/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos//ubuntu2004/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    rm -rf /var/lib/apt/lists/*

ENV CUDA_VERSION 11.2.0

# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-cudart-11-2 \
    cuda-compat-11-2 \
    && ln -s cuda-11.2 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

# Required for nvidia-docker v1
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf \
    && echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# FROM https://gitlab.com/nvidia/container-images/cuda/blob/master/dist/11.3.0/ubuntu18.04-x86_64/runtime/Dockerfile
ENV NCCL_VERSION 2.9.6

RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-libraries-11-2 \
    libnpp-11-2 \
    cuda-nvtx-11-2 \
    libcublas-11-2  \
    libcusparse-11-2 \
    libnccl2 \
    && rm -rf /var/lib/apt/lists/*

# apt from auto upgrading the cublas package. See https://gitlab.com/nvidia/container-images/cuda/-/issues/88
RUN apt-mark hold libcublas-11-2 libnccl2


# FROM https://gitlab.com/nvidia/container-images/opengl/blob/ubuntu18.04/glvnd/runtime/Dockerfile 
RUN apt-get update && apt-get install -y --no-install-recommends \
        libglvnd0  \
        libgl1  \
        libglx0  \
        libegl1  \
        libgles2  && \
    rm -rf /var/lib/apt/lists/*

COPY 10_nvidia.json /usr/share/glvnd/egl_vendor.d/10_nvidia.json

RUN apt-get update &&  apt-get install -y 	\
	mesa-utils && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update &&  apt-get install -y       \
        cuda-samples-11-2 && \
    rm -rf /var/lib/apt/lists/*

#Install Tigervnc
RUN sed -i '/deb-src/s/^# //' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y devscripts build-essential lintian

RUN mkdir /tigervnc && \
    cd /tigervnc && \
    apt-get source tigervnc && \
    cd tigervnc-1.11.0+dfsg && \
    apt-get build-dep -y tigervnc && \
    debuild -us -uc

RUN cd /tigervnc && \
    apt-get install -y \
    ./tigervnc-standalone-server_1.11.0+dfsg-2_amd64.deb

RUN cp /usr/bin/Xtigervnc /usr/bin/Xvnc 

# to compile sample source code
# RUN cd /usr/local/cuda-11.2/samples && make -j $(getconf _NPROCESSORS_ONLN)

# restore balloon context user
USER 4096

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES all
ENV NVIDIA_REQUIRE_CUDA "cuda>=11.2 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=440,driver<441 driver>=450"
