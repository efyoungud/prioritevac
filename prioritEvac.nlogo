breed [ walls wall]
breed [ exits exit]
breed [ windows window]
breed [ fires fire]
breed [ smoky smoke]
breed [ people person]
undirected-link-breed [friends friend]
undirected-link-breed [coworkers coworker]
undirected-link-breed [partners partner]
undirected-link-breed [families family]
undirected-link-breed [multiples multiple]
walls-own [first-end second-end]
exits-own [first-end second-end patch-past appeal]
windows-own [first-end second-end]
fires-own [arrival]
smoky-own [arrival level]
people-own [gender alarmed? age visited? group-number group-type group-constant path vision speed leadership-quality leader  ;; the speed of the turtle
  goal  energy  next-desired-patch ;; where am I currently headed
 speed-limit time-group-left noted-exits goals-over-time distance-to-exits traits-list]
globals [acceleration max-wall-distance scale-modifier p-valids start final-cost;; the constant that controls how much a person speeds up or slows down by if it is to accelerate or decelerate
 count-dead count-at-main count-at-bar count-at-kitchen count-at-stage count-at-bar-windows count-at-sunroom-window master-list]

patches-own [ temp-smoke fh father cost-path visited-patch? active? ;; true if the patch is at the intersection of two roads
available
  ]
;;------------------
extensions [csv profiler vid]
__includes [ "tests.nls" "goal-setting.nls" "setup.nls" "paths.nls" "utilities.nls" "leave-simulation.nls"]

to go ; master command to run simulation
 tick ; makes one second of time pass
   ;If Arrival time of fire is less than time (in seconds), smoke is set off in that area,
  ;people in that area die and surrounding people that live move to the closest exit
  set-fh
  ask people [ prioritize-group
    ifelse alarmed? != true [alert]
    [     move
    ; set goals-over-time lput goal goals-over-time
    ]
    injure
  ]
  ;Windows are turned into exits based on timings provided by NIST Documentation
  ;Windows are then recolored to represent exits
  if ticks = 94 [ ask windows with [who = 57 or who = 34] [ set breed exits set color hsb  0  50 100] ask exit 57 [set appeal -10] ask exit 34 [set appeal -1]  ask people [preferreddirection]]
  if ticks = 105 [ ask windows with [who = 59] [ set breed exits set color hsb  0  50 100 set appeal -12] ask people [preferreddirection]]
  recolor-patches
  ask patches with [pcolor > 50] [set available false]
end

to create-vid-interface
   setup
  vid:start-recorder
  vid:record-interface
  while [ticks < 180]
  [carefully [go vid:record-interface]
    [ask people [preferreddirection] go vid:record-interface]]
  vid:save-recording "prioritevac_interface.mp4"
end

to create-vid-view
   setup
  vid:start-recorder
  vid:record-view
  while [ticks < 180]
  [carefully [go vid:record-view]
    [ask people [preferreddirection] go]]
  export-results
  vid:save-recording "prioritevac_view_defense.mp4"
end

to srti-lists
 ask people [ foreach [self] of people [
  set traits-list (list (who) (color) (heading)(xcor)(ycor)(shape)(breed)(hidden?)(size) (alarmed?) (age)(visited?)(group-number) (group-type) (group-constant)(speed) (leadership-quality) (leader) (goal) (energy)(speed-limit)
  )]] ; doesn't include next-desired-patch or path because that's calculated each step
  set master-list [traits-list] of people
end

to srti-go ; go command for SRTI integration
  go
  srti-lists
end

to master-run ; runs the whole simulation for 200 seconds and then exports results
  setup
  while [ticks < 180]
  [carefully [go]
    [ask people [preferreddirection] go]] ; if an error is encountered it is expected to be in priorities
  ; so people are asked to reassess their priorities and then go
  ask people [set count-dead count-dead + 1 die]
  export-results
end

to move ; governs where and how people move, triggers goal-setting
  preferreddirection ;assess goals
  set-path ; circumstances are dynamic, so paths also need to be
  face next-desired-patch ;; person heads towards its goal
  set-speed
  repeat speed [move-to next-desired-patch if path != false and length path > 1 [set path remove-item 0 path] set-next-desired-patch
  if any? exits with [intersects-here exits] = true ; if the person passes through an exit, they leave
    [exit-building]]
   ask patches with [available = false] [ask people-here [move-to min-one-of patches with [available != false] [distance myself]]]
end

