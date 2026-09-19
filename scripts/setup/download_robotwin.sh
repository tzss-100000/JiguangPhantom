#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

THIRD_PARTY_ROOT="${THIRD_PARTY_ROOT:-${PROJECT_ROOT}/third_party}"
DATA_ROOT="${DATA_ROOT:-/project/${USER}/datasets}"

ROBOTWIN_ROOT="${THIRD_PARTY_ROOT}/RoboTwin"

ROBOTWIN_COMMIT="13c3c47ff4312dd62484bcd51be034af55c062d1"

mkdir -p "${THIRD_PARTY_ROOT}"
mkdir -p "${DATA_ROOT}"

echo "========================================"
echo "JiguangPhantom - RoboTwin Setup"
echo "========================================"
echo "ROBOTWIN_ROOT : ${ROBOTWIN_ROOT}"
echo "DATA_ROOT     : ${DATA_ROOT}"
echo "COMMIT        : ${ROBOTWIN_COMMIT}"
echo "========================================"

if [ ! -d "${ROBOTWIN_ROOT}/.git" ]; then
    echo "[INFO] Cloning RoboTwin..."
    git clone \
        https://github.com/RoboTwin-Platform/RoboTwin.git \
        "${ROBOTWIN_ROOT}"
else
    echo "[INFO] RoboTwin repository already exists."
fi

cd "${ROBOTWIN_ROOT}"

git fetch origin
git checkout "${ROBOTWIN_COMMIT}"

echo
echo "[INFO] RoboTwin pinned to:"
git rev-parse HEAD

mkdir -p policy/pi0/processed_data
mkdir -p policy/pi0/training_data

mkdir -p "${DATA_ROOT}/RoboTwin2.0/raw"
mkdir -p "${DATA_ROOT}/RoboTwin2.0/processed"
mkdir -p "${DATA_ROOT}/RoboTwin2.0/lerobot"

echo
echo "========================================"
echo "IMPORTANT COMPETITION RULE"
echo "========================================"
echo "Only competition-designated CLEAN data"
echo "may be used for training."
echo
echo "Do NOT use randomized data for training."
echo
echo "Official dataset:"
echo "https://huggingface.co/datasets/TianxingChen/RoboTwin2.0"
echo
echo "Place downloaded CLEAN dataset under:"
echo "${DATA_ROOT}/RoboTwin2.0/raw/"
echo
echo "[DONE]"
