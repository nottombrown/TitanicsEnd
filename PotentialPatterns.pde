
class InfiniteSmileys extends LXPattern {
    
  PGraphics g;
  
  PImage[] images;
  float[] xZoomTargets;
  float[] yZoomTargets;
  float[] targetZooms;
  float[] maxZooms;
  color[] backgroundColors;
  
  int currentSmiley;
  float currentZoom;
  int nextSmiley;
  float nextZoom;
  
  float xTranslate = 0;
  float yTranslate = 0;

  float xTranslateStart = 0;
  float yTranslateStart = 0;
  
  color backgroundColor;
  
  InfiniteSmileys(LX lx) {
    super(lx);
    
    images = new PImage[4];
    images[0] = loadImage("images/smiley1.png");
    images[1] = loadImage("images/smiley2.png");
    images[2] = loadImage("images/smiley3.png");
    images[3] = loadImage("images/smiley4.png");
    
    xZoomTargets = new float[] {-45, 0, -85, 85};
    yZoomTargets = new float[] {75, -150, 250, 60};
    targetZooms = new float[] {0.8, 0.2, 0.5, 0.5};
    maxZooms = new float[] {10, 8, 10, 10};
    backgroundColors = new color[] {
      color(0, 0, 0), 
      color(336, 81, 53), 
      color(345, 11, 14), 
      color(0, 0, 24)
    };

    backgroundColor = color(0, 0, 0);
    
    currentSmiley = 0;
    currentZoom = 0.1;
    nextSmiley = 0;
    nextZoom = 0;
    
    g = createGraphics(int(model.xRange), int(model.yRange));
  }

  PImage drawImage() {
    float beatZoom = constrain(eq.getAveragef(1, 4) + 0.8, 1., 1.5);
    
    g.imageMode(CENTER);
    
    g.beginDraw();
    g.background(backgroundColor);
    g.noStroke();
    g.pushMatrix();
    g.translate(model.cx, model.cy);
    g.scale(currentZoom * beatZoom, -currentZoom * beatZoom);
    g.translate(xZoomTargets[currentSmiley], yZoomTargets[currentSmiley]);

    g.image(images[currentSmiley], 0, 0);

    g.popMatrix();

    // Is this code just for a single frame?
    // csmoak: this code redraws the smaller smiley each frame. is shows the smaller smiley when the larger one has zoomed in enough. you will have at most 2 on the screen at once.
    if (currentZoom > targetZooms[currentSmiley]) {
      g.pushMatrix();
      g.translate(model.cx, model.cy);
      g.scale(nextZoom * beatZoom, -nextZoom * beatZoom);
      g.translate(xZoomTargets[nextSmiley], yZoomTargets[nextSmiley]);
      g.image(images[nextSmiley], 0, 0);
      g.popMatrix();
    }

    g.endDraw();
    
    return g.get();
  }

  float zoomSpeed = 1.02;

  int pickNextSmiley() {
    int pick;
    do {
      pick = int(random(images.length));
    } while(pick == currentSmiley);
    return pick;
  }

  void update() {
    currentZoom *= zoomSpeed;
    if (currentZoom > maxZooms[currentSmiley]) {
      backgroundColor = backgroundColors[currentSmiley];

      currentSmiley = nextSmiley;
      currentZoom = nextZoom;
      
      nextSmiley = pickNextSmiley();
      nextZoom = 0.01;
    }
    xTranslate = xZoomTargets[currentSmiley]; 
    yTranslate = yZoomTargets[currentSmiley]; 

    if (currentZoom > targetZooms[currentSmiley]) {
      nextZoom *= zoomSpeed;
    }
    else {
      nextZoom = 0.01;
    }
  }

  public void run(double deltaMs) {
    update();
    
    PImage img = drawImage();
    
    for (LXPoint p : model.points) {
      int ix, iy;
      if (p.z > 0) {
        ix = int((model.xRange - p.x - 5*FEET) / model.xRange * img.width); 
        iy = int(p.y / model.yRange * img.height); 
      }
      else {
        ix = int(p.x / model.xRange * img.width); 
        iy = int(p.y / model.yRange * img.height); 
      }
      colors[p.index] = img.get(ix, iy);
    }
  }
}


