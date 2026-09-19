#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STORAGE_ROOT="${STORAGE_ROOT:-${PROJECT_ROOT}/runtime}"
DATA_ROOT="${DATA_ROOT:-${STORAGE_ROOT}/datasets}"
CACHE_ROOT="${CACHE_ROOT:-${STORAGE_ROOT}/cache}"
ROBOTWIN_ROOT="${ROBOTWIN_ROOT:-${PROJECT_ROOT}/third_party/RoboTwin}"

DOWNLOAD_ROOT="${DATA_ROOT}/RoboTwin2.0/hf_download"
RAW_ROOT="${ROBOTWIN_ROOT}/data"
HF_LEROBOT_HOME="${HF_LEROBOT_HOME:-${DATA_ROOT}/RoboTwin2.0/lerobot}"
REPO_ID="${LEROBOT_REPO_ID:-jiguang_robotwin_clean}"

mkdir -p "${DOWNLOAD_ROOT}" "${RAW_ROOT}" "${HF_LEROBOT_HOME}" "${CACHE_ROOT}"
export HF_HOME="${CACHE_ROOT}/huggingface"
export XDG_CACHE_HOME="${CACHE_ROOT}"
export HF_LEROBOT_HOME

python - <<PY
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id="TianxingChen/RoboTwin2.0",
    repo_type="dataset",
    local_dir=r"${DOWNLOAD_ROOT}",
    allow_patterns=["dataset/*/demo_clean.zip"],
)
PY

python - <<PY
from pathlib import Path
import zipfile

src = Path(r"${DOWNLOAD_ROOT}") / "dataset"
dst = Path(r"${RAW_ROOT}")
archives = sorted(src.glob("*/demo_clean.zip"))
if not archives:
    raise SystemExit("No demo_clean.zip archives were downloaded")

for archive in archives:
    task = archive.parent.name
    task_dir = dst / task
    task_dir.mkdir(parents=True, exist_ok=True)
    marker = task_dir / ".jiguang_clean_extracted"
    if marker.exists():
        continue
    print("Extracting", task)
    with zipfile.ZipFile(archive) as zf:
        zf.extractall(task_dir)
    marker.touch()
print("Extracted", len(archives), "clean task archives")
PY

cd "${ROBOTWIN_ROOT}/policy/pi0"
mkdir -p processed_data training_data/jiguang_clean

for task_dir in "${RAW_ROOT}"/*; do
    [ -d "${task_dir}" ] || continue
    task="$(basename "${task_dir}")"
    cfg_dir="$(find "${task_dir}" -mindepth 1 -maxdepth 1 -type d -name '*clean*' | head -n 1 || true)"
    [ -n "${cfg_dir}" ] || continue
    cfg="$(basename "${cfg_dir}")"
    out="processed_data/${task}-${cfg}-50"
    if [ ! -d "${out}" ]; then
        echo "[PROCESS] ${task} ${cfg}"
        bash process_data_pi0.sh "${task}" "${cfg}" 50
    fi
    if [ -d "${out}" ] && [ ! -e "training_data/jiguang_clean/$(basename "${out}")" ]; then
        cp -r "${out}" training_data/jiguang_clean/
    fi
done

if [ ! -d "${HF_LEROBOT_HOME}/${REPO_ID}" ]; then
    bash generate.sh ./training_data/jiguang_clean/ "${REPO_ID}"
fi

TRAIN_LIST="${DATA_ROOT}/RoboTwin2.0/robotwin_clean.txt"
printf 'robotwin %s\n' "${HF_LEROBOT_HOME}/${REPO_ID}" > "${TRAIN_LIST}"

echo "[SUCCESS] Clean-only training list: ${TRAIN_LIST}"
cat "${TRAIN_LIST}"
