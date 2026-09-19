#!/usr/bin/env bash
#SBATCH --job-name=jiguang-train
#SBATCH --time=1-00:00:00
#SBATCH --output=logs/train-%j.out
#SBATCH --error=logs/train-%j.err
set -euo pipefail

cd "${SLURM_SUBMIT_DIR}"

MASTER_ADDR="$(scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -n1)"
MASTER_PORT="${MASTER_PORT:-29500}"
GPUS_PER_NODE="${GPUS_PER_NODE:-4}"
TOTAL_GPUS=$((SLURM_NNODES * GPUS_PER_NODE))

export MASTER_ADDR MASTER_PORT
export NNODES="${SLURM_NNODES}"
export TOTAL_GPUS
export STORAGE_ROOT="${STORAGE_ROOT:-/project/${USER}}"

srun --ntasks="${SLURM_NNODES}" --ntasks-per-node=1 bash -lc '
  export NODE_RANK="${SLURM_PROCID}"
  export NPROC_PER_NODE="${GPUS_PER_NODE}"
  bash scripts/nvidia/train.sh
'
