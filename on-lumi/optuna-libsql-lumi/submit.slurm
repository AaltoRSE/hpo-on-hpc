#!/bin/bash
#SBATCH --job-name=optuna_optimization
#SBATCH --account=project_462000365
#SBATCH --time=00:15:00
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --cpus-per-gpu=7
#SBATCH --gpus-per-node=8
#SBATCH --mem=480G
#SBATCH --partition=standard-g
#SBATCH --output=logs/optuna_optimization_%j.out

set -o pipefail
module load LUMI
module load PyTorch/2.6.0-rocm-6.2.4-python-3.12-singularity-20250404

# 1. Start the libSQL Database
# This step initializes the libSQL database that will store Optuna's study data

echo "Starting libsql server ..."
source ./start_db.sh

# 2. Setup the Optuna study
# This step creates and configures the Optuna study with specified parameters
echo "Setting up Optuna study..."

echo "Connecting to libsql with the following connector: "$OPTUNA_STORAGE

python create_study.py --study-name "my_study" --storage $OPTUNA_STORAGE

# Wait for study setup to complete
sleep 5

# 3. Start optimizer
# This step starts multiple optimizers on different GPUs
srun --cpus-per-gpu=$SLURM_CPUS_PER_GPU --gpus-per-task=1 --ntasks=$SLURM_GPUS_PER_NODE \
    python -u optimization.py \
        --study-name "my_study" \
        --storage $OPTUNA_STORAGE \
        --n-trials 2 --n-jobs 1

# Gather results
python -u check_results.py --study-name "my_study" --storage $OPTUNA_STORAGE

# Shut down the libSQL database
source ./shutdown_db.sh
