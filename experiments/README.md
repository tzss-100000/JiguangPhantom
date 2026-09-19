# Experiment Management

All important training and evaluation runs should be recorded here.

## Experiment ID

Use sequential experiment IDs:

- exp001
- exp002
- exp003
- ...

## Configuration

Each experiment should have a configuration file:

```text
configs/experiments/<exp_id>.yaml

Example:

configs/experiments/exp001.yaml
Output

Training outputs should use:

/project/<username>/outputs/<exp_id>/

Do not commit checkpoints to Git.

Experiment Record

Record important experiments in:

experiments/results.csv

The following information should be preserved:

experiment ID
date
owner
Git branch
configuration
random seed
GPU count
training steps
clean evaluation result
randomized evaluation result
experiment status
notes
Competition Constraint

Only competition-designated RoboTwin 2.0 clean data may be used for training.

Randomized data may be used for evaluation only and must not be used as training data.
