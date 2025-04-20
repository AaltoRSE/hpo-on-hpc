# Hyperparameter Grid Search via SLURM Array Jobs

This example contains a Python script for submitting multiple SLURM jobs to perform hyperparameter grid search for a machine learning model.

## Usage
1. Prepare your script to accept parameters via command line arguments, checkout ```main.py```
2. Prepare a `hyperparams.json` file with your desired hyperparameter ranges. Example:

```json
{
    "epoch": [10, 20, 30],
    "lr": [0.001, 0.01, 0.1],
    "batch_size": [32, 64, 128],
    "hidden_size": [64, 128, 256]
}
```

3. Run the submission script:
```bash
python submit_jobs.py
```
4. Collect and analyze results

## Script Details

The script will:
1. Generate all possible combinations of hyperparameters
2. Create temporary SLURM submission scripts for each combination
3. Submit jobs to the SLURM queue
4. Clean up temporary files

## Output

- Model checkpoints will be saved with names indicating their hyperparameters
- Log files will be created in the `logs/` directory

## Customization

You can modify the `SBATCH_TEMPLATE` in `submit_jobs.py` to adjust:
- Resource requirements (CPU, memory, time)
- Job name
- Output directory
- ...
