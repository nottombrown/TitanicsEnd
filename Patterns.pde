// Here's all the pattern code. Each pattern is a class
// with a run method, and lots of helpers available like
// LFOs, modulators, parameters. They can have transitions
// between them, layers, effects, etc.

class Periodicity extends LXPattern {
  
  final SinLFO[] pos = new SinLFO[Model.NUM_STRIPS]; 
  
  Periodicity(LX lx) {
    super(lx);
    for (int i = 0; i < pos.length; ++i) {
      pos[i] = new SinLFO(0, 1, 60*SECONDS / (float) i);  
      addModulator(pos[i]).start(); 
    }
  }
  
  public void run(double deltaMs) {
    int si = 0;
    for (LXModel strip : model.strips) {
      float pp = pos[si++ % Model.NUM_STRIPS].getValuef();
      for (LXPoint p : strip.points) {
        float pi = p.y / model.yRange;
        colors[p.index] = lx.hsb(
          (lx.getBaseHuef() + dist(p.x, p.y, model.cx, model.cy) / model.xRange * 180) % 360,
          100,
          max(0, 100 - 200*abs(pp - pi)) 
        );
      }
    }
  }
}

class Warp extends LXPattern {
  
  private final SinLFO hr = new SinLFO(90, 180, 34000);
  
  private final SinLFO sr = new SinLFO(9000, 37000, 41000);
  private final SinLFO slope = new SinLFO(0.5, 1.5, sr); 
  
  private final SinLFO speed = new SinLFO(500, 2500, 27000);
  private final SawLFO move = new SawLFO(TWO_PI, 0, speed);
  private final SinLFO tight = new SinLFO(6, 14, 19000);
  
  private final SinLFO cs = new SinLFO(17000, 31000, 11000);
  private final SinLFO cx = new SinLFO(model.xRange * .25, model.xRange * .75, cs); 
  
  Warp(LX lx) {
    super(lx);
    addModulator(hr).start();
    addModulator(sr).start();
    addModulator(slope).start();
    addModulator(speed).start();
    addModulator(move).start();
    addModulator(tight).start();
    addModulator(cs).start();
    addModulator(cx).start();
  }
  
  public void run(double deltaMs) {
    for (LXPoint p : model.points) {
      float dx = (abs(p.x - cx.getValuef()) - slope.getValuef() * abs(p.y - model.cy)) / model.xRange;
      float b = 50 + 50*sin(dx * tight.getValuef() + move.getValuef());
      
      colors[p.index] = lx.hsb(
        (lx.getBaseHuef() + + abs(p.y - model.cy) / model.yRange * hr.getValuef() + abs(p.x - cx.getValuef()) / model.xRange * hr.getValuef()) % 360,
        100,
        b
      );
    }
  }
}

class ParameterWave extends LXPattern {
  
  final BasicParameter amp = new BasicParameter("AMP", 1);
  final BasicParameter speed = new BasicParameter("SPD", 0.5, -1, 1); 
  final BasicParameter period = new BasicParameter("PERIOD", 0.5, 0.5, 5);
  final BasicParameter thick = new BasicParameter("THICK", 2, 1, 5);
  final BasicParameter xColor = new BasicParameter("X-COLOR", 0.5);
  final BasicParameter yColor = new BasicParameter("Y-COLOR", 0.5);
  
  private float base = 0;
  
  ParameterWave(LX lx) {
    super(lx);
    addParameter(amp);
    addParameter(speed);
    addParameter(period);
    addParameter(thick);
    addParameter(xColor);
    addParameter(yColor);
  }
  
  public void run(double deltaMs) {
    base += deltaMs / 1000. * TWO_PI * speed.getValuef();
    
    for (LXPoint p : model.points) {
      float svy = model.cy + amp.getValuef() * model.yRange/2.*sin(base + (p.x - model.cx) / model.xRange * TWO_PI * period.getValuef());
      float hShift =
        abs(p.x - model.cx) / model.xRange * 360 * xColor.getValuef() +
        abs(p.y - model.cy) / model.yRange * 360 * yColor.getValuef();
      colors[p.index] = lx.hsb(
        (lx.getBaseHuef() + hShift) % 360,
        100,
        max(0, 100 - (100 / (thick.getValuef()*FEET)) * abs(p.y - svy))
      );
    }
  }
}

