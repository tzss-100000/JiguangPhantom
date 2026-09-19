#!/usr/bin/env bash
set -euo pipefail

: "${GPU_PARTITION:?Set GPU_PARTITION}"
: "${GPU_ACCOUNT:?Set GPU_ACCOUNT}"

NODES="${NODES:-2}"
GPUS_PER_NODE="${GPUS_PER_NODE:-4}"
CPUS_PER_GPU="${CPUS_PER_GPU:-16}"
MEM_PER_GPU_GB="${MEM_PER_GPU_GB:-60}"
CPUS_PER_TASK=$((GPUS_PER_NODE * CPUS_PER_GPU))
MEM_GB=$((GPUS_PER_NODE * MEM_PER_GPU_GB))
STORAGE_ROOT="${STORAGE_ROOT:-/project/${USER}}"

mkdir -p logs

sbatch \
  -p "${GPU_PARTITION}" \
  -A "${GPU_ACCOUNT}" \
  --nodes="${NODES}" \
  --ntasks-per-node=1 \
  --gres="gpu:${GPUS_PER_NODE}" \
  --cpus-per-task="${CPUS_PER_TASK}" \
  --mem="${MEM_GB}G" \
  --export=ALL,STORAGE_ROOT="${STORAGE_ROOT}",GPUS_PER_NODE="${GPUS_PER_NODE}",MAX_STEPS="${MAX_STEPS:-30000}",SAVE_STEPS="${SAVE_STEPS:-10000}",EXP_ID="${EXP_ID:-baseline}" \
  scripts/slurm/train_whu.sbatch
