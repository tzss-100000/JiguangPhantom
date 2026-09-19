#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STORAGE_ROOT="${STORAGE_ROOT:-${PROJECT_ROOT}/runtime}"
MODEL_ROOT="${MODEL_ROOT:-${STORAGE_ROOT}/models}"
DATA_ROOT="${DATA_ROOT:-${STORAGE_ROOT}/datasets}"
CACHE_ROOT="${CACHE_ROOT:-${STORAGE_ROOT}/cache}"
OUTPUT_ROOT="${OUTPUT_ROOT:-${STORAGE_ROOT}/outputs}"
MINICONDA_ROOT="${MINICONDA_ROOT:-${STORAGE_ROOT}/miniconda3}"

mkdir -p "${STORAGE_ROOT}" "${MODEL_ROOT}" "${DATA_ROOT}" "${CACHE_ROOT}" "${OUTPUT_ROOT}"

if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "[ERROR] Run this script on an allocated NVIDIA GPU node."
    exit 1
fi

if [ ! -x "${MINICONDA_ROOT}/bin/conda" ]; then
    echo "[INFO] Installing private Miniconda under ${MINICONDA_ROOT}"
    installer="${STORAGE_ROOT}/Miniconda3-latest-Linux-x86_64.sh"
    if command -v curl >/dev/null 2>&1; then
        curl -L https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o "${installer}"
    else
        wget -O "${installer}" https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    fi
    bash "${installer}" -b -p "${MINICONDA_ROOT}"
    rm -f "${installer}"
fi

export PATH="${MINICONDA_ROOT}/bin:${PATH}"
eval "$(conda shell.bash hook)"

git -C "${PROJECT_ROOT}" submodule update --init --recursive

ENV_NAME=lingbotvla bash "${PROJECT_ROOT}/scripts/setup/setup_env_nvidia.sh"

conda activate lingbotvla
export HF_HOME="${CACHE_ROOT}/huggingface"
export XDG_CACHE_HOME="${CACHE_ROOT}"

MODEL_ROOT="${MODEL_ROOT}" bash "${PROJECT_ROOT}/scripts/setup/download_models.sh"
DATA_ROOT="${DATA_ROOT}" PLATFORM=nvidia bash "${PROJECT_ROOT}/scripts/setup/download_robotwin.sh"

if [ "${PREPARE_DATA:-1}" = "1" ]; then
    STORAGE_ROOT="${STORAGE_ROOT}" DATA_ROOT="${DATA_ROOT}" CACHE_ROOT="${CACHE_ROOT}" \
      bash "${PROJECT_ROOT}/scripts/nvidia/prepare_clean_data.sh"
fi

if [ "${SETUP_EVAL_ENV:-1}" = "1" ]; then
    STORAGE_ROOT="${STORAGE_ROOT}" CACHE_ROOT="${CACHE_ROOT}" \
      bash "${PROJECT_ROOT}/scripts/nvidia/setup_eval_env.sh"
fi

echo "[SUCCESS] NVIDIA bootstrap finished."
echo "STORAGE_ROOT=${STORAGE_ROOT}"