class AuroraBorealis extends LXPattern {
  
  final SinLFO yOffset = new SinLFO(0, 3*FEET, 3*SECONDS);
  
  AuroraBorealis(LX lx) {
    super(lx);
    addModulator(yOffset).start();
  }
  
  public void run(double deltaMs) {
    for (LXPoint p : model.points) {
      colors[p.index] = lx.hsb(
        (p.y + 2*FEET * sin(p.x/model.xRange * 4*PI) + yOffset.getValuef())/model.yRange * 180,
        100,
        100
      );
    }
  }
}

class Bouncing extends LXPattern {
  
  final BasicParameter size = new BasicParameter("SIZE", 1*FEET, 1*FEET, 5*FEET);
  final BasicParameter rate = new BasicParameter("RATE", 2*SECONDS, 1*SECONDS, 4*SECONDS);
  final BasicParameter max = new BasicParameter("MAX", model.cy, model.cy, model.yMax);
  final BasicParameter min = new BasicParameter("MIN", 0, 0, model.cy);
  
  final SinLFO py = new SinLFO(min, max, rate);
  
  Bouncing(LX lx) {
    super(lx);
    addParameter(size);
    addParameter(rate);
    addParameter(min);
    addParameter(max);
    addModulator(py).start();
  }
  
  public void run(double deltaMs) {
    for (LXPoint p : model.points) {
      colors[p.index] = lx.hsb(
        0,
        100,
        max(0, 100 - (100/size.getValuef()) * abs(p.y - py.getValuef()))
      );
    }
  }
}




class Pulse extends LXPattern {
  final BasicParameter speed = new BasicParameter("SPEED", 1, 0.1, 10);
  float time = 0.;

  Pulse(LX lx) {
    super(lx);
    addParameter(speed);
  }
  
  public void run(double deltaMs) {
    time += deltaMs * speed.getValuef();
    float timeS = time / 1000.;

    for (LXPoint p : model.points) {
      colors[p.index] = lx.hsb(
        40,
        100,
        100 * ((Math.round(timeS) % 2))
      );
    }
  }
}

class Strobe extends LXPattern {
  final BasicParameter speed = new BasicParameter("SPEED", 3, .3, 30);
  float time = 0.;

  Strobe(LX lx) {
    super(lx);
    addParameter(speed);
  }
  
  public void run(double deltaMs) {
    time += deltaMs * speed.getValuef();
    float timeS = time / 1000.;

    for (LXPoint p : model.points) {
      colors[p.index] = lx.hsb(
        42,
        100,
        100 * ((Math.round(timeS) % 2))
      );
    }
  }
}

class Plasma extends LXPattern {
  
  final BasicParameter speed = new BasicParameter("SPEED", 1, 0.1, 10);
  final BasicParameter hueSpread = new BasicParameter("SPREAD", 45, 0, 360);
  final BasicParameter hueBase = new BasicParameter("BASE", 200, 0, 360);
  
  float time = 0.;

  Plasma(LX lx) {
    super(lx);
    addParameter(speed);
    addParameter(hueSpread);
    addParameter(hueBase);
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
      
      colors[p.index] = lx.hsb(
        max(0, min(360, sin(v) * hueSpread.getValuef() + hueBase.getValuef())),
        100,
        max(50, min(100, v * 25 + 50))
      );
    }
  }
}

class BounceHigh extends LXPattern {
  
  final BasicParameter size = new BasicParameter("SIZE", 1*FEET, 1*FEET, 5*FEET);
  final BasicParameter rate = new BasicParameter("RATE", 3*SECONDS, 1.5*SECONDS, 6*SECONDS);
  final BasicParameter max = new BasicParameter("MAX", 1.9*model.cy, 1.9*model.cy, 1.9*model.yMax);
  final BasicParameter min = new BasicParameter("MIN", 0, 0, model.cy);
  
