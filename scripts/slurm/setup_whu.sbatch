#!/usr/bin/env bash
#SBATCH --job-name=jiguang-setup
#SBATCH --time=12:00:00
#SBATCH --output=logs/setup-%j.out
#SBATCH --error=logs/setup-%j.err
set -euo pipefail

cd "${SLURM_SUBMIT_DIR}"
STORAGE_ROOT="${STORAGE_ROOT:-/project/${USER}}" PREPARE_DATA="${PREPARE_DATA:-1}" \
  bash scripts/nvidia/bootstrap.sh
