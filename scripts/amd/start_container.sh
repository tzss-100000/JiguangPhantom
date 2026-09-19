#!/usr/bin/env bash
set -euo pipefail

IMAGE="${AMD_IMAGE:-robotwin-lingbot-vla-v2:rocm7.2.1_ubuntu24.04_py3.12_pytorch_release_2.9.1}"
CONTAINER="${AMD_CONTAINER:-robotwin-lingbot-vla-v2}"

mkdir -p /workspace/robotwin-runtime

if docker ps -a --format '{{.Names}}' | grep -Fxq "${CONTAINER}"; then
    docker start "${CONTAINER}" >/dev/null
else
    docker run --name "${CONTAINER}" \
      --device=/dev/kfd \
      --device=/dev/dri \
      --group-add video \
      --ipc=host \
      --shm-size=32g \
      --security-opt seccomp=unconfined \
      --cap-add=SYS_PTRACE \
      --network=host \
      -v /workspace/robotwin-runtime:/workspace/runtime \
      -d "${IMAGE}" sleep infinity >/dev/null
fi

docker exec "${CONTAINER}" bash -lc 'source /opt/robotwin-env/bin/activate && python - <<PY
import torch
print("torch", torch.__version__, "hip", torch.version.hip, "gpus", torch.cuda.device_count())
assert torch.cuda.is_available() and torch.version.hip is not None
PY'
echo "[SUCCESS] AMD container is running: ${CONTAINER}"
