#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTAINER="${AMD_CONTAINER:-robotwin-lingbot-vla-v2}"
GPU_COUNT="${GPU_COUNT:-4}"
EPISODES="${EPISODES:-10}"
MODEL_PATH="${MODEL_PATH:-}"
RUN_NAME="${RUN_NAME:-jiguang_clean_eval}"

if [ -z "${MODEL_PATH}" ]; then
  echo "[ERROR] Set MODEL_PATH to the trained HF checkpoint."
  exit 1
fi

CMD="cd /RoboTwin && source /opt/robotwin-env/bin/activate && python experiments/lingbot_vla_v2_6b_robotwin/scripts/run_clean_benchmark.py --gpu-count ${GPU_COUNT} --episodes ${EPISODES} --expert-check --accept-expert-info-on-failure --no-video --model-path '${MODEL_PATH}' --run-name '${RUN_NAME}' --runtime-dir /workspace/runtime --resume"

if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -Fxq "${CONTAINER}"; then
  docker exec "${CONTAINER}" bash -lc "${CMD}"
  exit $?
fi

if [ -f "${PROJECT_ROOT}/.amd_runtime.env" ]; then
  source "${PROJECT_ROOT}/.amd_runtime.env"
fi

cd "${ROBOTWIN_ROOT:-/RoboTwin}"
source /opt/robotwin-env/bin/activate
python experiments/lingbot_vla_v2_6b_robotwin/scripts/run_clean_benchmark.py   --gpu-count "${GPU_COUNT}"   --episodes "${EPISODES}"   --expert-check   --accept-expert-info-on-failure   --no-video   --model-path "${MODEL_PATH}"   --run-name "${RUN_NAME}"   --runtime-dir /workspace/runtime   --resume