public class Dance extends LXPattern {

  PGraphics g;
  final int MOVE_COUNT = 6;
  PImage[] moves = new PImage[MOVE_COUNT];
  int move = 0;
  int flip = 1;
  
  int[] table = new int[256];

  final int SOURCE_TEMPO = 0;
  final int SOURCE_BEAT = 1;
  final int SOURCE_COUNT = 2;
  
  final DiscreteParameter beatSource = new DiscreteParameter("BTSRC", SOURCE_TEMPO, SOURCE_COUNT);

  BasicParameter speed = new BasicParameter("SPEED", 1, 0, 2);
  
  Dance(LX lx) {
    super(lx);
    addParameter(speed);
    addParameter(beatSource);
    
    // One period of the sinus function shifted to range [0-255] 
    for (int i = 0; i < 256; i++) {
      table[i] = (int)(128 + 127.0 * sin(i * TWO_PI / 256.0));
    }

    for (int i = 0; i < MOVE_COUNT; i++) {
      moves[i] = loadImage("images/dance" + Integer.toString(i + 1) + "a.png");
    }

    g = createGraphics(int(model.xRange), int(model.yRange));
  }
  
  color rgb2hsv(float r, float g, float b) {
    float h, s, v;

    float min, max, delta;
    min = min( r, g, b );
    max = max( r, g, b );
    v = max;        // v
    delta = max - min;
    if( max != 0 )
      s = delta / max;    // s
    else {
      // r = g = b = 0    // s = 0, v is undefined
      s = 0;
      h = -1;
      return color(0, s * 100, v * 100);
    }
    if( r == max )
      h = ( g - b ) / delta;    // between yellow & magenta
    else if( g == max )
      h = 2 + ( b - r ) / delta;  // between cyan & yellow
    else
      h = 4 + ( r - g ) / delta;  // between magenta & cyan
    h *= 60;        // degrees
    if( h < 0 )
      h += 360;
      
    return color(h, s * 100, v * 100);
  }
  
  float timeMs = 0;
  
  PImage drawImage() {
    // grab some samples, hmm could have used lookup table...
    int t = (int)(128 + 127.0 * sin(0.0013 * (float)timeMs));
    int t2 = (int)(128 + 127.0 * sin(0.0023 * (float)timeMs));
    int t3 = (int)(128 + 127.0 * sin(0.0007 * (float)timeMs));

    g.loadPixels();
    for (int y = 0; y < g.height; y++) {
      for (int x = 0; x < g.width; x++) {
        // Define a function for each color component that depends on the
        // x,y coordinate and time. Use the lookup table for nice swirly movement.
        // There is no deeper logic here, I just experimented with the functions
        // untill I found something that looked pleasing.
        int r = table[(x / 5 + t / 4 + table[(t2 / 3 + y / 8) & 0xff]) & 0xff];
        int gr = table[(y / 3 + t + table[(t3 + x / 5) & 0xff]) & 0xff];
        int b = table[(y / 4 + t2 + table[(t + gr / 4 + x / 3) & 0xff]) & 0xff];
        g.pixels[x + y * g.width] = rgb2hsv(r, gr, b);
      }
    }
    g.updatePixels();

    float beatZoom = map(eq.getAveragef(1, 4), 0, 1, 1, 4);
    
    g.beginDraw();
    g.pushMatrix();
    g.translate(model.cx / 2, model.cy + 50);
    g.scale(1, -1);
    g.scale(0.25);
    g.blendMode(SUBTRACT);
    g.translate(moves[move].width / 2, 0);
    g.scale(flip, 1);
    g.translate(-moves[move].width / 2, 0);
    g.image(moves[move], 0, 0);
    g.popMatrix();
    g.endDraw();

    return g.get();
  }

  int pickMove() {
    int m = move;
    do {
      m = int(random(MOVE_COUNT));
    } while (m == move);
    return m;
  }

