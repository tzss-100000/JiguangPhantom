# JiguangPhantom

Competition repository for the Robbyant Embodied AI Challenge based on LingBot-VLA 2.0 and RoboTwin 2.0.

The repository supports AMD Radeon Cloud / ROCm and NVIDIA Linux GPU platforms (including WHU HPC).

Large models, datasets, checkpoints, caches, logs, and videos are not stored in Git.

## Clone

Clone the main repository first. Platform setup scripts fetch the exact upstream sources they need.

```bash
git clone https://github.com/tzss-100000/JiguangPhantom.git
cd JiguangPhantom
```

## AMD Radeon Cloud

On the AMD competition notebook/terminal:

```bash
bash scripts/run.sh setup
```

The setup script automatically chooses between the validated Docker workflow and the official native ROCm installation path. Docker is not required.

After setup, start a smoke training run:

```bash
GPU_COUNT=1 MAX_STEPS=1 SAVE_STEPS=1 EXP_ID=smoke bash scripts/run.sh train
```

Then run a real experiment, for example:

```bash
GPU_COUNT=4 MAX_STEPS=30000 SAVE_STEPS=10000 EXP_ID=baseline bash scripts/run.sh train
```

## NVIDIA GPU machine

Run setup on an allocated GPU node:

```bash
STORAGE_ROOT=/path/with/enough/space bash scripts/run.sh setup
```

Smoke train:

```bash
STORAGE_ROOT=/path/with/enough/space MAX_STEPS=1 EXP_ID=smoke bash scripts/run.sh train
```

Real train:

```bash
STORAGE_ROOT=/path/with/enough/space MAX_STEPS=30000 EXP_ID=baseline bash scripts/run.sh train
```

## WHU HPC

First setup:

```bash
GPU_PARTITION=<partition> GPU_ACCOUNT=<account> \
STORAGE_ROOT=/project/$USER \
bash scripts/slurm/submit_whu_setup.sh
```

Training example for two 4-GPU nodes:

```bash
GPU_PARTITION=<partition> GPU_ACCOUNT=<account> \
STORAGE_ROOT=/project/$USER \
NODES=2 GPUS_PER_NODE=4 MAX_STEPS=30000 EXP_ID=baseline \
bash scripts/slurm/submit_whu_train.sh
```

## Competition data rule

Training uses only the competition-designated RoboTwin 2.0 clean data. Randomized data must not be added to the training set.
