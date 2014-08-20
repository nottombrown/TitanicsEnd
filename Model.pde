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

  public final List<LXModel> strips;

  Model() {
    super(new Fixture());
    Fixture f = (Fixture) fixtures.get(0);
    this.strips = Collections.unmodifiableList(f.strips);
  }

  private static class Fixture extends LXAbstractFixture {

    public static final int NUM_PORT_SIDE_STRIPS = 24;
    public static final int NUM_PORT_BACK_STRIPS = 12;
    public static final int NUM_PORT_STRIP_LOCATIONS = NUM_PORT_SIDE_STRIPS + NUM_PORT_BACK_STRIPS;

    public static final int NUM_STARBOARD_SIDE_STRIPS = 20; // 4 skipped for ice cavern door
    public static final int NUM_STARBOARD_STRIP_LOCATIONS = NUM_STARBOARD_SIDE_STRIPS;

    private final List<LXModel> strips = new ArrayList<LXModel>();

    private static boolean portGap(int i) {
      // There's a gap for the driver's door
      return false;//i >= 0 && i <= 3;
    }

    private static boolean starboardGap(int i) {
      // There's a gap for the stairs and ice-cavern entrance
      return false; //i >= 0 && i <= 3;
    }

    Fixture() {
      // Build an array of strips, from left to right, some will be skipped to make a gap
      LXModel strip;

      // Starboard side
      for (int i = 0; i < NUM_STARBOARD_STRIP_LOCATIONS; ++i) {
        if (!starboardGap(i)) {
          strip = new VerticalStrip(0, (4 + NUM_PORT_BACK_STRIPS + i)*STRIP_SPACING);
          strips.add(strip);
          addPoints(strip);
        }
      }

      for (int i = 0; i < 4; i++) {
        strip = new VerticalHalfStrip(0, (NUM_PORT_BACK_STRIPS + 4 + NUM_STARBOARD_STRIP_LOCATIONS + i)*STRIP_SPACING);
        strips.add(strip);
        addPoints(strip);
      }

      // Front of the car
      for (int i = 0; i < 2; i++) {
        strip = new HorizontalStrip((NUM_PORT_BACK_STRIPS + 4 + NUM_STARBOARD_STRIP_LOCATIONS + 4)*STRIP_SPACING, (11 - i)*STRIP_SPACING, 0);
        strips.add(strip);
        addPoints(strip);
      }

      for (int i = 0; i < 4; i++) {
        strip = new HorizontalStrip((NUM_PORT_BACK_STRIPS + 4 + NUM_STARBOARD_STRIP_LOCATIONS + 4)*STRIP_SPACING, (5 - i / 2.)*STRIP_SPACING, 0);
        strips.add(strip);
        addPoints(strip);
      }

      for (int i = 0; i < 4; i++) {
        strip = new HorizontalStrip((NUM_PORT_BACK_STRIPS + 4 + NUM_STARBOARD_STRIP_LOCATIONS + 4)*STRIP_SPACING, (3 - i)*STRIP_SPACING, 0);
        strips.add(strip);
        addPoints(strip);
      }

      // Port & rear side
      for (int i = 0; i < NUM_PORT_STRIP_LOCATIONS; ++i) {
        if (!portGap(i)) {
          strip = new VerticalStrip(9*FEET, (NUM_PORT_STRIP_LOCATIONS - i)*STRIP_SPACING);
          strips.add(strip);
          addPoints(strip);
        }
      }
    }
  }
}

static class VerticalStrip extends LXModel {

  public static final int NUM_POINTS = 100;
  public static final int NUM_POINTS_PER_PART = NUM_POINTS / 2;
  public static final float POINT_SPACING = METER / 30.;

  public final float x;
  public final float z;

  VerticalStrip(float z, float x) {
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

      for (int i = 0; i < NUM_POINTS_PER_PART; ++i) {
        addPoint(new LXPoint(x, (NUM_POINTS_PER_PART - 1 - i)*POINT_SPACING, z));
      }
    }
  }
}

static class VerticalHalfStrip extends LXModel {

  public static final int NUM_POINTS = 50;
  public static final int NUM_POINTS_PER_PART = NUM_POINTS;
  public static final float POINT_SPACING = METER / 30.;

  public final float x;
  public final float z;

  VerticalHalfStrip(float z, float x) {
    super(new Fixture(z, x));
    this.z = z;
    this.x = x;
  }

  private static class Fixture extends LXAbstractFixture {
    Fixture(float z, float x) {
      /**
       * Points in each strip are mapped from top to bottom
       */
      for (int i = 0; i < NUM_POINTS_PER_PART; ++i) {
        addPoint(new LXPoint(x, (NUM_POINTS_PER_PART - 1 - i)*POINT_SPACING, z));
      }
    }
  }
}

static class HorizontalStrip extends LXModel {

  public static final int NUM_POINTS = 100;
  public static final int NUM_POINTS_PER_PART = NUM_POINTS / 2;
  public static final float POINT_SPACING = METER / 30.;

  public final float x;
  public final float y;
  public final float z;

  HorizontalStrip(float x, float y, float z) {
    super(new Fixture(x, y, z));
    this.x = x;
    this.y = y;
    this.z = z;
  }

  private static class Fixture extends LXAbstractFixture {
    Fixture(float x, float y, float z) {
      /**
       * Points in each strip are mapped in two sections:
       * - the first half are added middle to left
       * - the second half are added middle to right
       * NOTE: depending on the strips, this may need to be flipped
       */
      for (int i = 0; i < NUM_POINTS_PER_PART; ++i) {
        addPoint(new LXPoint(x + (NUM_POINTS_PER_PART + i)*POINT_SPACING, y, z));
      }

      for (int i = 0; i < NUM_POINTS_PER_PART; ++i) {
        addPoint(new LXPoint(x + (NUM_POINTS_PER_PART - 1 - i)*POINT_SPACING, y, z));
      }
    }
  }
}