  public void run(double deltaMs) {
    timeMs += deltaMs * speed.getValuef();
   
    if (beatSource.getValuei() == SOURCE_TEMPO) {
      if (lx.tempo.beat()) {
        move = pickMove();
        flip = random(1) > 0.5 ? 1 : -1;
      }
    }
    else {
      if (beat.peak()) {
        move = pickMove();
        flip = random(1) > 0.5 ? 1 : -1;
      }
    }

    PImage img = drawImage();
    
    for (LXPoint p : model.points) {
      int ix, iy;
      if (p.z > 0) {
        ix = int((model.xRange - p.x - 5*FEET) / model.xRange * img.width); 
        iy = int(p.y / model.yRange * img.height); 
      }
      else {
        ix = int(p.x / model.xRange * img.width); 
        iy = int(p.y / model.yRange * img.height); 
      }
      colors[p.index] = img.get(ix, iy);
    }
  }
}

public class Logo extends LXPattern {

  PGraphics g;
  PImage ship, iceberg;
  float shipX = 0;
  float shipY = 0;
  float shipAngle = 0;
  boolean willSink = true;
  
  BasicParameter speed = new BasicParameter("SPEED", 5, 0, 20);
  
  Logo(LX lx) {
    super(lx);
    addParameter(speed);
    
    iceberg = loadImage("images/iceberg1b.png");
    ship = loadImage("images/titanic2.png");
    
    g = createGraphics(int(model.xRange), int(model.yRange));
  }
  
  PImage drawImage() {
    g.beginDraw();
    g.background(color(0, 0, 0));
    g.pushMatrix();
    g.translate(0, 85);
    g.scale(1, -1);
    g.image(iceberg, 0, -100);
    g.translate(shipX - ship.width, shipY);
    g.translate(ship.width / 2, 0);
    g.rotate(shipAngle);
    g.translate(-ship.width / 2, 0);
    g.image(ship, 0, 0);
    g.popMatrix();
    g.endDraw();
    return g.get();
  }

  public void run(double deltaMs) {
    boolean reset = false;
    
    if (willSink && shipX > model.cx) {
      float deltaDist = (float) deltaMs / 100. * speed.getValuef();
      shipAngle = constrain(shipAngle + (float) deltaMs / 10000. / 5 * speed.getValuef(), 0, PI/4);
      shipX = shipX + deltaDist * cos(shipAngle);
      shipY = shipY + deltaDist * sin(shipAngle);
      if (shipY > sin(shipAngle) * ship.width) {
        reset = true;
      }
    }
    else {
      shipX += (float) deltaMs / 100. * speed.getValuef();
      if (shipX > model.xRange + ship.width) {
        reset = true;
      }
    }
    
    if (reset) {
      shipX = 0;
      shipY = 0;
      shipAngle = 0;
      willSink = random(1) > 0.5;
    }
    
    PImage img = drawImage();
    
    for (LXPoint p : model.points) {
      int ix, iy;
      if (p.z > 0) {
        ix = int((model.xRange - p.x - 5*FEET) / model.xRange * img.width); 
        iy = int(p.y / model.yRange * img.height); 
      }
      else {
        ix = int(p.x / model.xRange * img.width); 
        iy = int(p.y / model.yRange * img.height); 
      }
      colors[p.index] = img.get(ix, iy);
    }
  }
}


public class TextScroller extends LXPattern {

  PFont font;
  PGraphics g;
  float scrollX = 0;
  float scrollXBeat = 0;
  String[] messages = new String[] {
    "TITANIC'S END -- FOLLOW US TO THE BOTTOM OF THE DUSTY SEA",
    "THIS IS JUST THE TIP",
    "BURN BABY BURN",
    "S. O. S. ... S. O. S.",
    "LET'S PLAY CHICKEN"
  };
  int message = 0;
  DiscreteParameter nextMessage = new DiscreteParameter("MSG", 5);  

