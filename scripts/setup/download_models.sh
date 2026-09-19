#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODEL_ROOT="${MODEL_ROOT:-${PROJECT_ROOT}/models}"

mkdir -p "${MODEL_ROOT}"

echo "========================================"
echo "JiguangPhantom - Model Downloader"
echo "========================================"
echo "MODEL_ROOT: ${MODEL_ROOT}"
echo "========================================"

if ! command -v python >/dev/null 2>&1; then
    echo "[ERROR] Python is not available."
    exit 1
fi

python - <<'PY'
try:
    import huggingface_hub
    print("huggingface_hub available")
except ImportError as exc:
    raise SystemExit("huggingface_hub is required") from exc
PY

download_model() {
    local repo_id="$1"
    local local_dir="$2"
    local revision="${3:-}"

    if [ -d "${local_dir}" ] && [ -n "$(ls -A "${local_dir}" 2>/dev/null)" ]; then
        echo "[SKIP] ${repo_id}: ${local_dir} already exists."
        return
    fi

    REPO_ID="${repo_id}" LOCAL_DIR="${local_dir}" REVISION="${revision}" python - <<'PY'
import os
from huggingface_hub import snapshot_download

kwargs = {
    "repo_id": os.environ["REPO_ID"],
    "local_dir": os.environ["LOCAL_DIR"],
}
revision = os.environ.get("REVISION")
if revision:
    kwargs["revision"] = revision

snapshot_download(**kwargs)
PY
}

download_model     "robbyant/lingbot-vla-v2-6b"     "${MODEL_ROOT}/lingbot-vla-v2-6b"

download_model     "Qwen/Qwen3-VL-4B-Instruct"     "${MODEL_ROOT}/Qwen3-VL-4B-Instruct"

download_model     "Ruicheng/moge-2-vitb-normal"     "${MODEL_ROOT}/moge-2-vitb-normal"

echo "[SUCCESS] Model download completed."
echo "LingBot base weights include the depth and DINO-video teacher files."
