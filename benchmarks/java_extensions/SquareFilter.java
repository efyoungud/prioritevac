import org.nlogo.agent.*;
import org.nlogo.api.*;
import org.nlogo.api.Agent;
import org.nlogo.api.AgentSet;
import org.nlogo.api.Patch;
import org.nlogo.api.Turtle;
import org.nlogo.api.World;
import org.nlogo.core.AgentKindJ;
import org.nlogo.core.Syntax;
import org.nlogo.core.SyntaxJ;
import org.nlogo.parse.SymbolType;
import org.nlogo.agent.ArrayAgentSet;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by ningjing on 4/15/17.
 */
public class SquareFilter implements Reporter {
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
        int count = 0;
        for(int dy = dymin; dy <= dymax; dy++){
            for(int dx = dxmin; dx <= dxmax; dx++){
                if (dx * dx + dy * dy <= r * r){
                    try {
                        list.add(startPatch.getPatchAtOffsets(dx, dy));
                    }
                    catch (AgentException e) {
                        org.nlogo.api.Exceptions.ignore(e);
                    }
                    //list.add(world.fastGetPatchAt( dx + (int) startX, dy +(int) startY));
                }
            }
        }
        return org.nlogo.agent.AgentSet.fromArray(caller.kind(), list.toArray(new org.nlogo.agent.Agent[list.size()]));
        //return list.toLogoList();
    }
}
/*
int minPxcor = world.minPxcor();
        int minPycor = world.minPycor();
        int maxPxcor = world.maxPxcor();
        int maxPycor = world.minPxcor();

        int r = (int) StrictMath.ceil(radius);
        int xdiff = minPxcor - startPatch.pxcor();
        int dxmin = StrictMath.abs(xdiff) < r ? xdiff : -r;
        int dxmax = StrictMath.min((maxPxcor - startPatch.pxcor()), r);
        int ydiff = minPycor - startPatch.pycor();
        int dymin = StrictMath.abs(ydiff) < r ? ydiff : -r;
        int dymax = StrictMath.min((maxPycor - startPatch.pycor()), r);

        for (int dy = dymin; dy <= dymax; dy++) {
            for (int dx = dxmin; dx <= dxmax; dx++) {
                try {
                    Patch patch = startPatch.getPatchAtOffsets(dx, dy);

                    if (sourceSet.kind() == AgentKindJ.Patch()) {
                        if (world.protractor().distance(patch.pxcor, patch.pycor, startX, startY, wrap) <= radius &&
                                (sourceSet == world.patches() || sourceSet.contains(patch))) {
                            result.add(patch);
                        }
                    } else if (sourceSet.kind() == AgentKindJ.Turtle()) {
                        // Only check patches that might have turtles within the radius on them.
                        // The 1.415 (square root of 2) adjustment is necessary because it is
                        // possible for portions of a patch to be within the circle even though
                        // the center of the patch is outside the circle.  Both turtles, the
                        // turtle in the center and the turtle in the agentset, can be as much
                        // as half the square root of 2 away from its patch center.  If they're
                        // away from the patch centers in opposite directions, that makes a total
                        // of square root of 2 additional distance we need to take into account.
                        if (world.rootsTable.gridRoot(dx * dx + dy * dy) > radius + 1.415) {
                            continue;
                        }
                        for (Turtle turtle : patch.turtlesHere()) {
                            if (world.protractor().distance(turtle.xcor(), turtle.ycor(), startX, startY, wrap) <= radius &&
                                    (sourceSet == world.turtles() ||
                                            // any turtle set with a non-null print name is either
                                            // the set of all turtles, or a breed agentset - ST 2/19/04
                                            (sourceSet.printName() != null &&
                                                    sourceSet == turtle.getBreed()) ||
                                            (sourceSet.printName() == null &&
                                                    sourceSet.contains(turtle)))) {
                                result.add(turtle);
                            }
                        }
                    }
                } catch (AgentException e) {
                    org.nlogo.api.Exceptions.ignore(e);
                }
            }
        }

        return list.toLogoList();
 */
