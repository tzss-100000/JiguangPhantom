#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPRO_ROOT="${AMD_REPRO_ROOT:-/workspace/Robotwin-radeon-cloud}"
ROBOTWIN_ROOT="${AMD_ROBOTWIN_ROOT:-/RoboTwin}"
RUNTIME_ROOT="${AMD_RUNTIME_ROOT:-/workspace/runtime}"

ROBOTWIN_COMMIT="${ROBOTWIN_COMMIT:-266f3aadf505a4f7fe9af0faa41a20f5f47cd123}"
LINGBOT_COMMIT="${LINGBOT_COMMIT:-951475ae1b1d87553e7dc47c97b53a3d695c0d13}"
AITER_COMMIT="${AITER_COMMIT:-9bab8388c35936814a659b4ebd245c491e1b940a}"
FLASH_ATTN_COMMIT="${FLASH_ATTN_COMMIT:-bc76302fbb24c0158207978930db030ca1eca5ca}"
MODEL_REVISION="${MODEL_REVISION:-11c703bf6a5c1f45b3b69168482da11fdbba53d7}"
QWEN_REVISION="${QWEN_REVISION:-ebb281ec70b05090aa6165b016eac8ec08e71b17}"
MOGE_REVISION="${MOGE_REVISION:-ca5f0e07ff01d3e5a364c1d954ed12ee1814b368}"
DATA_REVISION="${DATA_REVISION:-a967b852afa21a9cbf19a198f7e653109042e87c}"
GPU_ARCHS="${AITER_GPU_ARCHS:-gfx1100;gfx1201}"

git_safe() {
  git -c http.version=HTTP/1.1 -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=120 "$@"
}

retry() {
  local n=0 max=6 delay=5
  until "$@"; do
    n=$((n+1))
    if [ "${n}" -ge "${max}" ]; then return 1; fi
    echo "[WARN] command failed; retry ${n}/${max} in ${delay}s"
    sleep "${delay}"
    delay=$((delay*2))
  done
}

clone_at_commit() {
  local url="$1" dst="$2" commit="$3"
  if [ ! -d "${dst}/.git" ]; then
    rm -rf "${dst}"
    mkdir -p "${dst}"
    git_safe -C "${dst}" init
    git_safe -C "${dst}" remote add origin "${url}"
  fi
  retry git_safe -C "${dst}" fetch --depth 1 origin "${commit}"
  git_safe -C "${dst}" checkout -f FETCH_HEAD
}

BASE_PYTHON="/opt/venv/bin/python"
if [ ! -x "${BASE_PYTHON}" ]; then
  BASE_PYTHON="$(command -v python)"
fi

"${BASE_PYTHON}" - <<'PY'
import torch
print("Base torch:", torch.__version__, "HIP:", torch.version.hip, "GPU count:", torch.cuda.device_count())
assert torch.cuda.is_available(), "PyTorch cannot see the AMD GPU"
assert torch.version.hip is not None, "The current PyTorch build is not ROCm/HIP"
PY

if command -v docker >/dev/null 2>&1 && [ "${AMD_FORCE_NATIVE:-0}" != "1" ]; then
  IMAGE="${AMD_IMAGE:-robotwin-lingbot-vla-v2:rocm7.2.1_ubuntu24.04_py3.12_pytorch_release_2.9.1}"
  if [ ! -d "${REPRO_ROOT}/.git" ]; then
    retry git_safe clone https://github.com/ZiguanWang/Robotwin-radeon-cloud.git "${REPRO_ROOT}"
  fi
  if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
    cd "${REPRO_ROOT}"
    IMAGE_NAME="${IMAGE}" bash docker/full/build.sh
  fi
  mkdir -p /workspace/robotwin-runtime
  echo "[SUCCESS] AMD Docker image ready: ${IMAGE}"
  exit 0
fi

echo "[INFO] Docker is unavailable; using the official native ROCm installation path."

if command -v apt-get >/dev/null 2>&1; then
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq     git git-lfs curl wget ffmpeg unzip     libgl1 libglib2.0-0 libvulkan1 vulkan-tools mesa-vulkan-drivers     build-essential ninja-build cmake pkg-config
fi
git lfs install || true

if [ ! -d "${REPRO_ROOT}/.git" ]; then
  retry git_safe clone https://github.com/ZiguanWang/Robotwin-radeon-cloud.git "${REPRO_ROOT}"
