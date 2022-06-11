import numpy as np
import networkx as nx
import itertools
import matplotlib.pyplot as plt
import random

clients=np.random.randint(5, size=(1,500))[0]
pros=np.random.randint(5, size=(1,20))[0]

all=np.concatenate([clients,pros])


all[0:len(clients)]
len(all[len(clients):])==len(pros)


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

clientes=[]
profs=[]

def interact_client(part):
    subject=all[part]
    most_similar_cli=[i for i in range(0,len(clients)) if np.isclose(subject, clients[i], rtol=1e-05, atol=degree_of_similarity, equal_nan=False)]
    most_similar_pro=[i for i in range(len(clients),len(all)) if np.isclose(subject, all[i], rtol=1e-05, atol=degree_of_similarity, equal_nan=False)]
    cc=random.choice(most_similar_cli)
    pp=random.choice(most_similar_pro)
    initial_condition=[clients[cc],all[part],all[pp]]
    clientes.append([part,cc])
    clientes.append([part,pp])
    #print(initial_condition)
    return cellular_automaton(initial_condition)

def interact_pros(part):
    subject2=all[part]
    most_similar_pros_cli=[i for i in range(0,len(clients)) if np.isclose(subject2, clients[i], rtol=1e-05, atol=degree_of_similarity, equal_nan=False)]
    most_similar_pros_pro=[i for i in range(len(clients),len(all)) if np.isclose(subject2, all[i], rtol=1e-05, atol=degree_of_similarity, equal_nan=False)]
    ccc=random.choice(most_similar_pros_cli)
    ppp=random.choice(most_similar_pros_pro)
    initial_condition=[clients[ccc],all[part],all[ppp]]
    profs.append([part,ppp])
    profs.append([part,ccc])
    #print(initial_condition)
    return cellular_automaton(initial_condition)


rule_of_interaction='similar'

degree_of_similarity=2

output_client=list(map(lambda x: interact_client(x),range(0,len(clients))))
output_client

output_pros=list(map(lambda x: interact_pros(x),range(len(clients),len(all))))
output_pros

edges=profs+clientes

#edges eh lista // nodes eh cada individuo

# nao esta diferenciando clientes de profissionais

G = nx.Graph()
#G.add_nodes_from(profs)
G.add_edges_from(e)
subax1 = plt.subplot(121)
nx.draw(G, with_labels=True, font_weight='bold')
plt.show()
