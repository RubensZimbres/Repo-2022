extensions [ py nw]

globals [
  percent-similar
  ticks-to-run
]


turtles-own [neighbor-left neighbor-right neighbor-left-state neighbor-right-state state similar-nearby
  nearest-neighbor total-nearby other-nearby community]


to setup
  ca
  ask patches [ set pcolor black ]

  crt amount-turtles-unhappy [ setxy random-xcor random-ycor

    set shape "default"
    set size 0.8
    set neighbor-left one-of other turtles in-radius radius-of-interaction
    set neighbor-right one-of other turtles in-radius radius-of-interaction
    set state 0
    set neighbor-left-state one-of [ 0 1 ]
    set neighbor-right-state one-of [ 0 1 ]

    set size 1
    if state = 0 [ set color red ]
      if state = 1 [ set color green ]

  ]

  crt amount-turtles-happy [ setxy random-xcor random-ycor

    set shape "default"
    set size 0.8
    set neighbor-left one-of other turtles in-radius radius-of-interaction
    set neighbor-right one-of other turtles in-radius radius-of-interaction
    set state 1
    set neighbor-left-state one-of [ 0 1 ]
    set neighbor-right-state one-of [ 0 1 ]

    set size 1
    if state = 0 [ set color red ]
      if state = 1 [ set color green ]
  ]
  reset-ticks
end


to cellular_automata
    py:setup
    py:python3
    py:set "a" neighbor-left-state
    py:set "b" state
    py:set "c" neighbor-right-state
    py:set "rule" Cellular-Automaton-rule
    py:run "regra=rule"
    py:run "base1=2"
    py:run "import numpy as np"
    py:run "import itertools"
    py:run "import random"
    py:run "import collections"
    py:run "state=np.arange(0,base1)"
    (py:run "def cellular_automaton(kernel):"
           "    all_possible_states=np.array([p for p in itertools.product(state, repeat=3)])[::-1]"
           "    zeros_all_possible_states = np.zeros(all_possible_states.shape[0])"
           "    final_states = [int(i) for i in np.base_repr(int(regra),base=base1)]"
           "    zeros_all_possible_states[-len(final_states):]=final_states"
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
    if state = 0 [ set color red ]
      if state = 1 [ set color green ]

end



to update-turtles
  let step 0
  ask turtles [
    
    carefully[ set neighbor-left one-of other turtles in-radius radius-of-interaction ]
    [ find-new-spot
      stop]
    carefully[ set neighbor-right one-of other turtles in-radius radius-of-interaction ]
    [ find-new-spot
    stop]
    
    set similar-nearby count ( turtles-on neighbors ) in-radius radius-of-interaction

    set total-nearby similar-nearby + other-nearby

    cellular_automata
      if state = 0
    [ find-new-spot
    ]


]
set step (step + 1)

end

to find-new-spot
  rt random-float movement-steps
  fd random-float movement-steps
  if any? other turtles-here [ find-new-spot ]
  move-to patch-here  ; move to center of patch
end

to update-globals
  let similar-neighbors sum [ similar-nearby ] of turtles
  let total-neighbors sum [ total-nearby ] of turtles

  set percent-similar ( similar-neighbors / total-neighbors ) * 100
end

to go
  update-turtles
  update-globals

end
