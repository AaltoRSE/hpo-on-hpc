#!/bin/bash
#SBATCH --job-name=pg-optuna
#SBATCH --cpus-per-task=4
#SBATCH --mem=10GB
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --time=10:30:00
#SBATCH --output=logs/pg_optuna_%j.out

# 1. Start the PostgreSQL Database
echo "Starting PostgreSQL Database ..."
source ./start_db.sh

sleep 30

# 2. Setup the Optuna study
echo "Setting up Optuna study..."
source ./start_study.sh

sleep 30

# 3. Submit the optimization job and get the job ID
job_id=$(sbatch submit_array_jobs.slurm | awk '{print $4}')

# Wait for the job to complete
while squeue -j $job_id > /dev/null 2>&1; do
    sleep 60
done

echo "Job $job_id completed"