# Optuna Optimization with libSQL on LUMI

This directory contains scripts for running Optuna hyperparameter
optimization with libSQL on a single LUMI node.

## Files

- `submit.slurm`: Main SLURM script that orchestrates the optimization process
- `start_db.sh`: Script to initialize libSQL database for Optuna
- `shutdown_db.sh`: Script to shutdown libSQL database for Optuna
- `create_study.py`: Script to configure the Optuna study
- `optimization.py`: The actual optimization code that runs the model
- `check_results.py`: Checks the best optimization.

## Usage

1. Download libsql server:
   ```bash
   wget https://github.com/tursodatabase/libsql/releases/download/libsql-server-v0.24.32/libsql-server-x86_64-unknown-linux-gnu.tar.xz
   tar xf libsql-server-x86_64-unknown-linux-gnu.tar.xz
   ```
2. Install the PyTorch container:
   ```bash
   # Set his path to your actual project folder
   export EBU_USER_PREFIX=/pfs/lustrep2/scratch/project_XXXXXXXXX/easybuild
   module load LUMI partition/container EasyBuild-user
   eb PyTorch-2.6.0-rocm-6.2.4-python-3.12-singularity-20250404.eb
   ```

3. Install extra packages alongside PyTorch container:
   ```bash
   module load LUMI  PyTorch/2.6.0-rocm-6.2.4-python-3.12-singularity-20250404
   pip install -r requirements.txt
   ```

4. Submit the job to SLURM:
   ```bash
   sbatch submit.slurm
   ```
5. Monitor progress by viewing the logs in `logs/`

## Process Flow

1. Starts libSQL server
2. Configures Optuna study
3. Runs multiple optimizations on different GPUs
4. Waits for completion and outputs results

## Requirements

- SLURM job scheduler
- libSQL server
- Optuna
- Python environment with required dependencies, see `requirement.txt`
