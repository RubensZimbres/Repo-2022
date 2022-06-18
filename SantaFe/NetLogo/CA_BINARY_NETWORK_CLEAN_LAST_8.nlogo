extensions [ py nw ]

directed-link-breed [ directed-edges directed-edge ]
undirected-link-breed [ undirected-edges undirected-edge ]

globals [
  percent-similar
  clients
  providers
  ;neighborss-state
  ;neighborss
  nb-nodes
  ticks-to-run
  population
  individuals-mutate
  highlighted-node                ; used for the "highlight mode" buttons to keep track of the currently highlighted node
  highlight-bicomponents-on       ; indicates that highlight-bicomponents mode is active
  stop-highlight-bicomponents     ; indicates that highlight-bicomponents mode needs to stop
  highlight-maximal-cliques-on    ; indicates highlight-maximal-cliques mode is active
  stop-highlight-maximal-cliques  ; indicates highlight-maximal-cliques mode needs to stop
]

turtles-own [neighbor-left neighbor-right neighbor-left-state neighbor-right-state state similar-nearby
  nearest-neighbor total-nearby other-nearby community]

to setup
  clear-all
  set-default-shape turtles "circle"
  crt 60 [

    set state one-of [ 0 1 ]
    ;set neighborss n-of 2 other turtles; in-radius radius-of-interaction
    set size 1
    if state = 0 [ set color red ]
    if state = 1 [ set color green ]
    set size 0.8
  ]
  ;; make the initial network of two turtles and an edge
  make-node turtle 0        ;; first node, unattached
  make-node turtle 1
  ;; second node, attached to first node
  py:setup
  py:python3

  reset-ticks
end

to resize-nodes
  ifelse all? turtles [size <= 1]
  [
    ;; a node is a circle with diameter determined by
    ;; the SIZE variable; using SQRT makes the circle's
    ;; area proportional to its degree
    ask turtles [ set size ( sqrt count link-neighbors ) / 2 ]
  ]
  [
    ask turtles [ set size 1 ]
  ]
end

to make-node [old-node]
  ask turtles
  [setxy random-xcor random-ycor
    if old-node != nobody
      [ create-link-with one-of other turtles [ set color gray ]
        ;; position the new node near its partner
        move-to old-node
        ;fd 3
      ]
  ]
end

to-report limit-magnitude [number limit]
  if number > limit [ report limit ]
  if number < (- limit) [ report (- limit) ]
  report number
end

to community-detection
  nw:set-context turtles links
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

to mutate
   carefully[ask n-of mutated turtles with [state = 0]
   [ set state 1
  ]]
  [stop]
end

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

    py:set "a" one-of links
    py:set "b" state
    py:set "c" one-of links
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
    ;;;create-links-to n-of 2 other turtles
    ;set neighborss n-of 2 links
    set similar-nearby count ( turtles-on neighbors ) in-radius radius-of-interaction
    set total-nearby similar-nearby + other-nearby
    cellular_automata
      if state = 0
    [ find-new-spot
    ]
    mutate
]
end

to-report find-partner
  report [one-of both-ends] of one-of links
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
end

to go
  ;; new edge is green, old edges are gray

  ask links [ set color gray ]
  make-node find-partner         ;; find partner & use it as attachment
  update-turtles
  update-globals
  tick
  let x-offset max [xcor] of turtles + min [xcor] of turtles
  let y-offset max [ycor] of turtles + min [ycor] of turtles
  display


  ;;;;;;;;ask links [ set color gray ]
end
@#$#@#$#@
GRAPHICS-WINDOW
577
11
1111
546
-1
-1
15.94
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
20.0

BUTTON
186
30
249
63
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
42
577
353
727
Distribution of States
State
Amount
0.0
2.0
0.0
300.0
true
true
"" ""
PENS
"State 0" 1.0 1 -2674135 true "" "plot count turtles with [ state = 0]"
"State 1" 1.0 0 -13840069 true "" "plot count turtles with [ state = 1]"

PLOT
377
577
717
727
Degree Distribution
Degree
Nb-nodes
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Links" 1.0 1 -16777216 true "" "histogram [ count my-links ] of turtles"

