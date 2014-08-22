class BeatHelpers {
  color beatBrighten(color in, float mult) {
    float _hue = hue(in);
    float sat = saturation(in);
    float bri = brightness(in);
    float toAdd = eq.getAveragef(1, 4) * mult;
    if (toAdd > 100 - bri) {
      if (bri == 0) {  // assume this is meant as black -- don't turn it into red
        bri = 100;
      }
      else {
        bri = 100;
        sat -= toAdd - (100 - bri);
      }
    }
    else {
      bri += toAdd;
    }
    return lx.hsb(
      hue(in),
      constrain(sat, 0, 100),
      constrain(bri, 0, 100)
    );
  }

  color beatBrighten(color in, float mult, int startBand) {
    float sat = saturation(in);
    float bri = brightness(in);
    float toAdd = eq.getAveragef(startBand, 4) * mult;
    if (toAdd > 100 - bri) {
      bri = 100;
      sat -= toAdd - (100 - bri);
    }
    else {
      bri += toAdd;
    }
    return lx.hsb(
      hue(in),
      constrain(sat, 0, 100),
      constrain(bri, 0, 100)
    );
  }
  
  color beatFlash(color in) {
    float sat = saturation(in);
    float bri = brightness(in);
    float toAdd = beat.getValuef() * 25;
    if (toAdd > 100 - bri) {
      bri = 100;
      sat -= toAdd - (100 - bri);
    }
    else {
      bri += toAdd;
    }
    return lx.hsb(
      hue(in),
      constrain(sat, 0, 100),
      constrain(bri, 0, 100)
    );
  }

  color beatFlash(color in, float mult) {
    float sat = saturation(in);
    float bri = brightness(in);
    float toAdd = sqrt(beat.getValuef()) * mult * 2;
    if (toAdd > 100 - bri) {
      bri = 100;
      sat -= toAdd - (100 - bri);
    }
    else {
      bri += toAdd;
    }
    return lx.hsb(
      hue(in),
      constrain(sat, 0, 100),
      constrain(bri, 0, 100)
    );
  }
}

BeatHelpers beatHelpers = new BeatHelpers();

class Plasma extends LXPattern {
  
  final BasicParameter speed = new BasicParameter("SPEED", 1, 0.5, 5);
  final BasicParameter hueSpread = new BasicParameter("SPREAD", 45, 0, 360);
  final BasicParameter hueBase = new BasicParameter("BASE", 200, 0, 360);
  final BasicParameter beatMult = new BasicParameter("BEAT+", 50, 0, 100);
  
  float time = 0.;

  Plasma(LX lx) {
    super(lx);
    addParameter(speed);
    addParameter(hueSpread);
    addParameter(hueBase);
    addParameter(beatMult);
  }
  
  public void run(double deltaMs) {
    time += deltaMs * speed.getValuef();
    float timeS = time / 1000.;
    for (LXPoint p : model.points) {
      float v1 = sin(p.x / 30. + timeS * 3.);
      float v2 = sin(10 * sin(p.x / (model.cx * 2.) * sin(timeS / 2.) + p.y / (model.cx * 2.) * cos(timeS / 3.)) + timeS);
      float cx = p.x / (model.cx * 2.) + 0.5 * sin(timeS / 2.);
      float cy = p.y / (model.cx * 2.) + 0.5 * cos(timeS / 1.5);
      float v3 = sin(sqrt(50. * (cx * cx + cy * cy) + 1.) + timeS);
      float v = v1 + v2 + v3;
      
      colors[p.index] = beatHelpers.beatBrighten(lx.hsb(
        (sin(v) * hueSpread.getValuef() + hueBase.getValuef() + 360) % 360,
        100,
        constrain(v * 25 + 50, 50, 100)
      ), beatMult.getValuef());
    }
  }
}

class FuzzyBeats extends LXPattern {
  
  final BasicParameter speed = new BasicParameter("SPEED", 1, 0.1, 10);
  final BasicParameter xfreq = new BasicParameter("XFREQ", 10/1.5, 1, 100);
  final BasicParameter yfreq = new BasicParameter("YFREQ", 4/1.5, 1, 100);
  
  final SinLFO spin = new SinLFO(0, 1, 15*SECONDS);
  
  float time = 0;
  float rot = 0;

