FROM abcdesktopio/oc.user.18.04:dev

USER 0


# from https://gitlab.com/nvidia/container-images/cuda/blob/master/dist/11.3.0/ubuntu18.04-x86_64/base/Dockerfile
# FROM ubuntu:18.04
# LABEL maintainer "NVIDIA CORPORATION <cudatools@nvidia.com>"

RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl \
    && rm -rf /var/lib/apt/lists/*

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
	mesa-utils 

# RUN  apt-get update &&  apt-get install -y       \
#        cuda-samples-11-2
# RUN cd /usr/local/cuda-11.2/samples && make -j $(getconf _NPROCESSORS_ONLN)
	
USER 4096
# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES all
ENV NVIDIA_REQUIRE_CUDA "cuda>=11.2 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=440,driver<441 driver>=450"
