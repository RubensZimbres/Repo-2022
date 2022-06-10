import numpy as np
import networkx
import itertools

clients=np.random.randint(5, size=(1,100))[0]
pros=np.random.randint(5, size=(1,8))[0]

print(clients)
print(pros)

regra=2159062512564987644819455219116893945895958528152021228705752563807962227809675103689306
base1=5
states=np.arange(0,base1)
dimensions=3


def cellular_automaton(kernel):
#    global kernel
    lista=states

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
        out.append(final_state_central_cell[next((i for i, val in enumerate(all_possible_states) if np.all(val == kernel)), -1)][1])
        return out

    final_state=np.array(ca(0))

    return final_state

def interact(part,cc,pp):
    initial_condition=[clients[cc],clients[part],pros[pp]]
    print(initial_condition)
    return cellular_automaton(initial_condition)

interact(40,3,2)