  FuzzyBeats(LX lx) {
    super(lx);

    addParameter(speed);
    addParameter(xfreq);
    addParameter(yfreq);

    addModulator(spin).start();
  }

  public void run(double deltaMs) {
    time += deltaMs * speed.getValuef();
    float timeS = time / 1000.;
    
    rot += spin.getValuef() * deltaMs / 1000.;

    float zoom = eq.getAveragef(1, 4) + 0.4;
    
    for (LXPoint p : model.points) {
      float ax = (p.x - model.cx);
      float ay = (p.y - model.cy);
      float y = ax * cos(rot) + ay * sin(rot); 
      float x = ax * sin(rot) + ay * cos(rot); 
      color bubbles1 = lx.hsb(
        (180 + 20 * timeS * speed.getValuef()) % 360,
        100.,
        constrain(100 * ((
          1 + (
              sin(PI * xfreq.getValuef() * x / model.xRange / zoom) * 
              cos(PI * yfreq.getValuef() * y / model.yRange / zoom)
          )
        ) / 2), 0, 100)
      );

      color bubbles2 = lx.hsb(
        (0 + 20 * timeS * speed.getValuef()) % 360,
        100.,
        max(0, 100 * ((
          1 + (
              sin(PI * xfreq.getValuef() * x / model.xRange / zoom) * 
              cos(PI * yfreq.getValuef() * y / model.yRange / zoom)
          )
        ) / 2))
      );
      
      colors[p.index] = bubbles1;
      addColor(p.index, bubbles2);
    }
  }
}

// TODO: make whole pattern rotate slowly
class BubbleBeats extends LXPattern {
  
  final BasicParameter speed = new BasicParameter("SPEED", 1, 0.1, 10);
  final BasicParameter baseSize = new BasicParameter("SIZE", 90, 60, 150);
  final BasicParameter hueSpread = new BasicParameter("SPREAD", 90, 15, 120);
  final BasicParameter circleSize = new BasicParameter("CSIZE", 1, 0.25, 2);
  final BasicParameter allowStretch = new BasicParameter("STRETCH", 1, 0, 1);
  
  final SawLFO baseHue = new SawLFO(0, 360, 20*SECONDS);
  final SawLFO posOffset = new SawLFO(0, 1, 3*SECONDS);
  final SinLFO stretch = new SinLFO(1, 2, 60*SECONDS);
  final SinLFO beatMult = new SinLFO(25, 50, 45*SECONDS);
  
  boolean stretchWhich = false;

  PGraphics g;
  
  BubbleBeats(LX lx) {
    super(lx);
    addParameter(baseSize);
    addParameter(hueSpread);
    addParameter(circleSize);
    addParameter(allowStretch);
    addModulator(baseHue).start();
    addModulator(posOffset).start();
    addModulator(stretch).start();
    addModulator(beatMult).start();
  
    g = createGraphics(int(model.xRange), int(model.yRange));
  }
  
  float stretchValue(boolean which) {
    if (stretchWhich == which) {
      return allowStretch.getValuef() * stretch.getValuef() + ((1 - allowStretch.getValuef()) * 1);
    }
    else {
      return 1;
    } 
  }
  
  void drawBubbles(int startBand, float eqMult, float hue, float xOffs, float yOffs, float bubbleSize) {
    float spacing = baseSize.getValuef();
    float size = 1. + eq.getAveragef(startBand, 4) * eqMult;
    
    for (int y = -5; y < 5; y++) {
      for (int x = -1; x < 10; x++) {
        float xx = x + posOffset.getValuef();
        g.fill(beatHelpers.beatBrighten(lx.hsb(
          (hue + baseHue.getValuef()) % 360, 
          100, 
          75
        ), beatMult.getValuef(), startBand));
        g.translate(
          (xx + xOffs) * spacing, 
          (y + yOffs) * spacing
        );
        g.rotate(-PI / 10.);
        g.ellipse(
          0, 
          0, 
          spacing * bubbleSize * size * stretchValue(true) * circleSize.getValuef(), 
          spacing * bubbleSize * size * stretchValue(false) * circleSize.getValuef()
        );
        g.rotate(PI / 10.);
        g.translate(
          -(xx + xOffs) * spacing, 
          -(y + yOffs) * spacing
        );
      }
    }
  }