  final SinLFO py = new SinLFO(min, max, rate);
  
  BounceHigh(LX lx) {
    super(lx);
    addParameter(size);
    addParameter(rate);
    addParameter(min);
    addParameter(max);
    addModulator(py).start();
  }
  
  public void run(double deltaMs) {
    for (LXPoint p : model.points) {
      colors[p.index] = lx.hsb(
        30,
        100,
        max(0, 100 - (100/size.getValuef()) * abs(p.y - py.getValuef())/2.0)
      );
    }
  }
}


class BounceColor extends LXPattern {
  
  final BasicParameter size = new BasicParameter("SIZE", 1*FEET, 1*FEET, 5*FEET);
  final BasicParameter rate = new BasicParameter("RATE", 3*SECONDS, 1.5*SECONDS, 6*SECONDS);
  final BasicParameter max = new BasicParameter("MAX", 1.9*model.cy, 1.9*model.cy, 1.9*model.yMax);
  final BasicParameter min = new BasicParameter("MIN", 0, 0, model.cy);
  final BasicParameter xColor = new BasicParameter("X-COLOR", 0.5);
  final BasicParameter yColor = new BasicParameter("Y-COLOR", 0.5);

  final SinLFO py = new SinLFO(min, max, rate);
  
  BounceColor(LX lx) {
    super(lx);
    addParameter(size);
    addParameter(rate);
    addParameter(min);
    addParameter(max);
    addParameter(xColor);
    addParameter(yColor);

    addModulator(py).start();
  }
  
  public void run(double deltaMs) {
    for (LXPoint p : model.points) {
      float hShift =
        abs(p.x - model.cx) / model.xRange * 360 * xColor.getValuef() +
        abs(p.y - model.cy) / model.yRange * 360 * yColor.getValuef();

      hShift= 2*hShift;

      colors[p.index] = lx.hsb(
        (lx.getBaseHuef() + hShift + (p.x - model.cx)) % 360,
        100,
        // interesting: reverse bounce... cool arrow pointed in direction we are going...
        // 100 - max(0, 100 - (100/size.getValuef()) * abs(p.y - py.getValuef()))

        max(0, 100 - (100/size.getValuef()) * abs(p.y - py.getValuef())/2.0)
      );
    }
  }
}

class BounceArrow extends LXPattern {
  
  final BasicParameter size = new BasicParameter("SIZE", 1*FEET, 1*FEET, 5*FEET);
  final BasicParameter rate = new BasicParameter("RATE", 2*SECONDS, 1*SECONDS, 4*SECONDS);
  final BasicParameter max = new BasicParameter("MAX", 1.9*model.cy, 1.9*model.cy, 1.9*model.yMax);
  final BasicParameter min = new BasicParameter("MIN", 0, 0, model.cy);
  final BasicParameter xColor = new BasicParameter("X-COLOR", 0.5);
  final BasicParameter yColor = new BasicParameter("Y-COLOR", 0.5);

  final SinLFO py = new SinLFO(min, max, rate);
  
  BounceArrow(LX lx) {
    super(lx);
    addParameter(size);
    addParameter(rate);
    addParameter(min);
    addParameter(max);
    addParameter(xColor);
    addParameter(yColor);

    addModulator(py).start();
  }
  
  public void run(double deltaMs) {
    for (LXPoint p : model.points) {
      float hShift =
        abs(p.x - model.cx) / model.xRange * 360 * xColor.getValuef() +
        abs(p.y - model.cy) / model.yRange * 360 * yColor.getValuef();

      hShift= 2*hShift;

      colors[p.index] = lx.hsb(
        (lx.getBaseHuef() + hShift + 3*(p.x - model.cx)) % 360,
        100,
        // interesting: reverse bounce... cool arrow pointed in direction we are going...
        100 - max(0, 100 - (100/size.getValuef()) * abs(p.y - py.getValuef())/1.5)
      );
    }
  }
}

