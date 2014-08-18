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
  float[] xZoomTargets;
  float[] yZoomTargets;
  float[] targetZooms;
  float[] maxZooms;
   
  int currentSmiley;
  float currentZoom;
  int nextSmiley;
  float nextZoom;
  
  float xTranslate = 0;
  float yTranslate = 0;

  float xTranslateStart = 0;
  float yTranslateStart = 0;
  
  color backgroundColor;
  
  BasicParameter minSize = new BasicParameter("SIZE", 0.09, 0, 0.2);
  BasicParameter pulseDelta = new BasicParameter("PULSE", 1, 0, 10);
  BasicParameter baseSaturation = new BasicParameter("SAT", 100, 0, 100);
  BooleanParameter useBeat = new BooleanParameter("BEAT", true);
  
  Heartbeat(LX lx) {
    super(lx);
    
    addParameter(minSize);
    addParameter(pulseDelta);
    
    heart = new PImage();
    heart = loadImage("images/heart.png");

    xZoomTargets = new float[] {-45, 0, -85, 85};
    yZoomTargets = new float[] {75, -150, 250, 60};
    targetZooms = new float[] {0.8, 0.2, 0.5, 0.5};
    maxZooms = new float[] {10, 8, 10, 10};
    
    backgroundColor = LXColor.hsb(0,0,0);
    
    currentZoom = 0.1;
    nextSmiley = 0;
    nextZoom = 0;
    
    g = createGraphics(int(model.xRange), int(model.yRange));
  }

  PImage drawImage() {
    float beatZoom = constrain(eq.getAveragef(1, 10)*pulseDelta.getValuef() + 1, 1., 1.5);
    
    g.imageMode(CENTER);
    
    float zoom = beatZoom * minSize.getValuef();
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
    currentZoom *= zoomSpeed;
    if (currentZoom > maxZooms[currentSmiley]) {
      nextZoom = 0.01;
    }
    xTranslate = xZoomTargets[currentSmiley]; 
    yTranslate = yZoomTargets[currentSmiley]; 
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
        int unfilteredColor = colors[p.index];
        colors[p.index] = LXColor.lightest(imageColor, unfilteredColor);
      }
    }
  }
}
