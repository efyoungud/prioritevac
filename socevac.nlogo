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
people-own [gender alarmed? age visited? group-number group-type group-constant fh path vision speed current-path leadership-quality leader  ;; the speed of the turtle
  goal     next-desired-patch ;; where am I currently headed
speed-limit]
globals [max-wall-distance open closed optimal-path acceleration  p-valids start final-cost;; the constant that controls how much a person speeds up or slows down by if it is to accelerate or decelerate
  ]

patches-own [inside-building? parent-patch smoke temp-smoke f g h intersection?  father cost-path visited-patch? active? ;; true if the patch is at the intersection of two roads

  ]
;;------------------
extensions [csv profiler]
__includes [ "tests.nls" ]

to profile
  profiler:start         ;; start profiling
repeat 12 [ go ]       ;; run something you want to measure
profiler:stop          ;; stop profiling
print profiler:report
end

to alert ; manages alert, but with issues: 395 people are activated at tick 72, and all of them at tick 73, which is bad both because it's a rapid cascading effect and because it happens too late: aim is for activation between 24 and 30 seconds in order to mimic actual events
  ;perpetual issue of visibility: it's defined as an agentset, and people can see through walls
  let seen people in-cone (10 - (10 * smoke)) (210 - (210 * smoke)) with [alarmed? = true]
  let proximal people in-radius 5 with [alarmed? = true]
  let visible-fire fires with [color = red] in-cone (10 - (10 * smoke)) (210 - (210 * smoke))
  let visible-smoke patches with [smoke > .5 = true ] in-radius 5
  if (count seen + count visible-fire + count proximal + count visible-smoke) > 10
  [set alarmed? true]
end

to set-path
  set path A* patch-here goal
   ifelse path != false and length path > 1
    [set next-desired-patch item 1 path]
    [set next-desired-patch patch-ahead 1]
end

to set-f [destination-patch person-at-patch] ; sets the total f-score for relevant patches in order to look for the next patch
  let neighbor-list [self] of neighbors with [(pcolor = red) = false]
  foreach neighbor-list [set f ((distance destination-patch) + ([fh] of person-at-patch))]
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
  see
 ask walls [set color hsb  216 50 100  set intersection? true stamp]
 ask exits [set color hsb  0  50 100]
 ask windows [set color hsb 80 50 100]
 ask fires [ set color [0 0 0 0 ]
  if any? walls with [intersects-here walls] = true [set intersection? true]]
  ask people [preferreddirection set color white set-speed-limit set speed .1 + random-float .4 set leadership-quality 0
 ; if any? walls with [seen-walls] = true [set intersection? true]
  ]
 ;;there's initially no smoke
 ask patches [set smoke 0
    set father nobody
    set Cost-path 0
    set visited-patch? false
    set active? false]
end

