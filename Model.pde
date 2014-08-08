// This file defines the structural model of where lights
// are placed. It can be extended and tacked onto, and each
// light point can exist anywhere in 3-D space. The model
// can be iterated over to visit all the points, and each
// point has an index into the underlying color buffer.

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

static class Model extends LXModel {

  public static final int NUM_STRIPS = 30;
  public static final int STRIP_SPACING = 9*INCHES;

  public final List<Strip> strips;

  Model() {
    super(new Fixture());
    Fixture f = (Fixture) fixtures.get(0);
    this.strips = Collections.unmodifiableList(f.strips);
  }

  private static class Fixture extends LXAbstractFixture {

    public static final int NUM_TALL_PORT_STRIPS = 30; // 6 back, 24 left
    public static final int NUM_TALL_STARBOARD_STRIPS = 36; // 6 back, 24 left (4 skipped), 4 front
    private final List<Strip> strips = new ArrayList<Strip>();


    private static boolean portGap(int i) {
      // There's a gap for the driver's door
      return i > 8 && i <10;
    }

    private static boolean starboardGap(int i) {
      // There's a gap for the stairs and ice-cavern entrance
      return i > 5 && i <= 9;
    }
    
    Fixture() {
      // Build an array of strips, from left to right, some will be skipped to make a gap
      Strip strip;
      
      // Starboard side 
      for (int i = 0; i < NUM_TALL_STARBOARD_STRIPS; ++i) {
        if (!starboardGap(i)) {
          strip = new Strip(0, i*STRIP_SPACING);
          strips.add(strip);
          addPoints(strip);
        }
      }
      
      // Port side
      for (int i = 0; i < NUM_TALL_PORT_STRIPS; ++i) {
        if (!portGap(i)) {
          strip = new Strip(9*FEET, i*STRIP_SPACING);
          strips.add(strip);
          addPoints(strip);
        }
      }
    }
  }
}

static class Strip extends LXModel {

  public static final int NUM_POINTS = 100;
  public static final float POINT_SPACING = METER / 30.;

  public final float x;
  public final float z;

  Strip(float z, float x) {
    super(new Fixture(z, x));
    this.z = z;
    this.x = x;
  }

  private static class Fixture extends LXAbstractFixture {
    Fixture(float z, float x) {
      // Points in each strip are added from bottom to top
      for (int i = 0; i < NUM_POINTS; ++i) {
        addPoint(new LXPoint(x, i*POINT_SPACING, z));
      }
    }
  }
}
