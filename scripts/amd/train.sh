#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${AMD_CONTAINER:-robotwin-lingbot-vla-v2}"
GPU_COUNT="${GPU_COUNT:-4}"
MAX_STEPS="${MAX_STEPS:-30000}"
SAVE_STEPS="${SAVE_STEPS:-10000}"
EXP_ID="${EXP_ID:-baseline_full_sft}"
ENABLE_FULL_SHARD="${ENABLE_FULL_SHARD:-true}"
TEACHER_MODE="${TEACHER_MODE:-full}"
OUTPUT_DIR="/workspace/runtime/outputs/${EXP_ID}"

docker ps --format '{{.Names}}' | grep -Fxq "${CONTAINER}" || {
  echo "[ERROR] Start the container first: bash scripts/amd/start_container.sh"; exit 1;
}

docker exec \
  -e GPU_COUNT="${GPU_COUNT}" \
  -e MAX_STEPS="${MAX_STEPS}" \
  -e SAVE_STEPS="${SAVE_STEPS}" \
  -e OUTPUT_DIR="${OUTPUT_DIR}" \
  -e ENABLE_FULL_SHARD="${ENABLE_FULL_SHARD}" \
  -e TEACHER_MODE="${TEACHER_MODE}" \
  "${CONTAINER}" bash -lc '
    cd /RoboTwin
    source /opt/robotwin-env/bin/activate
    export AITER_TRITON_ONLY=1
    export FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE
    export PYTHONPATH=/opt/aiter${PYTHONPATH:+:${PYTHONPATH}}
    bash experiments/lingbot_vla_v2_6b_robotwin/training/train_full_sft.sh
  '
