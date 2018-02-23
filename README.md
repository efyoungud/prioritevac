##Simulation##
This simulation is of the 2003 Station Nightclub Fire and is part of the Interdependencies in Community Resilience (ICoR) project. The final simulation will consist of several components.

* Physical Environment
* Fire
* Smoke
* Agents (people)
* Behavior consisting of several components, including pathfinding and group-finding.
* Results
 

##Component Details##
Physical environment, fire, and smoke all built by Matt Saponaro.  
  -Physical Environment: The physical environment models the ground level of The Station nightclub in Warwick
  Rhode Island. The building had four exits (designated by red in the simulation) and eleven (yellow).
  The walls of the building (blue) remains intact throughout the fire; however, the fire reaches the windows
  towards the end of the disaster.

 -Fire & Smoke: The fire and smoke models are based on the temperatures within in an area provided by the NIST
documentation <insert ref>. Based on Nist's temperature model, we assume that there were fires in locations
(at 1.5m height for the first 90 seconds, then at .6m height for the rest of the fire) exceeding 200 celsius.
The fire starts on stage near the pyrotechnics and eventually spreads throughout the night club.
For our simulation, we represent a "tick" as a second in real-time. Based on NIST documentation <insert ref>
and a video of the nightclub fire, we model two front-facing windows being broken down by attendees wanting to
escape at 90 and 104 seconds. In our simulation, when these windows become exits, they change their color from
yellow to red to signify occupants are able to leave.
 
 -Agents (people): Agents within the model are based on people in attendence at the night of the fire. Information was
 collected on all people and included their age, sex, group type, group number, and if they had visited the club prior
 to the night of the fire. Our model presents the agents placed within their area based on their initial location.
 Placement of these agents is randomized based on their initial location given the area that they are in (bar area, dance floor,
 etc).
	
People were built by Matt Saponaro and Eileen Young. Placement within reported ecologies was done by Nihar Junagade.
Reported ecologies and all additional details come from interview with survivors of the fire.
Information from interviews has been anonymized for use in the simulation. The code book describes how the
information is structured.

##Git Status##
Master contains latest fully working copy.

Selected windows have now been updated to become exits at timings based on NIST documentation.

Boards contain current to do list as well as items underway.

http://udspace.udel.edu/handle/19716/35 is a link to the DRC library.

##Citations##

From Setup:

Isobe, Motoshige, Taku Adachi and Takashi Nagatani, Experiment and simulation of pedestrian counter flow, Physica A: Statistical Mechanics and its Applications,
Volume 336, Issues 3–4,2004, Pages 638-650, ISSN 0378-4371,
https://doi.org/10.1016/j.physa.2004.01.043. (http://www.sciencedirect.com/science/article/pii/S037843710400130X)