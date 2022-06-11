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
import collections

np.random.seed(222)
regra=30 #2159062512564987644819455219116893945895958528152021228705752563807959237655911950549124 #thesis
#2159062512564987644819455219116893945895958528152021228705752563807962227809675103689306
base1=2 #5
length_clients=200
length_pros=20
degree_of_similarity=2
environment_noise=0



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
sum_each=[]
sum_each1=[]
sum_each2=[]
sum_each3=[]
sum_each4=[]

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

mean_cli=[]
mean_pro=[]

m=80
while m>0:
    m=m-1
    output_client=list(map(lambda x: interact_client(x),range(0,len(clients))))
    output_pros=list(map(lambda x: interact_pros(x),range(len(clients),len(all))))
    all=[int(i*1-environment_noise) for i in np.concatenate([output_client,output_pros]).reshape(1,-1)[0]]
    clients=all[0:length_clients]
    pros=all[length_clients:]
    mean_cli.append(np.mean(clients))
    mean_pro.append(np.mean(pros))
    sum_each.append(np.transpose(all.count(0)))
    sum_each1.append(np.transpose(all.count(1)))
    sum_each2.append(np.transpose(all.count(2)))
    sum_each3.append(np.transpose(all.count(3)))
    sum_each4.append(np.transpose(all.count(4)))
    edges=profs+clientes
    nodes=np.arange(0,len(all))

    G = nx.Graph()
    G.add_nodes_from(nodes)
    G.add_edges_from(edges)
    pos = nx.spring_layout(G) #nx.spectral_layout(G)
    list_degree=list(G.degree())
    nodes , degree = map(list, zip(*list_degree))
    mapa=dict(np.transpose(np.array([nodes,all])))
    cores=[]
    if base1<3:
        for value in list(mapa.values())[0:length_clients]:
            if value==int(base1/2):
                cores.append('black')
            if value!=int(base1/2):
                cores.append('gray')
        for value in list(mapa.values())[length_clients:]:
            cores.append('blue')
    else:
        for value in list(mapa.values())[0:length_clients]:
            if value<int(base1-1/2):
                cores.append('red')
            if value>int(base1-1/2):
                cores.append('blue')
            if value==int(base1-1/2):
                cores.append('yellow')

        for value in list(mapa.values())[length_clients:]:
            cores.append('black')

    fig, ax = plt.subplots(ncols=1, nrows=3,figsize=(15, 15),gridspec_kw={'height_ratios': [3, 1,1]})
    #fig.subplots_adjust(bottom=0.5)    
    d = dict(G.degree())
    if base1>=3:
        cmap=mpl.cm.get_cmap('jet_r')
    else:
        cmap=mpl.cm.get_cmap('gray_r')
    #nx.draw(G, with_labels=False, font_weight='light',linewidths=2,width=0.3,node_color=cores,node_size=[(v * 7)+1 for v in degree], cmap=plt.cm.jet)
    plt.subplot(311)
    ec = nx.draw_networkx_edges(G, pos, alpha=0.2)
    nc = nx.draw_networkx_nodes(G, pos, nodelist=nodes, node_color=cores, 
                             node_size=[(v * 7)+1 for v in degree], cmap=cmap,node_shape='H')
    #cmap = (mpl.colors.ListedColormap(['red', 'orange', 'yellow', 'green']).with_extremes(over='0.25', under='0.75'))

    #bounds = [0, 1, 2, 3, 4]
    #norm = mpl.colors.BoundaryNorm(bounds, cmap.N)
    norm = mpl.colors.Normalize(vmin=0, vmax=4)
    cbar=plt.colorbar(mpl.cm.ScalarMappable(cmap=cmap, norm=norm))
    cbar.set_label(label='Quality Perception', size='xx-large', weight='bold')
    cbar.ax.tick_params(labelsize='large')
    #ax.set_ylabel('Quality Perception', fontsize=40) 
    #plt.colorbar(nc)
    plt.axis('off')
    plt.subplot(312)
    plt.plot(mean_cli, color='red', label='Clients average perception')
    plt.plot(mean_pro, color='blue', label='Professionals average perception')
    leg=plt.legend(fontsize=15)
    for line in leg.get_lines():
        line.set_linewidth(3.0)
    plt.subplot(313)
    plt.plot(sum_each, label='Count of zeros', color='red')
    plt.plot(sum_each1, label='Count of 1s', color='orange')
    plt.plot(sum_each2, label='Count of 2s', color='yellow')
    plt.plot(sum_each3, label='Count of 3s', color='green')
    plt.plot(sum_each4, label='Count of 4s', color='blue')
    leg=plt.legend(fontsize=15)
    for line in leg.get_lines():
        line.set_linewidth(3.0)

    plt.tight_layout()
    plt.savefig('/home/theone/Documents/MBA_binary_noise/foo{}.png'.format(time()))


fp_in = "/home/theone/Documents/MBA_binary_noise/foo*.png"
fp_out = "/home/theone/Documents/MBA_binary_noise_movie.gif"

img, *imgs = [Image.open(f) for f in sorted(glob.glob(fp_in))]
img.save(fp=fp_out, format='GIF', append_images=imgs,
         save_all=True, duration=1200, loop=0)
