breed [ walls wall]
breed [ exits exit]
breed [ windows window]
breed [ fires fire]
breed [ people person]
undirected-link-breed [friends friend]
undirected-link-breed [coworkers coworker]
undirected-link-breed [partners partner]
undirected-link-breed [families family]
undirected-link-breed [multiples multiple]
walls-own [first-end second-end]
exits-own [first-end second-end]
windows-own [first-end second-end]
fires-own [arrival]
people-own [gender age visited? group-number group-type fh vision speed path current-path   ;; the speed of the turtle
  goal      ;; where am I currently headed
speed-limit]
globals [max-wall-distance open closed optimal-path acceleration  ;; the constant that controls how much a person speeds up or slows down by if it is to accelerate or decelerate
  ]

patches-own [inside-building? parent-patch smoke temp-smoke f1 g h intersection?   ;; true if the patch is at the intersection of two roads

  ]
;;------------------
extensions [csv]
to find-shortest-path-to-destination
  ask one-of people
  [
    set path find-path patch-here goal self
    set optimal-path path
    set current-path path
  ]
end

to-report find-path [source-patch destination-patch person-at-patch]
  let current-patch 0
  let search-path []
  set open []
  set closed []
  set open lput exits open
 set closed lput fires closed
  set closed lput walls closed
   set closed lput windows closed
  while [next-patch != goal]
  [set open (sort-on ["f1"] patches ); sort the patches in open list in increasing order of their f() values
      ; take the first patch in the open list
      set current-patch item 0 open ; as the current patch (which is currently being explored (n))
      set open remove-item 0 open  ; and remove it from the open list
      set closed lput current-patch closed    ; add the current patch to the closed list
  ask current-patch
        [    ask neighbors4 with [ (not member? self closed) ]  ; asks the top, bottom, left and right patches that aren't already closed or the parent patch
          [  if (self != source-patch) and (self != destination-patch) ; if they're not the source or destination patches
          [set open lput self open ; adds the current patch to the open list
                set parent-patch current-patch
  set g (g + 1)
                set f1 (g + ([fh] of person-at-patch)) ; needs path length
   set search-path lput current-patch search-path
  ]]]]
     set search-path fput destination-patch search-path

  ; reverse the search path so that it starts from a patch adjacent to the
  ; source patch and ends at the destination patch
  set search-path reverse search-path
     report search-path
end

to setup ; sets up the initial environment
 ca
 reset-ticks
 set-default-shape walls "line"
 set-default-shape exits "line"
 set-default-shape windows "line"
 set-default-shape fires "square"
 read-building-from-file "building_nightclub.csv"
 read-fire-from-file "fire_nightclub_merged.csv"
  read-patch-labels-from-file "labels.csv"
 read-people-from-file "people.csv"
 set max-wall-distance (max [size] of walls) / 2
  set acceleration 0.099 ; taken from goal-oriented traffic simulation in model library, must be less than .1 to avoid rounding errors
soclink
 ask walls [set color hsb  216 50 100]
 ask exits [set color hsb  0  50 100]
 ask windows [set color hsb 80 50 100]
 ask fires [ set color [0 0 0 0 ]]
 ask people [set color white set-speed-limit set speed .1 + random-float .4
    if (group-number != 0)  [set goal  min-one-of link-neighbors [distance myself]]]
 ;;there's initially no smoke
 ask patches [set smoke 0]
  see
end

;;whether the patch is in the building or outside of the building
to read-patch-labels-from-file [filename]
   let rows bf csv:from-file filename
   foreach rows
   [[row] ->
     ask patch (item 0 row) (item 1 row)
     [
       set inside-building? (item 2 row)
       ifelse inside-building?
       [set pcolor black]
       [set pcolor black]
     ]
  ]
end

to read-fire-from-file [ filename]
  ;;header: x y time
  let values bf csv:from-file filename
  foreach values
  [ [row] ->
    create-fires 1
    [
      setxy item 0 row item 1 row
      set arrival item 2 row
      set color blue
    ]
  ]
end