CHOOSER
42
101
236
146
Cellular-Automaton-rule
Cellular-Automaton-rule
30 126 214 232
0

SLIDER
30
369
233
402
radius-of-interaction
radius-of-interaction
0
16
3.5
0.5
1
NIL
HORIZONTAL

SLIDER
38
305
224
338
movement-steps
movement-steps
0.1
20
0.5
0.1
1
NIL
HORIZONTAL

MONITOR
420
26
515
71
Count-happy
count turtles with [state = 1]
0
1
11

MONITOR
305
26
403
71
Count-unhappy
count turtles with [state = 0]
0
1
11

SLIDER
46
429
224
462
mutated
mutated
0
15
9.0
1
1
NIL
HORIZONTAL

BUTTON
320
384
502
417
Detect communities
community-detection
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
356
432
461
465
Closeness
closeness
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
345
478
473
511
Betweenness
betweenness
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
9
30
167
63
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
27
164
255
197
clear-before-generating
clear-before-generating
0
1
-1000

MONITOR
275
98
562
143
NIL
mean [nw:clustering-coefficient] of turtles
17
1
11

MONITOR
309
160
405
205
NIL
count turtles
17
1
11

MONITOR
426
160
509
205
NIL
count links
17
1
11

MONITOR
328
224
497
269
Mean path length
nw:mean-path-length
17
1
11

CHOOSER
67
228
205
273
links-to-use
links-to-use
"directed" "undirected"
1

BUTTON
308
336
519
369
NIL
highlight-maximal-cliques\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
311
290
514
323
NIL
find-biggest-cliques
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

The origin of this project was in my doctorate, when I used cellular automata to simulate human interactions that happened in the real world. I started with a market research with real people in two different times: one at time zero and the second at time zero plus 4 months (longitudinal market research). 

The idea was to develop an agent-based model whose initial condition was inherited from the results of the first market research response values and evolve it to simulate human interactions that led to the values of the second market research, without explicitly imposing rules. Then, compare results of the model with the second market research.

In the same way, this project models the behavior of individuals in a closed society whose behavior depend upon the result of interaction with two neighbors, one on the "right" and one on the "left". States here are defined as a quality perception, where red means unhappy and green means happy, a good quality perception.


## HOW IT WORKS

The system is modelled using one of the 256 two-states one-dimensional cellular automaton (CA) rules available. An amorphous cellular automaton. The behavior of an agent is defined by the type of neighbors he/she has at time t. So, at time t+1 the states of all agents that interacted with two neighbors are updated. 

Initialization

The system is initialized choosing:
- the CELLULAR AUTOMATON RULE (choose-CA-rule) - from 0 to 255 
- the amount of turtles with value 0 (red - UNHAPPY) and the amount of turtles with value 1 (green - HAPPY). 
- the MINIMUM_SEPARATION variable helps the agent to decide the radius in which neighbors will be chosen. 
- the MOVEMENT-STEP variable defines how much should an agent move in case there are not neighbors available inside the radius defined in Setup.


Iterative

The agents will randomly choose their left and right neighbors. In case there are not two neighbors within the radius defined in MINIMUM-SEPARATION, they will move MOVEMENT-STEPs until they find two available neigbors. In this movement, relative radius is updated. As soon as they find two neighbors, they update their state according to the colors of each one of the neighbors, following the transition table of the chosen CA rule, available at:

https://www.wolframalpha.com/input/?i=cellular+automaton+rule+30

Cellular Automata principle: for each cell in the grid with its position c(i,j) where i and j are the row and the column respectively, a function Sc(t)=S(t;i,j) is associated with the lattice to describe the cell c state in time t. So, in a time t+1, state S(t+1,i,j) is given by:

S(t+1;i, j ) = [S(t;i,j)+δ]mod k

where − k ≤ δ ≤ k and k is the number of cell c states. The formula for δ is:

δ = μ if condition (a) is true

δ = -S(t;i,j) if condition (b) is true

δ = 0 otherwise

where a and b change according to the rule.

