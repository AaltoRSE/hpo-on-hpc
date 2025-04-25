#!/bin/bash
#SBATCH --job-name=pg-optuna
#SBATCH --cpus-per-task=4
#SBATCH --mem=10GB
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --time=00:03:00
#SBATCH --output=logs/main_%j.out

# 1. Start the PostgreSQL Database
# This step initializes the PostgreSQL database that will store Optuna's study data
echo "Starting PostgreSQL Database ..."
source ./start_db.sh

# Wait for database to fully initialize
sleep 30

# 2. Setup the Optuna study
# This step creates and configures the Optuna study with specified parameters
echo "Setting up Optuna study..."
source ./start_study.sh

# Wait for study setup to complete
sleep 30

# 3. Submit the optimization job and get the job ID
# This submits an array job that will run multiple optimization trials in parallel
job_id=$(sbatch submit_array_jobs.slurm | awk '{print $4}')

# Wait for the job to complete
# Continuously check job status until it's no longer in the queue
while squeue -j $job_id > /dev/null 2>&1; do
    sleep 60
done

# Final completion message
echo "Job $job_id completed successfully"
echo "Optimization process finished. Results stored in PostgreSQL database."

# Load mamba and activate the environment
module load mamba
source activate optuna_parallel

# Run the final results script
python -u final_results.py
