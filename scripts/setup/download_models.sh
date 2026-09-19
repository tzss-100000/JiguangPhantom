#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODEL_ROOT="${MODEL_ROOT:-${PROJECT_ROOT}/models}"

LINGBOT_REVISION="${LINGBOT_REVISION:-11c703bf6a5c1f45b3b69168482da11fdbba53d7}"
QWEN_REVISION="${QWEN_REVISION:-ebb281ec70b05090aa6165b016eac8ec08e71b17}"
MOGE_REVISION="${MOGE_REVISION:-ca5f0e07ff01d3e5a364c1d954ed12ee1814b368}"

mkdir -p "${MODEL_ROOT}"

python - <<'PY'
import huggingface_hub
print("huggingface_hub", huggingface_hub.__version__)
PY

download_snapshot() {
    local repo_id="$1"
    local local_dir="$2"
    local revision="$3"
    local mode="${4:-full}"

    if [ -d "${local_dir}" ] && [ -n "$(ls -A "${local_dir}" 2>/dev/null)" ]; then
        echo "[SKIP] ${repo_id}: ${local_dir} already exists"
        return
    fi

    REPO_ID="${repo_id}" LOCAL_DIR="${local_dir}" REVISION="${revision}" MODE="${mode}" python - <<'PY'
import os
from huggingface_hub import snapshot_download

kwargs = dict(
    repo_id=os.environ["REPO_ID"],
    revision=os.environ["REVISION"],
    local_dir=os.environ["LOCAL_DIR"],
)
if os.environ["MODE"] == "tokenizer":
    kwargs["allow_patterns"] = [
        "*.json", "*.txt", "*.jinja", "merges.txt", "vocab.json",
    ]
snapshot_download(**kwargs)
PY
}

download_snapshot   "robbyant/lingbot-vla-v2-6b"   "${MODEL_ROOT}/lingbot-vla-v2-6b"   "${LINGBOT_REVISION}" full

download_snapshot   "Qwen/Qwen3-VL-4B-Instruct"   "${MODEL_ROOT}/Qwen3-VL-4B-Instruct"   "${QWEN_REVISION}" tokenizer

download_snapshot   "Ruicheng/moge-2-vitb-normal"   "${MODEL_ROOT}/moge-2-vitb-normal"   "${MOGE_REVISION}" full

test -f "${MODEL_ROOT}/lingbot-vla-v2-6b/depth/model.pt"
test -f "${MODEL_ROOT}/lingbot-vla-v2-6b/dino_video/teacher_step_10000.pth"
test -f "${MODEL_ROOT}/lingbot-vla-v2-6b/dino_video/config.yaml"
test -f "${MODEL_ROOT}/moge-2-vitb-normal/model.pt"

echo "[SUCCESS] Required model assets are present under ${MODEL_ROOT}"
