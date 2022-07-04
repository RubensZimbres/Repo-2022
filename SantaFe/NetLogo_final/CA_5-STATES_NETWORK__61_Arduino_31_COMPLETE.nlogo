extensions [ py nw arduino ]

directed-link-breed [ directed-edges directed-edge ]
undirected-link-breed [ undirected-edges undirected-edge ]

breed [ service-providers service-provider ]
breed [ clients client ]

globals [
  paths                           ; variable for mean path length
  counter                         ; counter to end iterations for Behavior Space
  temperature                     ; the initial temperature
  graus                           ; the temperature at time of the agents' interaction
  setup-yet?                      ; check if Arduino is properly set up
  highlighted-node                ; used for the "highlight mode" buttons to keep track of the currently highlighted node
  centroid-x                      ; centroid of x axis
  centroid-y                      ; centroid of y axis

]

turtles-own [neighbor-left neighbor-right neighbor-left-state neighbor-right-state state similar-nearby
  nearest-neighbor total-nearby other-nearby community cash ]

links-own [weight]

;;https://stackoverflow.com/questions/44556752/creating-edge-list-from-netlogo-social-network

to setup
  ifelse clear-before-generating = True ; if NetLogo clears previous nodes to generate new ones
  [ clear-all ]
  []
  set counter 0
  if arduino-on = True [                ; if Arduino mode is set up to ON
  set setup-yet? false
  ifelse arduino:is-open? [
    set setup-yet? user-yes-or-no? (word
      "A communication port to Arduino is already open.\n"
      "You can choose to work with this one (Choose YES)\n"
      "or you can close it (Choose NO).\n"
      "If you choose NO, click SETUP again to select a new port.")
    if not setup-yet? [ arduino:close ]
  ]
  [
    let ports arduino:ports
    ifelse not empty? ports [
      carefully [
        arduino:open user-one-of "Select the Arduino Port:" ports
        set setup-yet? true

          user-message (word
          "Communication Established.\n"
          "If your Arduino has the appropriate sketch loaded, you are ready to communicate.")
      ]
      [
        user-message (word
          "Error in establishing communications:\n"
          error-message)
        arduino:close
      ]
    ]
    [
      user-message (word
        "No available arduino ports were found.\n"
        "Please check that your board is connected\n"
        "and no other programs using it are open.")
    ]
  ]
    set temperature arduino:get "TEMP"                      ; sets the initial temperature of the system
  ]

  set-default-shape clients "person"
  set-default-shape service-providers "star"

  ;;set-default-shape turtles "pentagon"

  if load-graphml = True [                                  ; if you want to load a GraphML file
  file-open path-to-save ;;"/home/theone/Downloads/NetLogo/relationships_matrix.graphml"     ;; add your path here
    ask turtles [    if state = 0 [ set color red ]
      if state = 1 [ set color red ]
      if state = 2 [ set color yellow ]
      if state = 3 [ set color green ]
      if state = 4 [ set color green ]
      set size 0.8
      set cash 0
                ask n-of (frac-providers *  ( int ( N-turtles * percentage-unhappy / 100  ) ) ) turtles [
    set breed service-providers
  ]
  ask turtles with [ breed != service-providers ] [
    set breed clients
  ]


    ]
  ask links [ set color gray ]
  ]

  if load-graphml = False[



  crt int ( N-turtles * percentage-unhappy / 100  )    ; create unhappy agents
    [setxy random-xcor random-ycor ; random coordinates
    set state one-of [ 0 1 ]
    set neighbor-left-state one-of [ 0 1 ]                     ;; state of neighbors that each agent will interact with
    set neighbor-right-state one-of [ 0 1 ]
    if state = 0 [ set color red ]
    if state = 1 [ set color red ]
    if state = 2 [ set color yellow ]
    if state = 3 [ set color green ]
    if state = 4 [ set color green ]
    set size 0.8
      set cash 0

      ]
  crt N-turtles - int ( percentage-unhappy / 100 * N-turtles ) ;create agents with state bigger or equal to 2
    [setxy random-xcor random-ycor ; random coordinates
    set state one-of [ 2 3 4 ]
    set neighbor-left-state one-of [ 2 3 4 ]
    set neighbor-right-state one-of [ 2 3 4 ]
    if state = 0 [ set color red ]
    if state = 1 [ set color red ]
    if state = 2 [ set color yellow ]
    if state = 3 [ set color green ]
    if state = 4 [ set color green ]
    set size 0.8
      set cash 0
      ]

                  ask n-of (frac-providers *  N-turtles ) turtles [
    set breed service-providers
  ]
  ask turtles with [ breed != service-providers ] [
    set breed clients
  ]



  ;; make the initial network of two turtles and an edge
  ask turtles [ make-node turtle 0]        ;; first node, unattached
  ask turtles [ make-node turtle 1 ]       ;; second node, attached to first node
  ask links [ set weight 0
      set color gray
    set thickness weight]
  ]
  py:setup                                 ;; uses Python extension
  py:python3
  reset-ticks
