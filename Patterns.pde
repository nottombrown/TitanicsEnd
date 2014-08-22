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
        color clr = lx.hsb(
          (lx.getBaseHuef() + dist(p.x, p.y, model.cx, model.cy) / model.xRange * 180) % 360,
          100,
          max(0, 100 - 200*abs(pp - pi)) 
        );
        colors[p.index] = beatHelpers.beatBrighten(clr, 50);
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

      color clr = lx.hsb(
        (lx.getBaseHuef() + + abs(p.y - model.cy) / model.yRange * hr.getValuef() + abs(p.x - cx.getValuef()) / model.xRange * hr.getValuef()) % 360,
        100,
        b
      );
      
      colors[p.index] = beatHelpers.beatBrighten(clr, 50);
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
  private float altBase = 0;
  
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
    
    altBase += deltaMs / 1000. * TWO_PI * (speed.getValuef() * 1.23);
    
    for (LXPoint p : model.points) {
      float svy = model.cy + amp.getValuef() * model.yRange/2.*sin(base + (p.x - model.cx) / model.xRange * TWO_PI * period.getValuef());
      float hShift =
        abs(p.x - model.cx) / model.xRange * 360 * xColor.getValuef() +
        abs(p.y - model.cy) / model.yRange * 360 * yColor.getValuef();
      color clr = lx.hsb(
        (lx.getBaseHuef() + hShift) % 360,
        100,
        max(0, 100 - (100 / (thick.getValuef()*FEET)) * abs(p.y - svy))
      );

      float svy2 = model.cy + amp.getValuef() * model.yRange/2.*sin(altBase + (p.x - model.cx) / model.xRange * TWO_PI * period.getValuef());
      float hShift2 =
        abs(p.x) / model.xRange * 360 * xColor.getValuef() +
        abs(p.y) / model.yRange * 360 * yColor.getValuef();
        
      float bri = constrain(sqrt(eq.getAveragef(1, 4)) * max(0, 100 - (100 / (thick.getValuef()*FEET)) * abs(p.y - svy2)), 0, 100);
      float sat;
      if (bri > brightness(clr)) {
        sat = 100;
      }
      else {
        bri = brightness(clr);
        sat = saturation(clr);
      }
      colors[p.index] = lx.hsb(
        (hue(clr) + (lx.getBaseHuef() + hShift2)) % 360,
        sat,
        bri
      );
    }
  }
}

class AuroraBorealis extends LXPattern {
  
  final SinLFO yOffset = new SinLFO(0, 6*FEET, 3*SECONDS);
  final SinLFO beatOffs = new SinLFO(-1, 1, 1*SECONDS);
  
  float xOffs = 0;
  
  AuroraBorealis(LX lx) {
    super(lx);
    addModulator(yOffset).start();
    addModulator(beatOffs).start();
  }
  
  public void run(double deltaMs) {
    xOffs += deltaMs / 1000 * 20;
    float beatXOffs = beatOffs.getValuef() * eq.getAveragef(1, 4) * 100;
    
    for (LXPoint p : model.points) {
      colors[p.index] = beatHelpers.beatBrighten(lx.hsb(
        (p.y + 2*FEET * sin((p.x + xOffs + beatXOffs)/model.xRange * 4*PI) + yOffset.getValuef())/model.yRange * 180,
        100,
        100
      ), 50);
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




