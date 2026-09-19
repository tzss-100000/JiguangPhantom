#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STORAGE_ROOT="${STORAGE_ROOT:-${PROJECT_ROOT}/runtime}"
MODEL_ROOT="${MODEL_ROOT:-${STORAGE_ROOT}/models}"
OUTPUT_ROOT="${OUTPUT_ROOT:-${STORAGE_ROOT}/outputs}"
LINGBOT_ROOT="${LINGBOT_ROOT:-${PROJECT_ROOT}/third_party/lingbot-vla-v2}"
ROBOTWIN_ROOT="${ROBOTWIN_ROOT:-${PROJECT_ROOT}/third_party/RoboTwin}"
MODEL_PATH="${MODEL_PATH:?Set MODEL_PATH to a trained hf_ckpt directory}"
TASK_CONFIG="${TASK_CONFIG:-demo_clean}"
NUM_TASKS="${NUM_TASKS:-50}"
NUM_GPUS="${NUM_GPUS:-4}"
NUM_PER_GPU="${NUM_PER_GPU:-1}"
CONDA_SH="${CONDA_SH:-${STORAGE_ROOT}/miniconda3/etc/profile.d/conda.sh}"

cd "${LINGBOT_ROOT}"

QWEN3VL_PATH="${MODEL_ROOT}/Qwen3-VL-4B-Instruct" \
bash experiment/robotwin/start_robotwin_infer_and_eval.sh \
  --model_path "${MODEL_PATH}" \
  --eval_workdir "${ROBOTWIN_ROOT}" \
  --output_base "${OUTPUT_ROOT}/evaluation" \
  --conda_sh "${CONDA_SH}" \
  --inference_env lingbotvla \
  --sim_env RoboTwin \
  --task_config "${TASK_CONFIG}" \
  --num_tasks "${NUM_TASKS}" \
  --num_gpus "${NUM_GPUS}" \
  --num_per_gpu "${NUM_PER_GPU}"
