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
  	- Physical Environment: The physical environment consists of an interface of the ground level of The Station nighclub in Warwick Rhode Island. The
	building had 4 exits and were set to a red color to distinguish them from the model for significance while windows are represented with a yellow
	color. The building remains intact throughout the fire, however, up until the fire reaches near the windows.  
  	- Fire & Smoke: The spreading of the fire as well as the smoke is based on the temperatures within in an area provided by the NIST documentation.
	An equation is used to determine a range of temperatures to define whether an area of patches is light smoke, heavy smoke, light fire or heavy fire.
	The fire starts on stage near the pyrotechnics and eventually spreads throughout the night club with each "tick" (representing a second in real-time).
	Based on NIST documentation and a video of the nightclub fire, a couple front-facing windows towards the main exit were broken down by attendees
	wanting to escape. The transition from these windows becoming exits have been given an equation and change their color from yellow to red to signify
	an exit.
	
People were built by Matt Saponaro and Eileen Young. Placement within reported ecologies was done by Nihar Junagade. Reported ecologies and all additional details come from interview with survivors of the fire.
Information from interviews has been anonymized for use in the simulation. The code book describes how the information is structured.

##Git Status##
Master contains latest fully working copy.

Selected windows have now been updated to become exits at timings based on NIST documentation.

Boards contain current to do list as well as items underway.

http://udspace.udel.edu/handle/19716/35 is a link to the DRC library.

