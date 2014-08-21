public class Plasma2 extends LXPattern {

  PGraphics g;
  
  int[] table = new int[256];
  int baseIdx = 0;

  final int SOURCE_TEMPO = 0;
  final int SOURCE_BEAT = 1;
  final int SOURCE_COUNT = 2;
  
  final DiscreteParameter beatSource = new DiscreteParameter("BTSRC", SOURCE_TEMPO, SOURCE_COUNT);

  BasicParameter speed = new BasicParameter("SPEED", 0.35, 0, 2);

  BasicParameter hueRot = new BasicParameter("HUEROT", 45, 0, 360);
  
  Plasma2(LX lx) {
    super(lx);
    addParameter(speed);
    addParameter(beatSource);
    addParameter(hueRot);
    
    // One period of the sinus function shifted to range [0-255] 
    for (int i = 0; i < 256; i++) {
      table[i] = (int)(128 + 127.0 * sin(i * TWO_PI / 256.0));
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

    float ramp = beatSource.getValuei() == SOURCE_TEMPO ? lx.tempo.rampf() : (1. - beat.getValuef());

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
        color clr = rgb2hsv(r, gr, b);
        g.pixels[x + y * g.width] = color(
          (hue(clr) + baseIdx) % 360,
          constrain(saturation(clr) - map(ramp * ramp, 0, 1, 25, 0), 0, 100),
          brightness(clr)
        );
      }
    }
    g.updatePixels();

    return g.get();
  }

  public void run(double deltaMs) {
    timeMs += deltaMs * speed.getValuef();
   
    if (beatSource.getValuei() == SOURCE_TEMPO) {
      if (lx.tempo.beat()) {
        baseIdx += hueRot.getValuef();
      }
    }
    else {
      if (beat.peak()) {
        baseIdx += hueRot.getValuef();
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
