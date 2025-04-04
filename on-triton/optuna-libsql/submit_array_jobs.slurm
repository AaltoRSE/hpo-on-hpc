#!/bin/bash
#SBATCH --array=1-2
#SBATCH --cpus-per-task=4
#SBATCH --gpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --time=01:00:00
#SBATCH --output=logs/opt_job_%A_%a.out  # Separate log for each array job

module load mamba
source activate optuna_libsql  # Load Python environment

python -u optimization.py --study-name "my_study" --storage $OPTUNA_STORAGE \
    --n-trials 10 --n-jobs 1