class BounceCrazy extends LXPattern {
  
  final BasicParameter size = new BasicParameter("SIZE", 1*FEET, 1*FEET, 5*FEET);
  final BasicParameter rate = new BasicParameter("RATE", 3*SECONDS, 1.5*SECONDS, 6*SECONDS);
  final BasicParameter max = new BasicParameter("MAX", 1.9*model.cy, 1.9*model.cy, 1.9*model.yMax);
  final BasicParameter min = new BasicParameter("MIN", 0, 0, model.cy);
  final BasicParameter xColor = new BasicParameter("X-COLOR", 0.5);
  final BasicParameter yColor = new BasicParameter("Y-COLOR", 0.5);

  final SinLFO py = new SinLFO(min, max, rate);
  
  BounceCrazy(LX lx) {
    super(lx);
    addParameter(size);
    addParameter(rate);
    addParameter(min);
    addParameter(max);
    addParameter(xColor);
    addParameter(yColor);

    addModulator(py).start();
  }
  
  public void run(double deltaMs) {
    for (LXPoint p : model.points) {
      float hShift =
        abs(p.x - model.cx) / model.xRange * 360 * xColor.getValuef() +
        abs(p.y - model.cy) / model.yRange * 360 * yColor.getValuef();

      hShift= 4 * hShift;

      colors[p.index] = lx.hsb(
        (lx.getBaseHuef() + hShift + (p.x - model.cx)/4.0) % 360,
        100,
        max(0, hShift + 100 - (100/size.getValuef()) * abs(p.y - py.getValuef())/4.0)
      );
    }
  }
}



class Cascade extends LXPattern {
  
  final BasicParameter size = new BasicParameter("SIZE", 1*FEET, 1*FEET, 5*FEET);
  final BasicParameter rate = new BasicParameter("RATE", 3*SECONDS, 1.5*SECONDS, 6*SECONDS);
  final BasicParameter max = new BasicParameter("MAX", 1.9*model.cy, 1.9*model.cy, 1.9*model.yMax);
  final BasicParameter min = new BasicParameter("MIN", 0, 0, model.cy);
  final BasicParameter xColor = new BasicParameter("X-COLOR", 0.5);
  final BasicParameter yColor = new BasicParameter("Y-COLOR", 0.5);

  final SinLFO py = new SinLFO(min, max, rate);
  
  Cascade(LX lx) {
    super(lx);
    addParameter(size);
    addParameter(rate);
    addParameter(min);
    addParameter(max);
    addParameter(xColor);
    addParameter(yColor);

    addModulator(py).start();
  }
  
  public void run(double deltaMs) {
    for (LXPoint p : model.points) {
      float hShift =
        abs(p.x - model.cx) / model.xRange * 360 * xColor.getValuef() +
        abs(p.y - model.cy) / model.yRange * 360 * yColor.getValuef();
      colors[p.index] = lx.hsb(
        max(30,(lx.getBaseHuef() + hShift + (p.x - model.cx)) % 360),
        100,
        max(150,(lx.getBaseHuef() + hShift + (p.y - model.cy)) % 360)
      );
    }
  }
}

class CascadeT extends LXPattern {
  
  final BasicParameter size = new BasicParameter("SIZE", 1*FEET, 1*FEET, 5*FEET);
  final BasicParameter rate = new BasicParameter("RATE", 3*SECONDS, 1.5*SECONDS, 6*SECONDS);
  final BasicParameter max = new BasicParameter("MAX", 1.9*model.cy, 1.9*model.cy, 1.9*model.yMax);
  final BasicParameter min = new BasicParameter("MIN", 0, 0, model.cy);
  final BasicParameter xColor = new BasicParameter("X-COLOR", 0.5);
  final BasicParameter yColor = new BasicParameter("Y-COLOR", 0.5);

  final SinLFO py = new SinLFO(min, max, rate);
  