to recolor-patches ; recolors patches subject to the hazards present
 ;Recolors patches based on time fire has reached a location/patch
   ask fires with [arrival < ticks][set color red]
  ask smoky with [arrival < ticks][set color scale-color white level 0 100]
end

to-report see [agentset] ; makes it dynamic rather than static and frequently updated, also restricts by kind of thing people are looking at
  let obscured-patches patches with [pcolor = white or pcolor = hsb 216 50 100] in-cone (100 * scale-modifier) 180 ; can't see through walls or thick smoke
  report agentset in-cone ((100 * scale-modifier) - (count obscured-patches)) (180 - (count obscured-patches)) ; 10m distance except when there's stuff
end

to export-results ; creates a csv with all of the parameters for the simulation as well as the results
  export-world (word "results" random-float 1.0".csv")
end

to set-speed  ; how fast people will go
  ;; count the people in a meter in front of a person
  let people-ahead other people in-cone (10 * scale-modifier) 180
  ;; if there are people in front of the person and within one meter
  ;; otherwise, speed up
  ifelse any? people-ahead
    [ set speed [speed] of one-of people-ahead slow-down] ; people match speeds and slow down when there's someone within a meter in front of them to avoid collision
  [speed-up ]
  if speed <= 1 [speed-up]
end

to speed-up  ;; turtle procedure to increase the speed of the person
  ifelse speed > speed-limit
    [ set speed speed-limit ] ; cannot go faster than speed limit
    [ set speed speed + acceleration ]
end

to slow-down
  if speed > 1
  [set speed speed - (acceleration / 10)]
end

to alert ; manages alert, aim is for activation between 10 and 24 seconds in order to mimic actual events
  let visible-smoke count smoky with [arrival < ticks] ; smoke that has arrived. does not discriminate by amount of smoke. all smoke would be considered alarming
  ;perpetual issue of visibility: it's defined as an agentset, and people can see through walls
  let seen people in-cone (100 * scale-modifier) 180 with [alarmed? = true]
  let proximal people in-radius (50 * scale-modifier) with [alarmed? = true]
  let visible-fire fires with [arrival < ticks] in-cone (100  * scale-modifier) 180
  let smoky-patches smoky with [arrival < ticks] in-radius (50 * scale-modifier)
  if (count seen + count visible-fire + count proximal + count smoky-patches ) > 10
  [set alarmed? true set speed 1] ; aim is for an average of 29s per Ben's comment
end

to note-exits
  set noted-exits (list ([self] of see exits) ([self] of exits with [distance myself < 5]) ([self] of exits with [appeal < 0]) (exit 60))
  ; will note exits they can see, exits less than half a meter away
; the bar exit had a sign and the broken windows would have made noise and caused a shift in the traffic of the room, meaning they would have 'appeal'
end

to-report crowdedness ; measures how crowded an area is
  report count people in-radius (2 * scale-modifier)
end

to-report fire-distance ; reports distance to closest fire
  let lit-fires fires with [arrival < ticks] ; only the firest that are actually active are counted
  ifelse count lit-fires = 0 [report 0] ; if there are no currently active fires, reports 0
  [ report distance (min-one-of lit-fires [distance myself])] ; reports the distance to the closest fire, since the closest would presumably be the most relevant
end

to-report smoke-distance ; reports distance to the closest smoke
 let active-smoke smoky with [arrival < ticks] ; only the firest that are actually active are counted
  ifelse count active-smoke = 0 [report 0] ; if there are no currently active fires, reports 0
  [ report distance (min-one-of active-smoke [distance myself])]
end

to set-fh ; reports total heuristic preference
   ask patches [carefully ; carefully means that if fire-distance and crowdedness are 0 there's no error from dividing by 0 but also the two things only need to be called once instead of twice
    [set fh (1 - (1 /  (fire-distance + crowdedness + smoke-distance)))]
    [set fh 0]]; values are presented as (1 - (1/ variable)) so that the heuristic will be admissable: that is, that it will never be larger than the movement cost
end ; with this configuration as the added variables get larger, the (1/ variable) number will get smaller, thus leaving the final fh closer to the upper bound of 1

to-report group-heuristic
  ifelse (fire-distance + smoke-distance) != 0
  [ report 1 - (1 / (fire-distance + smoke-distance))]; fire distance is going to be a large number that gets smaller as the fire gets closer
  ; that means that when the fire is far away, the heuristic here is closer to 1
  ; as the fire gets closer, it will get smaller
  [ report 1] ; if the distance is 0, the multiplier should just be 1
