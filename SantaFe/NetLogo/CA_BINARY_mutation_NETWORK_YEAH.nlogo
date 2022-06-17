extensions [ py nw ]

directed-link-breed [ directed-edges directed-edge ]
undirected-link-breed [ undirected-edges undirected-edge ]

globals [
  percent-similar
  clients
  providers
  neighborss-state
  neighborss
  nb-nodes
  ticks-to-run
  population
  individuals-mutate
  neighborhood-size
 highlighted-node                ; used for the "highlight mode" buttons to keep track of the currently highlighted node
  highlight-bicomponents-on       ; indicates that highlight-bicomponents mode is active
  stop-highlight-bicomponents     ; indicates that highlight-bicomponents mode needs to stop
  highlight-maximal-cliques-on    ; indicates highlight-maximal-cliques mode is active
  stop-highlight-maximal-cliques  ; indicates highlight-maximal-cliques mode needs to stop
]


turtles-own [neighbor-left neighbor-right neighbor-left-state neighbor-right-state state similar-nearby
  nearest-neighbor total-nearby other-nearby community]


to setup
  ca
  set-current-plot "Degree distribution"
  ask patches [ set pcolor black ]
  crt 30 [ setxy random-xcor random-ycor
    
    set shape "default"
    set size 0.8
    set neighbor-left one-of other turtles in-radius radius-of-interaction
    set neighbor-right one-of other turtles in-radius radius-of-interaction
    set state 0
    set neighborss-state one-of [ 0 1 ]


    
    set size 1
    if state = 0 [ set color red ]
      if state = 1 [ set color green ]

  ]

  crt 30 [ setxy random-xcor random-ycor
    
    set shape "default"
    set size 0.8
    set neighbor-left one-of other turtles in-radius radius-of-interaction ;;;;;;;;;;;;
    set neighbor-right one-of other turtles in-radius radius-of-interaction ;;;;;;;;;;;;;
    set state 1
    set neighborss-state one-of [ 0 1 ]

    set size 1
    if state = 0 [ set color red ]
      if state = 1 [ set color green ]
  ]
  set neighborhood-size 2
  set nb-nodes 60
    py:setup
    py:python3
  reset-ticks

end


;to preferential-attachment
 ; generate [ -> nw:generate-preferential-attachment turtles get-links-to-use nb-nodes 1 [set color green
  ;  setxy  random-xcor random-ycor ]]
;end


;to-report get-links-to-use
;  report ifelse-value (links-to-use = "directed")
;    [ directed-edges ]
;    [ undirected-edges ]
;end

to generate [ generator-task ]
  if clear-before-generating [ setup ] ;?
  ; we have a general "generate" procedure that basically just takes a task
  ; parameter and runs it, but takes care of calling layout and update plots
  run generator-task
  ;layout-turtles
  update-plots
end


;to generate-random
 ; generate  [ -> nw:generate-random  turtles links nb-nodes connection-prob [set color green
  ;  setxy  random-xcor random-ycor ]]
  
;end


;to layout-turtles

;    let root-agent max-one-of turtles [ count my-links ]
 ;   layout-radial turtles links root-agent
  ;display
;end

; Colorizes each node according to the community it is part of
to community-detection
  nw:set-context turtles links ;;get-links-to-use
  color-clusters nw:louvain-communities
end

to find-biggest-cliques
  if links-to-use != "undirected" [
    user-message "Maximal cliques only work with undirected links."
    stop
  ]
  nw:set-context turtles undirected-edges
  color-clusters nw:biggest-maximal-cliques
end

to highlight-clusters [ clusters ]
  ; get the node with neighbors that is closest to the mouse
  let node min-one-of turtles [ distancexy mouse-xcor mouse-ycor ]
  if node != nobody and node != highlighted-node [
    set highlighted-node node
    ; find all clusters the node is in and assign them different colors
    color-clusters filter [ cluster -> member? node cluster ] clusters
    ; highlight target node
    ask node [ set color white ]
  ]
end