to read-building-from-file [filename]
  let values bf csv:from-file filename
  foreach values
  [ [row] ->
    let breed-name item 0 row
    let x1 item 1 row
    let y1 item 2 row
    let x2 item 3 row
    let y2 item 4 row
    let component nobody
    if breed-name = "Wall" [ create-walls 1 [set component self]]
    if breed-name = "Exit" [ create-exits 1 [set component self]]
    if breed-name = "Window" [ create-windows 1 [set component self]]
    ask component [ setxy ((x1 + x2) / 2) (y1 + y2) / 2]
    ask component [ facexy x1 y1]
    ;ask component [ set label (word x1)]
    ask component [ set size distancexy x1 y1 + distancexy x2 y2]
    ask component [ set first-end (list x1 y1)]
    ask component [ set second-end (list x2 y2)]
  ]
end
to read-people-from-file [filename] ; information was encoded in a CSV based on interview data and organized by Database Codebook
  let rows bf csv:from-file filename
  foreach rows
  [[row] ->
    create-people 1
    [
     set size .46
     setxy (item 0 row) (item 1 row) ; initial position, randomized within an ecology that patrons had reported when interviewd
     set age (item 2 row)
     set gender (item 3 row)
     set visited? (item 4 row) ;true or false
     set group-number (item 6 row) ; people were assigned group numbers based on the people they came with
     set group-type (item 7 row) ; based on composition of group
  ]]
end

to soclink ;groups that came together have links based type of relationship
ask people [if group-type != 0 ;type 0 is 'alone'
 [
if group-type = 1 [ask other people with [group-number = [group-number] of myself] [create-coworker-with myself]]
if group-type = 2 [ask other people with [group-number = [group-number] of myself] [create-friend-with myself]]
if group-type = 3 [ask other people with [group-number = [group-number] of myself] [create-partner-with myself]]
if group-type = 4 [ask other people with [group-number = [group-number] of myself] [create-family-with myself]]
if group-type = 5 [ask other people with [group-number = [group-number] of myself] [create-multiple-with myself]]
 ]]
  ask links [hide-link]
end

to go
 tick
   ;If Arrival time of fire is less than time (in seconds), smoke is set off in that area,
  ;people in that area die and surrounding people that live move to the closest exit
  ask fires with [arrival < ticks]
  [
    ask patch-here [ set smoke 1]
    ask people-here [die-by-fire]
  ]
  ask people [ face next-patch ;; person heads towards its goal
    set-speed
    fd speed ; need to set it so they can't walk through walls
    let possible-positions valid-next-locations self
    let next-pos argmin possible-positions [[pos] -> ([distancexy (first pos) (last pos)] of  goal)]
   if any? exits with [intersection (first next-pos) (last next-pos) [xcor] of myself [ycor] of myself (first first-end) (last first-end) (first second-end) (last second-end)]
    [  exit-building]
  ]
  ;Windows are turned into exits based on timings provided by NIST Documentation
  ;Windows are then recolored to represent exits
  if ticks = 94 [ ask windows with [who = 57 or who = 34] [ set breed exits set color hsb  0  50 100]]
  if ticks = 105 [ ask windows with [who = 59] [ set breed exits set color hsb  0  50 100]]
  diffuse-smoke 1
  recolor-patches
  see
end

to-report valid-next-locations [a-person] ; reports locations that are not walls or fire
  let x1 [xcor] of a-person
  let y1 [ycor] of a-person
  let valid-neighbors (list)
  let n 5
  let max-width 3
  let max-height 2
  let all-positions  get-grid n max-width max-height x1 y1
  foreach all-positions
  [[pos] ->
    let x2 (first pos)
    let y2 (last pos)

    if patch x2 y2 != nobody and [not any? fires-here with [color = red]] of patch x2 y2 ;;can't have fire
    [
      if not any? ([((turtle-set walls windows) in-radius max-wall-distance
        with [intersection x1 y1 x2 y2 (first first-end) (last first-end) (first second-end) (last second-end)])
      ] of patch x2 y2) [

        set valid-neighbors fput pos valid-neighbors
      ]
    ]
  ]
  report valid-neighbors
end

to-report get-grid [n max-width max-height startx starty]
  let stepx max-width / (2 * n )
  let stepy max-height / (2 * n)
  let minx startx - n * stepx
  let miny starty - n * stepy
  let maxx startx + n * stepx
  let maxy starty + n * stepy
  let result (list)
  let currx minx
  while [currx <= maxx]
  [
    let curry miny
    while [curry <= maxy]
    [
      set result fput (list (precision currx 2) (precision curry 2)) result
      set curry curry + stepy
    ]
    set currx currx + stepx
 ]
  report result
end

