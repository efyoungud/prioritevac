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

##Codebook for People##
1. AGE

2. SEX
0 = Female
1 = Male

3. PRIOR VISIT (had been to the club before or not)
0 = No
1 = Yes

4. SEESPARKS (whether or not patron saw flames)
0 = No visual or auditory receipt of warning or perception of threat
1 = Seeing sparks, seeing flames, hearing warning of threat

5. LOCEVENTINT (location at the start of the fire)
1 = Horseshoe Bar
2 = Back Bar
3 = Soundboard/Dance Floor/Dining Area to left of stage
4 = In or Near Green House Area/Pool Tables
5 = Near Ticket Booth/Front Entrance
6 = Near bathrooms or in the hallway

6. LOCFOUNDDEAD-(DEAD ONLY)
1 = Horseshoe Bar
2 = Back Bar/Office
3 = Soundboard/Dance Floor/Dining Area to left of stage
4 = In or Near Green House Area/Pool Tables
5 = Near Ticket Booth/Front Entrance
6 = Near bathrooms or in the hallway
9 = N/A SURVIVOR

7. ACEXIT (actual exit used- SURVIVORS ONLY)
1 = Green House windows
2 = Main entrance
3 = Side exit by Horseshoe Bar
4 = Kitchen Exit
5 = Exit by Stage
6 = Windows near Horseshoe Bar
9 = N/A DECEASED

8. INTENDEXIT (intended exit)
1 = Green House windows
2 = Main entrance
3 = Side exit by Horseshoe Bar
4 = Kitchen Exit
5 = Exit by Stage
6 = Windows near Horseshoe Bar

9. EVACUATEALONE (evacuated alone or with others)
0 = Alone
1 = With others
9 = N/A Deceased??

10. EVACUATIONASSISTANCE (whether patron was assisted in escaping)
0 = No
1 = Yes
9 = N/A Deceased??

11. INJURIES
0 = No
1 = Yes (*Deceased are defaulted to “yes”)

12. DEAD
0 = Survived
1 = Dead

13. COconcentration (amount of CO concentration in blood-need to check with Dr. Laposata what units the numbers are measured in)
9999 = N/A SURVIVOR


Group Variables:

14. GROUPSIZE

Actual number of people in the group (1-10; 10 people was the largest group size)
99= MISSING GROUP SIZE 
22= Band or Entourage Members
33 = Station Employee

15. GROUPRELATIONS
0 = Alone (no group relationships)
1 = Work/Business associates
2 = Friendships
3 = Dating partners
4 = Family members/Spouses
5 = More than one type of relationship

16. GROUPMEMINJURIES
0 = No
1=Yes

17. GROUPASSIGNMENT

There are currently 211 groups. They are coded 1-211. People in the same group have the same “group assignment” number. 

Employees = GROUP 300

Band/Entourage = GROUP 400
Temporarily Excluded Variables

18. ADEVACUATE
0 = No
1 = Yes

19. HELPINGBEHAV
0 = No
1 = Yes
9= Outside Only

20. LEADERINSIDEOUTSIDE
0 = Outside
1 = Inside
2 = No leader

21. NUMBEROFLEADERS

22. MEDICALCARE
0 = No
1 = Yes
9 = N/A Deceased


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