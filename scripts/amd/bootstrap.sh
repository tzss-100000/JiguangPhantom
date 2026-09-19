#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPRO_ROOT="${AMD_REPRO_ROOT:-${PROJECT_ROOT}/third_party/Robotwin-radeon-cloud}"
IMAGE="${AMD_IMAGE:-robotwin-lingbot-vla-v2:rocm7.2.1_ubuntu24.04_py3.12_pytorch_release_2.9.1}"

if ! command -v docker >/dev/null 2>&1; then
    echo "[ERROR] Docker is required by the validated AMD reproduction workflow."
    exit 1
fi

if [ ! -e /dev/kfd ]; then
    echo "[ERROR] /dev/kfd is missing; this does not look like an AMD ROCm GPU instance."
    exit 1
fi

if [ ! -d "${REPRO_ROOT}/.git" ]; then
    git clone https://github.com/ZiguanWang/Robotwin-radeon-cloud.git "${REPRO_ROOT}"
else
    git -C "${REPRO_ROOT}" pull --ff-only
fi

if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
    echo "[INFO] Building validated AMD full image. This downloads models, assets and clean data."
    cd "${REPRO_ROOT}"
    IMAGE_NAME="${IMAGE}" bash docker/full/build.sh
fi

mkdir -p /workspace/robotwin-runtime
echo "[SUCCESS] AMD image ready: ${IMAGE}"
