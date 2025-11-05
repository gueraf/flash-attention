#!/bin/bash

set -e

# Default values
PYTHON_VERSION=${1:-"3.12"}
CUDA_VERSION=${2:-"12.9.0"}
TORCH_VERSION=${3:-"2.9.0"}
BUILD_WITH_NINJA=${4:-"TRUE"}
MAX_JOBS=${5:-8}
NVCC_THREADS=${6:-8}

DOCKER_IMAGE="nvidia/cuda:${CUDA_VERSION}-devel-ubuntu22.04"

echo "Using Docker image: ${DOCKER_IMAGE}"

# Check if docker is installed
if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: docker is not installed.' >&2
  exit 1
fi

# Pull the docker image
docker pull ${DOCKER_IMAGE}

# Run the build script inside the container
docker run --gpus all --rm -v "$(pwd)":/workspace -w /workspace ${DOCKER_IMAGE} \
    ./docker_build_helper.sh \
    "${PYTHON_VERSION}" "${CUDA_VERSION}" "${TORCH_VERSION}" \
    "${BUILD_WITH_NINJA}" "${MAX_JOBS}" "${NVCC_THREADS}"
