##Simulation##
This simulation is of the 2003 Station Nightclub Fire and is part of the Interdependencies in Community Resilience (ICoR) project (http://www-personal.umich.edu/~eltawil/icor.html). The final simulation will consist of several components.

* Physical Environment
* Fire
* Smoke
* Agents (people)
* Behavior consisting of several components, including pathfinding and prioritization.
 

##Component Details##  
  -Physical Environment: The physical environment models the ground level of The Station nightclub in Warwick,
  Rhode Island. The building had four exits (designated by red in the simulation) and eleven windows (yellow).
  The walls of the building (blue) remains intact throughout the fire. The environment was created using a drawing
  of the club and plotting the lines on top, and then uploading an image of just the walls so that those aspects of the building 
  that weren't damaged by fire can act as both agents and objects.

 -Fire & Smoke: The fire and smoke models are based on the temperatures within in an area provided by the NIST
documentation. Based on Nist's temperature model, we assume that there were fires in locations
(at 1.5m height for the first 90 seconds, then at .6m height for the rest of the fire) exceeding 200 celsius.
The fire starts on stage near the pyrotechnics and eventually spreads throughout the night club.
For our simulation, we represent a "tick" as a second in real-time. Based on NIST documentation and a video of the nightclub fire, we model two front-facing windows being broken down by attendees wanting to
escape at 90 and 104 seconds. In our simulation, when these windows become exits, they change their color from
yellow to red to signify occupants are able to leave through them.
 
 -Agents (people): Agents within the model are based on people in attendence at the night of the fire. Information was
 collected on all people where possible and included their age, sex, group type, group number, and if they had visited the club prior
 to the night of the fire. Our model presents the agents placed within their area based on their initial location.
 Placement of these agents is randomized based on their initial location given the area that they are in (bar area, dance floor,
 etc).
  The X & Y positions of the people are fixed throughout the randomization process. The distribution of people features 
  (e.g. age, sex, group type) were uniformally randomly pulled with no replacement from the people.csv within each
  subecology. We apply this uniformally random distribution on the data since we do not have precise information regarding individual location
  rather we only know the general location (i.e. subecology) of individuals.
  
Reported ecologies and all additional details come from interview with survivors of the fire.
Information from interviews has been anonymized for use in the simulation. 


##Codebook for Group Types##

0 = Alone (no group relationships)
1 = Work/Business associates
2 = Friendships
3 = Dating partners
4 = Family members/Spouses
5 = More than one type of relationship

##Behavior
The primary determinant  of behavior is whether someone came alone or not. The purpose of this model is to 
examine group ties, so separating out those without group ties is a more important first step than differentiating 
by group type. If someone came alone, they then set a goal based on whether or not they have previous familiarity 
with the building. Those who had previously visited the nightclub are assumed to be familiar with its layout and
 use the closest exit, regardless of whether or not they could see it. Those who had not previously visited then 
 seek either the closest visible exit in a cone of visibility that is impacted by smoke or, if they are unable to see a 
 close exit, the main entrance. It is assumed that people would have entered through the main entrance and therefore
  remember approximately where it is. For all exits, when a person is very close to their goal exit, their goal becomes 
  the area outside: they want to be out of the nightclub. For people who came in groups, their goals are more complicated. 
  The primary question for this research is: at what point during a fire do group ties break down? Accordingly, people’s groups are differentiated by type. Coworker bonds are different from familial bonds, for example. At the outset, people search for their nearest group-member, and so that person becomes their goal.
However, group members already in close proximity to each other - roughly arms length, 2m - are considered to be able to act as a group: they know where that group-member is, and so no longer have to seek them. At that point, those group members in proximity to each other transition to leader-follower behavior. That is, a leader decides the subsequent goal and the followers keep the leader as their goal, setting up a follow-the-leader pattern. A group leader will continue to try to locate and accumulate group members until all are in close proximity, and then will search for either the closest or closest visible exit.


##Git Status##
Operational, still being calibrated.

##Citations##

From Setup:

Isobe, Motoshige, Taku Adachi and Takashi Nagatani, Experiment and simulation of pedestrian counter flow, Physica A: Statistical Mechanics and its Applications,
Volume 336, Issues 3�4,2004, Pages 638-650, ISSN 0378-4371,
https://doi.org/10.1016/j.physa.2004.01.043. (http://www.sciencedirect.com/science/article/pii/S037843710400130X)

For size of people:

Oberhagemann, D. (2012). Static and dynamic crowd densities at
major public events; (). Altenberge: German Fire Protection Association. Retrieved from https://www.vfdb.de/fileadmin/download/tb_13_01_crowd_densities.pdf