#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLATFORM="${PLATFORM:-auto}"

detect_platform() {
    if [ "${PLATFORM}" != "auto" ]; then
        printf '%s\n' "${PLATFORM}"
        return
    fi

    if command -v rocm-smi >/dev/null 2>&1 || [ -e /dev/kfd ]; then
        printf '%s\n' "amd"
        return
    fi

    if command -v nvidia-smi >/dev/null 2>&1; then
        printf '%s\n' "nvidia"
        return
    fi

    printf '%s\n' "unknown"
}

DETECTED_PLATFORM="$(detect_platform)"

case "${DETECTED_PLATFORM}" in
    nvidia)
        exec bash "${PROJECT_ROOT}/scripts/setup/setup_env_nvidia.sh" "$@"
        ;;
    amd)
        exec bash "${PROJECT_ROOT}/scripts/setup/setup_env_amd.sh" "$@"
        ;;
    *)
        echo "[ERROR] Unable to detect GPU platform."
        echo "Set PLATFORM=nvidia or PLATFORM=amd explicitly."
        exit 1
        ;;
esac
