import torch
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
import pandas as pd
import random

np.random.seed(222)
regra=2159062512564987644819455219116893945895958528152021228705752563807959237655911950549124 #thesis
#2159062512564987644819455219116893945895958528152021228705752563807962227809675103689306
base1=5
length_clients=370
length_pros=30
degree_of_similarity=2
environment_noise=0

#datasets: https://chatox.github.io/networks-science-course/practicum/data/



df=pd.read_csv('/home/theone/other_models/SantaFe/social.csv', sep=',',header=None)

df=df.iloc[0:length_clients+length_pros,:]

people=np.unique(np.array(df).reshape(1,-1)[0])

node_attr = dict(zip(people, range(0,len(np.unique(np.array(df).reshape(1,-1)[0])))))

df.columns=['from','to']

df['from2'] = df['from'].replace(node_attr, regex=True)

df['to2'] = df['to'].replace(node_attr, regex=True)

df2=df.iloc[:,2:]

edges0=np.array(df2)

clients=[]
pros=[]
distribution_clients = torch.tensor([0.6, .2, .1, .1,0])
c = torch.distributions.categorical.Categorical(distribution_clients)
import itertools
for _ in itertools.repeat(None, length_clients):
    clients.append(c.sample())

distribution_pros = torch.tensor([0, .1, .1, .1,0.7])
c4 = torch.distributions.categorical.Categorical(distribution_pros)
for _ in itertools.repeat(None, length_pros):
    pros.append(c4.sample())


all=np.concatenate([np.array(clients),np.array(pros)])

states=np.arange(0,base1)
dimensions=3


nodes=np.arange(0,len(all))
G = nx.Graph() #nx.from_pandas_edgelist(df2, 'from2', 'to2') #
G.add_nodes_from(nodes)
G.add_edges_from(edges0)

individuals=np.arange(0,len(all))

x=np.random.uniform(-1, 1, len(all))
y=x=np.random.uniform(-1, 1, len(all))

coordinates=np.array([x,y]).reshape(-1,2)

pos=dict(zip(individuals,coordinates))




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
coord_update=np.zeros(len(individuals))


def distances(a,list):
    out=[]
    for o in list:
        out.append(np.linalg.norm(a-o))
    return out


def interact_client(part):
    subject=all[part]
    most_similar_cli=[i for i in range(0,len(clients)) if np.isclose(subject, clients[i], rtol=0.5, atol=degree_of_similarity, equal_nan=False)]
    most_similar_pro=[i for i in range(len(clients),len(all)) if np.isclose(subject, all[i], rtol=0.5, atol=degree_of_similarity, equal_nan=False)]
    ## saber com quem esta interagindo
    cc=np.where(distances(coordinates[part],coordinates[most_similar_cli])==np.min(distances(coordinates[part],coordinates[most_similar_cli])))[0]
    pp=np.where(distances(coordinates[part],coordinates[most_similar_pro])==np.min(distances(coordinates[part],coordinates[most_similar_pro])))[0]
    cc=random.choice(cc)
    pp=random.choice(pp)
    initial_condition=[clients[cc],all[part],all[pp]]
    clientes.append([part,cc])
    clientes.append([part,pp])
    cc2=np.arange(0,len(clients))[cc]
    pp2=np.arange(0,len(all))[pp]
    pos.update({individuals[part]:np.mean([coordinates[cc2],coordinates[pp2]],axis=0)})
    return cellular_automaton(initial_condition)

def interact_pros(part):
    subject2=all[part]
    most_similar_pros_cli=[i for i in range(0,len(clients)) if np.isclose(subject2, clients[i], rtol=0.5, atol=degree_of_similarity, equal_nan=False)]
    most_similar_pros_pro=[i for i in range(len(clients),len(all)) if np.isclose(subject2, all[i], rtol=0.5, atol=degree_of_similarity, equal_nan=False)]
    ccc=np.where(distances(coordinates[part],coordinates[most_similar_pros_cli])==np.min(distances(coordinates[part],coordinates[most_similar_pros_cli])))[0]
    ppp=np.where(distances(coordinates[part],coordinates[most_similar_pros_pro])==np.min(distances(coordinates[part],coordinates[most_similar_pros_pro])))[0]
    ccc=random.choice(ccc)
    ppp=random.choice(ppp)
    initial_condition=[clients[ccc],all[part],all[ppp]]
    profs.append([part,ppp])
    profs.append([part,ccc])
    ccc2=np.arange(0,len(clients))[ccc]
    ppp2=np.arange(0,len(all))[ppp]
    pos.update({individuals[part]:np.mean([coordinates[ccc2],coordinates[ppp2]],axis=0)})
    return cellular_automaton(initial_condition)


## LOOP

mean_cli=[]
mean_pro=[]
degree_c=[]
closeness=[]

iter=20
iterations=iter


