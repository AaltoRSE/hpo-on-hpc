import argparse
import torch
import torch.nn as nn
from torchvision import datasets, transforms

class SimpleNN(nn.Module):
    def __init__(self, input_size=784, hidden_size=128, num_classes=10):
        super(SimpleNN, self).__init__()
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(hidden_size, num_classes)
    
    def forward(self, x):
        out = self.fc1(x)
        out = self.relu(out)
        out = self.fc2(out)
        return out

def train_model(args):
    model = SimpleNN(input_size=784, hidden_size=args.hidden_size, num_classes=10)
    optimizer = torch.optim.Adam(model.parameters(), lr=args.lr)
    criterion = nn.CrossEntropyLoss()
    
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
    ])
    
    train_dataset = datasets.MNIST(root='./data', train=True, download=True, transform=transform)
    test_dataset = datasets.MNIST(root='./data', train=False, transform=transform)
    
    train_loader = torch.utils.data.DataLoader(dataset=train_dataset, 
                                              batch_size=args.batch_size, 
                                              shuffle=True)
    test_loader = torch.utils.data.DataLoader(dataset=test_dataset, 
                                             batch_size=args.batch_size, 
                                             shuffle=False)

    for epoch in range(args.epoch):
        model.train()
        running_loss = 0.0
        for inputs, labels in train_loader:
            inputs = inputs.view(-1, 784)
            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            running_loss += loss.item()
        
        model.eval()
        correct = 0
        total = 0
        with torch.no_grad():
            for inputs, labels in test_loader:
                inputs = inputs.view(-1, 784)
                outputs = model(inputs)
                _, predicted = torch.max(outputs.data, 1)
                total += labels.size(0)
                correct += (predicted == labels).sum().item()
        
        accuracy = 100 * correct / total
        print(f'Epoch [{epoch+1}/{args.epoch}], Loss: {running_loss/len(train_loader):.4f}, Accuracy: {accuracy:.2f}%')
    
    print(f"Final test accuracy: {accuracy:.2f}%")

    if args.save_path:
        torch.save(model.state_dict(), args.save_path)
    else:
        torch.save(model.state_dict(), 'model.pth')

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--epoch", default=10, type=int, help="The number of training epoch")
    parser.add_argument("--lr", default=0.01, type=float, help="Learning rate")
    parser.add_argument("--batch_size", default=256, type=int, help="Training batch size")
    parser.add_argument("--hidden_size", default=128, type=int, help="Hidden layer size")
    parser.add_argument('--save_path', type=str, default='', 
                       help='Path to save the trained model')
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()  
    print(args)
    train_model(args)    
