
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
      colors[p.index] = beatHelpers.beatFlash(lx.hsb(
        30,
        100,
        max(0, 100 - (100/size.getValuef()) * abs(p.y - py.getValuef())/2.0)
      ), 50);
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

      colors[p.index] = beatHelpers.beatFlash(lx.hsb(
        (lx.getBaseHuef() + hShift + (p.x - model.cx)) % 360,
        100,
        // interesting: reverse bounce... cool arrow pointed in direction we are going...
        // 100 - max(0, 100 - (100/size.getValuef()) * abs(p.y - py.getValuef()))

        max(0, 100 - (100/size.getValuef()) * abs(p.y - py.getValuef())/2.0)
      ), 50);
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

      colors[p.index] = beatHelpers.beatFlash(lx.hsb(
        (lx.getBaseHuef() + hShift + 3*(p.x - model.cx)) % 360,
        100,
        // interesting: reverse bounce... cool arrow pointed in direction we are going...
        100 - max(0, 100 - (100/size.getValuef()) * abs(p.y - py.getValuef())/1.5)
      ));
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

      colors[p.index] = beatHelpers.beatFlash(lx.hsb(
        (lx.getBaseHuef() + hShift + (p.x - model.cx)/4.0) % 360,
        100,
        max(0, hShift + 100 - (100/size.getValuef()) * abs(p.y - py.getValuef())/4.0)
      ));
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
      colors[p.index] = beatHelpers.beatFlash(lx.hsb(
        max(30,(lx.getBaseHuef() + hShift + (p.x - model.cx)) % 360),
        100,
        max(150,(lx.getBaseHuef() + hShift + (p.y - model.cy)) % 360)
      ));
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
      colors[p.index] = beatHelpers.beatFlash(lx.hsb(
        max(100,(lx.getBaseHuef() + hShift + (p.x - model.cx)) % 360),
        30,
        max(100,(lx.getBaseHuef() + hShift + (p.y - model.cy)) % 360)
      ));
    }
  }
}
