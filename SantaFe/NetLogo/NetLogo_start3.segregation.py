extensions [ py ]

globals [
  percent-similar  ; on the average, what percent of a turtle's neighbors
                   ; are the same color as that turtle?
]

;;to setup
;;  clear-all
;;  py:setup py:python
;;  (py:run
;;    "import numpy as np"
;;    "import sklearn.cluster as cl"
;;  )
;;end


turtles-own [neighbor neighbor-state state similar-nearby 
  nearest-neighbor total-nearby other-nearby similar-nearby2]

;;links-own [weight]

to setup
  ca
  py:setup ;;"/home/anaconda/bin/python"
  py:python3
  py:run "import numpy as np"
  py:run "import itertools"
  py:run "import random"
  py:run "import collections"
  crt 200 [ setxy random-xcor random-ycor
    set shape "circle"
    set state one-of [False True]
    set size 0.7
    ifelse state
      [set color green]
      [set color red]
  ]


ask links [
    set color white
    ]
 repeat (count links) [ layout-spring turtles links 0.2 5 5 ]
  update-turtles
  update-globals
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

  let final-state py:runresult "cellular_automaton([a,b,c])"
end

to go
  ask turtles [
    update-turtles
  ]
tick
end

to update-turtles
  ask turtles [
    set similar-nearby n-of 2 turtles  with [ color = [ color ] of myself ]
    set similar-nearby2 count (turtles-on neighbors)  with [ color = [ color ] of myself ]
    set total-nearby similar-nearby2 + other-nearby
    set neighbor n-of 2 similar-nearby
    ;;set neighbor-state random 2


    forward 0.5
    create-links-with other neighbor
    py:set "a" neighbor-state
    py:set "b" state
    py:set "c" neighbor-state

    cellular_automata

    ifelse state = 0
      [set state 0 set color yellow]
      [set state 1 set color red]


    ]
 
end
to move-unhappy-turtles
  ask turtles with [ not similar-nearby ]
    [ find-new-spot ]
end
to find-new-spot
  rt random-float 360
  fd random-float 10
  if any? other turtles-here [ find-new-spot ] ; keep going until we find an unoccupied patch
  move-to patch-here  ; move to center of patch
end

to update-globals
  let similar-neighbors sum [ similar-nearby ] of turtles
  let total-neighbors sum [ total-nearby ] of turtles

  set percent-similar (similar-neighbors / total-neighbors) * 100
end

;;to community-detection ;detect community using the louvain method
;;  color-clusters nw:louvain-communities
;;end

;;to closeness ;weighted closeness centrality by taking into consideration the weight variable assigned to directed links
;;  centrality [ -> nw:weighted-closeness-centrality weight]
;;end
