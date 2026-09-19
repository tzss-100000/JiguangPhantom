#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
THIRD_PARTY_ROOT="${THIRD_PARTY_ROOT:-${PROJECT_ROOT}/third_party}"
REPRO_ROOT="${AMD_REPRO_ROOT:-${THIRD_PARTY_ROOT}/Robotwin-radeon-cloud}"
ROBOTWIN_ROOT="${ROBOTWIN_ROOT:-${THIRD_PARTY_ROOT}/RoboTwin}"

ROCM_EXPECTED="${ROCM_EXPECTED:-7.2.1}"
PYTORCH_EXPECTED="${PYTORCH_EXPECTED:-2.9.1}"

if [ ! -e /dev/kfd ] && ! command -v rocm-smi >/dev/null 2>&1; then
    echo "[ERROR] AMD ROCm device was not detected."
    exit 1
fi

if [ ! -d "${REPRO_ROOT}/.git" ]; then
    echo "[INFO] Cloning AMD RoboTwin reproduction repository..."
    git clone https://github.com/ZiguanWang/Robotwin-radeon-cloud.git "${REPRO_ROOT}"
fi

echo "[INFO] AMD/ROCm platform detected."
command -v rocm-smi >/dev/null 2>&1 && rocm-smi || true

python - <<PY
import torch
print("torch:", torch.__version__)
print("hip:", torch.version.hip)
print("gpu available:", torch.cuda.is_available())
print("gpu count:", torch.cuda.device_count())
assert torch.cuda.is_available(), "PyTorch cannot see AMD GPU"
assert torch.version.hip is not None, "Current PyTorch is not a ROCm build"
PY

TORCH_VERSION="$(python - <<'PY'
import torch
print(torch.__version__.split("+", 1)[0])
PY
)"

HIP_VERSION="$(python - <<'PY'
import torch
print(torch.version.hip or "")
PY
)"

if [ "${TORCH_VERSION}" != "${PYTORCH_EXPECTED}" ]; then
    echo "[WARN] AMD reference environment uses PyTorch ${PYTORCH_EXPECTED}; current: ${TORCH_VERSION}"
fi

if [[ "${HIP_VERSION}" != "${ROCM_EXPECTED}"* ]]; then
    echo "[WARN] AMD reference environment uses ROCm ${ROCM_EXPECTED}; current HIP runtime: ${HIP_VERSION}"
fi

cat <<EOF

AMD environment detected successfully.

The official competition reference stack uses:
  ROCm      : ${ROCM_EXPECTED}
  PyTorch   : ${PYTORCH_EXPECTED}
  Reference : ${REPRO_ROOT}

For Radeon Cloud, prefer the validated AMD reproduction image/workflow from:
  https://github.com/ZiguanWang/Robotwin-radeon-cloud

Do NOT run LingBot's upstream CUDA environment installer on ROCm,
because it installs CUDA/PyPI torch and flash-attn dependencies that can
replace the ROCm stack.

[SUCCESS] AMD base environment check passed.
EOF
