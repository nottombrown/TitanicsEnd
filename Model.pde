// This file defines the structural model of where lights
// are placed. It can be extended and tacked onto, and each
// light point can exist anywhere in 3-D space. The model
// can be iterated over to visit all the points, and each
// point has an index into the underlying color buffer.

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

static class Model extends LXModel {

  public static final int NUM_STRIPS = 34; // Actual number of strips per side
  public static final int STRIP_SPACING = 9*INCHES;

  public final List<Strip> strips;

  Model() {
    super(new Fixture());
    Fixture f = (Fixture) fixtures.get(0);
    this.strips = Collections.unmodifiableList(f.strips);
  }

  private static class Fixture extends LXAbstractFixture {

    public static final int NUM_PORT_FRONT_STRIPS = 8; // 4 skipped for driver door
    public static final int NUM_PORT_SIDE_STRIPS = 24;
    public static final int NUM_PORT_BACK_STRIPS = 6;
    public static final int NUM_PORT_STRIP_LOCATIONS = NUM_PORT_FRONT_STRIPS + NUM_PORT_SIDE_STRIPS + NUM_PORT_BACK_STRIPS;

    public static final int NUM_STARBOARD_BACK_STRIPS = 6;
    public static final int NUM_STARBOARD_SIDE_STRIPS = 24; // 4 skipped for ice cavern door
    public static final int NUM_STARBOARD_FRONT_STRIPS = 8;
    public static final int NUM_STARBOARD_STRIP_LOCATIONS = NUM_STARBOARD_BACK_STRIPS + NUM_STARBOARD_SIDE_STRIPS + NUM_STARBOARD_FRONT_STRIPS;

    private final List<Strip> strips = new ArrayList<Strip>();

    private static boolean portGap(int i) {
      // There's a gap for the driver's door
      return i > 3 && i <= 7;
    }

    private static boolean starboardGap(int i) {
      // There's a gap for the stairs and ice-cavern entrance
      return i > 5 && i <= 9;
    }
    
    Fixture() {
      // Build an array of strips, from left to right, some will be skipped to make a gap
      Strip strip;
      
      // Starboard side 
      for (int i = 0; i < NUM_STARBOARD_STRIP_LOCATIONS; ++i) {
        if (!starboardGap(i)) {
          strip = new Strip(0, i*STRIP_SPACING);
          strips.add(strip);
          addPoints(strip);
        }
      }
      
      // Port side
      for (int i = 0; i < NUM_PORT_STRIP_LOCATIONS; ++i) {
        if (!portGap(i)) {
          strip = new Strip(9*FEET, (NUM_PORT_STRIP_LOCATIONS - 1 - i)*STRIP_SPACING);
          strips.add(strip);
          addPoints(strip);
        }
      }
    }
  }
}

static class Strip extends LXModel {

  public static final int NUM_POINTS = 100;
  public static final int NUM_POINTS_PER_PART = NUM_POINTS / 2;
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
      /**
       * Points in each strip are mapped in two sections: 
       * - the first half are added middle to top
       * - the second half are added middle to bottom
       */
      for (int i = 0; i < NUM_POINTS_PER_PART; ++i) {
        addPoint(new LXPoint(x, (NUM_POINTS_PER_PART + i)*POINT_SPACING, z));
      }

      // Points in each strip are added from bottom to top
      for (int i = 0; i < NUM_POINTS_PER_PART; ++i) {
        addPoint(new LXPoint(x, (NUM_POINTS_PER_PART - 1 - i)*POINT_SPACING, z));
      }
    }
  }
}