end

to resize-node
    ;; area proportional to its degree
    ask turtles [ set size 0.8 + ( sqrt count link-neighbors ) / 6              ;; size of node according to number of links with neighbors
             ] ;;set label who]
end

to make-node [old-node]
  if breed = clients [
    set neighbor-left one-of turtles with [ distance myself <= radius-of-interaction ] with [ breed = clients ]   ;; choooses one of neighbors inside radius of interaction
       set neighbor-right one-of turtles with [ distance myself <= radius-of-interaction ]  with [ breed = service-providers ] ;; choooses one of neighbors inside radius of interaction
    if old-node != nobody
        [carefully[create-link-with neighbor-left [ set color 42
        set weight weight + 0.14                                               ;; add weight to the edge to the current left neighbor
        ]
        create-link-with neighbor-right [ set color 42
  set weight weight + 0.14                                                     ;; add weight to the edge to the current right neighbor
  ]]
        []
  ]
  ]


  if breed = service-providers [
  set neighbor-left one-of turtles with [ distance myself <= radius-of-interaction ] with [ breed = service-providers ]   ;; choooses one of neighbors inside radius of interaction
       set neighbor-right one-of turtles with [ distance myself <= radius-of-interaction ]  with [ breed = service-providers ] ;; choooses one of neighbors inside radius of interaction
    if old-node != nobody
        [carefully[create-link-with neighbor-left [ set color 42
        set weight weight + 0.14                                               ;; add weight to the edge to the current left neighbor
        ]
        create-link-with neighbor-right [ set color 42
  set weight weight + 0.14                                                     ;; add weight to the edge to the current right neighbor
  ]]
        []
  ]
  ]

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
  nw:set-context turtles links
  highlight-clusters nw:maximal-cliques
end

to highlight-clusters [ clusters ]
  ; get the node with neighbors that is closest to the mouse
  let node min-one-of turtles [ distancexy mouse-xcor mouse-ycor ]
  if node != nobody and node != highlighted-node [
    set highlighted-node node
    ; find all clusters the node is in and assign them different colors
    color-clusters filter [ cluster -> member? node cluster ] clusters
    ; highlight target node
    ask node [ set color red ]
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
        ask my-links [ set color cluster-color - 1 ]
      ]
    ])
end

to mutate
   carefully[ask n-of mutated turtles with [state = 0] ;; mutation of individuals to generate diversity
   [ set state 4
  ]]
  [stop]
end

to betweenness
  centrality [ -> nw:betweenness-centrality ]
end

to closeness
  centrality [ -> nw:closeness-centrality ]
end

to path-L
  set paths nw:mean-path-length
end


to centrality [ measure ]
  nw:set-context turtles links
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

to cellular_automata                                        ;; algorithm for the cellular automata
    py:set "a" neighbor-left-state                          ;; state of one of the neighbors
    py:set "b" state                                        ;; state of the agent itself
    py:set "c" neighbor-right-state                         ;; state of one of the neighbors
    py:run "regra=2159062512564987644819455219116893945895958528152021228705752563807959237655911950549124" ;; 2159062512564987644819455219116893945895958528152021228705752563807962227809675103689306" ;; rule of my thesis 2159062512564987644819455219116893945895958528152021228705752563807959237655911950549124
    py:run "base1=5"     ;; 5 states
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
           "    final_state_central_cell=[]"                               ;; final state of central cells at t+1
           "    for i in range(0,len(zeros_all_possible_states)):"
           "        final_state_central_cell.append([0,int(zeros_all_possible_states[i]),0])"
           "    initial_and_final_states=[]"
           "    for i in range(0,len(all_possible_states)):"
           "        initial_and_final_states.append(np.array([all_possible_states[i],np.array(final_state_central_cell).astype(np.int8)[i]]))"
           "    def ca(row):"                                              ;; applies the CA rule
           "        out=[]"
           "        out.append(final_state_central_cell[next((i for i, val in enumerate(all_possible_states) if np.all(val == kernel)), -1)][1])"
           "        return out"
           "    final_state=np.array(ca(0))"
           "    return final_state")

  let final-state py:runresult "cellular_automaton([a,b,c])[0]"            ;; assigns result of the cellular automaton to the agent state and color it
  set state final-state