Cellular automaton was developed using the Python extension for NetLogo and in fact is able to support rules with 2 to 5 states.

Initially turtles looks for two of other turles inside their defined radius. If he/she does not find exactly two neighbors, he/she finds a new spot. When neighbors are available, cellular automata rule is applied to all turtles who has the available neighbors. If the turtle tries to move to a spot already occupied by another turtle, he/she moves again until they are available.


## HOW TO USE IT

Click the SETUP button to set up the agents. There are approximately equal numbers of red and green agents, but you can change it. The agents are set up so no patch has more than one agent.  Click GO to start the simulation. If agents don't have enough neighbors in the radius of interaction, they move to a nearby patch. (Note that the topology is not wrapping).


## THINGS TO NOTICE

When you execute SETUP, the red and green agents are randomly distributed throughout the neighborhood. 

But many agents are "unhappy" since their interactions with neighbors may result in unhappiness. The unhappy agents move to new locations in the vicinity. But in the new locations, they may alter the equilibrium of the local population, prompting other agents to leave.

Notice the emergence of ........

## THINGS TO TRY

Try to alter the amount of movement the agent does when he is unhappy or with few neighbors. You can also change the radius an agent will consider when interating with others. Does a small radius isolate him/her in the social dynamics ?

Make experiments with these interesting rules. These are the behaviors in two dimensional lattice, not amorphous CA.

30 - random rule
126 - random rule
214 - minority rule
232 - majority rule

## EXTENDING THE MODEL

Incorporate social networks into this model.  For instance, have unhappy agents decide on a new location based on information about the other communities, like betweeness centrality, closeness of agents, etc.

Change the rules for agent happiness. With 2 states, you have 256 possible rules. With 5 states, you have 2350988701644575015937473074444491355637331113544175043017503412556834518909454345703125 possible rules. The biggest issue here is to know which will be the outcome for a chosen rule. 

A hint: CA 5-state unidimensional rule number 2159062512564987644819455219116893945895958528152021228705752563807959237655911950549124 simulated interactions in the real world with 73.80% accuracy. 

Find the perfect setup for the rapid emergence of happiness and a good quality perception.


## REFERENCES

Axelrod, R. (1997). Advancing the Art of Simulation in the Social Sciences. Handbook of Research on Nature Inspired Computing for Economy and Management, Jean-Philippe Rennard (Ed.).Hersey, PA: Idea Group.

Axelrod, R. (1997). Complexity of cooperation. New Jersey: Princeton University Press, 1997.

Bertalanffy, L. (1950). An Outline of General System Theory. British Journal of the Philosophy of Science, 1950

Flache, A. Hegselmann, R. (2001). Do Irregular Grids make a Difference? Relaxing the Spatial Regularity Assumption in Cellular Models of Social Dynamics. Journal of Artificial Societies and Social Simulation, v. 4, n. 4.

Ganguly, N.; Sikdar, B.K.; Deutch, A.; Canright, G.; Chaudhuri, P.P. A survey on cellular automata. Available at www.cs.unibo.it/bison/publications/CAsurvey.pdf.

Macy, M.W.; Willer, R. (2002). From factors to actors: Computational sociology and agent-
based modeling. Annual Review of Sociology, v. 28.

Sawyer, R.K. (2003). Artificial societies: Multiagent systems and the micro-macro link in
sociological theory. Sociological Methods and Research, v. 31, n. 3, Feb 2003.

Sawyer, R.K. (2004). Social explanation and computational simulation. Philosophical
explorations, v. 7, n. 3.

Schelling, T. (1978). Micromotives and Macrobehavior. New York: Norton.

Wolfram, S. (2002). A new kind of science. Canada: Wolfram Media Inc.



## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Zimbres, R.A., Oliveira, P.P.B. (2009). Dynamics of Quality Perception in a Social Network: A Cellular Automaton Based Model in Aesthetics Services. Electronic Notes in Theoretical Computer Science. Volume 252, 1, Pages 157–180.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.


## COPYRIGHT AND LICENSE

Copyright of NetLogo - 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

<!-- 1997 2001 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