to color-clusters [ clusters ]
  ; reset all colors
  ask turtles [ set color gray - 3 ]
  ask links [ set color gray - 3 ]
  let n length clusters
  let colors ifelse-value (n <= 12)
    [ n-of n remove gray remove white base-colors ] ;; choose base colors other than white and gray
    [ n-values n [ approximate-hsb (random 255) (255) (100 + random 100) ] ] ; too many colors - pick random ones

    ; loop through the clusters and colors zipped together
    (foreach clusters colors [ [cluster cluster-color] ->
      ask cluster [ ; for each node in the cluster
        ; give the node the color of its cluster
        set color cluster-color
        ; colorize the links from the node to other nodes in the same cluster
        ; link color is slightly darker...
        ask my-undirected-edges [ if member? other-end cluster [ set color cluster-color - 1 ] ]
        ask my-in-directed-edges [ if member? other-end cluster [ set color cluster-color - 1 ] ]
        ask my-out-directed-edges [ if member? other-end cluster [ set color cluster-color - 1 ] ]
      ]
    ])
end

;to mutate
;
 ; carefully[ask n-of mutated turtles with [state = 0]
  ; [ set state 1
;  ]]
 ; [stop]
;end

to betweenness
  centrality [ -> nw:betweenness-centrality ]
end

to closeness
  centrality [ -> nw:closeness-centrality ]
end

to centrality [ measure ]
  nw:set-context turtles links ;;get-links-to-use
  ask turtles [
    let res (runresult measure) ; run the task for the turtle
    ifelse is-number? res [
      set label precision res 2
      set size res ; this will be normalized later
    ]
    [ ; if the result is not a number, it is because eigenvector returned false (in the case of disconnected graphs
      set label res
      set size 1
    ]
  ]
  normalize-sizes-and-colors
end

to normalize-sizes-and-colors
  if count turtles > 0 [
    let sizes sort [ size ] of turtles ; initial sizes in increasing order
    let delta last sizes - first sizes ; difference between biggest and smallest
    ifelse delta = 0 [ ; if they are all the same size
      ask turtles [ set size 1 ]
    ]
    [ ; remap the size to a range between 0.5 and 2.5
      ask turtles [ set size ((size - first sizes) / delta) * 2 + 0.5 ]
    ]
    ask turtles [ set color scale-color red size 0 5 ] ; using a higher range max not to get too white...
  ]
end

to highlight-bicomponents

  if stop-highlight-bicomponents = true [
    ; we're asked to stop - do so
    set stop-highlight-bicomponents false
    set highlight-bicomponents-on false
    stop
  ]
  set highlight-bicomponents-on true ; we're on!
  if highlight-maximal-cliques-on = true [
    ; if the other guy is on, he needs to stop
    set stop-highlight-maximal-cliques true
  ]

  if mouse-inside? [
    nw:set-context turtles links ;;get-links-to-use
    highlight-clusters nw:bicomponent-clusters
  ]
  display
end

; Allows the user to mouse over and highlight all maximal cliques
to highlight-maximal-cliques
  if (links-to-use != "undirected") [
    user-message "Maximal cliques only work with undirected links."
    stop
  ]
  if stop-highlight-maximal-cliques = true [
    ; we're asked to stop - do so
    set stop-highlight-maximal-cliques false
    set highlight-maximal-cliques-on false
    stop
  ]
  set highlight-maximal-cliques-on true ; we're on!
  if highlight-bicomponents-on = true [
    ; if the other guy is on, he needs to stop
    set stop-highlight-bicomponents true
  ]

  if mouse-inside? [
    nw:set-context turtles undirected-edges
    highlight-clusters nw:maximal-cliques
  ]
  display
end


to cellular_automata
    py:set "a" one-of neighbors
    py:set "b" state
    py:set "c" one-of neighborss
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

  ask turtles [
    create-links-to n-of 4 other turtles

    set neighborss n-of 2 other links 


    
    set similar-nearby count ( turtles-on neighbors ) in-radius radius-of-interaction

    set total-nearby similar-nearby + other-nearby

    cellular_automata
      if state = 0
    [ find-new-spot
    ]

    ;mutate

]
  
    carefully[ask turtles [create-links-with neighbor-left in-radius radius-of-interaction ]]
    [stop]
  carefully[ask turtles [create-links-with neighbor-right in-radius radius-of-interaction ]]
    [stop]
  
   ask turtles [ ask links [set color gray]]


end

to find-new-spot
  rt movement-steps
  fd movement-steps
  if any? other turtles-here [ find-new-spot ]
  move-to patch-here  ; move to center of patch
end

to update-globals
  let similar-neighbors sum [ similar-nearby ] of turtles
  let total-neighbors sum [ total-nearby ] of turtles

  ;set percent-similar ( similar-neighbors / total-neighbors ) * 100
end

to go

  update-turtles
  update-globals

end
