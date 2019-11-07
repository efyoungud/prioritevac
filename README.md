##Simulation##
This simulation is of the 2003 Station Nightclub Fire and is part of the Interdependencies in Community Resilience (ICoR) project (http://www-personal.umich.edu/~eltawil/icor.html). The final simulation consists of several components.

* Physical Environment
* Fire
* Smoke
* Agents (people)
* Behavior consisting of several components, including pathfinding and prioritization.

##How to Run##
 NetLogo is required to run this simulation. Download here: https://ccl.northwestern.edu/netlogo/. When installed, the RAM NetLogo has access to must be increased from
 1024 bytes to at least 3000 in order to accommodate the size of PrioritEvac.
 
 Download, at minimum, all of the files in the main folder. The results folder is optional, containing all prior results of the simulation, run with different
 parameters. Those can be used to examine the validity of the code and prior variables explored, or you can run the program yourself.
 
 To run, open NetLogo, then use NetLogo to open PrioritEvac.nlogo. Adjust the sliders to preferred levels for testing: high threshold means groups are more
 easily abandoned, high group constants mean high loyalty, and high danger-sensitivity means that agents are more inclined to avoid dangerous exits even if
 they're closer. Hit the "setup" button. This sets up the nightclub environment before the fire started. To advance one tick, hit "step." To run indefinitely,
 hit "go." To run for 180 simulated seconds (the effective duration of the evacuation for this dataset) and then export a results file, hit "master-run."
 
 The dataset included is of the 2003 Station nightclub fire in Warwick, Rhode Island. All data has been anonymized.

##Component Details##  
  -Physical Environment: The physical environment models the ground level of The Station nightclub in Warwick,
  RI. The building had four exits (designated by red in the simulation) and eleven windows (yellow).
  The walls of the building (blue) remained intact throughout the fire. The environment was created using a drawing
  of the club and plotting the lines on top, and then uploading an image of just the walls so that those aspects of the building 
  that weren't damaged by fire can act as both agents and objects.

 -Fire & Smoke: The fire and smoke models are based on the temperatures within in an area provided by the NIST
documentation. Based on Nist's temperature model, we assume that there were fires in locations
(at 1.5m height for the first 90 seconds, then at .6m height for the rest of the fire) exceeding 200 celsius.
The fire starts on stage near the pyrotechnics and eventually spreads throughout the nightclub. Based on NIST documentation and a video of the nightclub fire, 
we model two front-facing windows being broken down by attendees wanting to escape at 90 and 104 seconds. When these windows become exits,
 they change their color from yellow to red to signify occupants are able to leave through them.
 
 -Agents (people): Agents within the model are based on people in attendence at the night of the fire. Information was
 collected on all people where possible and included their age, sex, group type, group number, and if they had visited the club prior
 to the night of the fire. Our model presents the agents placed within their area based on their initial location.
 Placement of these agents is randomized based on their initial location given the area that they are in (bar area, dance floor,
 etc). Reported ecologies and all additional details come from interviews with survivors of the fire. 

##Codebook for Group Types##

0 = Alone (no group relationships)
1 = Work/Business associates
2 = Friendships
3 = Dating partners
4 = Family members/Spouses
5 = More than one type of relationship