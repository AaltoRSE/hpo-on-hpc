# Hyperparameter Optimization with Weights & Biases Sweeps on HPC

This example contains code for training a simple neural network using Weights & Biases (wandb) for hyperparameter optimization on an HPC cluster with SLURM array jobs.

## Files

### 1. `train.py`
The main training script that:
- Builds a simple neural network for MNIST classification
- Supports configurable hyperparameters (learning rate, optimizer, etc.)
- Logs metrics to Weights & Biases
- Includes functions for dataset preparation, model building, training, and validation

### 2. `submit_sweep.slurm`
A SLURM job script that:
- Launches a wandb sweep on an HPC cluster
- Uses job arrays to run multiple sweep agents in parallel
- Handles sweep creation and agent coordination

### 3. `sweep.yaml`
A configuration file that defines the hyperparameter search space.

## Set your wandb API key as an environment variable:
```bash
export WANDB_API_KEY=your_api_key_here
```

## Usage

Submit the SLURM job to start the sweep:
```bash
sbatch submit_sweep.slurm
```

The script will:
1. Create a new sweep in your wandb project
2. Launch multiple agents to run experiments with different hyperparameters
3. Log results to your wandb dashboard

## Customization

- Modify `train.py` to use a different model architecture or dataset
- Adjust the SLURM parameters in `submit_sweep.slurm` based on your cluster's resources
- Update the wandb entity and project names in the SLURM script
- Modify the `sweep.yaml` file to define your hyperparameter search space

## Monitoring

Monitor your sweep progress in the Weights & Biases dashboard at: https://wandb.ai/[your-entity]/[your-project]/sweeps 