import os
import argparse
import optuna

if __name__=="__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--study-name', type=str, required=True)
    parser.add_argument('--storage', type=str, required=True)
    args = parser.parse_args()

    storage = optuna.storages.RDBStorage(
        url=args.storage,
        engine_kwargs={
            "connect_args": {
                "auth_token": os.getenv("LIBSQL_TOKEN"),
            }
        }
    )

    study = optuna.load_study(study_name=args.study_name, storage=storage)

    # Get all trials
    trials = study.trials

    # Print basic info
    print(f"Study name: {study.study_name}")
    print(f"Number of trials: {len(trials)}")
    print(f"Best trial value: {study.best_trial.value}")
    print(f"Best parameters: {study.best_trial.params}")
    print(f"Best trial index: {study.best_trial.number}")

