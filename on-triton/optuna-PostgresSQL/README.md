# Optuna Optimization with PostgreSQL on Triton

This directory contains scripts for running Optuna hyperparameter optimization with PostgreSQL on Triton using SLURM job scheduling.

## Files

- `submit.slurm`: Main SLURM script that orchestrates the optimization process
- `start_db.sh`: Script to initialize PostgreSQL database for Optuna
- `start_study.sh`: Script to configure the Optuna study
- `submit_array_jobs.slurm`: Script to submit parallel optimization trials

## Usage

1. Install the example environment:
   ```bash
   module load mamba
   mamba env create -f env.yml
   ```
2. Modify the SLURM parameters in `submit.slurm` as needed (e.g., time limit, memory)
3. Submit the job to SLURM:
   ```bash
   sbatch submit.slurm
   ```
4. Monitor progress:
   - Check job status: `squeue -j <job_id>`
   - View output logs: `logs/`

## Process Flow

1. Starts PostgreSQL database
2. Configures Optuna study
3. Submits parallel optimization trials
4. Waits for completion and outputs results

## Requirements

- SLURM job scheduler
- PostgreSQL
- Optuna
- Python environment with required dependencies, see `env.yml`
