#!/usr/bin/env bash

set -euo pipefail

MODEL_ROOT="${MODEL_ROOT:-/project/${USER}/models}"

mkdir -p "${MODEL_ROOT}"

echo "========================================"
echo "JiguangPhantom - Model Downloader"
echo "========================================"
echo "MODEL_ROOT: ${MODEL_ROOT}"
echo "========================================"

if ! command -v python >/dev/null 2>&1; then
    echo "[ERROR] Python is not available."
    echo "Please activate the lingbotvla environment first."
    exit 1
fi

python - <<'PY'
try:
    import huggingface_hub
    print("huggingface_hub available")
except ImportError:
    raise SystemExit(
        "huggingface_hub is missing. "
        "Activate the lingbotvla environment first."
    )
PY

download_model () {
    REPO_ID="$1"
    LOCAL_DIR="$2"

    if [ -d "${LOCAL_DIR}" ] && [ "$(ls -A "${LOCAL_DIR}" 2>/dev/null)" ]; then
        echo "[SKIP] ${REPO_ID}"
        echo "       ${LOCAL_DIR} already exists."
        return
    fi

    echo
    echo "[DOWNLOAD] ${REPO_ID}"
    echo "[TARGET]   ${LOCAL_DIR}"

    python - <<PY
from huggingface_hub import snapshot_download

snapshot_download(
    repo_id="${REPO_ID}",
    local_dir="${LOCAL_DIR}",
)
PY
}

download_model \
    "robbyant/lingbot-vla-v2-6b" \
    "${MODEL_ROOT}/lingbot-vla-v2-6b"

download_model \
    "Qwen/Qwen3-VL-4B-Instruct" \
    "${MODEL_ROOT}/Qwen3-VL-4B-Instruct"

download_model \
    "Ruicheng/moge-2-vitb-normal" \
    "${MODEL_ROOT}/moge-2-vitb-normal"

echo
echo "========================================"
echo "Model download completed."
echo "========================================"

echo
echo "Important:"
echo "LingBot-VLA 2.0 also requires depth/video teacher"
echo "files contained in the official LingBot weight repository."
echo
echo "Expected structure:"
echo "${MODEL_ROOT}/lingbot-vla-v2-6b/depth/"
echo "${MODEL_ROOT}/lingbot-vla-v2-6b/dino_video/"

echo
echo "[DONE]"
