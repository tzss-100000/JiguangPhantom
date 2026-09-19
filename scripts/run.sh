#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
shift || true

if [ -z "${ACTION}" ]; then
    echo "Usage: bash scripts/run.sh {setup|train|eval}"
    exit 2
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLATFORM="${PLATFORM:-auto}"

if [ "${PLATFORM}" = "auto" ]; then
    if [ -e /dev/kfd ] || command -v rocm-smi >/dev/null 2>&1; then
        PLATFORM=amd
    elif command -v nvidia-smi >/dev/null 2>&1; then
        PLATFORM=nvidia
    else
        echo "[ERROR] No GPU platform detected."
        echo "On a Slurm login node use scripts/slurm/submit_whu_*.sh instead."
        exit 1
    fi
fi

case "${PLATFORM}:${ACTION}" in
    amd:setup) exec bash "${PROJECT_ROOT}/scripts/amd/bootstrap.sh" "$@" ;;
    amd:train)
        bash "${PROJECT_ROOT}/scripts/amd/start_container.sh"
        exec bash "${PROJECT_ROOT}/scripts/amd/train.sh" "$@"
        ;;
    amd:eval)
        bash "${PROJECT_ROOT}/scripts/amd/start_container.sh"
        exec bash "${PROJECT_ROOT}/scripts/amd/eval.sh" "$@"
        ;;
    nvidia:setup) exec bash "${PROJECT_ROOT}/scripts/nvidia/bootstrap.sh" "$@" ;;
    nvidia:train) exec bash "${PROJECT_ROOT}/scripts/nvidia/train.sh" "$@" ;;
    nvidia:eval) exec bash "${PROJECT_ROOT}/scripts/nvidia/eval.sh" "$@" ;;
    *) echo "[ERROR] Unsupported PLATFORM/ACTION: ${PLATFORM}/${ACTION}"; exit 2 ;;
esac
