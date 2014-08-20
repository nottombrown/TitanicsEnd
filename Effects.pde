class BeatMask extends LXEffect {
  
  public final BasicParameter amount = new BasicParameter("AMOUNT", 0); 
  
  public BeatMask(LX lx) {
    super(lx);
    addParameter(amount);
  }
  
  public void run(double deltaMs) {
    float scale = lerp(1, beat.getValuef(), amount.getValuef());
    if (scale < 1) {
      LXColor.scaleBrightness(this.colors, scale, null);
    }
  }
}

class Heartbeat extends LXEffect {
  PGraphics g;
  
  PImage heart;
  color backgroundColor;
  
  BasicParameter minSize = new BasicParameter("SIZE", 0.09, 0, 0.2);
  BasicParameter pulseDelta = new BasicParameter("PULSE", 1, 0, 10);
  
  Heartbeat(LX lx) {
    super(lx);
    
    addParameter(minSize);
    addParameter(pulseDelta);
    
    heart = new PImage();
    heart = loadImage("images/heart.png");
    backgroundColor = LXColor.hsb(0,0,0);
    
    g = createGraphics(int(model.xRange), int(model.yRange));
  }

  PImage drawImage() {
    float beatZoom = constrain(eq.getAveragef(1, 10)*pulseDelta.getValuef() + 1, 1., 1.5); 
    float zoom = beatZoom * minSize.getValuef();
    
    g.imageMode(CENTER);
    g.beginDraw();
    g.background(backgroundColor);
    g.noStroke();
    g.pushMatrix();
    g.translate(model.cx, model.cy);
    g.scale(zoom, -zoom);
    g.image(heart, 0, 0);
    g.popMatrix();
    g.endDraw();
    return g.get();
  }

  float zoomSpeed = 1.02;

  void update() {
  }

  public void run(double deltaMs) {
    if (amulet.heartbeatMode.getValueb()){
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
        int imageColor = img.get(ix, iy);
        int origColor = colors[p.index];
        float[] origHSB = LXColor.RGBtoHSB(origColor, null);
        
        // Invert the hues when the heart is on
        if (LXColor.b(imageColor) > 50) {
          colors[p.index] = LXColor.hsb(
            -LXColor.h(origColor),
            LXColor.s(origColor),
            LXColor.b(origColor)
          );
        }
      }
    }
  }
}
