#!/bin/bash
#SBATCH --array=1-2
#SBATCH --cpus-per-task=4
#SBATCH --gpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --time=00:30:00
#SBATCH --output=logs/opt_job_%A_%a.out  # Separate log for each array job

module load mamba
  # Load Python environment
source activate optuna_libsql

# Check that needed variables are set
[[ -z ${OPTUNA_STUDY} ]] && { echo 'OPTUNA_STUDY is not set'; exit 1; }
[[ -z ${OPTUNA_STORAGE} ]] && { echo 'OPTUNA_STORAGE is not set'; exit 1; }
[[ -z ${LIBSQL_TOKEN} ]] && { echo 'LIBSQL_TOKEN is not set'; exit 1; }

# Run 5 trials per job
python -u optimization.py \
    --study-name "$OPTUNA_STUDY" \
    --storage "$OPTUNA_STORAGE" \
    --auth-token "$LIBSQL_TOKEN" \
    --n-trials 5 --n-jobs 1
