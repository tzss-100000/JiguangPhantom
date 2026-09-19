#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STORAGE_ROOT="${STORAGE_ROOT:-${PROJECT_ROOT}/runtime}"
MODEL_ROOT="${MODEL_ROOT:-${STORAGE_ROOT}/models}"
DATA_ROOT="${DATA_ROOT:-${STORAGE_ROOT}/datasets}"
OUTPUT_ROOT="${OUTPUT_ROOT:-${STORAGE_ROOT}/outputs}"

LINGBOT_ROOT="${LINGBOT_ROOT:-${PROJECT_ROOT}/third_party/lingbot-vla-v2}"
TRAIN_LIST="${TRAIN_LIST:-${DATA_ROOT}/RoboTwin2.0/robotwin_clean.txt}"
EXP_ID="${EXP_ID:-baseline}"
MAX_STEPS="${MAX_STEPS:-30000}"
SAVE_STEPS="${SAVE_STEPS:-10000}"
MICRO_BATCH_SIZE="${MICRO_BATCH_SIZE:-1}"
GRAD_ACCUM="${GRAD_ACCUM:-1}"
ENABLE_GRAD_CKPT="${ENABLE_GRAD_CKPT:-true}"

export PATH="${STORAGE_ROOT}/miniconda3/bin:${PATH}"
eval "$(conda shell.bash hook)"
conda activate lingbotvla

test -f "${TRAIN_LIST}" || { echo "[ERROR] Missing clean training list: ${TRAIN_LIST}"; exit 1; }

MODEL_PATH="${MODEL_ROOT}/lingbot-vla-v2-6b"
[ -d "${MODEL_PATH}/hf_ckpt" ] && MODEL_PATH="${MODEL_PATH}/hf_ckpt"

LOCAL_GPUS="${NPROC_PER_NODE:-}"
if [ -z "${LOCAL_GPUS}" ]; then
    if [ -n "${CUDA_VISIBLE_DEVICES:-}" ]; then
        LOCAL_GPUS="$(tr ',' '\n' <<<"${CUDA_VISIBLE_DEVICES}" | wc -l)"
    else
        LOCAL_GPUS="$(nvidia-smi -L | wc -l)"
    fi
fi
NNODES="${NNODES:-1}"
TOTAL_GPUS="${TOTAL_GPUS:-$((LOCAL_GPUS * NNODES))}"
GLOBAL_BATCH_SIZE="${GLOBAL_BATCH_SIZE:-$((MICRO_BATCH_SIZE * TOTAL_GPUS * GRAD_ACCUM))}"

RUN_DIR="${OUTPUT_ROOT}/${EXP_ID}"
CONFIG_DIR="${RUN_DIR}/config"
CONFIG_FILE="${CONFIG_DIR}/robotwin_clean.yaml"
mkdir -p "${CONFIG_DIR}"

BASE_CONFIG="${LINGBOT_ROOT}/configs/vla/robotwin/robotwin.yaml"
BASE_CONFIG="${BASE_CONFIG}" CONFIG_FILE="${CONFIG_FILE}" \
MODEL_PATH="${MODEL_PATH}" TOKENIZER_PATH="${MODEL_ROOT}/Qwen3-VL-4B-Instruct" \
TRAIN_LIST="${TRAIN_LIST}" RUN_DIR="${RUN_DIR}" MODEL_ROOT="${MODEL_ROOT}" \
MAX_STEPS="${MAX_STEPS}" SAVE_STEPS="${SAVE_STEPS}" MICRO_BATCH_SIZE="${MICRO_BATCH_SIZE}" \
GRAD_ACCUM="${GRAD_ACCUM}" GLOBAL_BATCH_SIZE="${GLOBAL_BATCH_SIZE}" ENABLE_GRAD_CKPT="${ENABLE_GRAD_CKPT}" \
python - <<'PY'
import os, yaml
from copy import deepcopy

with open(os.environ["BASE_CONFIG"], "r", encoding="utf-8") as f:
    cfg = yaml.safe_load(f)

cfg["model"]["model_path"] = os.environ["MODEL_PATH"]
cfg["model"]["tokenizer_path"] = os.environ["TOKENIZER_PATH"]
cfg["data"]["train_path"] = os.environ["TRAIN_LIST"]

t = cfg["train"]
t["output_dir"] = os.environ["RUN_DIR"]
t["micro_batch_size"] = int(os.environ["MICRO_BATCH_SIZE"])
t["gradient_accumulation_steps"] = int(os.environ["GRAD_ACCUM"])
t["global_batch_size"] = int(os.environ["GLOBAL_BATCH_SIZE"])
t["max_steps"] = int(os.environ["MAX_STEPS"])
t["save_steps"] = int(os.environ["SAVE_STEPS"])
t["enable_gradient_checkpointing"] = os.environ["ENABLE_GRAD_CKPT"].lower() == "true"

root = os.environ["MODEL_ROOT"]
align = t.get("align_params", {})
if align:
    align["depth"]["moge_path"] = f"{root}/moge-2-vitb-normal/model.pt"
    align["depth"]["morgbd_path"] = f"{root}/lingbot-vla-v2-6b/depth/model.pt"
    align["video"]["ckpt_path"] = f"{root}/lingbot-vla-v2-6b/dino_video/teacher_step_10000.pth"
    align["video"]["config_path"] = f"{root}/lingbot-vla-v2-6b/dino_video/config.yaml"

with open(os.environ["CONFIG_FILE"], "w", encoding="utf-8") as f:
    yaml.safe_dump(cfg, f, sort_keys=False)
print("wrote", os.environ["CONFIG_FILE"])
PY

cd "${LINGBOT_ROOT}"
bash train.sh tasks/vla/train_lingbotvla.py "${CONFIG_FILE}"
