import org.nlogo.api.*;
import org.nlogo.core.AgentKindJ;
import org.nlogo.core.Syntax;
import org.nlogo.core.SyntaxJ;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by ningjing on 4/15/17.
 */
public class Pythagorean implements Reporter {
    // take one number as input, report a list
    public Syntax getSyntax() {
        return SyntaxJ.reporterSyntax(
                new int[] {Syntax.AgentType(),Syntax.AgentsetType(), Syntax.NumberType()}, Syntax.AgentsetType());
    }

    public Object report(Argument args[], Context context)
            throws ExtensionException {
        // create a NetLogo list for the result
        //LogoListBuilder list = new LogoListBuilder();

        List<Agent> list = new ArrayList<Agent>();
        AgentSet agents;
        Agent caller;
        double radius;
        // use typesafe helper method from
        // org.nlogo.api.Argument to access arguments
        try {
            caller = args[0].getAgent();
            agents = args[1].getAgentSet();
            radius = args[2].getDoubleValue();
        }
        catch(LogoException e) {
            throw new ExtensionException(e.getMessage());
        }

        Patch startPatch;
        double startX, startY;

        if (caller instanceof Turtle) {
            Turtle startTurtle = (Turtle) caller;
            startPatch = startTurtle.getPatchHere();
            startX = startTurtle.xcor();
            startY = startTurtle.ycor();
        } else {
            startPatch = (Patch) caller;
            startX = startPatch.pxcor();
            startY = startPatch.pycor();
        }
        World world = caller.world();
        int r = (int) StrictMath.ceil(radius);
        //set bounding area
        int minPxcor = world.minPxcor();
        int minPycor = world.minPycor();
        int maxPxcor = world.maxPxcor();
        int maxPycor = world.maxPycor();
        int xdiff = minPxcor - startPatch.pxcor();
        int dxmin = StrictMath.abs(xdiff) < r ? xdiff : -r;
        int dxmax = StrictMath.min(maxPxcor - startPatch.pxcor(), r);
        //build the resulting list
       for(int dx= dxmin; dx <= dxmax; dx++){
           int y0 = (int) StrictMath.sqrt(r* r - dx * dx);
           int dymin = StrictMath.max(minPycor - startPatch.pycor(), -y0);
           int dymax = StrictMath.min(maxPycor - startPatch.pycor(), y0);
           for(int dy = dymin; dy <= dymax; dy++){
               try {
                   list.add(startPatch.getPatchAtOffsets(dx, dy));
               }
               catch (AgentException e) {
                   org.nlogo.api.Exceptions.ignore(e);
               }
           }
       }
       return org.nlogo.agent.AgentSet.fromArray(caller.kind(), list.toArray(new org.nlogo.agent.Agent[list.size()]));
        //return list.toLogoList();
    }
}
/*for x in [-floor(r), floor(r)]
    y_max = floor(sqrt(r^2 - x^2))    # Pythagora's theorem
    for y in [-y_max, y_max]
        # (x, y) is good !*/