else
  retry git_safe -C "${REPRO_ROOT}" pull --ff-only
fi

mkdir -p "${RUNTIME_ROOT}" /opt

if [ ! -x /opt/robotwin-env/bin/python ]; then
  "${BASE_PYTHON}" -m venv --system-site-packages /opt/robotwin-env
fi
MODEL_SITE="$(/opt/robotwin-env/bin/python -c 'import site; print(site.getsitepackages()[0])')"
if [ -d /opt/venv ]; then
  printf '%s\n'     /opt/venv/lib/python3.12/site-packages     /opt/venv/local/lib/python3.12/dist-packages     /opt/venv/lib/python3/dist-packages     /opt/venv/lib/python3.12/dist-packages     > "${MODEL_SITE}/rocm_image_venv.pth"
fi

/opt/robotwin-env/bin/python -m pip install --upgrade 'pip<26' 'setuptools<81' wheel
/opt/robotwin-env/bin/python -m pip install --prefer-binary -r "${REPRO_ROOT}/docker/requirements.txt"
/opt/robotwin-env/bin/python -m pip install --no-deps -r "${REPRO_ROOT}/docker/requirements-no-deps.txt"
/opt/robotwin-env/bin/python -m pip install --prefer-binary open3d==0.19.0

if [ ! -x /opt/lerobot-env/bin/python ]; then
  "${BASE_PYTHON}" -m venv --system-site-packages /opt/lerobot-env
fi
DATA_SITE="$(/opt/lerobot-env/bin/python -c 'import site; print(site.getsitepackages()[0])')"
if [ -d /opt/venv ]; then
  printf '%s\n'     /opt/venv/lib/python3.12/site-packages     /opt/venv/local/lib/python3.12/dist-packages     /opt/venv/lib/python3/dist-packages     /opt/venv/lib/python3.12/dist-packages     > "${DATA_SITE}/rocm_image_venv.pth"
fi
/opt/lerobot-env/bin/python -m pip install --upgrade 'pip<26' 'setuptools<81' wheel
/opt/lerobot-env/bin/python -m pip install 'lerobot[dataset]==0.6.0' 'h5py==3.14.0'

clone_at_commit https://github.com/ROCm/aiter.git /opt/aiter "${AITER_COMMIT}"
sed -i '/flydsl==0.1.9.dev599/d' /opt/aiter/pyproject.toml || true
(
  cd /opt/aiter
  GPU_ARCHS="${GPU_ARCHS}" AITER_USE_SYSTEM_TRITON=1     /opt/robotwin-env/bin/python setup.py develop
)

clone_at_commit https://github.com/ZiguanWang/flash-attention.git /opt/flash-attention-source "${FLASH_ATTN_COMMIT}"
(
  cd /opt/flash-attention-source
  PYTHONPATH=/opt/aiter   AITER_TRITON_ONLY=1   GPU_ARCHS="${GPU_ARCHS}"   FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE   FLASH_ATTENTION_USE_SYSTEM_AITER=TRUE     /opt/robotwin-env/bin/python -m pip install --no-build-isolation --no-deps .
)

clone_at_commit https://github.com/RoboTwin-Platform/RoboTwin.git "${ROBOTWIN_ROOT}" "${ROBOTWIN_COMMIT}"
retry git_safe -C "${ROBOTWIN_ROOT}" submodule update --init --recursive --depth 1
test "$(git -C "${ROBOTWIN_ROOT}" rev-parse HEAD)" = "${ROBOTWIN_COMMIT}"

if ! git -C "${ROBOTWIN_ROOT}" status --porcelain | grep -q .; then
  git -C "${ROBOTWIN_ROOT}" apply "${REPRO_ROOT}/docker/patches/robotwin-rocm-reproduction.patch"
fi
if ! git -C "${ROBOTWIN_ROOT}/XPolicyLab" status --porcelain | grep -q .; then
  git -C "${ROBOTWIN_ROOT}/XPolicyLab" apply "${REPRO_ROOT}/docker/patches/xpolicylab-lerobot-v30.patch"
fi

LINGBOT_ROOT="${ROBOTWIN_ROOT}/experiments/lingbot_vla_v2_6b_robotwin/source/lingbot-vla-v2"
mkdir -p "$(dirname "${LINGBOT_ROOT}")"
clone_at_commit https://github.com/robbyant/lingbot-vla-v2.git "${LINGBOT_ROOT}" "${LINGBOT_COMMIT}"
if ! git -C "${LINGBOT_ROOT}" status --porcelain | grep -q .; then
  git -C "${LINGBOT_ROOT}" apply "${REPRO_ROOT}/docker/patches/lingbot-vla-v2-rocm.patch"
