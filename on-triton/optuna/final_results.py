import optuna
import os

# Connect to your study using environment variables
study = optuna.load_study(
    study_name="my_study",  # Get study name from env var
    storage=os.getenv("OPTUNA_STORAGE")    # Get storage URL from env var
)

# Get all trials
trials = study.trials

# Print basic info
print(f"Study name: {study.study_name}")
print(f"Number of trials: {len(trials)}")
print(f"Best trial value: {study.best_trial.value}")
print(f"Best parameters: {study.best_trial.params}")
print(f"Best trial index: {study.best_trial.number}")