  public void run(double deltaMs) {
    if (beat.peak()) stretchWhich = !stretchWhich;
    
    g.beginDraw();
    g.background(0);
    g.noStroke();
    g.pushMatrix();
    g.rotate(PI / 10.);
    
    drawBubbles(1, 1, 0, 0, 0, 1/2.);
    drawBubbles(5, 2, hueSpread.getValuef(), 0.2, 0.4, 1/3.);
    drawBubbles(9, 2, hueSpread.getValuef() * 2., 0.6, 0.3, 1/4.);
    drawBubbles(13, 2.5, hueSpread.getValuef() * 3., 0.5, 0.7, 1/5.);

    g.popMatrix();
    g.endDraw();
    
    PImage img = g.get();
    
    for (LXPoint p : model.points) {
      int ix = int(p.x / model.xRange * img.width); 
      int iy = int(p.y / model.yRange * img.height); 
      colors[p.index] = img.get(ix, iy);
    }
  }
}

public class Fire extends LXPattern {

  //final BasicParameter scaleX = new BasicParameter("XSCALE", 200, 1, 1000);
  //final BasicParameter scaleY = new BasicParameter("YSCALE", 250, 1, 1000);

  final BasicParameter xNoiseScale = new BasicParameter("XNOISE", 0.01, 0.01, 0.02);
  final BasicParameter yNoiseScale = new BasicParameter("YNOISE", 0.01, 0.01, 0.02);

  final BasicParameter noiseBase = new BasicParameter("NOISE", 0, 0, 1000);
  final BasicParameter noiseOctaves = new BasicParameter("OCT", 3, 1, 6);
  final BasicParameter noiseWeight = new BasicParameter("WGHT", 0.6, 0, 1);
  
  PGraphics g;
  PImage source, iceSource;
  PImage disp;
  float dispX = 0, dispY = 0;

  int dispScale = 2;
  int dispShift = 1;
  
  Fire(LX lx) {
    super(lx);
    createSource();
    createIceSource();
    g = createGraphics(int(model.xRange), int(model.yRange));

    //addParameter(scaleX);
    //addParameter(scaleY);

    addParameter(xNoiseScale);
    addParameter(yNoiseScale);

    addParameter(noiseBase);
    addParameter(noiseOctaves);
    addParameter(noiseWeight);
  }
  
  void drawGradientPart(PGraphics g, int y1, int y2, color c1, color c2) {
    for (int i = y1; i <= y2; i++) {
      float inter = map(i, y1, y2, 0, 1);
      color c = lerpColor(c1, c2, inter);
      g.stroke(c);
      g.line(0, i, g.width, i);
    }
  }
  
  void drawGradient(PGraphics g, float[] ys, color[] cs) {
    for (int i = 0; i < ys.length - 1; i++) {
      drawGradientPart(g, int(ys[i] * g.height), int(ys[i+1] * g.height), cs[i], cs[i+1]);
    }
  }
  
  void createSource() {
    PGraphics g = createGraphics(int(model.xRange), int(model.yRange));
    g.beginDraw();
    g.noFill();
    drawGradient(g, new float[] {0, 0.4, 0.45, 0.6, 0.8, 0.95, 1}, new color[] {
      color(0,0,0), 
      color(0,0,30),
      color(21,50,50),
      color(21,100,100),
      color(31,100,100),
      color(50,100,100),
      color(50,75,100)
    });
    g.endDraw();
    source = g.get();
    source.loadPixels();
  }
    
  void createIceSource() {
    PGraphics g = createGraphics(int(model.xRange), int(model.yRange));
    g.beginDraw();
    g.noFill();
    drawGradient(g, new float[] {0, 0.4, 0.45, 0.5, 0.6, 0.8, 1}, new color[] {
      color(261,0,0), 
      color(261,30,30),
      color(261,50,50),
      color(261,100,100),
      color(219,70,100),
      color(197,70,100),
      color(197,0,100)
    });
    g.endDraw();
    iceSource = g.get();
    iceSource.loadPixels();
  }
  
