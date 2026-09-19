#!/usr/bin/env bash
set -euo pipefail

: "${GPU_PARTITION:?Set GPU_PARTITION}"
: "${GPU_ACCOUNT:?Set GPU_ACCOUNT}"
STORAGE_ROOT="${STORAGE_ROOT:-/project/${USER}}"
mkdir -p logs

sbatch \
  -p "${GPU_PARTITION}" \
  -A "${GPU_ACCOUNT}" \
  --nodes=1 \
  --ntasks-per-node=1 \
  --gres=gpu:1 \
  --cpus-per-task=16 \
  --mem=60G \
  --export=ALL,STORAGE_ROOT="${STORAGE_ROOT}",PREPARE_DATA="${PREPARE_DATA:-1}" \
  scripts/slurm/setup_whu.sbatch