  BasicParameter speed = new BasicParameter("SPEED", 3, 0.1, 10);
  BasicParameter baseHue = new BasicParameter("HUE", 0, 0, 360);
  BasicParameter baseSaturation = new BasicParameter("SAT", 100, 0, 100);
  BooleanParameter useBeat = new BooleanParameter("BEAT", true);
  
  SinLFO hueChange = new SinLFO(0, 50, 1*SECONDS);
  
  float scale = 1;
  
  TextScroller(LX lx) {
    super(lx);
    addParameter(speed);
    addParameter(nextMessage);
    addParameter(baseHue);
    addParameter(baseSaturation);
    addParameter(useBeat);
    addModulator(hueChange).start();
    
    font = loadFont("AvenirNext-Bold-48.vlw");
    g = createGraphics(int(model.xRange), int(model.yRange));
    g.textFont(font, 100);
  }
  
  PImage drawImage() {
    g.beginDraw();
    g.background(0);
    g.pushMatrix();
    g.scale(1, -1);
    g.translate(model.xRange - (scrollX + (scale > 1 ? scrollXBeat * (scale - 1) : 0)), 0);
    g.fill(color(baseHue.getValuef() + hueChange.getValuef(), baseSaturation.getValuef(), 100));
    g.textFont(font, 100 * scale);
    g.text(messages[message], -0 * (scale - 1), -20 + 50 * (scale - 1));
    g.popMatrix();
    g.endDraw();
    return g.get();
  }
  
  public void run(double deltaMs) {
    scale = useBeat.isOn() ? 1 + beat.getValuef() * 0.5 : 1;
    
    float oldScrollX = scrollX;
    g.textFont(font, 100);
    scrollX = (scrollX + (float) deltaMs / 10. * speed.getValuef()) % int(g.textWidth(messages[message]) + model.xRange);
    g.textFont(font, 100 * scale);
    scrollXBeat = (g.textWidth(messages[message]) + model.xRange) * (scrollX / int(g.textWidth(messages[message]) + model.xRange));
    if (scrollX < oldScrollX) {
      message = nextMessage.getValuei();
      scrollX = 0;
      scrollXBeat = 0;
    }
    
    PImage img = drawImage();
    
    for (LXPoint p : model.points) {
      int ix, iy;
      if (p.z > 0) {
        ix = int((model.xRange - p.x - 5*FEET) / model.xRange * img.width); 
        iy = int(p.y / model.yRange * img.height); 
      }
      else {
        ix = int(p.x / model.xRange * img.width); 
        iy = int(p.y / model.yRange * img.height); 
      }
      colors[p.index] = img.get(ix, iy);
    }
  }
}


class Tribal extends LXPattern {

  final int ringCount = 5;
  
  final BasicParameter hueBase = new BasicParameter("HUE", 0, 0, 360);
  final BasicParameter hueSpread = new BasicParameter("SPREAD", 0, 0, 360);

  final SawLFO hueRotate = new SawLFO(0, 360, 10*SECONDS);

  final SawLFO[] ringSpin = new SawLFO[ringCount];
  final SawLFO glowSpin = new SawLFO(0, 2*PI, 10*SECONDS);
  final SawLFO glowMaskSpin = new SawLFO(0, 2*PI, 8*SECONDS);

  int[][] rings = new int[ringCount][];
  color[] ringColors = new color[ringCount];
  float[] ringAngles = new float[ringCount];
  
  final int PORT_SIDE = 0;
  final int STARBOARD_SIDE = 1;
  float[] offsets = new float[] {8*FEET, 0};

  float zoom = 0;
    
  Tribal(LX lx) {
    super(lx);
    addParameter(hueBase);
    addParameter(hueSpread);

    addModulator(hueRotate).start();
    addModulator(glowSpin).start();
    addModulator(glowMaskSpin).start();

    float[] spinSpeeds = new float[] {5, -4, 3.5, 6, -8};     
    for (int i = 0; i < ringCount; i++) {
      ringSpin[i] = new SawLFO(0, 360, spinSpeeds[i]*SECONDS);
      addModulator(ringSpin[i]).start();
    }
    
    ringColors[0] = color(0, 81, 74);
    rings[0] = new int[] {120, 150, 270};
    ringColors[1] = color(313, 95, 74);
    rings[1] = new int[] {180, 210};
    ringColors[2] = color(207, 81, 74);
    rings[2] = new int[] {200, 250, 300, 330, 359};
    ringColors[3] = color(49, 81, 74);
    rings[3] = new int[] {30, 60, 90, 260, 290};
    ringColors[4] = color(167, 81, 74);
    rings[4] = new int[] {300, 359, 60, 100, 140, 250};
    
    ringAngles = new float[] {0, 0, 0, 0, 0};
  }

