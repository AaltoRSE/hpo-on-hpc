#!/bin/bash
#SBATCH --job-name=wandb_sweep
#SBATCH --output=sweep_%A_%a.out
#SBATCH --error=sweep_%A_%a.err
#SBATCH --array=1-2
#SBATCH --mem=30G
#SBATCH --ntasks=1
#SBATCH --gpus=1
#SBATCH --partition=gpu-debug
# Add other SBATCH directives as needed (time, partition, memory, etc.)

# Load necessary modules
module purge
module load scicomp-python-env

# Set your wandb entity name
ENTITY_NAME='tiany4-aalto-university'
# Set your project name
PROJECT_NAME='hpc-sweep'

# If this is the first array task, create the sweep
if [ $SLURM_ARRAY_TASK_ID -eq 1 ]; then
    # Login to wandb using the API key
    wandb login $WANDB_API_KEY

    # Create a temporary file to store the sweep output
    TEMP_FILE=$(mktemp)

    # Run the sweep command and redirect all output to the temp file
    wandb sweep --project "$PROJECT_NAME" --entity "$ENTITY_NAME" sweep.yaml &> "$TEMP_FILE"

    # Display the output
    cat "$TEMP_FILE"

    # Try to extract the ID using various methods
    SWEEP_ID=$(grep -oP 'with ID: \K[^\s]+' "$TEMP_FILE" || 
               grep -oP 'Created sweep with ID: \K[^\s]+' "$TEMP_FILE" ||
               grep -oP 'agent \K[^ ]+$' "$TEMP_FILE" || 
               grep -oP '/sweeps/\K[^\s]+' "$TEMP_FILE")

    echo "Extracted Sweep ID: $SWEEP_ID"
    
    # Save the sweep ID to a file so other array tasks can read it
    echo "$SWEEP_ID" > sweep_id.txt
    
    # Clean up
    rm "$TEMP_FILE"
else
    # Wait for the sweep ID file to be created by the first task
    while [ ! -f sweep_id.txt ]; do
        sleep 5
    done
    
    # Read the sweep ID from the file
    SWEEP_ID=$(cat sweep_id.txt)
    
    # Login to wandb
    wandb login $WANDB_API_KEY
fi

echo "Task $SLURM_ARRAY_TASK_ID starting agent for sweep $SWEEP_ID"

# Run the wandb agent with the training script
wandb agent "$ENTITY_NAME/$PROJECT_NAME/$SWEEP_ID" --count 12