  CascadeT(LX lx) {
    super(lx);
    addParameter(size);
    addParameter(rate);
    addParameter(min);
    addParameter(max);
    addParameter(xColor);
    addParameter(yColor);

    addModulator(py).start();
  }
  
  public void run(double deltaMs) {
    for (LXPoint p : model.points) {
      float hShift =
        abs(p.x - model.cx) / model.xRange * 360 * xColor.getValuef() +
        abs(p.y - model.cy) / model.yRange * 360 * yColor.getValuef();
      colors[p.index] = lx.hsb(
        max(100,(lx.getBaseHuef() + hShift + (p.x - model.cx)) % 360),
        30,
        max(100,(lx.getBaseHuef() + hShift + (p.y - model.cy)) % 360)
      );
    }
  }
}

class FuzzyBeats extends LXPattern {
  
  final BasicParameter speed = new BasicParameter("SPEED", 1, 0.1, 10);
  final BasicParameter xfreq = new BasicParameter("XFREQ", 10/1.5, 1, 100);
  final BasicParameter yfreq = new BasicParameter("YFREQ", 4/1.5, 1, 100);
  
  final GraphicEQ eq = new GraphicEQ(lx.audioInput(), 4);

  float time = 0;

  FuzzyBeats(LX lx) {
    super(lx);

    addParameter(xfreq);
    addParameter(yfreq);

    eq.attack.setValue(10);
    eq.release.setValue(250);
    eq.range.setValue(14);
    eq.gain.setValue(16);
    addModulator(eq).start();  
  }

  public void run(double deltaMs) {
    time += deltaMs * speed.getValuef();
    float timeS = time / 1000.;

    float zoom = eq.getAveragef(1, 4) + 0.4;
    
    for (LXPoint p : model.points) {
      float x = (p.x - model.cx);
      float y = (p.y - model.cy);
      color bubbles1 = lx.hsb(
        (180 + 20 * timeS * speed.getValuef()) % 360,
        100.,
        max(0, 100 * ((
          1 + (
              sin(PI * xfreq.getValuef() * x / model.xRange / zoom) * 
              cos(PI * yfreq.getValuef() * y / model.yRange / zoom)
          )
        ) / 2))
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

class BubbleBeats extends LXPattern {
  
  final BasicParameter speed = new BasicParameter("SPEED", 1, 0.1, 10);
  final BasicParameter baseSize = new BasicParameter("SIZE", 90, 60, 150);
  final BasicParameter hueSpread = new BasicParameter("SPREAD", 90, 15, 120);
  
  final SawLFO baseHue = new SawLFO(0, 360, 20*SECONDS);
  final SawLFO posOffset = new SawLFO(0, 1, 3*SECONDS);
  
  final GraphicEQ eq = new GraphicEQ(lx.audioInput(), 4);

  PGraphics g;
  
  BubbleBeats(LX lx) {
    super(lx);
    addParameter(baseSize);
    addParameter(hueSpread);
    addModulator(baseHue).start();
    addModulator(posOffset).start();
  
    eq.attack.setValue(10);
    eq.release.setValue(250);
    eq.range.setValue(14);
    eq.gain.setValue(16);
    addModulator(eq).start();
  
    g = createGraphics(int(model.xRange), int(model.yRange));
  }

  void drawBubbles(int startBand, float eqMult, float hue, float xOffs, float yOffs, float bubbleSize) {
    float spacing = baseSize.getValuef();
    float size = 1. + eq.getAveragef(startBand, 4) * eqMult;
    
    for (int y = -5; y < 5; y++) {
      for (int x = -1; x < 10; x++) {
        float xx = x + posOffset.getValuef();
        g.fill(color(
          (hue + baseHue.getValuef()) % 360, 
          constrain(100 - size * 10, 0, 100), 
          constrain(50 + size * 25, 0, 100)
         ));
        g.ellipse(
          (xx + xOffs) * spacing, 
          (y + yOffs) * spacing, 
          spacing * bubbleSize * size, 
          spacing * bubbleSize * size
        );
      }
    }
  }

  public void run(double deltaMs) {
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