to-report argmin [alist f]
  let min-element (first alist)
  let min-value (runresult f (first alist))
  foreach alist
   [ [element] ->
     if (runresult f element) < min-value
     [
      set min-element element
      set min-value (runresult f element)
     ]
   ]
  report min-element
end

to diffuse-smoke [diffusion-rate ]
    ;; assumes patches-own [ value new-value ]
    if 0 > diffusion-rate or diffusion-rate > 1 [ diffuse plabel diffusion-rate ] ;; cause a run-time error

    ask patches with [inside-building?]
    [
      set temp-smoke (smoke * (1 - diffusion-rate)) +
      diffusion-rate * (sum [ smoke / (count neighbors with [inside-building?])  ] of neighbors with [inside-building?])
    ]
    ask patches with [inside-building?] [set smoke temp-smoke]
end

to die-by-fire ; prints the time the agent is removed from the simulation and that they died by fire
  show "Died by proximity to fire at second" ; this can be changed to output-print when the outputs are set up
  print ticks
  die ; removes from simulation
end

to exit-building ; prints the time the agent is removed from simulation
  show "Exited building at exit, time"
  print closest ; shows the closest exit, which should map the exit they exited by: this needs tested
  print ticks
  die ; removes from simulation
end
to recolor-patches
 ;Recolors patches based on time fire has reached a location/patch
   ask fires with [arrival < ticks][set color red]
  ask patches [ set pcolor scale-color white smoke 0 1]
end

to see ; needs to be made actually a cone
  ask people [set vision
   patches in-cone (10 - (10 * smoke)) (210 - (210 * smoke))]; people can 'see' normally in no smoke, but with drastically reduced vision as smoke approaches 1
  ; cone of radius 10 ahead of itself, angle is based on wikipedia field of view
end

to-report preferredexit
  ifelse visited? = false
    [report closestvisible]
    [report closest] ;the logic is that people with previous acquaintance with the bar will know where the exits are
end

to-report closestvisible ; selects closest visible exit
  let seen (any? exits in-cone (10 - (10 * smoke)) (210 - (210 * smoke)) = true) ; same parameters as 'see' - smoke reduces visual distance and peripheral vision, starts at 10m ahead and 210 degrees
  ifelse seen
  [report closest] ;if they can see an exit (including the main exit) they will head towards the closest
  [report exit 60];they would know the door they came in from
end

to-report closest ; selects closest exit regardless of visibility
  report (min-one-of exits [distance myself])
end

to-report within? [v v1 v2]  ;;
  report (v <= v1 and v >= v2) or (v <= v2 and v >= v1)
end

to-report intersection [x1 y1 x2 y2 x3 y3 x4 y4 ]
  ;show "--started--"
  ;show (list x1 y1 x2 y2 x3 y3 x4 y4)
  let m1 nobody
  let m2 nobody
  if x1 != x2 [set m1 (y2 - y1) / (x2 - x1)]
  if x3 != x4 [set m2 (y4 - y3) / (x4 - x3)]

  ;; is t1 vertical? if so, swap the two turtles
  if m1 = nobody
  [
    ifelse m2 = nobody
      [report false ]
      [ report intersection x3 y3 x4 y4 x1 y1 x2 y2 ]
  ]
  ;; is t2 vertical? if so, handle specially
  if m2 = nobody[
     ;; represent t1 line in slope-intercept form (y=mx+c)
      let c1 y1 - (x1 * m1)
      ;; t2 is vertical so we know x already
      let x x3
      ;; solve for y
      let y m1 * x + c1
      ;; check if intersection point lies on both segments
      if not within? x x1 x2 [ report false ]
      if not within? y y3 y4 [ report false ]

      report true
  ]
  ;; now handle the normal case where neither turtle is vertical;
  ;; start by representing lines in slope-intercept form (y=mx+c)
  let c1 y1 - (x1 * m1)
  let c2 y3 - (x3 * m2)
  ;treat collinear lines that are ontop of each other as intersecting
  if m1  = m2 [report c1 = c2 and (within? x1 x3 x4 or within? x2 x3 x4)]
  ;; now solve for x

  let x (c2 - c1) / (m1 - m2)
  ;; check if intersection point lies on both segments
  if not within? x x1 x2 [

   report false ]
  if not within? x x3 x4 [
   report false ]

  report true
end

