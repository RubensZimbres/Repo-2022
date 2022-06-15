extensions [ py ]

globals [
  percent-similar  ; on the average, what percent of a turtle's neighbors
                   ; are the same color as that turtle?
]


turtles-own [neighbor neighbor-state state similar-nearby
  nearest-neighbor total-nearby other-nearby similar-nearby2 ]


to setup
  ca
  py:setup
  py:python3
  py:run "import numpy as np"
  py:run "import itertools"
  py:run "import random"
  py:run "import collections"
  crt 200 [ setxy random-xcor random-ycor
    set shape "circle"
    set state one-of [0 1 2 3 4]
    set size 0.5
    set neighbor-state one-of [0 1 2 3 4]
    if state = 0 [set color red]
      if state = 1 [set color orange]
        if state = 2 [set color yellow]
          if state = 3 [set color green]
            if state = 4 [set color blue]
      
  ]
  reset-ticks
end


to cellular_automata
    py:set "a" neighbor-state
    py:set "b" state
    py:set "c" neighbor-state
    py:run "regra=2159062512564987644819455219116893945895958528152021228705752563807959237655911950549124"
    py:run "base1=5"
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

  let final-state py:runresult "cellular_automaton([a,b,c])[0]"
  set state final-state
    if state = 0 [set color red]
      if state = 1 [set color orange]
        if state = 2 [set color yellow]
          if state = 3 [set color green]
            if state = 4 [set color blue]


end



to update-turtles
  ask turtles [

    carefully[set similar-nearby n-of 2 turtles with [ color = [ color ] of myself ]]
    [find-new-spot
      stop]


    set similar-nearby2 count (turtles-on neighbors)  with [ color = [ color ] of myself ]

    set total-nearby similar-nearby2 + other-nearby
    set neighbor n-of 2 similar-nearby

    ;;forward 0.5
    ;;create-links-with other neighbor

    cellular_automata



    ]

end

to find-new-spot
  rt random-float 180
  fd random-float 30
  if any? other turtles-here [ find-new-spot ] ;
  move-to patch-here  ; move to center of patch
end

to update-globals
  let similar-neighbors sum [ similar-nearby ] of turtles
  let total-neighbors sum [ total-nearby ] of turtles

  set percent-similar (similar-neighbors / total-neighbors) * 100
end

to go
  update-turtles
  update-globals

  tick
end


;;to community-detection ;detect community using the louvain method
;;  color-clusters nw:louvain-communities
;;end

;;to closeness ;weighted closeness centrality by taking into consideration the weight variable assigned to directed links
;;  centrality [ -> nw:weighted-closeness-centrality weight]
;;end
