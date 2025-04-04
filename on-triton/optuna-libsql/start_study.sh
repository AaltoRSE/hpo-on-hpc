#!/bin/bash

module load mamba
source activate optuna_libsql

# Create study if it doesn't exist
optuna create-study --study-name "my_study" --storage ${OPTUNA_STORAGE} --direction minimize --skip-if-exists
