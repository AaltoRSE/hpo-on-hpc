# Optuna Optimization with libSQL on Triton - Single node

This directory contains scripts for running Optuna hyperparameter
optimization with libSQL on Triton with a single node setup.

## Files

- `submit_optuna_study.sh`: Main Slurm script that orchestrates
  the optimization process. It starts the libSQL database, creates
  the Optuna study and runs the optimization jobs.
- `start_db.sh`: Script to initialize libSQL database for Optuna
- `shutdown_db.sh`: Script to shutdown the libSQL database
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
2. Modify the SLURM parameters in `submit_optuna_study.sh` as needed
   (e.g., time limit, memory, GPUs).
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
3. Runs parallel optimization trials as separate task on multiple GPUs
4. It waits for completion and outputs results

## Requirements

- SLURM job scheduler
- libSQL server
- Optuna
- Python environment with required dependencies, see `env.yml`
