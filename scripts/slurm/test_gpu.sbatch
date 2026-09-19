#!/bin/bash

#SBATCH --job-name=jiguang-gpu-test
#SBATCH --partition=GPU_PARTITION
#SBATCH --account=GPU_ACCOUNT

#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1

#SBATCH --gres=gpu:1

#SBATCH --time=00:10:00

#SBATCH --output=logs/gpu-test-%j.out
#SBATCH --error=logs/gpu-test-%j.err

set -e

echo "========================================"
echo "JiguangPhantom GPU Test"
echo "========================================"

echo "Job ID:"
echo "${SLURM_JOB_ID}"

echo
echo "Node:"
hostname

echo
echo "CUDA_VISIBLE_DEVICES:"
echo "${CUDA_VISIBLE_DEVICES}"

echo
echo "GPU:"
nvidia-smi

echo
echo "========================================"
echo "PyTorch"
echo "========================================"

source ~/.bashrc

if conda env list | grep -q "^lingbotvla "; then
    conda activate lingbotvla

    python - <<'PY'
import torch

print("PyTorch:", torch.__version__)
print("CUDA runtime:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())
print("Visible GPUs:", torch.cuda.device_count())

for i in range(torch.cuda.device_count()):
    print(i, torch.cuda.get_device_name(i))
PY
else
    echo "lingbotvla environment not created yet."
fi
