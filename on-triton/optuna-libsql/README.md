# Optuna Optimization with libSQL on Triton

This directory contains scripts for running Optuna hyperparameter
optimization with libSQL on Triton using Slurm job scheduling.

## Files

- `submit_optuna_study.sh`: Main Slurm script that orchestrates
  the optimization process. It starts the libSQL database, creates
  the Optuna study and submits optimization jobs.
- `start_db.sh`: Script to initialize libSQL database for Optuna
- `shutdown_db.sh`: Script to shutdown the libSQL database
- `submit_optimization_array.sh`: Script to submit parallel optimization trials.
- `create_study.py`: Python script that configures the Optuna study
- `optimization.py`: Python script that contains the actual optimization code.
  Modify this to match your task and your optimization goals.
- `check_results.py`: Python script that checks what was the best trial.

## Usage

1. Install the example environment:
   ```bash
   module load mamba
   mamba env create -f env.yml
   ```
2. Modify the SLURM parameters in `submit_optuna_study.sh` and
   `submit_optimization_array.sh` as needed (e.g., time limit, memory, GPUs).
   Remember that `submit_optuna_study.sh` should have a time limit that is
   longer than `submit_optimization_array.sh` because the libSQL server needs
   to be running for the trials to be registered.
3. Submit the job to Slurm:
   ```bash
   sbatch submit_optuna_study.sh
   ```
4. Monitor progress:
   - Check job status: `squeue -j <job_id>`
   - View output logs: `logs/`

## Process Flow

`submit.slurm` does the following:

1. It starts a libSQL server
2. It configures an  Optuna study (in `create_study.py`)
3. It submits parallel optimization trials as an array job
4. It waits for completion and outputs results

Each job submitted by `submit_optimization_array.sh` will run their
study and report back to the libSQL server.

## Requirements

- SLURM job scheduler
- libSQL server
- Optuna
- Python environment with required dependencies, see `env.yml`