end

to update-turtles
  set graus arduino:get "TEMP"                               ;; gets the current temperature
  ask turtles [
    set similar-nearby count ( turtles-on neighbors ) in-radius radius-of-interaction
    set total-nearby similar-nearby + other-nearby
    cellular_automata                                            ;; applies the cellular automaton rule
    carefully[
      facexy ([xcor] of neighbor-left + [xcor] of neighbor-right) / 2       ;; sets new coordinates for the agent, depending on neighbors
      ([ycor] of neighbor-left + [ycor] of neighbor-right) / 2

  ]
    [
    ]
    if state = 0                                                       ;; if agent is unhappy, he/she moves to try to find a better place
    [
      find-new-spot
    ]
    mutate                                                           ;; mutate agents to generate diversity

    if state = 0 [ set color red

  ]
    if state = 1 [ set color red
    ]
    if state = 2 [ set color yellow
  ]
    if state = 3 [ set color green
   ]
    if state = 4 [ set color green
   ]

    update-plots
  display
]
end

to-report find-partner1
  report neighbor-left
end

to-report find-partner2
  report neighbor-right
end

to find-new-spot
  ifelse arduino-on = true
  [
    if graus > temperature + 0.5 [       ;; if arduino true and current temperature 0.5 degrees Celsius greater then initial temp, move faster
  rt movement-steps + 3 * ( graus - temperature)
  fd movement-steps + 3 * ( graus - temperature)
  if any? other turtles-here [ find-new-spot ]
      move-to patch-here ]

    if graus <= temperature [           ;; if arduino true and current temperature smaller then initial temp, move regularly
  rt movement-steps - 3 * ( graus - temperature)
  fd movement-steps - 3 * ( graus - temperature)
  if any? other turtles-here [ find-new-spot ]
      move-to patch-here ]
  ]
  [
    rt movement-steps                   ;; if arduino false, move regularly
  fd movement-steps
  if any? other turtles-here [ find-new-spot ]
    move-to patch-here

  ]

end

to update-globals
  let similar-neighbors sum [ similar-nearby ] of turtles
  let total-neighbors sum [ total-nearby ] of turtles
end


to go
  ;; new edge is green, old edges are gray
  ;; ifelse count turtles with [state = 0 or state = 1] > int ( N-turtles  / 2 ) [ turn-led True ]
  ;; [ turn-led False ]
   ifelse counter < 90 [

  resize-node
  ask links [ set color gray ]
  update-turtles
  update-globals
  ask turtles [

    make-node find-partner1         ;; find partner & use it as attachment
    make-node find-partner2


  ]
  ask links [
    set thickness abs weight
  ]
  path-L                                         ;; return mean path length
      set centroid-x mean ( [xcor] of turtles ) ;; get centroid of x axis
      set centroid-y mean ( [ycor] of turtles )   ;; get centroid of y axis
  set counter counter + 1

  update-plots
    display]
  [ stop ]
end



;to turn-led [ on? ]
;  ifelse arduino-on = true [arduino:write-byte ifelse-value on? [ 1 ] [ 0 ]][]
;end

to save-matrix
  nw:set-context turtles links
  nw:save-graphml path-to-save ;; "/home/theone/Downloads/NetLogo/relationships_matrix.graphml"
end

to load-matrix1
  clear-all
  nw:load-graphml path-to-save ;;"/home/theone/Downloads/NetLogo/relationships_matrix.graphml"
end
@#$#@#$#@
GRAPHICS-WINDOW
623
15
1195
588
-1
-1
17.1
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
198
495
261
528
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
25
611
336
761
Distribution of States
State
Amount
0.0
2.0
0.0
62.0
true
true
"" ""
PENS
"State 0 & 1" 1.0 0 -2674135 true "" "plot count turtles with [ state <= 1 ]"
"State 2" 1.0 0 -612749 true "" "plot count turtles with [ state = 2 ]"
"State 3 & 4" 1.0 0 -13840069 true "" "plot count turtles with [ state >= 3 ]"

PLOT
360
611
657
761
Degree Distribution
Degree
Nb-nodes
0.0
80.0
0.0
10.0
true
false
"" ""
PENS
"Links" 1.0 1 -16777216 true "" "histogram [ count my-links ] of turtles"