  void createDisplacementMap() {
    noiseDetail(int(noiseOctaves.getValuef()), noiseWeight.getValuef());
    noiseSeed(int(noiseBase.getValuef()));

    float xNoiseScaleF = xNoiseScale.getValuef();
    float yNoiseScaleF = yNoiseScale.getValuef();
  
    PGraphics g = createGraphics(int((model.xRange + 1) / dispScale), int((model.yRange + 1) / dispScale));
    g.beginDraw();
    g.loadPixels();
    for (int y = 0; y < g.height; y++) {
      for (int x = 0; x < g.width; x++) {
        g.pixels[y * g.width + x] = 
          int(map(noise(dispX + (x << dispShift) * xNoiseScaleF, 0 + (y << dispShift) * yNoiseScaleF), 0, 1, 0, 255)) +  
          (int(map(noise(dispX + (x << dispShift) * xNoiseScaleF, dispY + (y << dispShift) * yNoiseScaleF), 0, 1, 0, 255)) << 8) + 
          (int(map(noise(dispX + (x << dispShift) * xNoiseScaleF, dispY + (y << dispShift) * yNoiseScaleF), 0, 1, 0, 255)) << 16) + 
          (255 << 24);
      }
    }
    g.updatePixels();
    g.endDraw();
    disp = g.get();
    disp.loadPixels();
  }

  int beatNum = 0;

  public void run(double deltaMs) {
    dispX += 0.02;
    dispY += 0.05;
    createDisplacementMap();

    float scaleXF = 200;//scaleX.getValuef();
    float scaleYF = 250;//scaleY.getValuef();

    if (beat.peak()) {
      beatNum = (beatNum + 1) % 2;
    }
    float inc = beatNum == 0 ? beat.getValuef() * beat.getValuef() : 0;
    
    for (LXPoint p : model.points) {
      int x = int(p.x);
      int y = int(model.yRange - p.y);
      if (x < 0) x = 0;
      if (x >= source.width) x = source.width - 1;
      if (y < 0) y = 0;
      if (y >= source.height) y = source.height - 1;
      int sx = int(
          x + (
            (
              ((
                disp.pixels[(y >> dispShift) * disp.width + (x >> dispShift)]
              ) & 0xff) - 128
            ) * scaleXF
          ) / 256.
        );
      int sy = int(
          y + (
            (
              (((disp.pixels[(y >> dispShift) * disp.width + (x >> dispShift)]) >> 8) & 0xff) - 
              128
            ) * scaleYF
          ) / 256.
        );
      if (sx < 0) sx = 0;
      if (sx >= source.width) sx = source.width - 1;
      if (sy < 0) sy = 0;
      if (sy >= source.height) sy = source.height - 1;
      //float inc = eq.getAveragef(1, 4) > beatTrigger.getValuef() ? 1 : 0;
      colors[p.index] = lerpColor(source.pixels[sy * source.width + sx], iceSource.pixels[sy * source.width + sy], inc);
    }
  }
}

class HyperCube extends LXPattern {
  
  final BasicParameter speed = new BasicParameter("SPEED", 3*SECONDS, 0.5*SECONDS, 5*SECONDS);
  final BasicParameter hueBase = new BasicParameter("BASE", 200, 0, 360);
  
  final BasicParameter xSpeed = new BasicParameter("XSPD", 5*SECONDS, 0*SECONDS, 10*SECONDS);
  final BasicParameter ySpeed = new BasicParameter("YSPD", 6*SECONDS, 0*SECONDS, 10*SECONDS);
  
  final SawLFO xRot = new SawLFO(0, 2*PI, xSpeed);
  final SawLFO yRot = new SawLFO(0, 2*PI, ySpeed);

  final SinLFO size = new SinLFO(1, 2, speed);

  final int MODE_RAND = 0;
  final int MODE_FRONT = 1;
  final int MODE_HOLD = 2;
  final int MODE_COUNT = 3;

  final DiscreteParameter mode = new DiscreteParameter("MODE", MODE_RAND, MODE_COUNT);
  
  final int SOURCE_TEMPO = 0;
  final int SOURCE_BEAT = 1;
  final int SOURCE_COUNT = 2;
  
  final DiscreteParameter beatSource = new DiscreteParameter("BTSRC", SOURCE_BEAT, SOURCE_COUNT);

  final int COLOR_ROT = 0;
  final int COLOR_BASE = 1;
  final int COLOR_COUNT = 2;
  
  final DiscreteParameter colorMode = new DiscreteParameter("CLRMODE", COLOR_ROT, COLOR_COUNT);
  
  PGraphics g;

