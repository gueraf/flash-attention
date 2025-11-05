#!/bin/bash

set -e

# Default values
PYTHON_VERSION=${1:-"3.12"}
CUDA_VERSION=${2:-"12.9.0"}
TORCH_VERSION=${3:-"2.9.0"}
BUILD_WITH_NINJA=${4:-"TRUE"}

export UV_VENV_CLEAR=1
# Create a virtual environment
uv venv
# Activate the virtual environment
source .venv/bin/activate

# Install dependencies
CUDA_VERSION_URL_SUFFIX=$(echo $CUDA_VERSION | awk -F. '{print $1$2}')
uv pip install ninja packaging wheel setuptools torch==${TORCH_VERSION} --extra-index-url https://download.pytorch.org/whl/cu${CUDA_VERSION_URL_SUFFIX}

# Set build environment variables
export FLASH_ATTENTION_FORCE_BUILD="TRUE"
if [ "$BUILD_WITH_NINJA" = "TRUE" ]; then
    export CXX11_ABI=1
else
    export CXX11_ABI=0
fi
# Limit MAX_JOBS to avoid OOM errors
export MAX_JOBS=2
export NVCC_THREADS=2

# Build the wheel
python setup.py bdist_wheel --dist-dir=dist

# Rename the wheel
MATRIX_TORCH_VERSION=$(echo $TORCH_VERSION | awk -F . {'print $1 "." $2'})
WHEEL_CUDA_VERSION=$(echo $CUDA_VERSION | awk -F . {'print $1'})
tmpname=cu${WHEEL_CUDA_VERSION}torch${MATRIX_TORCH_VERSION}cxx11abi${CXX11_ABI}
wheel_name=$(ls dist/*whl | xargs -n 1 basename | sed "s/-/+$tmpname-/2")
ls dist/*whl |xargs -I {} mv {} dist/${wheel_name}

echo "Successfully built wheel: dist/${wheel_name}"
