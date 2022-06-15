extensions [ py ]

;;turtles-own [
  ;;flockmates         ;; agentset of nearby turtles
  ;;nearest-neighbor   ;; closest one of our flockmates
;;]

;;to setup
;;  clear-all
;;  py:setup py:python
;;  (py:run
;;    "import numpy as np"
;;    "import sklearn.cluster as cl"
;;  )
;;end

;;globals [ Cellular_Automata_Rule ] ;; wealth system

turtles-own [neighbor state]

;;links-own [weight]

to setup
  ca
  py:setup ;;"/home/anaconda/bin/python"
  py:python3
  py:run "import numpy as np"
  py:run "import itertools"
  py:run "import random"
  py:run "import collections"
  crt 100 [ setxy random-xcor random-ycor
    set shape "circle"
    set state one-of [True False]
    ifelse state
      [set color yellow]
      [set color red]
  ]
  ask turtles [ ;;edges
    set neighbor n-of 2 other turtles
    set state random 2
    create-links-with  other  neighbor
  ]

ask links [
    set color white
    ]
 repeat (count links) [ layout-spring turtles links 0.2 5 5 ]
  reset-ticks

end

to cellular_automata
    py:run "regra=30"
    py:run "base1=2"
    py:run "state=np.arange(0,base1)"
    (py:run "def cellular_automaton(kernel):"
           "    all_possible_states=np.array([p for p in itertools.product(state, repeat=3)])[::-1]"
           "    zeros_all_possible_states = np.zeros(all_possible_states.shape[0])"
           "    final_states = [int(i) for i in np.base_repr(int(regra),base=base1)]"
           "    length_rules=np.array(range(0,len(zeros_all_possible_states)))"
           "    final_state_central_cell=[]"
           "    for i in range(0,len(zeros_all_possible_states)):"
           "        final_state_central_cell.append([0,int(zeros_all_possible_states[i]),0])"
           "    initial_and_final_states=[]"
           "    for i in range(0,len(all_possible_states)):"
           "        initial_and_final_states.append(np.array([all_possible_states[i],np.array(final_state_central_cell).astype(np.int8)[i]]))"
           "    def ca(row):"
           "        out=[]"
           "        out.append(final_state_central_cell[next((i for i, val in enumerate(all_possible_states) if np.all(val == kernel)), -1)][1])"
           "        return out"
           "    final_state=np.array(ca(0))"
           "    return final_state")

  let final_state py:runresult "cellular_automaton([a,b,c])"
end

to go
  ask turtles [

    py:set "a" one-of [0 1]
    py:set "b" one-of [0 1]
    py:set "c" one-of [0 1]

    cellular_automata

    ifelse state = true
      [set state true set color yellow]
      [set state false set color red]
  ]
tick
end

;;to community-detection ;detect community using the louvain method
;;  color-clusters nw:louvain-communities
;;end

;;to closeness ;weighted closeness centrality by taking into consideration the weight variable assigned to directed links
;;  centrality [ -> nw:weighted-closeness-centrality weight]
;;end