  int side(LXPoint p) {
    return p.z > 0 ? PORT_SIDE : STARBOARD_SIDE;
  }

  float centerX(LXPoint p) {
    return model.cx + offsets[side(p)];
  }

  float centerY(LXPoint p) {
    return model.cy;
  }
  
  float modifyX(LXPoint p) {
    if (side(p) == PORT_SIDE) {
      return model.xMax - p.x;
    }
    else {
      return p.x;
    }
  }

  boolean isInRing(LXPoint p, int idx) {
    float distance = dist(centerX(p), centerY(p), modifyX(p), p.y);
    return distance >= (idx + 1) * 25 * zoom && distance <= (((idx + 1) * 25) + 14) * zoom; 
  }

  float fixAngle(float angle) {
    while (angle < 0) angle += 2*PI;
    while (angle > 2*PI) angle -= 2*PI;
    return angle;
  }
  
  boolean isDrawnInRing(LXPoint p, int idx) {
    float angle = fixAngle(atan2(p.y - centerY(p), modifyX(p) - centerX(p)));
    int[] ring = rings[idx];
    for (int i = 0; i < ring.length; i++) {
      float spaceAngle = fixAngle((ring[i] - ringSpin[idx].getValuef()) * PI / 180.);
      float sliceAngle = 15 * (1 - idx / ringCount) * PI / 180.;
      if (angle >= spaceAngle && angle <= spaceAngle + sliceAngle) {
        return false;
      }
    }
    return true;
  }

  float glowAt(float angle, float distance) {
    float glowAngle = fixAngle(angle + glowSpin.getValuef());
    float maskAngle = fixAngle(angle + glowMaskSpin.getValuef());
    
    float mask = constrain(cos(maskAngle*5), 0, 1);
    float glow = constrain(sin(glowAngle*3), 0, 1) * mask * constrain(1. - distance / 200., 0, 1); 
    float volume = eq.getAveragef(13, 4) * 3.;
    return glow * volume;
  }
  
  void addGlow(LXPoint p) {
    float angle = fixAngle(atan2(p.y - centerY(p), modifyX(p) - centerX(p)));
    float distance = dist(centerX(p), centerY(p), modifyX(p), p.y);
    colors[p.index] = color(
      hue(colors[p.index]), 
      constrain(saturation(colors[p.index]) - constrain(glowAt(angle, distance)*100, 0, 100), 0, 100), 
      constrain(brightness(colors[p.index]) + constrain(glowAt(angle, distance)*100, 0, 100), 0, 100)
    );
  } 

  public void run(double deltaMs) {
    zoom = constrain(eq.getAveragef(1, 4) + 0.8, 1, 3);
    
    for (LXPoint p : model.points) {
      colors[p.index] = color(0, 0, 0);
      for (int i = 0; i < rings.length; i++) {
        if (isInRing(p, i) && isDrawnInRing(p, i)) {
          colors[p.index] = color(
            (hue(ringColors[i]) + hueBase.getValuef() + hueSpread.getValuef() * i + hueRotate.getValuef()) % 360,
            saturation(ringColors[i]),
            brightness(ringColors[i])
          );
        }
      }
      
      addGlow(p);
    }
  }
}


class Tunnel extends LXPattern {
  
  final BasicParameter speed = new BasicParameter("SPEED", 1, 0.1, 3);
  final BasicParameter hueBase = new BasicParameter("HUE", 150, 0, 360);
  final BasicParameter hueSpread = new BasicParameter("SPREAD", 60, 1, 360);

