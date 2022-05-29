import numpy as np
import itertools
import numpy as np
import torch
import torchvision
import matplotlib.pyplot as plt
from time import time
from torchvision import datasets, transforms
from torch import nn, optim
import torch.nn.functional as F
import torch.nn as nn

regra=2159062512564987644819455219116893945895958528152021228705752563807959237655911950549124
base1=5
states=np.arange(0,base1)
dimensions=5

## KERNEL 5x5

kernel=[[1, 0, 1, 0, 1],
       [0, 1, 0, 1, 0],
       [0, 0, 1, 0, 0],
       [0, 1, 0, 1, 0],
       [1, 0, 1, 0, 1]]

def cellular_automaton():
    global kernel

    lista=states
    kernel=np.pad(kernel, (1, 1), 'constant', constant_values=(0))
    kernel[0]=kernel[1]
    kernel[-1]=kernel[-2]

    kernel2=np.transpose(kernel)
    kernel2[0]=kernel2[1]
    kernel2[-1]=kernel2[-2]

    kernel=np.transpose(kernel2)

    all_possible_states=np.array([p for p in itertools.product(lista, repeat=3)])[::-1]

    zeros_all_possible_states = np.zeros(all_possible_states.shape[0])
    final_states = [int(i) for i in np.base_repr(int(regra),base=base1)]
    zeros_all_possible_states[-len(final_states):]=final_states
    length_rules=np.array(range(0,len(zeros_all_possible_states)))

    final_state_central_cell=[]
    for i in range(0,len(zeros_all_possible_states)):
        final_state_central_cell.append([0,int(zeros_all_possible_states[i]),0])

    initial_and_final_states=[]
    for i in range(0,len(all_possible_states)):
        initial_and_final_states.append(np.array([all_possible_states[i],np.array(final_state_central_cell).astype(np.int8)[i]]))


    def ca(row):
        out=[]
        for cell in range(0,dimensions):
            out.append(final_state_central_cell[next((i for i, val in enumerate(all_possible_states) if np.all(val == kernel[row][cell:cell+3])), -1)][1])
        return out

    kernel=np.array([item for item in map(ca,range(1,kernel.shape[0]-1))])
    return kernel


device = torch.device("cuda")

batch_size1=1000

train_loader = torch.utils.data.DataLoader(
  torchvision.datasets.MNIST('/home/theone/other_models/mnist', train=True, download=True,
                             transform=torchvision.transforms.Compose([
                               torchvision.transforms.ToTensor(),
                               torchvision.transforms.Normalize(
                                 (0.0,), (1.,))
                             ])),
  batch_size=batch_size1, shuffle=True)

test_loader = torch.utils.data.DataLoader(
  torchvision.datasets.MNIST('/home/theone/other_models/mnist', train=False, download=True,
                             transform=torchvision.transforms.Compose([
                               torchvision.transforms.ToTensor(),
                               torchvision.transforms.Normalize(
                                 (0.0,), (1,))
                             ])),
  batch_size=batch_size1, shuffle=True)


class Net(nn.Module):
    def __init__(self,kernel):
        super(Net, self).__init__()
        self.conv1 = nn.Conv2d(32, 64, 3, 1,bias=False)
        self.conv2 = nn.Conv2d(1, 64, 10, 1,bias=False)
        self.dropout1 = nn.Dropout(0.2)
        self.dropout2 = nn.Dropout(0.4)
        self.fc1 = nn.Linear(3136, 28*28)
        self.fc2 = nn.Linear(28*28, 128)
        self.fc3 = nn.Linear(128, 10)
        torch.nn.init.xavier_uniform(self.conv1.weight)
        torch.nn.init.xavier_uniform(self.conv2.weight)
        torch.nn.init.xavier_uniform(self.fc1.weight)
        torch.nn.init.xavier_uniform(self.fc2.weight)
        torch.nn.init.xavier_uniform(self.fc3.weight)
        self.batch_norm = nn.BatchNorm1d(3136)
        self.conv1.weight = nn.Parameter(kernel,requires_grad=False)


    def forward(self, x):
        res = x.view(batch_size1, 784)
        x = self.conv1(x)
        x = F.relu(x)
        x = self.conv2(x)
        x = nn.MaxPool2d(2, 2)(x)
        x = F.relu(x)
        x = self.dropout1(x)
        x = torch.flatten(x, 1)
        x = self.batch_norm(x)
        x = self.fc1(x)
        x = F.relu(x)
        x = self.fc2(torch.mean(torch.stack((x,res)),0))
        x = F.relu(x)
        x = self.dropout2(x)
        x = self.fc3(x)
        output = F.log_softmax(x, dim=1)
        return output

