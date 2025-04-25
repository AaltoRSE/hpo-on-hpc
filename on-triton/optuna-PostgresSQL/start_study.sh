#!/bin/bash

module load mamba
source activate optuna_parallel

# Create study if it doesn't exist
if ! optuna studies --storage "$OPTUNA_STORAGE" | grep -qw "my_study"; then
    optuna create-study --study-name "my_study" --storage "$OPTUNA_STORAGE" --direction minimize
    echo "Study 'my_study' created successfully"
else
    echo "Study 'my_study' already exists"
fi 
