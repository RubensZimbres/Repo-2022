import numpy as np
import itertools
import numpy as np
import matplotlib.pyplot as plt

regra=2159062512564987644819455219116893945895958528152021228705752563807959237655911950549124
base1=5
states=np.arange(0,base1)
dimensions=5
kernel=[[1, 0, 1, 0, 1],
       [0, 1, 0, 1, 0],
       [0, 0, 1, 0, 0],
       [0, 1, 0, 1, 0],
       [1, 0, 1, 0, 1]]

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
