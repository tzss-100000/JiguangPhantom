#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
THIRD_PARTY_ROOT="${THIRD_PARTY_ROOT:-${PROJECT_ROOT}/third_party}"
LINGBOT_ROOT="${LINGBOT_ROOT:-${THIRD_PARTY_ROOT}/lingbot-vla-v2}"
ENV_NAME="${ENV_NAME:-lingbotvla}"

if ! command -v conda >/dev/null 2>&1; then
    echo "[ERROR] conda is not available."
    echo "Load or install Miniconda/Anaconda before running this script."
    exit 1
fi

if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "[ERROR] NVIDIA GPU environment was not detected."
    exit 1
fi

if [ ! -f "${LINGBOT_ROOT}/tools/create_train_env.sh" ]; then
    echo "[ERROR] LingBot-VLA submodule is missing."
    echo "Run: git submodule update --init --recursive"
    exit 1
fi

echo "[INFO] NVIDIA platform detected."
nvidia-smi || true

cd "${LINGBOT_ROOT}"

if conda env list | awk '{print $1}' | grep -Fxq "${ENV_NAME}"; then
    bash tools/create_train_env.sh --env-name "${ENV_NAME}" --resume
else
    bash tools/create_train_env.sh --env-name "${ENV_NAME}"
fi

eval "$(conda shell.bash hook)"
conda activate "${ENV_NAME}"

python - <<'PY'
import torch
print("torch:", torch.__version__)
print("cuda:", torch.version.cuda)
print("cuda available:", torch.cuda.is_available())
print("gpu count:", torch.cuda.device_count())
assert torch.cuda.is_available(), "CUDA is not available"
assert torch.version.hip is None, "ROCm build detected in NVIDIA environment"
PY

echo "[SUCCESS] NVIDIA LingBot-VLA environment is ready."
