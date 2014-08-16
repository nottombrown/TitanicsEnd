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
    for (Strip strip : model.strips) {
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


