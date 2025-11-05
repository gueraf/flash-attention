#!/bin/bash
set -e

PYTHON_VERSION=${1}
CUDA_VERSION=${2}
TORCH_VERSION=${3}
BUILD_WITH_NINJA=${4}
MAX_JOBS=${5}
NVCC_THREADS=${6}

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y software-properties-common
add-apt-repository ppa:deadsnakes/ppa
apt-get update
apt-get install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-dev python${PYTHON_VERSION}-venv curl git

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh
source /root/.local/bin/env

# Now run the build process from the original script
export UV_VENV_CLEAR=1
# Create a virtual environment
uv venv --python python${PYTHON_VERSION}
# Activate the virtual environment
source .venv/bin/activate

# Install dependencies
CUDA_VERSION_URL_SUFFIX=$(echo ${CUDA_VERSION} | awk -F. '{print $1$2}')
uv pip install pip ninja packaging wheel setuptools torch==${TORCH_VERSION} --extra-index-url https://download.pytorch.org/whl/cu${CUDA_VERSION_URL_SUFFIX}

# Set build environment variables
export FLASH_ATTENTION_FORCE_BUILD="TRUE"
if [ "${BUILD_WITH_NINJA}" = "TRUE" ]; then
    export CXX11_ABI=1
else
    export CXX11_ABI=0
fi
# Limit MAX_JOBS to avoid OOM errors
export MAX_JOBS=${MAX_JOBS}
export NVCC_THREADS=${NVCC_THREADS}

# Add workspace to git safe directories
git config --global --add safe.directory /workspace
git config --global --add safe.directory /workspace/csrc/composable_kernel
git config --global --add safe.directory /workspace/csrc/cutlass

# Build the wheel
python setup.py bdist_wheel --dist-dir=dist

# Rename the wheel
MATRIX_TORCH_VERSION=$(echo ${TORCH_VERSION} | awk -F . {'print $1 "." $2'})
WHEEL_CUDA_VERSION=$(echo ${CUDA_VERSION} | awk -F . {'print $1'})
tmpname=cu${WHEEL_CUDA_VERSION}torch${MATRIX_TORCH_VERSION}cxx11abi${CXX11_ABI}
wheel_name=$(ls dist/*whl | xargs -n 1 basename | sed "s/-/+$tmpname-/2")
ls dist/*whl |xargs -I {} mv {} dist/${wheel_name}

echo "Successfully built wheel: dist/${wheel_name}"
