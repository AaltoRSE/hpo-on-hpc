import json
import itertools
import subprocess
import os

# Define the sbatch template as a string
SBATCH_TEMPLATE = """#!/bin/bash
#SBATCH --job-name=grid_search   # job name
#SBATCH --cpus-per-task=8         # cpu-cores per task
#SBATCH --mem=10G                 # total memory
#SBATCH --time=00:20:00           # time limit
#SBATCH --output=logs/grid_search_%j.out

# Load required modules
module purge
module load scicomp-python-env

# Run the training script
python -u main.py \\
    --epoch {epoch} \\
    --lr {lr} \\
    --batch_size {batch_size} \\
    --hidden_size {hidden_size} \\
    --save_path "checkpoints/model_epoch{epoch}_lr{lr}_bs{batch_size}_hs{hidden_size}_$SLURM_JOB_ID.pth"
"""

# Load hyperparameters from JSON
with open('hyperparams.json', 'r') as f:
    params = json.load(f)

# Get all combinations of hyperparameters
keys = list(params.keys())
values = list(params.values())
all_combinations = list(itertools.product(*values))

# Ensure the log directory exists
os.makedirs("logs", exist_ok=True)
os.makedirs("checkpoints", exist_ok=True)

for combination in all_combinations:
    # Generate the sbatch script content with the current hyperparameter combination
    sbatch_script_content = SBATCH_TEMPLATE.format(
        epoch=combination[0],
        lr=combination[1], 
        batch_size=combination[2],
        hidden_size=combination[3]
    )
    
    # Write the sbatch script to a temporary file
    sbatch_script_path = "tmp_sbatch.sh"
    with open(sbatch_script_path, "w") as script_file:
        script_file.write(sbatch_script_content)
    
    # Submit the job using subprocess
    try:
        result = subprocess.run(["sbatch", sbatch_script_path], check=True, capture_output=True, text=True)
        job_id = result.stdout.split()[-1]  # Extract job ID from sbatch output
        print(f"Submitted job {job_id} with params: {combination}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to submit job: {e.stderr}")
    
    # Delete the temporary sbatch script
    os.remove(sbatch_script_path)
