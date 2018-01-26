import org.nlogo.api.*;
import org.nlogo.core.AgentKindJ;
import org.nlogo.core.Syntax;
import org.nlogo.core.SyntaxJ;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by ningjing on 4/15/17.
 */
public class Radial implements Reporter {
    // take one number as input, report a list
    public Syntax getSyntax() {
        return SyntaxJ.reporterSyntax(
                new int[] {Syntax.AgentType(),Syntax.AgentsetType(), Syntax.NumberType()}, Syntax.AgentsetType());
    }

    public Object report(Argument args[], Context context)
            throws ExtensionException {
        List<Agent> list = new ArrayList<Agent>();
        AgentSet agents;
        Agent caller;
        int radius;
        // use typesafe helper method from
        // org.nlogo.api.Argument to access arguments
        try {
            caller = args[0].getAgent();
            agents = args[1].getAgentSet();
            radius = args[2].getIntValue();
        }
        catch(LogoException e) {
            throw new ExtensionException(e.getMessage());
        }

        Patch startPatch;
        int startX, startY;

        if (caller instanceof Turtle) {
            Turtle startTurtle = (Turtle) caller;
            startPatch = startTurtle.getPatchHere();
            startX = (int) startTurtle.xcor();
            startY = (int) startTurtle.ycor();
        } else {
            startPatch = (Patch) caller;
            startX = startPatch.pxcor();
            startY = startPatch.pycor();
        }
        World world = caller.world();
        int lowestPxCor = (int) Math.min(world.minPxcor(), startX - radius);
        int lowestPyCor = (int) Math.min(world.minPycor(), startY - radius);
        int largestPxCor = (int) Math.max(world.maxPxcor(), startX + radius);
        int largestPyCor = (int) Math.max(world.maxPycor(), startY + radius);

        int r = (int) StrictMath.ceil(radius);
        int minPxcor = world.minPxcor();
        int minPycor = world.minPycor();
        int maxPxcor = world.maxPxcor();
        int maxPycor = world.maxPycor();
        int xdiff = minPxcor - startPatch.pxcor();
        int dxmin = StrictMath.abs(xdiff) < r ? xdiff : -r;
        int dxmax = StrictMath.min((maxPxcor - startPatch.pxcor()), r);
        int ydiff = minPycor - startPatch.pycor();
        int dymin = StrictMath.abs(ydiff) < r ? ydiff : -r;
        int dymax = StrictMath.min((maxPycor - startPatch.pycor()), r);


        // add the full length vertical center line once
        for (int y = dymin; y <= dymax; ++y) {
            list.add(world.fastGetPatchAt(startX, y));
        }
        int sqRadius = radius * radius;

        // add the shorter vertical lines to the left and to the right
        int h = radius;
        for (int dx = dxmin; dx <= dxmax; ++dx) {
            // decrease h
            while (dx*dx + h*h > sqRadius && h > 0) {
                h--;
            }
            int lowestY = (int) Math.min(world.minPycor(),-h + startY);
            int highestY = (int) Math.min(world.maxPycor(), h + startY);
            //fill out right slice
            if(startX + dx <= largestPxCor){
                for (int y = lowestY; y <= highestY; ++y) {
                    list.add(world.fastGetPatchAt(startX + dx, y));

                }
            }
            //fill out left slice
            if(startX - dx >= lowestPxCor){
                for (int y = lowestY; y <= highestY; ++y) {
                    list.add(world.fastGetPatchAt(startX - dx, y));

                }
            }

        }

        return org.nlogo.agent.AgentSet.fromArray(caller.kind(), list.toArray(new org.nlogo.agent.Agent[list.size()]));
        //return list.toLogoList();
    }
}