SLIDER
23
401
262
434
radius-of-interaction
radius-of-interaction
0
30
2.9
0.1
1
NIL
HORIZONTAL

SLIDER
23
357
263
390
movement-steps
movement-steps
0.1
20
1.3
0.1
1
NIL
HORIZONTAL

MONITOR
509
16
604
61
Count-happy
count turtles with [state = 3 or state = 4]
0
1
11

MONITOR
292
16
390
61
Count-unhappy
count turtles with [state = 0 or state = 1]
0
1
11

SLIDER
23
445
261
478
mutated
mutated
0
15
0.0
1
1
NIL
HORIZONTAL

BUTTON
294
282
603
315
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
294
368
603
401
Closeness-centrality
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
294
325
603
358
Betweenness-centrality
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
22
495
180
528
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
25
19
265
52
clear-before-generating
clear-before-generating
0
1
-1000

MONITOR
292
128
605
173
Mean clustering coefficient
mean [nw:clustering-coefficient] of turtles
17
1
11

MONITOR
492
183
604
228
Total of links
count links
17
1
11

MONITOR
293
182
483
227
Mean path length
paths
17
1
11

CHOOSER
22
212
262
257
links-to-use
links-to-use
"directed" "undirected"
1

BUTTON
293
239
604
272
Biggest cliques
find-biggest-cliques
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
23
269
263
302
N-turtles
N-turtles
30
300
80.0
1
1
NIL
HORIZONTAL

SLIDER
22
314
264
347
percentage-unhappy
percentage-unhappy
5
100
30.0
1
1
%
HORIZONTAL

PLOT
681
611
984
761
Mood evolution
Time
Mood
0.0
10.0
0.0
4.5
true
true
"" ""
PENS
"clients" 1.0 0 -13345367 true "" "plot ( mean [ state ] of turtles with [ breed = clients ] )"
"service-providers" 1.0 0 -955883 true "" "plot ( mean [ state ] of turtles with [ breed = service-providers ] )"

BUTTON
294
410
603
443
Load GraphML
load-matrix1
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
294
453
604
486
Save GraphML
save-matrix
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
295
497
604
530
load-graphml
load-graphml
1
1
-1000

MONITOR
22
108
264
153
connection to Arduino established?
setup-yet? = true
17
1
11

SWITCH
24
64
159
97
arduino-on
arduino-on
1
1
-1000

MONITOR
292
72
444
117
Humidity
arduino:get \"HUM\"
17
1
11

MONITOR
451
72
604
117
Temperature
arduino:get \"TEMP\"
17
1
11

TEXTBOX
165
59
283
119
If Arduino ON, click Setup, wait 4 secs then click Go
12
0.0
1

SLIDER
23
165
263
198
frac-providers
frac-providers
0
1
0.15
0.01
1
NIL
HORIZONTAL

MONITOR
395
16
503
61
Count-neutral
count turtles with [state = 3]
17
1
11

INPUTBOX
295
539
604
599
path-to-save
/home/theone/Downloads/NetLogo/relationships_matrix.graphml
1
0
String

@#$#@#$#@
## WHAT IS IT?

The origin of this project was in my doctorate, when I used cellular automata (CA) to simulate human interactions that happened in the real world. I started with a market research with real people in two different times: one at time zero and the second at time zero plus 4 months (longitudinal market research). 

The idea was to develop an agent-based model whose initial condition was inherited from the results of the first market research response values and evolve it to simulate human interactions with Agent-Based Modeling that led to the values of the second market research, without explicitly imposing rules. Then, compare results of the model with the second market research. The model reached 73.80% accuracy.

In the same way, this project models the behavior of individuals in a closed society whose behavior depends upon the result of interaction with two neighbors within a radius of interaction, one on the relative "right" and other one on the relative "left". States here are defined as levels of quality perception, where red means unhappy and green means happy.

Besides the interaction and the formation of social networks, the system is also subject to levels of temperature of the environment, measured with a sensor attached to Arduino.



## INSTALLATION

If you opt for using Arduino, first download the Arduino software at: https://www.arduino.cc/en/software

Install it and plug Arduino. Then, get the DHT library from Arduino and download the project .ino file from: 

https://raw.githubusercontent.com/RubensZimbres/Repo-2022/main/SantaFe/NetLogo/Arduino/arduino-example-sketch.ino

After that, connect the Temperature/Humidity sensor DHT11 to your Arduino, as the schema in the picture below:

