import optuna
import argparse
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
from sklearn.model_selection import train_test_split
from sklearn.datasets import make_classification

# Define a simple neural network
class SimpleNN(nn.Module):
    def __init__(self, input_size, num_layers, hidden_units, dropout_rate, activation):
        super(SimpleNN, self).__init__()
        layers = []
        for i in range(num_layers):
            in_features = input_size if i == 0 else hidden_units
            layers.append(nn.Linear(in_features, hidden_units))
            layers.append(nn.Dropout(dropout_rate))
            layers.append(nn.ReLU() if activation == 'relu' else 
                         nn.Tanh() if activation == 'tanh' else 
                         nn.Sigmoid())
        layers.append(nn.Linear(hidden_units, 1))
        self.model = nn.Sequential(*layers)

    def forward(self, x):
        return torch.sigmoid(self.model(x))

def build_model(input_size, num_layers, hidden_units, dropout_rate, activation):
    return SimpleNN(input_size, num_layers, hidden_units, dropout_rate, activation)

def train_model(model, train_loader, val_loader, learning_rate, weight_decay, epochs=10):
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    model = model.to(device)
    criterion = nn.BCELoss()
    optimizer = optim.Adam(model.parameters(), lr=learning_rate, weight_decay=weight_decay)
    
    for epoch in range(epochs):
        model.train()
        for inputs, targets in train_loader:
            inputs, targets = inputs.to(device), targets.to(device)
            optimizer.zero_grad()
            outputs = model(inputs)
            outputs = torch.clamp(outputs, 1e-7, 1 - 1e-7)
            loss = criterion(outputs, targets)
            loss.backward()
            optimizer.step()
    
    model.eval()
    val_loss = 0
    with torch.no_grad():
        for inputs, targets in val_loader:
            inputs, targets = inputs.to(device), targets.to(device)
            outputs = model(inputs)
            outputs = torch.clamp(outputs, 1e-7, 1 - 1e-7)
            val_loss += criterion(outputs, targets).item()
    return val_loss / len(val_loader)

def objective(trial):
    # Define hyperparameters
    learning_rate = trial.suggest_float('learning_rate', 1e-5, 1e-1, log=True)
    batch_size = trial.suggest_categorical('batch_size', [16, 32, 64, 128])
    num_layers = trial.suggest_int('num_layers', 1, 4)
    hidden_units = trial.suggest_int('hidden_units', 32, 512)
    dropout_rate = trial.suggest_float('dropout_rate', 0.0, 0.5)
    weight_decay = trial.suggest_float('weight_decay', 1e-6, 1e-2, log=True)
    activation = trial.suggest_categorical('activation', ['relu', 'tanh', 'sigmoid'])
    
    # Create model
    model = build_model(input_size=20, num_layers=num_layers, hidden_units=hidden_units,
                       dropout_rate=dropout_rate, activation=activation)
    
    # Create data loaders
    train_loader = DataLoader(train_dataset, batch_size=batch_size, num_workers=4, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, num_workers=4, shuffle=False)
    
    # Train and validate
    loss = train_model(model, train_loader, val_loader, learning_rate, weight_decay)
    return loss

if __name__ == "__main__":
    # Create synthetic dataset
    X, y = make_classification(n_samples=10000, n_features=20, n_classes=2, random_state=42)
    X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Convert to PyTorch tensors (keep on CPU for now)
    train_dataset = TensorDataset(torch.FloatTensor(X_train), torch.FloatTensor(y_train).unsqueeze(1))
    val_dataset = TensorDataset(torch.FloatTensor(X_val), torch.FloatTensor(y_val).unsqueeze(1))

    # Parse command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('--study-name', type=str, required=True)
    parser.add_argument('--storage', type=str, required=True)
    parser.add_argument('--n-trials', type=int, required=True)
    parser.add_argument('--n-jobs', type=int, required=True)
    args = parser.parse_args()

    # Load or create study
    try:
        study = optuna.load_study(study_name=args.study_name, storage=args.storage)
    except:
        study = optuna.create_study(study_name=args.study_name, storage=args.storage, direction='minimize')

    # Run optimization
    study.optimize(objective, n_trials=args.n_trials, n_jobs=args.n_jobs)