while iterations>0:
    try:
        output_client=list(map(lambda x: interact_client(x),range(0,len(clients))))
        output_pros=list(map(lambda x: interact_pros(x),range(len(clients),len(all))))
        all=[int(i*1-environment_noise) for i in np.concatenate([output_client,output_pros]).reshape(1,-1)[0]]
        clients=all[0:length_clients]
        pros=all[length_clients:]
        mean_cli.append(np.mean(clients))
        mean_pro.append(np.mean(pros))
        if base1==2:
            sum_each.append(np.transpose(all.count(0)))
            sum_each1.append(np.transpose(all.count(1)))
        else:
            sum_each.append(np.transpose(all.count(0)))
            sum_each1.append(np.transpose(all.count(1)))
            sum_each2.append(np.transpose(all.count(2)))
            sum_each3.append(np.transpose(all.count(3)))
            sum_each4.append(np.transpose(all.count(4)))


        # update nodes e edges restart graph
        edges=profs+clientes
        G.clear()
        for u in range(0,len(all)):
            G.add_node(all[u],pos=(list(pos.values())[u][0],list(pos.values())[u][1]))
        G.add_edges_from(edges)        
        
        list_degree=list(G.degree())
        nodes , degree = map(list, zip(*list_degree))
        mapa=dict(np.transpose(np.array([nodes,all])))
        cores=[]
        if base1==2:
            for value in list(mapa.values())[0:length_clients]:
                if value==1:
                    cores.append('blue')
                if value==0:
                    cores.append('red')
            for value in list(mapa.values())[length_clients:]:
                cores.append('gray')
        else:
            for value in list(mapa.values())[0:length_clients]:
                if value<3:
                    cores.append('red')
                if value==3:
                    cores.append('yellow')
                if value>3:
                    cores.append('blue')

            for value in list(mapa.values())[length_clients:]:
                cores.append('gray')
        degree_central=nx.degree_centrality(G)
        degree_c.append(np.mean(list(degree_central.values())))
        #Degree centrality assigns an importance score based simply on the number of links held by each node.
        closeness_central=nx.closeness_centrality(G)
        closeness.append(np.mean(list(closeness_central.values())))
        #Closeness centrality scores each node based on their ‘closeness’ to all other nodes in the network.
        fig, ax = plt.subplots(ncols=1, nrows=5,figsize=(11, 17),gridspec_kw={'height_ratios': [3, 1.2,1.2,1.2,1.2]})
        d = dict(G.degree())
        if base1>=3:
            cmap=mpl.cm.get_cmap('jet_r')
        else:
            cmap=mpl.cm.get_cmap('jet_r')
        plt.subplot(511)
        #tamanhos=[v*100 for v in degree_central.values()]
        
        ec = nx.draw_networkx_edges(G, pos, alpha=0.1)
        nc = nx.draw_networkx_nodes(G, pos, nodelist=nodes, node_color=cores, node_size=38, cmap=cmap)
        norm = mpl.colors.Normalize(vmin=0, vmax=4)
        cbar=plt.colorbar(mpl.cm.ScalarMappable(cmap=cmap, norm=norm))
        cbar.set_label(label='Quality Perception', size='xx-large', weight='bold')
        cbar.ax.tick_params(labelsize='large')
        #plt.text(-0.5,-0.1, "CA rule: {}".format(regra), size=12, ha="center")
        plt.axis('off')
        plt.subplot(512)
        plt.plot(mean_cli, color='red', label='Clients average perception')
        plt.plot(mean_pro, color='blue', label='Professionals average perception')
        leg=plt.legend(fontsize=12,loc = "upper left")
        for line in leg.get_lines():
            line.set_linewidth(3.0)
        plt.subplot(513)
        if base1==2:
            plt.plot(sum_each, label='Count of zeros', color='red')
            plt.plot(sum_each1, label='Count of 1s', color='orange')
        else:
            plt.plot(sum_each, label='Count of zeros', color='red')
            plt.plot(sum_each1, label='Count of 1s', color='orange')
            plt.plot(sum_each2, label='Count of 2s', color='yellow')
            plt.plot(sum_each3, label='Count of 3s', color='green')
            plt.plot(sum_each4, label='Count of 4s', color='blue')

        leg=plt.legend(fontsize=12,loc = "upper left")
        for line in leg.get_lines():
            line.set_linewidth(3.0)
        plt.subplot(514)
        plt.plot(degree_c, color='black', label='Degree centrality (average # links)')
        leg=plt.legend(fontsize=12,loc = "upper left")
        for line in leg.get_lines():
            line.set_linewidth(3.0)
        plt.subplot(515)
        plt.plot(closeness, color='green', label='Closeness centrality (average closeness)')
        leg=plt.legend(fontsize=12,loc = "upper left")
        for line in leg.get_lines():
            line.set_linewidth(3.0)

        plt.tight_layout()
        plt.savefig('/home/theone/Documents/MBA_output/foo{}.png'.format(time()))
        print(iterations)
        iterations=iterations-1
        print(list(pos.values())[0])
    except:
        pass

fp_in = "/home/theone/Documents/MBA_output/foo*.png"
fp_out = "/home/theone/Documents/MBA_github_completo_LINDO_circular.gif"

img, *imgs = [Image.open(f) for f in sorted(glob.glob(fp_in))]
img.save(fp=fp_out, format='GIF', append_images=imgs,
         save_all=True, duration=1200, loop=0)
