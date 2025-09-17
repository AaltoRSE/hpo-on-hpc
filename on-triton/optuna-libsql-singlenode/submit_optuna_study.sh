#!/bin/bash
#SBATCH --job-name=libsql-optuna
#SBATCH --mem=80GB
#SBATCH --cpus-per-gpu=4
#SBATCH --gpus-per-node=4
#SBATCH --nodes=1
#SBATCH --time=01:00:00
#SBATCH --output=logs/optimization_%j.out

# 1. Start the libSQL Database
# This step initializes the libSQL database that will store Optuna's study data
# and it will set environment variables needed by the database connection

echo "Starting libsql server ..."
source ./start_db.sh

# 2. Setup the Optuna study
# This step creates and configures the Optuna study
echo "Setting up Optuna study..."

# Set the study name.
# Needed by submit_array_jobs.slurm to determine which study to use.
export OPTUNA_STUDY="my_study"

# Load mamba and activate the environment
module load mamba
source activate optuna_libsql

# Create the study
python create_study.py \
    --study-name "$OPTUNA_STUDY" \
    --storage "$OPTUNA_STORAGE" \
    --auth-token "$LIBSQL_TOKEN"

# 3. Run multiple optimization tasks. One per GPU.
srun --cpus-per-gpu=$SLURM_CPUS_PER_GPU --gpus-per-task=1 --ntasks=$SLURM_GPUS_PER_NODE \
    python -u optimization.py \
        --study-name "$OPTUNA_STUDY" \
        --storage "$OPTUNA_STORAGE" \
        --auth-token "$LIBSQL_TOKEN" \
        --n-trials 5 --n-jobs 1

echo "Optimization process finished. Results stored in libSQL database."

# Check the results and find the best parameters
python -u check_results.py \
    --study-name "$OPTUNA_STUDY" \
    --storage "$OPTUNA_STORAGE" \
    --auth-token "$LIBSQL_TOKEN"

# Shut down the libSQL database
source ./shutdown_db.sh
