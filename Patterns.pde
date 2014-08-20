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
  final BasicParameter speed = new BasicParameter("SPEED", 100, 1, 100);
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
        50,
        100,
        75 * ((Math.round(timeS) % 2))
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

public class Fire extends LXPattern {

  final BasicParameter scaleX = new BasicParameter("XSCALE", 200, 1, 1000);
  final BasicParameter scaleY = new BasicParameter("YSCALE", 250, 1, 1000);

  final BasicParameter xNoiseScale = new BasicParameter("XNOISE", 0.01, 0.001, 1);
  final BasicParameter yNoiseScale = new BasicParameter("YNOISE", 0.01, 0.001, 1);

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

    addParameter(scaleX);
    addParameter(scaleY);

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
    drawGradient(g, new float[] {0, 0.4, 0.45, 0.5, 0.6, 0.8, 1}, new color[] {
      color(0,0,0), 
      color(0,0,30),
      color(21,50,50),
      color(21,100,100),
      color(31,100,100),
      color(50,70,100),
      color(50,30,100)
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

    float scaleXF = scaleX.getValuef();
    float scaleYF = scaleY.getValuef();

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
  
  final DiscreteParameter beatSource = new DiscreteParameter("BTSRC", SOURCE_TEMPO, SOURCE_COUNT);

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
    float hue = map(step, 0, branchMax, trunkHue, leafHue); 
    float brightness = map(step, 0, branchMax, trunkBrightness, leafBrightness); 
    
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
    g.background(color(200, map(beatZoom, 0, 4, 50, 100), 50));
    g.pushMatrix();
    g.translate(model.cx + slideX, 0);
    g.scale(1, -1);
    
    g.stroke(color(90, map(beatZoom, 0, 4, 100, 0), 100));
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