fi

cp -a "${REPRO_ROOT}/docker/assets/experiments/lingbot_vla_v2_6b_robotwin/."   "${ROBOTWIN_ROOT}/experiments/lingbot_vla_v2_6b_robotwin/"

/opt/robotwin-env/bin/python -m pip install -e "${ROBOTWIN_ROOT}/XPolicyLab"
/opt/robotwin-env/bin/python -m pip install --no-deps -e "${LINGBOT_ROOT}"

export AITER_TRITON_ONLY=1
export FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE
export PYTHONPATH=/opt/aiter${PYTHONPATH:+:${PYTHONPATH}}
export HF_HOME="${RUNTIME_ROOT}/.cache/huggingface"
mkdir -p "${HF_HOME}"

/opt/robotwin-env/bin/python - <<'PY'
import aiter, flash_attn, torch, triton
print("torch:", torch.__version__, "HIP:", torch.version.hip)
print("triton:", triton.__version__)
print("flash_attn:", flash_attn.__version__)
assert torch.version.hip is not None
assert flash_attn.__version__ == "2.8.4"
PY

cd "${ROBOTWIN_ROOT}"
/opt/robotwin-env/bin/python scripts/_download_assets.sh

MODEL_ROOT="${ROBOTWIN_ROOT}/experiments/lingbot_vla_v2_6b_robotwin/models"
mkdir -p "${MODEL_ROOT}"

/opt/robotwin-env/bin/huggingface-cli download robbyant/lingbot-vla-v2-6b   --revision "${MODEL_REVISION}"   --local-dir "${MODEL_ROOT}/robbyant_lingbot-vla-v2-6b"

/opt/robotwin-env/bin/huggingface-cli download Qwen/Qwen3-VL-4B-Instruct   --revision "${QWEN_REVISION}"   --include '*.json' '*.txt' '*.jinja' merges.txt vocab.json   --local-dir "${MODEL_ROOT}/Qwen3-VL-4B-Instruct-config-tokenizer"

/opt/robotwin-env/bin/huggingface-cli download Ruicheng/moge-2-vitb-normal   --revision "${MOGE_REVISION}"   --local-dir "${MODEL_ROOT}/moge-2-vitb-normal"

ROBOTWIN_DATA_ROOT="${ROBOTWIN_ROOT}/data" HF_ARCHIVE_CACHE="${RUNTIME_ROOT}/download-cache" HF_REVISION="${DATA_REVISION}" HF_KEEP_ARCHIVES=0 PATH=/opt/lerobot-env/bin:${PATH} bash scripts/download_xpolicylab_data.sh

LEROBOT_PYTHON=/opt/lerobot-env/bin/python CONVERSION_JOBS="${CONVERSION_JOBS:-8}" bash "${REPRO_ROOT}/docker/full/convert_all_data.sh"

mkdir -p "${RUNTIME_ROOT}/eval_result" "${RUNTIME_ROOT}/outputs" "${RUNTIME_ROOT}/.cache/huggingface"

cat > "${PROJECT_ROOT}/.amd_runtime.env" <<EOF
export AMD_NATIVE=1
export ROBOTWIN_ROOT=${ROBOTWIN_ROOT}
export AMD_REPRO_ROOT=${REPRO_ROOT}
export AMD_RUNTIME_ROOT=${RUNTIME_ROOT}
export LINGBOT_VLA_SOURCE=${LINGBOT_ROOT}
export QWEN3VL_PATH=${MODEL_ROOT}/Qwen3-VL-4B-Instruct-config-tokenizer
export LINGBOT_VLA_PYTHON=/opt/robotwin-env/bin/python
export HF_LEROBOT_HOME=${ROBOTWIN_ROOT}/data/lerobot
export ROBOTWIN_DISABLE_CUROBO=1
export ROBOTWIN_EE_PLANNER=mplib
export PYOPENGL_PLATFORM=egl
export AITER_TRITON_ONLY=1
export FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE
export PYTHONPATH=/opt/aiter
EOF

echo "[SUCCESS] Native AMD ROCm environment is ready."
echo "Runtime configuration: ${PROJECT_ROOT}/.amd_runtime.env"
