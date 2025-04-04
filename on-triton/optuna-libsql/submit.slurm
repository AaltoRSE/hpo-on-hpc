#!/bin/bash
#SBATCH --job-name=libsql-optuna
#SBATCH --cpus-per-task=1
#SBATCH --mem=10GB
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --time=00:03:00
#SBATCH --output=logs/main_%j.out

# 1. Start the PostgreSQL Database
# This step initializes the libSQL database that will store Optuna's study data

echo "Starting libsql server ..."
source ./start_db.sh

# 2. Setup the Optuna study
# This step creates and configures the Optuna study with specified parameters
echo "Setting up Optuna study..."

source ./start_study.sh

# Wait for study setup to complete
sleep 5

# 3. Submit the optimization job and get the job ID
# This submits an array job that will run multiple optimization trials in parallel
job_id=$(sbatch submit_array_jobs.slurm | awk '{print $4}')

# Wait for the job to complete
# Continuously check job status until it's no longer in the queue
while squeue -j $job_id > /dev/null 2>&1; do
    sleep 60
done

echo "Job $job_id completed successfully"
echo "Optimization process finished. Results stored in libSQL database."

# Load mamba and activate the environment
module load mamba
source activate optuna_libsql

# Run the final results script
python -u final_results.py
