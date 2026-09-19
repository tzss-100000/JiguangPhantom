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

if [ -x "${STORAGE_ROOT}/miniconda3/bin/conda" ]; then
    export PATH="${STORAGE_ROOT}/miniconda3/bin:${PATH}"
fi
eval "$(conda shell.bash hook)"
conda activate lingbotvla

test -f "${TRAIN_LIST}" || { echo "[ERROR] Missing ${TRAIN_LIST}; run bootstrap/prepare_clean_data first"; exit 1; }

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
mkdir -p "${RUN_DIR}"

cd "${LINGBOT_ROOT}"

bash train.sh tasks/vla/train_lingbotvla.py configs/vla/robotwin/robotwin.yaml \
  --model.model_path "${MODEL_PATH}" \
  --model.tokenizer_path "${MODEL_ROOT}/Qwen3-VL-4B-Instruct" \
  --data.train_path "${TRAIN_LIST}" \
  --train.output_dir "${RUN_DIR}" \
  --train.micro_batch_size "${MICRO_BATCH_SIZE}" \
  --train.gradient_accumulation_steps "${GRAD_ACCUM}" \
  --train.global_batch_size "${GLOBAL_BATCH_SIZE}" \
  --train.max_steps "${MAX_STEPS}" \
  --train.save_steps "${SAVE_STEPS}" \
  --train.enable_gradient_checkpointing "${ENABLE_GRAD_CKPT}" \
  --train.align_params.depth.moge_path "${MODEL_ROOT}/moge-2-vitb-normal/model.pt" \
  --train.align_params.depth.morgbd_path "${MODEL_ROOT}/lingbot-vla-v2-6b/depth/model.pt" \
  --train.align_params.video.ckpt_path "${MODEL_ROOT}/lingbot-vla-v2-6b/dino_video/teacher_step_10000.pth" \
  --train.align_params.video.config_path "${MODEL_ROOT}/lingbot-vla-v2-6b/dino_video/config.yaml"