to-report Total-expected-cost [#goal]
   report Cost-path  + heuristic #goal
  ;+ ([fh] of myself)
end

to-report Heuristic [#goal]
  report distance #Goal
end

to-report A* [#Start #goal]
  let #valid-map patches with [intersection? != true] ;and intersect-free-patches
  ; clear all the information in the agents
  ask #valid-map with [visited-patch?]
  [
    set father nobody
    set Cost-path 0
    set visited-patch? false
    set active? false
  ]
  ; Active the staring point to begin the searching loop
  ask #Start
  [
    set father self
    set visited-patch? true
    set active? true
  ]
  ; exists? indicates if in some instant of the search there are no options to
  ; continue. In this case, there is no path connecting #Start and #Goal
  let exists? true
  ; The searching loop is executed while we don't reach the #Goal and we think
  ; a path exists
  while [not [visited-patch?] of #goal and exists?]
  [
    ; We only work on the valid pacthes that are active
    let options #valid-map with [active?]
    ; If any
    ifelse any? options
    [
      ; Take one of the active patches with minimal expected cost
      ask min-one-of options [Total-expected-cost #goal]
      [
        ; Store its real cost (to reach it) to compute the real cost
        ; of its children
        let Cost-path-father Cost-path
        ; and deactivate it, because its children will be computed right now
        set active? false
        ; Compute its valid neighbors
        let valid-neighbors neighbors with [member? self #valid-map]
        ask valid-neighbors
        [
          ; There are 2 types of valid neighbors:
          ;   - Those that have never been visited (therefore, the
          ;       path we are building is the best for them right now)
          ;   - Those that have been visited previously (therefore we
          ;       must check if the path we are building is better or not,
          ;       by comparing its expected length with the one stored in
          ;       the patch)
          ; One trick to work with both type uniformly is to give for the
          ; first case an upper bound big enough to be sure that the new path
          ; will always be smaller.
          let t ifelse-value visited-patch? [ Total-expected-cost #goal] [2 ^ 20]
          ; If this temporal cost is worse than the new one, we substitute the
          ; information in the patch to store the new one (with the neighbors
          ; of the first case, it will be always the case)
          if t > (Cost-path-father + distance myself + Heuristic #goal)
          [
            ; The current patch becomes the father of its neighbor in the new path
            set father myself
            set visited-patch? true
            set active? true
            ; and store the real cost in the neighbor from the real cost of its father
            set Cost-path Cost-path-father + distance father
            set Final-Cost precision Cost-path 3
          ]
        ]
      ]
    ]
    ; If there are no more options, there is no path between #Start and #Goal
    [
      set exists? false
    ]
  ]
  ; After the searching loop, if there exists a path
  ifelse exists?
  [
    ; We extract the list of patches in the path, form #Start to #Goal
    ; by jumping back from #Goal to #Start by using the fathers of every patch
    let current #goal
    set Final-Cost ([Cost-path] of #Goal)
    let rep (list current)
    While [current != #Start]
    [
      set current [father] of current
      set rep fput current rep
    ]
    report rep
  ]
  [
    ; Otherwise, there is no path, and we return False
    report false
  ]
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

to read-fire-from-file [ filename] ; reads in the fire from a CSV
  ;;header: x y time
  let values bf csv:from-file filename
  foreach values
  [ [row] ->
    create-fires 1; this means the fires are always there, and so the patch color is the only way to access where a fire is at a certain tick
    [
      setxy item 0 row item 1 row
      set arrival item 2 row
      set color blue
    ]
  ]
end

to read-building-from-file [filename] ; reads in the building from a CSV
  let values bf csv:from-file filename
  foreach values
  [ [row] ->
    let breed-name item 0 row ; defines items
    let x1 item 1 row ; these define start and end points for a linear stretch
    let y1 item 2 row
    let x2 item 3 row
    let y2 item 4 row
    let component nobody
    if breed-name = "Exit" [ create-exits 1 [set component self]]
    if breed-name = "Window" [ create-windows 1 [set component self]]
     if breed-name = "Wall" [ create-walls 1 [setxy x1 y1 set color hsb  216 50 100 pd setxy x2 y2 pu set component self]] ; sets up the breed, putting set intersection? true after pd makes almost everything blocked off, but it does it to the whole patch and so nothing works
    ask component [ setxy ((x1 + x2) / 2) (y1 + y2) / 2]
    ask component [ facexy x1 y1]
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
     set size .5 ; based on crowding and evacuation from Oberhagen
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

to go ; master command to run simulation
 tick ; makes one second of time pass
   ;If Arrival time of fire is less than time (in seconds), smoke is set off in that area,
  ;people in that area die and surrounding people that live move to the closest exit
  ask fires with [arrival < ticks]
  [  ask patch-here [ set smoke 1]
    ask people-here [die-by-fire] ; people who are colocal with fire - not just close but in the fire - are presumed to die from it
  ]
  ask people [set-fh prioritize-group
    ifelse alarmed? = 0 [alert]
   [ move]
]
  ;Windows are turned into exits based on timings provided by NIST Documentation
  ;Windows are then recolored to represent exits
  if ticks = 94 [ ask windows with [who = 57 or who = 34] [ set breed exits set color hsb  0  50 100]]
  if ticks = 105 [ ask windows with [who = 59] [ set breed exits set color hsb  0  50 100]]
  diffuse-smoke 1 ; initiates smoke, should be replaced with smokeview csv when available
  recolor-patches
end

to-report seen-walls
   ;; each pair of segments checks for intersections
   let result intersection vision myself
  let intersect-here not empty? result
  ask walls [
    if not empty? result []
      ]
  report intersect-here
end

to-report intersects-here [ variety ]
   ;; each pair of segments checks for intersections
   let result intersection self myself
  let intersect-here not empty? result
  ask variety [
    if not empty? result []
      ]
  report intersect-here
end

;; reports a two-item list of x and y coordinates, or an empty
;; list if no intersection is found
to-report intersection [t1 t2]
  let m1 [tan (90 - heading)] of t1
  let m2 [tan (90 - heading)] of t2
  ;; treat parallel/collinear lines as non-intersecting
  if m1 = m2 [ report [] ]
  ;; is t1 vertical? if so, swap the two turtles
  if abs m1 = tan 90
  [
    ifelse abs m2 = tan 90
      [ report [] ]
      [ report intersection t2 t1 ]
  ]
  ;; is t2 vertical? if so, handle specially
  if abs m2 = tan 90 [
     ;; represent t1 line in slope-intercept form (y=mx+c)
      let c1 [ycor - xcor * m1] of t1
      ;; t2 is vertical so we know x already
      let x [xcor] of t2
      ;; solve for y
      let y m1 * x + c1
      ;; check if intersection point lies on both segments
      if not [x-within? x] of t1 [ report [] ]
      if not [y-within? y] of t2 [ report [] ]
      report list x y
  ]
  ;; now handle the normal case where neither turtle is vertical;
  ;; start by representing lines in slope-intercept form (y=mx+c)
  let c1 [ycor - xcor * m1] of t1
  let c2 [ycor - xcor * m2] of t2
  ;; now solve for x
  let x (c2 - c1) / (m1 - m2)
  ;; check if intersection point lies on both segments
  if not [x-within? x] of t1 [ report [] ]
  if not [x-within? x] of t2 [ report [] ]
  report list x (m1 * x + c1)
end

to-report x-within? [x]  ;; turtle procedure
  report abs (xcor - x) <= abs (size / 2 * dx)
end

to-report y-within? [y]  ;; turtle procedure
  report abs (ycor - y) <= abs (size / 2 * dy)
end

to move ; governs where and how people move, triggers goal-setting
 preferreddirection
  if path = 0 [set-path]
  if next-desired-patch = nobody [set-path]
   set-f goal self
  face next-desired-patch
  set-speed
    fd speed
  if any? exits with [intersects-here exits] = true
    [ exit-building] ;; person heads towards its goal
  if goal = nobody [preferreddirection set-path]
  if patch-here = next-desired-patch [set next-desired-patch nobody]
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

to recolor-patches ; recolors patches subject to the hazards present
 ;Recolors patches based on time fire has reached a location/patch
   ask fires with [arrival < ticks][set color red set intersection? true]
  ask patches [ set pcolor scale-color white smoke 0 1]
end

to see ; sets how far and how much people can see
  ask people [set vision
    patches in-cone (10 - (10 * smoke)) (210 - (210 * smoke)) ; people can 'see' normally in no smoke, but with drastically reduced vision as smoke approaches 1
    if empty? [self] of vision [set vision patch-ahead 1]] ; if everything is dense smoke such that negative numbers are produced, sets vision to 0
  ; cone of radius 10 ahead of itself, angle is based on wikipedia field of view
end

to-report preferredexit ; reports which exit should be the goal for a person
  ifelse (distance min-one-of exits [distance myself] < .2 )
  [report patch-ahead .2]
  [ ifelse visited? = false
    [report closestvisible]
  [report closest] ];the logic is that people with previous acquaintance with the bar will know where the exits are
end

to-report closestvisible ; selects closest visible exit
  let visibility [self] of vision ; defines the field of vision
  let seen patches with [visibility = true] ; only those patches in the field of vision are seen
  ifelse seen = true
  [report closest] ;if they can see an exit (including the main exit) they will head towards the closest
  [report exit 60];they would know the door they came in from
end

to-report closest ; selects closest exit regardless of visibility
  report (min-one-of exits [distance myself])
end

to preferreddirection ; sets the goal for a person, either the person or exit
  ; calls preferredexit, closest, closestvisible, and leader-follower functions
  ifelse any? link-neighbors = false ; sets the condition that if they came alone, ended up alone through losing their loved ones or deciding to no longer prioritize them then they go towards their preferred exit
  [set goal preferredexit] ; selects either closest or closest visible exit depending on visit history
  [ ifelse (distance min-one-of link-neighbors [distance myself] < 2 ) ; if they have loved ones they have not given up on, they go towards them
    [leader-follower] ; but if they are within two meters of their loved ones they switch to leader-follower behavior to work as a group
    [set goal min-one-of link-neighbors [distance myself]] ; people move towards their closest loved one
  ]
end

to set-leadership ; designates a group leader within a small group
   let close-group link-neighbors with [distance myself < 2] ; defines close groups as people with the same group number who are within 2 m
   ask close-group
    [set leadership-quality 0  + random-float 1 ; every time leadership has to be re-run they start fresh, with a small randomized element to ensure different scores when there would otherwise be ties
    foreach list (visited? = true) (gender = "male") ; needs something for less injured, also waiting to hear back about other factors
      [set leadership-quality leadership-quality + 1] ; for every leadership factor that applies, people receive one point
    if leader = true [set leadership-quality (leadership-quality * 2) ] ; if someone is already the leader, their score is doubled
    ]
    ask close-group with-max [leadership-quality] [set leader true]
end

to leader-follower ; designates a group leader within a small group and then sets subsequent behavior
 set-leadership
  let close-group link-neighbors with [distance myself < 2.1] ; defines close groups as people with the same group number who are within 2 m
  let group-leader close-group with [leader = true] ; defines who the leader is
 ; the person with the highest leadership quality is made the leader
  ask group-leader [ifelse goal = nobody or all? link-neighbors [distance myself < 2.1] or goal = 0; the leader selects the next goal. if the other people they were looking for are removed from simulation or all group members are within 2m, sets the goal for their preferred exit
    [set goal preferredexit]
    [set goal min-one-of link-neighbors with [distance myself > 2] [distance myself]]] ; aims for the closest group member who is outside the 2m radius
  ask close-group with [leader = 0] [set goal one-of group-leader set next-desired-patch one-of group-leader] ; other group members aim to follow the leader rather than set individual goals
end

to-report fprivatespace ; reports preference to maintain personal space
  ; applies only when distance between agent and other agent is less than the sphere of influence, which is 3m. citation forthcoming.
 ifelse (distance (min-one-of other people [distance myself])) < 3
  [report 5 * ((1 / (distance (min-one-of other people [distance myself])))-(1 / 3))]
  [report 0] ; original equation included 1/ influence distance, but proxemics indicates that 3m is the standard influence distance and a simplified version serves just as well
;original equation included 'dodging behavior' but inclusion in a* negates the necessity
end

to-report fwall ; reports preference to stay away from walls
  ; also applies only in sphere of influence, constant is 1
  ifelse (distance (min-one-of walls [distance myself]) < 30)
    [report  1 * (1 /(distance (min-one-of walls [distance myself]) - .5) - .3333)] ; original equation included 1/'influence distance' which has been replaced by .3333 because 3m is the comfortable distance : need to find citation
      [report 0] ; reports number when the distance between the agent and the wall is less than 30, 0 when it's more than 30
      ;radius of agent is .5
end
to-report crowd-at-exit ; counts how many people are between the agent and their closest door
  ;this slightly discourages going to crowded exits
  let door (distance (min-one-of exits [distance myself])) ;does not incorporate vision, not sure how to do that
  report count people in-cone door 90
end

to-report fire-distance ; reports distance to closest fire
  let door (distance (min-one-of exits [distance myself]))
  report 500 * (distance (min-one-of fires [distance myself])) ; runs based on how close fires are: multiplier is arbitary
end

to-report smoke-distance
; this needs to report smoke distance based on information from the CSV as soon as that's integrated
end

to set-fh ; reports total heuristic preference
ask people [set fh (1 - (1 / (fprivatespace + fwall + fire-distance + crowd-at-exit))) ;needs distance to exit too
    ]; values are presented as (1 - (1/ variable)) so that the heuristic will be admissable: that is, that it will never be larger than the movement cost
end ; with this configuration as the added variables get larger, the (1/ variable) number will get smaller, thus leaving the final fh closer to the upper bound of 1

to set-speed-limit ; how fast people can go
  ; units are m/s, from Isobe
  ask people [set speed-limit 1.1 + random-float .2]
end

to set-speed  ; how fast people will go
  ;; count the people on the patch in front of the person
  let people-ahead people in-cone (1 - (1 * smoke)) (210 - (210 * smoke))
  ;; if there are people in front of the person and visible, slow down
  ;; otherwise, speed up
  ifelse any? people-ahead
    [ set speed [speed] of one-of people-ahead
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

to prioritize-group ; dictates when people will stop caring about still-living group members
  ask links with [ [fh] of myself * [group-constant] of myself > threshold] [print "link severed" die] ; as the heuristic rises towards 1, it will eventually hit a threshold, which will be tested
end

to set-group-constant ; allows people to have different values for the degree to which they prioritize their groups, based on group type
  ask people [if group-type = 1 [set group-constant Coworkers-Constant]
  if group-type = 2 [set group-constant Friends-Constant]
  if group-type = 3 [set group-constant Dating-Constant]
  if group-type = 4 [set group-constant Family-Constant]
  if group-type = 5 [set group-constant Multiple-Constant]]
end

to-report next-patch ; selects the next patch a person will move towards
  let empty-patches neighbors with [not any? walls-here]
  ;; CHOICES is an agentset of the candidate patches that the person can move to
  let choices empty-patches with [(pcolor = red) = false]  ; this makes it so the next patch cannot have fire
; set choices remove invalid-next-locations self choices
 ; set-f goal self ; assigns f-scores for each neighbor based on the heuristic and the distance to the goal
  ;; choose the patch with the lowest f-score (closest to the exit and most desirable according to the heuristic), this is the patch the person will move to
 set choices sort-on [f] choices
  let choice first choices
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
1
1
1
ticks
30.0

BUTTON
32
22
121
55
death test
ask people with[ age > 1] [die]\nask people [preferreddirection]
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

SLIDER
28
155
200
188
threshold
threshold
0
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
28
193
200
226
Coworkers-Constant
Coworkers-Constant
0
100
32.0
1
1
NIL
HORIZONTAL

SLIDER
28
235
200
268
Friends-Constant
Friends-Constant
0
100
62.0
1
1
NIL
HORIZONTAL

SLIDER
28
275
200
308
Dating-constant
Dating-constant
0
100
75.0
1
1
NIL
HORIZONTAL

SLIDER
28
314
200
347
Family-constant
Family-constant
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
27
354
199
387
Multiple-constant
Multiple-constant
0
100
100.0
1
1
NIL
HORIZONTAL

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
