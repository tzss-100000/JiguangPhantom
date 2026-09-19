#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
THIRD_PARTY_ROOT="${THIRD_PARTY_ROOT:-${PROJECT_ROOT}/third_party}"
DATA_ROOT="${DATA_ROOT:-${PROJECT_ROOT}/data}"
ROBOTWIN_ROOT="${ROBOTWIN_ROOT:-${THIRD_PARTY_ROOT}/RoboTwin}"

ROBOTWIN_COMMIT_NVIDIA="${ROBOTWIN_COMMIT_NVIDIA:-13c3c47ff4312dd62484bcd51be034af55c062d1}"
ROBOTWIN_COMMIT_AMD="${ROBOTWIN_COMMIT_AMD:-266f3aadf505a4f7fe9af0faa41a20f5f47cd123}"
PLATFORM="${PLATFORM:-auto}"

if [ "${PLATFORM}" = "auto" ]; then
    if command -v rocm-smi >/dev/null 2>&1 || [ -e /dev/kfd ]; then
        PLATFORM="amd"
    else
        PLATFORM="nvidia"
    fi
fi

case "${PLATFORM}" in
    amd) ROBOTWIN_COMMIT="${ROBOTWIN_COMMIT_AMD}" ;;
    nvidia) ROBOTWIN_COMMIT="${ROBOTWIN_COMMIT_NVIDIA}" ;;
    *) echo "[ERROR] PLATFORM must be amd or nvidia"; exit 1 ;;
esac

mkdir -p "${THIRD_PARTY_ROOT}" "${DATA_ROOT}"

if [ ! -d "${ROBOTWIN_ROOT}/.git" ]; then
    git clone --recurse-submodules         https://github.com/RoboTwin-Platform/RoboTwin.git         "${ROBOTWIN_ROOT}"
fi

git -C "${ROBOTWIN_ROOT}" fetch origin
git -C "${ROBOTWIN_ROOT}" checkout "${ROBOTWIN_COMMIT}"
git -C "${ROBOTWIN_ROOT}" submodule update --init --recursive

mkdir -p "${ROBOTWIN_ROOT}/policy/pi0/processed_data"
mkdir -p "${ROBOTWIN_ROOT}/policy/pi0/training_data"
mkdir -p "${DATA_ROOT}/RoboTwin2.0/raw"
mkdir -p "${DATA_ROOT}/RoboTwin2.0/processed"
mkdir -p "${DATA_ROOT}/RoboTwin2.0/lerobot"

echo "[SUCCESS] RoboTwin prepared for platform: ${PLATFORM}"
echo "Commit: $(git -C "${ROBOTWIN_ROOT}" rev-parse HEAD)"
echo "Data root: ${DATA_ROOT}/RoboTwin2.0"
echo
echo "Competition constraint: only the designated CLEAN data may be used for training."