to-report preferreddirection ; selects direction by either sending someone towards their loved ones or an exit
  ; they only go towards an exit if they stop caring, if their loved ones are within 2m, or if they are alone (either from the time they arrive or because people are dead
  if (group-type = 0) or ((no-links) = true)
      ; or (link-length < 2 myself) link-length is link-only and this is for turtles, unsure how to implement in this context
  [report preferredexit]
end

to-report fprivatespace ; applies only when distance between agent and other agent is less than the sphere of influence, which is 3m. citation forthcoming.
 if (distance (min-one-of other people [distance myself])) < 3
  [report 5 * ((1 / (distance (min-one-of other people [distance myself])))-(.3333))] ; original equation included 1/ influence distance, but proxemics indicates that 3m is the standard influence distance and a simplified version serves just as well
;original equation included 'dodging behavior' but inclusion in a* negates the necessity
end

to-report fwall ; also applies only in sphere of influence, constant is 1
  ifelse (distance (min-one-of walls [distance myself]) < 30)
    [report  1 * (1 /(distance (min-one-of walls [distance myself]) - .46) - .3333)] ; original equation included 1/'influence distance' which has been replaced by .3333 because 3m is the comfortable distance : need to find citation
      [report 0] ; reports number when the distance between the agent and the wall is less than 30, 0 when it's more than 30
      ;radius of agent is .46
end
to-report crowd-at-exit ; counts how many people are between the agent and their closest door
  ;this slightly discourages going to crowded exits
  let door (distance (min-one-of exits [distance myself])) ;does not incorporate vision, not sure how to do that
  report count people in-cone door 90
end

to-report fire-distance
  let door (distance (min-one-of exits [distance myself]))
  report 500 * (distance (min-one-of fires [distance myself])) ; runs based on how close fires are: multiplier is arbitary
end

to set-fh
ask people [set fh (1 - (1 / (fprivatespace + fwall + fire-distance + crowd-at-exit))) ;needs distance to exit too
    ]; values are presented as (1 - (1/ variable)) so that the heuristic will be admissable: that is, that it will never be larger than the movement cost
end ; with this configuration as the added variables get larger, the (1/ variable) number will get smaller, thus leaving the final fh closer to the upper bound of 1

to set-speed-limit ; units are m/s, from Isobe
  ask people [set speed-limit 1.1 + random-float .2]
end

to set-speed  ;; turtle procedure
  ;; count the people on the patch in front of the person
  let people-ahead people in-cone (1 - (1 * smoke)) (210 - (210 * smoke))
  ;; if there are people in front of the person and visible, slow down
  ;; otherwise, speed up
  ifelse any? people-ahead
    [ set speed [speed] of one-of people-ahead
      slow-down
    ]
  [speed-up ]
end

;; decrease the speed of the person
to slow-down  ;; turtle procedure
  ifelse speed <= 0
    [ set speed 0 ]
    [ set speed speed - acceleration ]
end
;; increase the speed of the person
to speed-up  ;; turtle procedure
  ifelse speed > speed-limit
    [ set speed speed-limit ]
    [ set speed speed + acceleration ]
end

;; establish goal of person and move to next patch along the way. does not yet use A* or prioritise people
to-report next-patch
  ifelse ((no-links) = false)
  [if (distance min-one-of link-neighbors [distance myself] < 2) [set goal preferredexit]]
   [set goal preferredexit]
  ;; CHOICES is an agentset of the candidate patches that the car can move to
  let choices neighbors with [pcolor != red and turtles-here != walls ] ;and not any? (turtle-set walls windows) in-radius max-wall-distance will cut out walls and windows and needs to go SOMEWHERE
  ;; choose the patch closest to the goal, this is the patch the car will move to
  let choice min-one-of choices [ distance [ goal ] of myself ] ; this needs to be min fh
  ;; report the chosen patch
  report choice
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
660
305
-1
-1
13.0
1
10
1
1
1
0
0
0
1
0
33
0
21
0
0
1
ticks
30.0

BUTTON
32
22
121
55
death test
ask people with[ age > 23] [die]
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
28
68
94
101
setup
setup\n
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
104
68
167
101
NIL
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

BUTTON
28
110
91
143
step
go
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

This is a model of the evacuation from the Station Nightclub Fire in Rhode Island in 2003. It uses agent-based modeling and information from interviews and documentation of technical aspects of the fire.

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

thick-line
true
0
Line -7500403 true 150 0 150 300
Rectangle -7500403 true true 135 0 165 300

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
NetLogo 6.0.2
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