  HyperCube(LX lx) {
    super(lx);
    addParameter(speed);
    addParameter(hueBase);
    
    addParameter(xSpeed);
    addParameter(ySpeed);
    addParameter(mode);
    addParameter(beatSource);
    addParameter(colorMode);

    addModulator(xRot).start();
    addModulator(yRot).start();
    addModulator(size).start();

    g = createGraphics(int(model.xRange), int(model.yRange), P3D);
  }

  public final int OFFS_LEFT = 0;
  public final int OFFS_RIGHT = 1;
  public final int OFFS_FRONT = 2;
  public final int OFFS_BACK = 3;
  public final int OFFS_TOP = 4;
  public final int OFFS_BOT = 5;
  public final int OFFS_COUNT = 6;

  int whichOffs = OFFS_LEFT;
  float hue = 0;
  
  public void run(double deltaMs) {
  
    boolean isBeat = beatSource.getValuei() == SOURCE_TEMPO ? lx.tempo.beat() : beat.peak();
  
    if (lx.tempo.beat()) {
      if (colorMode.getValuei() == COLOR_ROT) {
        hue = hue + 30;
      }
      else {
        hue = random(90) - 45;
      }
    }

    float ramp = beatSource.getValuei() == SOURCE_TEMPO ? lx.tempo.rampf() : (1. - beat.getValuef());
    float offs = map(pow(ramp, 0.5), 0, 1, -100, 0);
    
    switch (mode.getValuei()) {
      case MODE_RAND:
        if (isBeat) {
          whichOffs = int(random(OFFS_COUNT));
        }
        break;
        
      case MODE_FRONT:
        if (isBeat) {
          whichOffs = OFFS_FRONT;
        }
        break;

      case MODE_HOLD:
        offs = 0;
        break;
    }
      
    float xOffs = 0, yOffs = 0, zOffs = 0;
    switch (whichOffs) {
      case OFFS_LEFT:
        xOffs = offs;
        break;
      case OFFS_RIGHT:
        xOffs = -offs;
        break;
      case OFFS_FRONT:
        zOffs = -offs;
        break;
      case OFFS_BACK:
        zOffs = offs;
        break;
      case OFFS_TOP:
        yOffs = -offs;
        break;
      case OFFS_BOT:
        yOffs = offs;
        break;
    }
    
    g.beginDraw();
    g.background(color(0, 0, 0));
    g.noFill();
    
    g.pushMatrix();
    g.translate(model.cx, model.cy * 0.8, 0);
    g.translate(xOffs, yOffs, zOffs);
    g.rotateY(yRot.getValuef());
    g.rotateX(xRot.getValuef());
    g.noLights();
    g.stroke(color((hueBase.getValuef() + hue) % 360, 100, 100));
    g.strokeWeight(10);
    g.box(model.cy * 0.85 * size.getValuef());
    g.stroke(color((hueBase.getValuef() + hue) % 360, 50, 100));
    g.strokeWeight(10);
    //g.box(model.cy * 0.85 * map(size.getValuef(), 1, 2, 2, 1));

    g.popMatrix();
    g.endDraw();
    
    PImage img = g.get();
    
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

public class Grow extends LXPattern {

  PGraphics g;
  int branchMax = 5;
  float timeS = 0;
  float progress = 0;
  float baseAngle = 30;
  float angleSpread = 15;
  int seed = 0;
  float minBranchLength = 10;
  float minBranchLengthSpread = 5;
  float maxBranchLength = 40;
  float maxBranchLengthSpread = 20;
  
  float trunkHue = 37;
  float trunkBrightness = 51;
  float leafHue = 93;
  float leafBrightness = 51;
  
  BasicParameter speed = new BasicParameter("SPEED", 5, 0, 20);
  
  Grow(LX lx) {
    super(lx);
    addParameter(speed);
    
    g = createGraphics(int(model.xRange), int(model.yRange));
  }
  
  void drawBranch(int step, float left) {
    float angle = baseAngle + map(random(1), 0, 1, -angleSpread, angleSpread);
    float baseBranchLength = map(step, 0, branchMax, 
      maxBranchLength + map(random(1), 0, 1, -maxBranchLengthSpread, maxBranchLengthSpread),
      minBranchLength + map(random(1), 0, 1, -minBranchLengthSpread, minBranchLengthSpread)
    );
    float len = -baseBranchLength * constrain(left, 0, 1);
    float branchWidth = map(step, 0, branchMax, 20, 5);
    float hue = step < branchMax - 1 ? trunkHue : leafHue; //map(step, 0, branchMax, trunkHue, leafHue); 
    float brightness = 100; //map(step, 0, branchMax, trunkBrightness, leafBrightness); 
    
    if (left > 0) {
      g.strokeWeight(branchWidth);
      g.noFill();
      g.stroke(color(hue, 100, brightness));
      g.line(0, 0, 0, len);
    }
    
    if (step < branchMax) {
      g.pushMatrix();
      g.translate(0, len);
      
      g.pushMatrix();
      g.rotate(radians(-angle));
      drawBranch(step + 1, left - 1);
      g.popMatrix();

      g.pushMatrix();
      g.rotate(radians(angle));
      drawBranch(step + 1, left - 1);
      g.popMatrix();
      
      g.popMatrix();
    }
  }
  
  PImage drawImage() {
    float beatZoom = map(eq.getAveragef(1, 4), 0, 1, 0, 4);
    
    g.beginDraw();
    g.background(color(200, map(beatZoom, 0, 4, 50, 100), map(beatZoom, 0, 4, 25, 50)));
    g.pushMatrix();
    g.translate(model.cx + slideX, 0);
    g.scale(1, -1);
    
    g.stroke(color(90, map(beatZoom, 0, 4, 100, 50), 100));
    g.strokeWeight(15);
    g.noFill();
    g.line(-model.xRange, 0, model.xRange, 0);

    randomSeed(seed);
    drawBranch(0, progress + beatZoom);

    g.popMatrix();
    g.endDraw();
    return g.get();
  }

  final int STATE_GROWING = 0;
  final int STATE_SLIDING = 1;
  final int STATE_COUNT = 2;

  int state = STATE_GROWING;
  float slideX = 0;

  public void run(double deltaMs) {
    timeS += deltaMs / 1000.;

    boolean reset = false;      
    
    if (state == STATE_GROWING) {
      if (progress >= branchMax) {
        state = STATE_SLIDING;
      }
      else {
        progress += deltaMs / 1000. * 2.;
      }
    }
    else {
      slideX += deltaMs;
      if (slideX >= model.xRange) {
        reset = true;
      }
    }
    
    if (reset) {
      progress = 0;
      slideX = 0;
      state = STATE_GROWING;
      
      randomSeed((long) (timeS * 1000));
      seed = (int) random(MAX_INT);

      branchMax = int(map(random(1), 0, 1, 4, 7));

      baseAngle = map(random(1), 0, 1, 15, 45);
      angleSpread = map(random(1), 0, 1, 5, 25);

      minBranchLength = map(random(1), 0, 1, 10, 20);
      minBranchLengthSpread = map(random(1), 0, 1, 0, minBranchLength * 0.3);
      maxBranchLength = minBranchLength + map(random(1), 0, 1, 10, 30);
      maxBranchLengthSpread = map(random(1), 0, 1, 0, maxBranchLength * 0.3);
      
      trunkHue = map(random(1), 0, 1, 26, 56);
      trunkBrightness = 80;//map(random(1), 0, 1, 51, 100);
      leafHue = map(random(1), 0, 1, 82, 145);
      leafBrightness = 100;//map(random(1), 0, 1, 51, 100);
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

public class Plasma2 extends LXPattern {

  PGraphics g;
  
  int[] table = new int[256];
  int baseIdx = 0;

  final int SOURCE_TEMPO = 0;
  final int SOURCE_BEAT = 1;
  final int SOURCE_COUNT = 2;
  
  final DiscreteParameter beatSource = new DiscreteParameter("BTSRC", SOURCE_BEAT, SOURCE_COUNT);

  BasicParameter speed = new BasicParameter("SPEED", 0.35, 0, 2);

  BasicParameter hueRot = new BasicParameter("HUEROT", 0, 0, 360);
  
  final SinLFO beatPlus = new SinLFO(25, 50, 30*SECONDS);
  
  Plasma2(LX lx) {
    super(lx);
    addParameter(speed);
    addParameter(beatSource);
    addParameter(hueRot);
    
    addModulator(beatPlus).start();
    
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
        g.pixels[x + y * g.width] = beatHelpers.beatBrighten(color(
          (hue(clr) + baseIdx) % 360,
          saturation(clr),
          brightness(clr)
        ), beatPlus.getValuef());
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
