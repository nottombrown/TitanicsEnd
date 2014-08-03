// This file defines the structural model of where lights
// are placed. It can be extended and tacked onto, and each
// light point can exist anywhere in 3-D space. The model
// can be iterated over to visit all the points, and each
// point has an index into the underlying color buffer.

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

static class Model extends LXModel {
  
  public static final int NUM_STRIPS = 24;
  public static final int STRIP_SPACING = 8*INCHES;  
  
  public final List<Strip> strips;
  
  Model() {
    super(new Fixture());
    Fixture f = (Fixture) fixtures.get(0);
    this.strips = Collections.unmodifiableList(f.strips);
  }
  
  private static class Fixture extends LXAbstractFixture {
    
    private final List<Strip> strips = new ArrayList<Strip>();
    
    Fixture() {
      // Build an array of strips, from left to right
      for (int i = 0; i < NUM_STRIPS; ++i) {
        Strip strip = new Strip(i*STRIP_SPACING);  
        strips.add(strip);
        addPoints(strip);
      }
    }
  }
}

static class Strip extends LXModel {
  
  public static final int NUM_POINTS = 100;
  public static final float POINT_SPACING = METER / 30.;
  
  public final float x;
  
  Strip(float x) {
    super(new Fixture(x));
    this.x = x;
  }
  
  private static class Fixture extends LXAbstractFixture {
    Fixture(float x) {
      // Points in each strip are added from bottom to top 
      for (int i = 0; i < NUM_POINTS; ++i) {
        addPoint(new LXPoint(x, i*POINT_SPACING, 0));
      }
    }
  }
}
