import wandb
import torch
import torch.optim as optim
import torch.nn.functional as F
import torch.nn as nn
from torchvision import datasets, transforms

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print("device: ", device)

def train(config=None):
    # Initialize a new wandb run
    with wandb.init(config=config):
        config = wandb.config

        train_loader, val_loader = build_dataset(config.batch_size)
        network = build_network(config.fc_layer_size, config.dropout)
        optimizer = build_optimizer(network, config.optimizer, config.learning_rate)

        for epoch in range(config.epochs):
            train_loss = train_epoch(network, train_loader, optimizer)
            val_loss, val_accuracy = validate(network, val_loader)
            wandb.log({
                "loss": train_loss, 
                "val_loss": val_loss,
                "val_accuracy": val_accuracy
            })

def build_dataset(batch_size):
    transform = transforms.Compose(
        [transforms.ToTensor(),
         transforms.Normalize((0.1307,), (0.3081,))])
    
    train_dataset = datasets.MNIST(".", train=True, download=True,
                             transform=transform)
    train_loader = torch.utils.data.DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    
    val_dataset = datasets.MNIST(".", train=False, download=True, transform=transform)
    val_loader = torch.utils.data.DataLoader(val_dataset, batch_size=batch_size)
    
    return train_loader, val_loader


def build_network(fc_layer_size, dropout):
    network = nn.Sequential(
        nn.Flatten(),
        nn.Linear(784, fc_layer_size), nn.ReLU(),
        nn.Dropout(dropout),
        nn.Linear(fc_layer_size, 10),
        nn.LogSoftmax(dim=1))

    return network.to(device)
        

def build_optimizer(network, optimizer, learning_rate):
    if optimizer == "sgd":
        optimizer = optim.SGD(network.parameters(),
                              lr=learning_rate, momentum=0.9)
    elif optimizer == "adam":
        optimizer = optim.Adam(network.parameters(),
                               lr=learning_rate)
    return optimizer


def train_epoch(network, loader, optimizer):
    network.train()
    cumu_loss = 0
    log_interval = len(loader) // 10
    
    for batch_idx, (data, target) in enumerate(loader):
        data, target = data.to(device), target.to(device)
        optimizer.zero_grad()

        loss = F.nll_loss(network(data), target)
        cumu_loss += loss.item()

        loss.backward()
        optimizer.step()

    return cumu_loss / len(loader)

def validate(network, loader):
    network.eval()  # Set model to evaluation mode
    val_loss = 0
    correct = 0
    
    with torch.no_grad():
        for data, target in loader:
            data, target = data.to(device), target.to(device)
            output = network(data)
            val_loss += F.nll_loss(output, target, reduction='sum').item()
            pred = output.argmax(dim=1, keepdim=True)
            correct += pred.eq(target.view_as(pred)).sum().item()
            
    val_loss /= len(loader.dataset)
    accuracy = 100. * correct / len(loader.dataset)
    
    return val_loss, accuracy


if __name__ == '__main__':
    train()