import torch.optim as optim

n_epochs = 2000
learning_rate = 0.001 # from 0.01
momentum1=0.6 #from 0.9
log_interval = 500
train_losses = []
test_losses = []
test_counter = [i*len(train_loader.dataset) for i in range(n_epochs + 1)]

def norm(x):
    return (x-x.min())/(x.max()-x.min())

c=torch.from_numpy(norm(cellular_automaton()).astype(np.float16).reshape(-1,1,dimensions,dimensions)).type(torch.cuda.FloatTensor)

net = Net(c).to(device)
optimizer = optim.SGD(net.parameters(), lr=learning_rate,momentum=momentum1)


def train(epoch):
  net.train()
  checkpoint = torch.load('/home/user/model_acc_99.29_377.pth')
  net.load_state_dict(checkpoint)
  for batch_idx, (data, target) in enumerate(train_loader):
    data, target = data.to(device), target.to(device)
    optimizer.zero_grad()
    output = net(data)
    loss = F.cross_entropy(output, target)
    loss.backward()
    optimizer.step()
    if batch_idx % log_interval == 0:
      print('Train Epoch: {} [{}/{} ({:.0f}%)]\tLoss: {:.6f}'.format(
        epoch, batch_idx * len(data), len(train_loader.dataset),
        100. * batch_idx / len(train_loader), loss.item()))
      train_losses.append(loss.item()) 


def test():
    net.eval()
    test_loss = 0
    correct = 0
    with torch.no_grad():        
        for data, target in test_loader:
            data, target = data.to(device), target.to(device)
            try:
              output = net(data)
              test_loss += F.cross_entropy(output, target, reduction='sum').item()
              pred = output.argmax(1, keepdim=True)
              correct += pred.eq(target.data.view_as(pred)).sum().item()
            except:
              pass
        test_loss /= len(test_loader.dataset)
        test_losses.append(test_loss)
        print('\nTest set: Avg. loss: {:.4f}, Accuracy: {}/{} ({:.6f}%)\n'.format(
                test_loss, correct, len(test_loader.dataset),
                100. * correct / len(test_loader.dataset)))
        torch.save(net.state_dict(), '/home/user/results/model_acc_{1}_{0}.pth'.format(epoch,100. * correct / len(test_loader.dataset)))

from tqdm import tqdm
for epoch in tqdm(range(1, n_epochs + 1)):
    train(epoch)
    test()

examples = enumerate(test_loader)
batch_idx, (example_data, example_targets) = next(examples)


with torch.no_grad():
    model = Net(c)
    checkpoint = torch.load('/home/user/results/model_acc_99.29_377.pth')
    model.load_state_dict(checkpoint)
    index = 100
    item = example_data
    image = item.to('cpu')
    true_target = example_targets[index].to('cpu')
    prediction = model.to('cpu')(image)
    predicted_class = np.argmax(prediction[index])
    image = image[index].reshape(28, 28, 1)
    plt.imshow(image, cmap='gray')
    plt.title(f'Prediction: {predicted_class} - Actual target: {true_target}')
    plt.show()

model_parameters = filter(lambda p: p.requires_grad, model.parameters())
params = sum([np.prod(p.size()) for p in model_parameters])
print(params)
