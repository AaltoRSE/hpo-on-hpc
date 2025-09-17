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

    try:
        study = optuna.load_study(study_name=args.study_name, storage=storage)
        print("Study already exists!")
    except:
        study = optuna.create_study(study_name=args.study_name, storage=storage, direction='minimize')
