# JiguangPhantom

Competition repository for the Robbyant Embodied AI Challenge based on LingBot-VLA 2.0 and RoboTwin 2.0.

This repository is designed to run on either:

- NVIDIA Linux GPU platforms, including WHU HPC
- AMD Radeon Cloud / ROCm

Large model weights, datasets, checkpoints, caches, logs, and videos are not stored in Git.

## Clone

```bash
git clone --recurse-submodules https://github.com/tzss-100000/JiguangPhantom.git
cd JiguangPhantom
```

If the repository was cloned without submodules:

```bash
git submodule update --init --recursive
```

## NVIDIA: one-time setup

Run this on an allocated NVIDIA GPU node, not on a CPU-only login node.

Generic NVIDIA machine:

```bash
STORAGE_ROOT=/path/with/enough/space bash scripts/nvidia/bootstrap.sh
```

WHU HPC:

```bash
GPU_PARTITION=<partition> GPU_ACCOUNT=<account> \
STORAGE_ROOT=/project/$USER \
bash scripts/slurm/submit_whu_setup.sh
```

After setup, train on a generic NVIDIA GPU machine:

```bash
STORAGE_ROOT=/path/with/enough/space \
MAX_STEPS=30000 \
bash scripts/nvidia/train.sh
```

WHU HPC training:

```bash
GPU_PARTITION=<partition> GPU_ACCOUNT=<account> \
STORAGE_ROOT=/project/$USER \
NODES=2 GPUS_PER_NODE=4 MAX_STEPS=30000 \
bash scripts/slurm/submit_whu_train.sh
```

For a single 4-GPU node, use `NODES=1 GPUS_PER_NODE=4`.

## AMD Radeon Cloud: one-time setup

The AMD path uses the competition ROCm reproduction repository and its validated Docker stack.

```bash
bash scripts/amd/bootstrap.sh
```

Start the persistent training container:

```bash
bash scripts/amd/start_container.sh
```

Run full-parameter SFT:

```bash
GPU_COUNT=4 MAX_STEPS=30000 SAVE_STEPS=10000 \
bash scripts/amd/train.sh
```

Run a clean benchmark:

```bash
GPU_COUNT=4 EPISODES=10 bash scripts/amd/eval.sh
```

## Competition data rule

Training scripts use only the competition-designated RoboTwin 2.0 clean data.

Randomized data must not be added to the training list.

## Main directories

- `third_party/lingbot-vla-v2`: pinned upstream LingBot-VLA 2.0 source
- `scripts/setup`: shared setup helpers
- `scripts/nvidia`: NVIDIA training/data/evaluation entry points
- `scripts/amd`: AMD Radeon Cloud entry points
- `scripts/slurm`: WHU Slurm submission wrappers
- `configs`: path/platform/experiment configuration
- `experiments/results.csv`: experiment tracking
- `models`, `data`, `outputs`, `logs`: runtime-only data, ignored by Git
