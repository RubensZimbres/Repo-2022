from ast import While
import numpy as np
import networkx as nx
import itertools
import matplotlib.pyplot as plt
import random
from matplotlib.pyplot import figure, text
from matplotlib.animation import FuncAnimation
from time import time
import glob
from PIL import Image
from itertools import count
import matplotlib as mpl

regra=2159062512564987644819455219116893945895958528152021228705752563807962227809675103689306
base1=5
length_clients=200
length_pros=20
degree_of_similarity=2

clients=np.random.randint(5, size=(1,length_clients))[0]
pros=np.random.randint(5, size=(1,length_pros))[0]

all=np.concatenate([clients,pros])

states=np.arange(0,base1)
dimensions=3


def cellular_automaton(kernel):
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
    return cellular_automaton(initial_condition)

## LOOP

m=50
while m>0:
    m=m-1
    output_client=list(map(lambda x: interact_client(x),range(0,len(clients))))
    output_pros=list(map(lambda x: interact_pros(x),range(len(clients),len(all))))
    all=np.concatenate([output_client,output_pros]).reshape(1,-1)[0]
    clients=all[0:length_clients]
    pros=all[length_clients:]

    edges=profs+clientes
    nodes=np.arange(0,len(all))

    G = nx.Graph()
    G.add_nodes_from(nodes)
    G.add_edges_from(edges)
    pos = nx.spectral_layout(G)
    list_degree=list(G.degree())
    nodes , degree = map(list, zip(*list_degree))
    mapa=dict(np.transpose(np.array([nodes,all])))
    cores=[]
    for value in list(mapa.values())[0:length_clients]:
        if value<2:
            cores.append('red')
        if value>2:
            cores.append('green')
        if value==2:
            cores.append('yellow')
    for value in list(mapa.values())[length_clients:]:
        cores.append('blue')

    fig, ax = plt.subplots(figsize=(20, 16))
    fig.subplots_adjust(bottom=0.5)    
    d = dict(G.degree())

    #nx.draw(G, with_labels=False, font_weight='light',linewidths=2,width=0.3,node_color=cores,node_size=[(v * 7)+1 for v in degree], cmap=plt.cm.jet)
    ec = nx.draw_networkx_edges(G, pos, alpha=0.2)
    nc = nx.draw_networkx_nodes(G, pos, nodelist=nodes, node_color=cores, 
                             node_size=[(v * 7)+1 for v in degree], cmap='RdYIGn',node_shape='H')
    cmap = (mpl.colors.ListedColormap(['red', 'orange', 'yellow', 'green']).with_extremes(over='0.25', under='0.75'))

    bounds = [0, 1, 2, 3, 4]
    #norm = mpl.colors.BoundaryNorm(bounds, cmap.N)
    norm = mpl.colors.BoundaryNorm(bounds, cmap.N)
    cbar=plt.colorbar(mpl.cm.ScalarMappable(cmap=cmap, norm=norm))
    cbar.set_label(label='Quality Perception', size='xx-large', weight='bold')
    cbar.ax.tick_params(labelsize='large')
    #ax.set_ylabel('Quality Perception', fontsize=40) 
    #plt.colorbar(nc)
    plt.axis('off')
    plt.savefig('/home/theone/Documents/MBA_spectral_sim00/foo{}.png'.format(time()))


fp_in = "/home/theone/Documents/MBA_spectral_sim00/foo*.png"
fp_out = "/home/theone/Documents/MBA_spectral_movie_sim00_Red.gif"

img, *imgs = [Image.open(f) for f in sorted(glob.glob(fp_in))]
img.save(fp=fp_out, format='GIF', append_images=imgs,
         save_all=True, duration=700, loop=0)
