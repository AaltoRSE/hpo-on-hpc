#!/bin/bash
#SBATCH --job-name=libsql-optuna
#SBATCH --cpus-per-task=1
#SBATCH --mem=10GB
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --time=01:00:00
#SBATCH --output=logs/main_%j.out

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
python create_study.py --study-name "$OPTUNA_STUDY" --storage "$OPTUNA_STORAGE"

# 3. Submit the optimization job and get the job ID
# This submits an array job that will run multiple optimization trials in parallel
job_id=$(sbatch submit_array_jobs.slurm | awk '{print $4}')

# Wait for the array job to complete
# Continuously check job status until it's no longer in the queue
while squeue -j $job_id > /dev/null 2>&1; do
    sleep 60
done

echo "Job $job_id completed successfully"
echo "Optimization process finished. Results stored in libSQL database."

# Check the results and find the best parameters
python -u check_results.py --study-name "$OPTUNA_STUDY" --storage "$OPTUNA_STORAGE"

# Shut down the libSQL database
source ./shutdown_db.sh
