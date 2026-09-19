#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${AMD_CONTAINER:-robotwin-lingbot-vla-v2}"
GPU_COUNT="${GPU_COUNT:-4}"
EPISODES="${EPISODES:-10}"
MODEL_PATH="${MODEL_PATH:-}"
RUN_NAME="${RUN_NAME:-jiguang_clean_eval}"

if [ -z "${MODEL_PATH}" ]; then
    echo "[ERROR] Set MODEL_PATH to the trained HF checkpoint inside the container."
    echo "Example: MODEL_PATH=/workspace/runtime/outputs/.../hf_ckpt"
    exit 1
fi

docker exec "${CONTAINER}" bash -lc "
  cd /RoboTwin
  source /opt/robotwin-env/bin/activate
  python experiments/lingbot_vla_v2_6b_robotwin/scripts/run_clean_benchmark.py \
    --gpu-count ${GPU_COUNT} \
    --episodes ${EPISODES} \
    --expert-check \
    --accept-expert-info-on-failure \
    --no-video \
    --model-path '${MODEL_PATH}' \
    --run-name '${RUN_NAME}' \
    --runtime-dir /workspace/runtime \
    --resume
"