  PGraphics g;
  float a = 0;
  float b = 0;
  float c = 0;
  float vx = 3;
  float vy = 3;
  
  Tunnel(LX lx) {
    super(lx);
    addParameter(speed);
    addParameter(hueBase);
    addParameter(hueSpread);
  
    g = createGraphics(int(model.xRange), int(model.yRange));
  }

  public void run(double deltaMs) {
    g.beginDraw();
    g.background(0);
    g.noStroke();
    g.pushMatrix();

    int step = 15;
    int maxIdx = int(g.width / step);
    for (int i = 1; i < g.width; i += step) {
      int idx = int(i / step);
      g.fill(color(
        (hueBase.getValuef() + idx + sin(idx + c) * hueSpread.getValuef()) % 360, 
        100, 
        constrain(200 * (1. * i / g.width), 0, 100)
      ));

      float moveMult = 6;
      ring(
        g.width / 2 + cos(a + (maxIdx - idx) * 0.08 * moveMult) * vx * (maxIdx - idx) * sin(a), 
        g.height / 2 + sin(b + (maxIdx - idx) * 0.06 * moveMult) * vy * (maxIdx - idx) * cos(b), 
        i, 
        g.width / 2 + cos(a + (maxIdx - idx + 1) * 0.08 * moveMult) * vx * (maxIdx - idx + 1) * sin(a), 
        g.height / 2 + sin(b + (maxIdx - idx + 1) * 0.06 * moveMult) * vy * (maxIdx - idx + 1) * cos(b),
        max(0, i - (step + 1))
      );
    } 
    
    a += -0.03 / 2 * speed.getValuef();
    b += -0.05 / 2 * speed.getValuef();
    c += -0.05 * 2 * speed.getValuef();

    g.popMatrix();
    g.endDraw();
    
    PImage img = g.get();
    
    for (LXPoint p : model.points) {
      int ix = int(p.x / model.xRange * img.width); 
      int iy = int(p.y / model.yRange * img.height); 
      colors[p.index] = img.get(ix, iy);
    }
  }
  
  // ring code from: http://processing.org/discourse/beta/num_1221179611.html
  
  // Create a ring by drawing an outer cicle clockwise and an inner circle anticlockwise.
  void ring(float cx1, float cy1, float r1, float cx2, float cy2, float r2) {
    g.beginShape();
    buildCircle(cx1,cy1,r1,true);
    buildCircle(cx2,cy2,r2,false); 
    g.endShape();
  }

  // Creates a circle using spline curves. Can be drawn either clockwise
  // which creates a solid circle, or anticlockwise that creates a hole.
  void buildCircle(float cx, float cy, float r, boolean isClockwise) {
    int numSteps = 5;
    float inc = TWO_PI/numSteps;
       
    if (isClockwise)
    {
      // First control point should be penultimate point on circle.
      g.curveVertex(cx+r*cos(-inc),cy+r*sin(-inc));
      
      for (float theta=0; theta<TWO_PI-0.01; theta+=inc)
      {
        g.curveVertex(cx+r*cos(theta),cy+r*sin(theta));
      }
      g.curveVertex(cx+r,cy);
      
      // Last control point should be second point on circle.
      g.curveVertex(cx+r*cos(inc),cy+r*sin(inc));
      
      // Move to start position to keep curves in circle.
      g.vertex(cx+r,cy);
    }
    else
    {
      // Move to start position to keep curves in circle.
      g.vertex(cx+r,cy);
      
      // First control point should be penultimate point on circle.
      g.curveVertex(cx+r*cos(inc),cy+r*sin(inc));
          
      for (float theta=TWO_PI; theta>0.01; theta-=inc)
      {
        g.curveVertex(cx+r*cos(theta),cy+r*sin(theta));
      }
      g.curveVertex(cx+r,cy);
       
      // Last control point should be second point on circle.
      g.curveVertex(cx+r*cos(TWO_PI-inc),cy+r*sin(TWO_PI -inc));
    }  
  }
}
