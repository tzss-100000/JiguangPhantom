#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMAGE="${AMD_IMAGE:-robotwin-lingbot-vla-v2:rocm7.2.1_ubuntu24.04_py3.12_pytorch_release_2.9.1}"
CONTAINER="${AMD_CONTAINER:-robotwin-lingbot-vla-v2}"

if command -v docker >/dev/null 2>&1 && docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  mkdir -p /workspace/robotwin-runtime
  if docker ps -a --format '{{.Names}}' | grep -Fxq "${CONTAINER}"; then
      docker start "${CONTAINER}" >/dev/null
  else
      docker run --name "${CONTAINER}"         --device=/dev/kfd --device=/dev/dri --group-add video         --ipc=host --shm-size=32g --security-opt seccomp=unconfined         --cap-add=SYS_PTRACE --network=host         -v /workspace/robotwin-runtime:/workspace/runtime         -d "${IMAGE}" sleep infinity >/dev/null
  fi
  docker exec "${CONTAINER}" bash -lc 'source /opt/robotwin-env/bin/activate && python - <<PY
import torch
print("torch", torch.__version__, "hip", torch.version.hip, "gpus", torch.cuda.device_count())
assert torch.cuda.is_available() and torch.version.hip is not None
PY'
  echo "[SUCCESS] AMD Docker container is running: ${CONTAINER}"
  exit 0
fi

if [ -f "${PROJECT_ROOT}/.amd_runtime.env" ]; then
  source "${PROJECT_ROOT}/.amd_runtime.env"
fi

test -x /opt/robotwin-env/bin/python || {
  echo "[ERROR] Native AMD environment not found. Run: bash scripts/run.sh setup"
  exit 1
}

/opt/robotwin-env/bin/python - <<'PY'
import torch
print("torch", torch.__version__, "hip", torch.version.hip, "gpus", torch.cuda.device_count())
assert torch.cuda.is_available() and torch.version.hip is not None
PY

echo "[SUCCESS] Native AMD ROCm environment is ready."
