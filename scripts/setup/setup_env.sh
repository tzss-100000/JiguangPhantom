#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

THIRD_PARTY_ROOT="${THIRD_PARTY_ROOT:-${PROJECT_ROOT}/third_party}"
LINGBOT_ROOT="${LINGBOT_ROOT:-${THIRD_PARTY_ROOT}/lingbot-vla-v2}"

ENV_NAME="${ENV_NAME:-lingbotvla}"

echo "========================================"
echo "JiguangPhantom - LingBot Environment"
echo "========================================"
echo "PROJECT_ROOT  : ${PROJECT_ROOT}"
echo "LINGBOT_ROOT  : ${LINGBOT_ROOT}"
echo "ENV_NAME      : ${ENV_NAME}"
echo "========================================"

if ! command -v conda >/dev/null 2>&1; then
    echo "[ERROR] conda is not available."
    echo "Please install/load Miniconda or Anaconda first."
    exit 1
fi

if [ ! -d "${LINGBOT_ROOT}" ]; then
    echo "[ERROR] LingBot-VLA repository not found:"
    echo "${LINGBOT_ROOT}"
    echo
    echo "Run:"
    echo "git submodule update --init --recursive"
    exit 1
fi

if [ ! -f "${LINGBOT_ROOT}/tools/create_train_env.sh" ]; then
    echo "[ERROR] Official LingBot environment script not found."
    exit 1
fi

echo "[INFO] Using official LingBot-VLA 2.0 environment installer."

cd "${LINGBOT_ROOT}"

if conda env list | awk '{print $1}' | grep -Fxq "${ENV_NAME}"; then
    echo "[INFO] Conda environment '${ENV_NAME}' already exists."
    echo "[INFO] Resuming installation..."
    bash tools/create_train_env.sh \
        --env-name "${ENV_NAME}" \
        --resume
else
    echo "[INFO] Creating environment '${ENV_NAME}'..."
    bash tools/create_train_env.sh \
        --env-name "${ENV_NAME}"
fi

echo
echo "[INFO] Verifying environment..."

eval "$(conda shell.bash hook)"
conda activate "${ENV_NAME}"

python - <<'PY'
import torch

print("Python/PyTorch environment ready")
print("PyTorch:", torch.__version__)
print("CUDA runtime:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())
print("GPU count:", torch.cuda.device_count())

if torch.cuda.is_available():
    for i in range(torch.cuda.device_count()):
        print(f"GPU {i}: {torch.cuda.get_device_name(i)}")
PY

echo
echo "[SUCCESS] LingBot-VLA training environment is ready."
