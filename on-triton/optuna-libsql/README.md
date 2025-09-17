# Optuna Optimization with libSQL on Triton

This directory contains scripts for running Optuna hyperparameter
optimization with libSQL on Triton using SLURM job scheduling.

## Files

- `submit.slurm`: Main SLURM script that orchestrates the optimization process
- `start_db.sh`: Script to initialize libSQL database for Optuna
- `start_study.sh`: Script to configure the Optuna study
- `submit_array_jobs.slurm`: Script to submit parallel optimization trials.
  Insert your code here.

## Usage

1. Install the example environment:
   ```bash
   module load mamba
   mamba env create -f env.yml
   ```
2. Modify the SLURM parameters in `submit.slurm` and `submit_array_jobs.slurm`
   as needed (e.g., time limit, memory, GPUs). Remember that `submit.slurm`
   should have a time limit that is longer than `submit_array_jobs.slurm`
   because the libsql server needs to be running for the trials to be
   registered.
3. Submit the job to SLURM:
   ```bash
   sbatch submit.slurm
   ```
4. Monitor progress:
   - Check job status: `squeue -j <job_id>`
   - View output logs: `logs/`

## Process Flow

`submit.slurm` does the following:

1. It starts a libSQL server
2. It configures an  Optuna study (in `start_study.sh`)
3. It submits parallel optimization trials as an array job
4. It waits for completion and outputs results

Each job submitted by `submit_array_jobs.slurm` will run their
study and report back to the libsql server.

## Requirements

- SLURM job scheduler
- libSQL server
- Optuna
- Python environment with required dependencies, see `env.yml`
