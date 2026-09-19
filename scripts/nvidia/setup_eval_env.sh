#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STORAGE_ROOT="${STORAGE_ROOT:-${PROJECT_ROOT}/runtime}"
CACHE_ROOT="${CACHE_ROOT:-${STORAGE_ROOT}/cache}"
ROBOTWIN_ROOT="${ROBOTWIN_ROOT:-${PROJECT_ROOT}/third_party/RoboTwin}"

export PATH="${STORAGE_ROOT}/miniconda3/bin:${PATH}"
eval "$(conda shell.bash hook)"
export HF_HOME="${CACHE_ROOT}/huggingface"
export XDG_CACHE_HOME="${CACHE_ROOT}"

if conda env list | awk '{print $1}' | grep -Fxq RoboTwin; then
    echo "[INFO] RoboTwin conda environment already exists."
else
    conda create -n RoboTwin python=3.10 -y
fi

conda activate RoboTwin
cd "${ROBOTWIN_ROOT}"

git submodule update --init --recursive
bash scripts/_install.sh
bash scripts/_download_assets.sh

python - <<'PY'
import sys
print("RoboTwin eval Python:", sys.executable)
PY

echo "[SUCCESS] RoboTwin simulation environment is ready."
