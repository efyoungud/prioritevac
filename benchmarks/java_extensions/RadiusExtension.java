/**
 * Created by ningjing on 4/15/17.
 */
import org.nlogo.api.*;

public class RadiusExtension extends DefaultClassManager {
   public void load(PrimitiveManager primitiveManager) {
        primitiveManager.addPrimitive("square-filter", new SquareFilter());
        primitiveManager.addPrimitive("pythagorean", new Pythagorean());
        //primitiveManager.addPrimitive("radial", new Radial());
    }
}