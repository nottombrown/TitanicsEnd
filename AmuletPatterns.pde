
class Heartbeat extends LXPattern {
    
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
  
  Heartbeat(LX lx) {
    super(lx);
    
    images = new PImage[4];
    images[0] = loadImage("images/heart.png");
    images[1] = loadImage("images/triangle.png");
    images[2] = loadImage("images/heart.png");
    images[3] = loadImage("images/triangle.png");
    
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