![Arduino](https://github.com/RubensZimbres/Repo-2022/blob/main/SantaFe/netlogo_bb.png?raw=true)

In Arduino software, compile and upload to the board. If you have issues with Linux, run:

sudo chmod a+rw /dev/ttyACM0

Open Tools / Monitor and check if the sensor is indeed reading the humidity and temperature. Close the Monitor so that the port will be available for NetLogo.



## HOW IT WORKS

With 2 cellular automaton (CA) states, you have 256 possible rules. With 5 states, used here, you have 2350988701644575015937473074444491355637331113544175043017503412556834518909454345703125 possible rules. The biggest issue here is to know which will be the outcome for a chosen rule. The rule of my thesis and used here is a CA 5-state radius-one unidimensional rule number 2159062512564987644819455219116893945895958528152021228705752563807959237655911950549124.

Initially, each individual has its own state. As an amorphous cellular automaton, neighborhood is not limited to immediate neighbors in lattice. The agent will interact with any of the other 2 individuals within the defined radius of interaction. In this model have two breeds, one is clients and the other service providers.

The behavior of an agent is defined by the type of neighbors he/she has at time t. So, at time t+1 the states of all agents that interacted with two neighbors are updated according to the rule. 

Cellular Automata principle: for each cell in the grid with its position c(i,j) where i and j are the row and the column respectively, a function Sc(t)=S(t;i,j) is associated with the lattice to describe the cell c state in time t. So, in a time t+1, state S(t+1,i,j) is given by:

S(t+1;i, j ) = [S(t;i,j)+δ]mod k

where − k ≤ δ ≤ k and k is the number of cell c states. The formula for δ is:

δ = μ if condition (a) is true

δ = -S(t;i,j) if condition (b) is true

δ = 0 otherwise

where a and b change according to the rule.

The chosen cellular automaton rule has the following transition table to guide the state update, according to the states of its 2 neighbors.

![CA Transition Rule](https://github.com/RubensZimbres/Repo-2022/blob/main/SantaFe/regra_trans.jpg?raw=true)

In a two-dimensional lattice, the chosen rule has the following behavior:

![CA Evolution](https://github.com/RubensZimbres/Repo-2022/blob/main/SantaFe/NetLogo/CA_rule_thesis.png?raw=true)


The cellular automaton algorithm was developed using the Python extension for NetLogo and in fact is able to support rules with 2 to 5 states.

Initialization

The system is initialized choosing:

- CLEAR-BEFORE_GENERATING: clear the lattice to generate agents
- ARDUINO-ON: choose if Arduino is set to ON or OFF. If Arduino is ON and properly set up, it is supposed that humidity and temperature values show up. If not, check your installation and if all wires and cables are connected.
- FRAC-PROVIDERS: fraction of the agents that are service providers. The other fraction is composed by clients.
- LINKS-TO-USE: if they are directed or indirected
- N-TURTLES: the N number of agents (turtles)
- PERCENT-UNHAPPY: amount of agents with state < 3
- the MOVEMENT-STEP variable defines how much an agent should move in case there are no neighbors available inside the radius defined in Setup, or even if it is unhappy.
- the RADIUS-OF-INTERACTION variable helps the agent to decide the radius in which neighbors will be chosen. 
- the MUTATED variable. Using a genetic metaphor, the idea here is to add diversity to allow the evolution of the social network.
- LOAD-GRAPHML: keep it OFF unless you are loading a previous saved configuration

The temperature is collected by a DHT11 sensor attached to Arduino and infuence the degree of movimentation of agents. In colder temperatures, agents move less, and in high temperatures, agents move more steps. This is similar to physical properties of the states of matter. At higher temperatures atoms are faster.


Iterative

The agents will randomly choose their left and right neighbors. Clients will choose another client and a service provider. Service providers will choose another two service providers.

In case there are not two neighbors within the radius defined in RADIUS-OF-INTERACTION, or if they are unhappy, they will move MOVEMENT-STEPs until they find two available neighbors. In this movement, relative radius is updated. As soon as they find two neighbors, they update their X,Y coordinates as the mean of neighbors position and their state according to the colors of each one of the neighbors, following the transition table of the chosen CA rule.

As interactions happen, the number of cliques, the closeness, betweenness and communities are recorded, as well as the degree distribution and the states in the social network. For the sake of simplicity and ease of visualization, states less than 3, unhappy, are represented by red, state 3, neutral is represented by yellow and states 3 and 4 are green.



## HOW TO USE IT

Click the SETUP button to set up the agents. You can choose equal numbers of red and green agents, but you can change it. The agents are set up so no patch has more than one agent.  Click GO to start the simulation. If agents don't have enough neighbors in the radius of interaction, they move to a nearby patch. (Note that the topology is not wrapping).

If you choose ARDUINO-ON, wait for temperature and humidity to show up. If they don't show up when you click SETUP, go to Arduino software Monitor and check if the sensor is really reading temperature and humidity. Only then and after 4 seconds, click Go.

When you stop the iterations, you can check the number of turtles unhappy, neutral and the number of turtles happy, the MEAN CLUSTERING COEFFICIENT of turtles and the MEAN OF PATH LENGTH. The mean path length regards the mean distance between all nodes. If it decreases, this means that the social network is developing strong ties among agents, as the average distance among them is smaller.

The strength of ties can be seen by the thickness of the connections among agents.

After you stop the model run, when you click BIGGEST CLIQUES, you will find the individual with more cliques in the social network. A clique is a sub-set of a network in which the actors are more closely and intensely tied to one another than they are to other members of the network. Think of it as a group of people connected by strong social ties.

DETECT COMMUNITIES

You can also detect communitites. Netlogo interface will show each community with its members and correspondent colors. This option detects community structures present in the network. It does this by maximizing modularity using the [Louvain method](https://en.wikipedia.org/wiki/Louvain_Modularity). The Louvain method is a greedy optimization of the modularity, a value between −0.5 (non-modular clustering) and 1 (fully modular clustering) that measures the relative density of edges inside communities with respect to edges outside the community tested. In a detected community, the modularity will increase. Then, community nodes are grouped to restart the algorithm.

CLOSENESS

The Closeness button will show you the closeness of each agent to the rest of the network. Closeness centrality indicates how close a node is to all other nodes in this network. It is calculated as the average of the shortest path length from the node to every other node in the network. A smaller value means that the given agent is closer to other nodes of the network.

BETWEENNESS

To calculate the [betweenness centrality](https://en.wikipedia.org/wiki/Betweenness_centrality) of an agent, you take every other possible pairs of agents and, for each pair, you calculate the proportion of shortest paths between members of the pair that passes through the current agent. The betweenness centrality for each node is the sum of the numbers of these shortest paths that pass through the node. 

The three plots in the interface show the distribution of states, the degree distribution as an histogram and the mood evolution. Note that the mood output may be very similar to the oscillating behavior found by Brian Arthur.

If you decrease the MOVEMENT-STEPS, RADIUS OF INTERACTION and the SPEED, you can see how communities are slowly being formed. Try MOVEMENT-STEPs = 2 and RADIUS-OF-INTERACTION = 2.

** The model runs better on GPU.



## THINGS TO NOTICE

When you execute SETUP, the red and green agents are randomly distributed throughout the neighborhood. Clients are turtles with shape "person" and service providers are turtles with shape "star".

But many agents are "unhappy" since their interactions with neighbors may result in unhappiness. The unhappy agents move to new locations in the vicinity and each agent moves towards its neighbors. When in the new locations, they may alter the equilibrium of the local population, prompting other agents to leave.

Notice the emergence of clusters of deep connected individuals.

Notice the weight of edges following multiple interactions with neighbors. You can find the most influential individuals in the network.Notice also that the size of nodes increases as the agents has more connections.

Note what happens in the network dynamics if the temperature of the environment goes up or down.




## THINGS TO TRY

Try to alter the amount of movement the agent does when he is unhappy or with few neighbors. You can also change the radius an agent will consider when interating with others. Does a small radius isolate him/her in the social dynamics ?

Edit the Python code and make experiments with these 2-state CA interesting rules. These are the behaviors in two dimensional lattice, not amorphous CA.

- 30 - random rule
- 126 - random rule
- 214 - minority rule
- 232 - majority rule

You can also try to choose left and right neighbors based on state similarity.

You can make experiments with variations of temperature and how this affects the dynamic of the system.

Try the following set up:

- LINKS undirected
- N-TURTLES 102
- PERCENTAGE-UNHAPPY 33%
- MOVEMENT-STEPS 2.1
- RADIUS OF INTERACTION 2.0
- MUTATED 7

You will notice that the system will probably reach an equilibrium, stop moving and stop creating new links. In this case, incrase the temperature of the system in the Arduino DHT11 sensor e see what happens.

Try also the opposite, when the social ties are forming, decrease environment temperature  and see if the system reaches an equilibrium.



## EXTENDING THE MODEL

Incorporate social networks concepts into this model.  For instance, have unhappy agents decide on a new location based on information about the other communities, like betweenness centrality, closeness of agents, etc.

Change the rules for agent happiness, make happy people move instead of the unhappy. 

Find the perfect setup for the rapid emergence of happiness and a good quality perception.



## REFERENCES

Albaum, G., (1967). Information flow and decentralised decision making in marketing.
California Management Review, 9(4), 59-70.

Arthur, W.B. (1994) Inductive Reasoning and Bounded Rationality. The American Economic Review, Vol. 84, No. 2, Papers and Proceedings of the Hundred and Sixth Annual Meeting of the American Economic Association, pp. 406-411.

Axelrod, R. (1997). Advancing the Art of Simulation in the Social Sciences. Handbook of Research on Nature Inspired Computing for Economy and Management, Jean-Philippe Rennard (Ed.).Hersey, PA: Idea Group.

Axelrod, R. (1997). Complexity of cooperation. New Jersey: Princeton University Press, 1997.

Bertalanffy, L. (1950). An Outline of General System Theory. British Journal of the Philosophy of Science, 1950

Cederman, L.E., (2003). Computational models of social forms: Advancing generative macro theory. Paper prepared for presentation at the 8 th Annual Methodology Meeting of the American Sociology Association, University of Washington, Seattle.

Epstein, J.M. & Axtell, R., (1996). Growing artificial societies: Social science from the bottom up. MIT Press, Cambridge.

Flache, A. Hegselmann, R. (2001). Do Irregular Grids make a Difference? Relaxing the Spatial Regularity Assumption in Cellular Models of Social Dynamics. Journal of Artificial Societies and Social Simulation, v. 4, n. 4.

Ganguly, N.; Sikdar, B.K.; Deutch, A.; Canright, G.; Chaudhuri, P.P. A survey on cellular automata. Available at www.cs.unibo.it/bison/publications/CAsurvey.pdf.

Granovetter M.S. (1973) The Strength of Weak Ties. American Journal of Sociology. Vol. 78, No. 6, pp. 1360-1380

Macy, M.W.; Willer, R. (2002). From factors to actors: Computational sociology and agent-
based modeling. Annual Review of Sociology, v. 28.

Sawyer, R.K. (2003). Artificial societies: Multiagent systems and the micro-macro link in
sociological theory. Sociological Methods and Research, v. 31, n. 3, Feb 2003.

Sawyer, R.K. (2004). Social explanation and computational simulation. Philosophical
explorations, v. 7, n. 3.

Schelling, T. (1978). Micromotives and Macrobehavior. New York: Norton.

Tesfatsion, L., (2005). Agent-based computational economics: A constructive approach to economic theory. Forthcoming in Judd, K.L. Tesfatsion, L. Handbook of Computational Economics. North-Holland.

Vicsek, T. (2002) Complexity: The Bigger Picture. Nature, v. 418.

Wolfram, S. (2002). A new kind of science. Canada: Wolfram Media Inc.

Zimbres, R.A. (2006) Modelagem Baseada em Agentes: uma Terceira Maneira de se Fazer Ciência? ANPAD, Presented at Encontro da Associação Nacional de Pós-Graduação e Pesquisa em Administração.

Zimbres, R.A.; Brito, E.P.Z.; Oliveira, P.P.B. (2008) Cellular automata based modeling of the formation and evolution of social networks: A case in Dentistry. In: J. Cordeiro and J. Filipe, eds. Proc. of the 10th Int. Conf. on Enterprise Information Systems, INSTICC Press: Setùbal-Portugal, Vol. III: Artiﬁcial Intelligence and Decision Support Systems, pp. 333-339.

Zimbres, R.A., Oliveira,P.P.B. (2009) Dynamics of Quality Perception in a Social Network: A Cellular Automaton Based Model in Aesthetics Services. Electronic Notes in Theoretical Computer Science, Elsevier, 252 pp 157–180.



## ACKNOWLEDGEMENTS

The author thanks Google Developers Experts for supporting his research activities.



## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the cellular automata model:

* Zimbres, R.A., Oliveira, P.P.B. (2009). Dynamics of Quality Perception in a Social Network: A Cellular Automaton Based Model in Aesthetics Services. Electronic Notes in Theoretical Computer Science, Elsevier, Volume 252, 1, Pages 157–180.

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
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>( sum [ state ] of turtles with [ breed = clients ] ) /  (( 1 - frac-providers) * N-turtles)</metric>
    <metric>( sum [ state ] of turtles with [ breed = service-providers ] ) /  ( frac-providers * N-turtles )</metric>
    <metric>mean [nw:clustering-coefficient] of turtles</metric>
    <metric>paths</metric>
    <metric>mean [nw:closeness-centrality] of turtles</metric>
    <metric>mean [nw:betweenness-centrality] of turtles</metric>
    <steppedValueSet variable="radius-of-interaction" first="1.5" step="2" last="5.5"/>
    <steppedValueSet variable="movement-steps" first="1" step="2" last="5"/>
    <enumeratedValueSet variable="load-graphml">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-turtles">
      <value value="80"/>
    </enumeratedValueSet>
    <steppedValueSet variable="percentage-unhappy" first="10" step="10" last="40"/>
    <enumeratedValueSet variable="clear-before-generating">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arduino-on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutated">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="links-to-use">
      <value value="&quot;undirected&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frac-providers">
      <value value="0.05"/>
      <value value="0.05"/>
      <value value="0.15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_centroid" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>( sum [ state ] of turtles with [ breed = clients ] ) /  (( 1 - frac-providers) * N-turtles)</metric>
    <metric>( sum [ state ] of turtles with [ breed = service-providers ] ) /  ( frac-providers * N-turtles )</metric>
    <metric>mean [nw:clustering-coefficient] of turtles</metric>
    <metric>paths</metric>
    <metric>mean [nw:closeness-centrality] of turtles</metric>
    <metric>mean [nw:betweenness-centrality] of turtles</metric>
    <metric>centroid-x</metric>
    <metric>centroid-y</metric>
    <steppedValueSet variable="radius-of-interaction" first="1.5" step="2" last="5.5"/>
    <steppedValueSet variable="movement-steps" first="1" step="2" last="5"/>
    <enumeratedValueSet variable="load-graphml">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-turtles">
      <value value="80"/>
    </enumeratedValueSet>
    <steppedValueSet variable="percentage-unhappy" first="10" step="10" last="40"/>
    <enumeratedValueSet variable="clear-before-generating">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arduino-on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutated">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="links-to-use">
      <value value="&quot;undirected&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frac-providers">
      <value value="0.05"/>
      <value value="0.05"/>
      <value value="0.15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_centroid_links" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>( sum [ state ] of turtles with [ breed = clients ] ) /  (( 1 - frac-providers) * N-turtles)</metric>
    <metric>( sum [ state ] of turtles with [ breed = service-providers ] ) /  ( frac-providers * N-turtles )</metric>
    <metric>mean [nw:clustering-coefficient] of turtles</metric>
    <metric>paths</metric>
    <metric>mean [nw:closeness-centrality] of turtles</metric>
    <metric>mean [nw:betweenness-centrality] of turtles</metric>
    <metric>centroid-x</metric>
    <metric>centroid-y</metric>
    <metric>count links</metric>
    <steppedValueSet variable="radius-of-interaction" first="1.5" step="2" last="5.5"/>
    <steppedValueSet variable="movement-steps" first="1" step="2" last="5"/>
    <enumeratedValueSet variable="load-graphml">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-turtles">
      <value value="80"/>
    </enumeratedValueSet>
    <steppedValueSet variable="percentage-unhappy" first="10" step="10" last="40"/>
    <enumeratedValueSet variable="clear-before-generating">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arduino-on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutated">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="links-to-use">
      <value value="&quot;undirected&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frac-providers">
      <value value="0.05"/>
      <value value="0.05"/>
      <value value="0.15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_centroid_links_mutated" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean [ state ] of turtles with [ breed = clients ]</metric>
    <metric>mean [ state ] of turtles with [ breed = service-providers ]</metric>
    <metric>mean [nw:clustering-coefficient] of turtles</metric>
    <metric>paths</metric>
    <metric>mean [nw:closeness-centrality] of turtles</metric>
    <metric>mean [nw:betweenness-centrality] of turtles</metric>
    <metric>centroid-x</metric>
    <metric>centroid-y</metric>
    <metric>count links</metric>
    <steppedValueSet variable="radius-of-interaction" first="1.5" step="2" last="5.5"/>
    <steppedValueSet variable="movement-steps" first="1" step="2" last="5"/>
    <enumeratedValueSet variable="load-graphml">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-turtles">
      <value value="80"/>
    </enumeratedValueSet>
    <steppedValueSet variable="percentage-unhappy" first="10" step="10" last="40"/>
    <enumeratedValueSet variable="clear-before-generating">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arduino-on">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutated">
      <value value="0"/>
      <value value="7"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="links-to-use">
      <value value="&quot;undirected&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="frac-providers">
      <value value="0.05"/>
      <value value="0.05"/>
      <value value="0.15"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