end

to prioritize-group ; dictates when people will stop caring about still-living group members
  let people-with-links people with [count my-links > 0]
  ask people-with-links with [(group-constant * group-heuristic) < threshold] [
    ask my-links [die] preferreddirection
    set time-group-left ticks] ; as the heuristic gets smaller, it will eventually hit a threshold, which will be tested
end

to set-group-constant ; allows people to have different values for the degree to which they prioritize their groups, based on group type
  if group-type = 1 [set group-constant Coworkers-Constant]
  if group-type = 2 [set group-constant Friends-Constant]
  if group-type = 3 [set group-constant Dating-Constant]
  if group-type = 4 [set group-constant Family-Constant]
  if group-type = 5 [set group-constant Multiple-Constant]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
880
441
-1
-1
2.0
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
330
0
210
0
0
1
ticks
30.0

BUTTON
99
88
191
121
master run
master-run
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
23
50
89
83
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
99
50
162
83
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
23
87
90
120
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
25
189
197
222
threshold
threshold
0
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
24
228
196
261
Coworkers-Constant
Coworkers-Constant
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
24
270
196
303
Friends-Constant
Friends-Constant
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
24
310
196
343
Dating-constant
Dating-constant
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
24
349
196
382
Family-constant
Family-constant
0
100
40.0
1
1
NIL
HORIZONTAL

SLIDER
23
389
195
422
Multiple-constant
Multiple-constant
0
100
40.0
1
1
NIL
HORIZONTAL

OUTPUT
23
443
554
535
11

PLOT
23
538
554
739
Links
time
Links and turtles
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"People" 1.0 0 -16777216 true "" "plot count people"
"Links" 1.0 0 -7500403 true "" "plot count links"

SWITCH
23
10
131
43
Full-Scale
Full-Scale
0
1
-1000

TEXTBOX
31
170
184
188
Group Loyalty
11
0.0
1

PLOT
575
541
775
691
Exit Counts
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Bar" 1.0 0 -16777216 true "" "plot count-at-bar"
"Main" 1.0 0 -7500403 true "" "plot count-at-main"
"Kitchen" 1.0 0 -2674135 true "" "plot count-at-kitchen"
"Stage" 1.0 0 -955883 true "" "plot count-at-stage"
"Dead" 1.0 0 -6459832 true "" "plot count-dead"
"Windows" 1.0 0 -1184463 true "" "plot count-at-bar-windows + count-at-sunroom-window"

SLIDER
586
459
758
492
Injury-divisor
Injury-divisor
0
100
70.0
1
1
NIL
HORIZONTAL

BUTTON
23
124
97
157
NIL
srti-lists
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

This is a social science-centered behavioral model of evacuation from a building fire. It incorporates group loyalty and leadership factors.

## HOW IT WORKS

The building layout, fire, smoke, and details about the people who were there is all read in from external CSVs.

## HOW TO USE IT

The full-scale toggle on the interface determines whether you're running the model at full scale (complete, operational) or at 1/100th scale, which is quick and can quickly determine if there is an obvious point of failure but lacks full functionality.

The group loyalty sliders determine what level of loyalty group members have to each other. For each of them, when environmental stressors drop the group loyalty heuristic below the threshold, people will abandon their groups for self-preservation. The threshold means that it is easy for people to abandon their groups with higher threshold numbers and harder as the threshold numbers decrease.

It can then be run in two different ways. Setup followed by 'go' will run the simulation indefinitely. Setup followed by 'step' will advance the simulation one tick. 'Step' can be used to run the model as many times as desired. Master-run will set up the model, run it for 180 ticks, and export the results as a .csv.

## THINGS TO TRY

Try moving the sliders to see how group loyalty impacts evacuation and survival.

## EXTENDING THE MODEL

Additional factors in group leadership could be included.
Stairs are not accounted for at all.
Mobility and accessibility issues could be addressed.


## RELATED MODELS

Speed is from the traffic model in the model library. Best (2013) and Fang (2015) also informed the model.
A* implementation adapted from http://www.cs.us.es/~fsancho/?e=131

## CREDITS AND REFERENCES

Website: https://icor.engin.umich.edu/fire-evacuation/
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

molecule hydrogen
true
0
Circle -1 true false 138 108 84
Circle -16777216 false false 138 108 84
Circle -1 true false 78 108 84
Circle -16777216 false false 78 108 84

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
NetLogo 6.1.0
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
