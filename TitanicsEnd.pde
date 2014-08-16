// Imports!
import heronarts.lx.*;
import heronarts.lx.audio.*;
import heronarts.lx.model.*;
import heronarts.p2lx.*;
import heronarts.p2lx.ui.*;
import heronarts.p2lx.ui.control.*;
import ddf.minim.*;

// Useful constants
final static int SECONDS = 1000;
final static int MINUTES = 60*SECONDS;
final static int FEET = 12;
final static int INCHES = 1;
final static float METER = 39.37*INCHES;

// fcserver configuration
final static String FCSERVER_HOST = "127.0.0.1";
final static int FCSERVER_PORT = 7890;

// Car Components (used for rendering the model)
final static float CAR_BODY_HEIGHT = 9.5*FEET;
final static float CAR_BODY_LENGTH = 16*FEET;

// Global engine objects
Model model;
P2LX lx;
FrequencyGate beat;

void setup() {
  // Processing config
  size(800, 600, OPENGL);
  
  // LX engine instance
  lx = new P2LX(this, model = new Model());
  
  // Patterns
  final LXPattern[] patterns;
  lx.setPatterns(patterns = new LXPattern[] {
    new Plasma(lx),
    new Warp(lx),
    new Strobe(lx),
    new Bouncing(lx),
    new AuroraBorealis(lx),
    new Periodicity(lx),
    new IteratorTestPattern(lx),
    new ParameterWave(lx),
    new BounceHigh(lx),
    new BounceColor(lx),
    new BounceArrow(lx),
    new BounceCrazy(lx),
    new Cascade(lx),
    new CascadeT(lx),
    // ...add your new patterns here
  });
  for (LXPattern pattern : patterns) {
    pattern.setTransition(new DissolveTransition(lx).setDuration(1000));
  }
  
  // Effects
  final BeatMask beatMask;
  lx.addEffect(beatMask = new BeatMask(lx));
  
  // Audio detection
  GraphicEQ eq = new GraphicEQ(lx.audioInput(), 4);
  eq.attack.setValue(10);
  eq.release.setValue(250);
  eq.range.setValue(14);
  eq.gain.setValue(16);
  beat = new FrequencyGate("BEAT", eq).setBands(1, 4);
  beat.floor.setValue(0.9);
  beat.threshold.setValue(0.75);
  beat.release.setValue(480);
  lx.addModulator(eq).start();
  lx.addModulator(beat).start();
  
  // Midi Control
  LXMidiInput qx25input = LXMidiSystem.matchInput(lx, "QX25");
  if (qx25input != null) {
    LXMidiDevice qx25 = new LXMidiDevice(qx25input) {
      public void noteOn(LXMidiNoteOn noteOn) {
        println("noteOn:" + noteOn.getPitch());
      }
      
      public void noteOff(LXMidiNoteOff noteOff) {
        println("noteOff:" + noteOff.getPitch());
      }
      
      public void controlChange(LXMidiControlChange cc) {
        println("cc:" + cc.getCC() + ":" + cc.getValue());
      }
    };
    
  }
  
  // OPC Output
  final FadecandyOutput output;
  lx.addOutput(output = new FadecandyOutput(lx, FCSERVER_HOST, FCSERVER_PORT) {
    protected void didConnect() {
      super.didConnect();
      println("Connected to fcserver");
    }
    protected void didDispose(Exception x) {
      println("Closed connection to fcserver: " + x.getMessage());
    }
  });
  output.enabled.setValue(false);
  
  // UI layers
  lx.ui.addLayer(new UICameraLayer(lx.ui) {
      protected void beforeDraw() {
        hint(ENABLE_DEPTH_TEST);
      }
      protected void afterDraw() {
        hint(DISABLE_DEPTH_TEST);
      }
    }
    .setCenter(model.cx, model.cy, model.cz)
    .setRadius(34*FEET)
    .setTheta(PI/6)
    .addComponent(new UIGLPointCloud(lx).setPointWeight(2))
    .addComponent(new CarBodyWalls())
    .addComponent(new CarCabinWalls())
  );
  lx.ui.addLayer(new UIChannelControl(lx.ui, lx, 4, 4));
  lx.ui.addLayer(new UIBeatDetect(lx.ui, beat, 4, 326));
  lx.ui.addLayer(new UIOutputControl(lx.ui, output, 4, 518));
  lx.ui.addLayer(new UIEffect(lx.ui, beatMask, width - 144, 4));
  lx.engine.setThreaded(true);
}

void draw() {
  // Wipe background, engine takes care of the rest
  background(#191919);
}

static class UIOutputControl extends UIWindow {
  public UIOutputControl(UI ui, LXOutput output, float x, float y) {
    super(ui, "OUTPUT (" + FCSERVER_HOST + ":" + FCSERVER_PORT + ")", x, y, UIChannelControl.WIDTH, 72);
    float yPos = UIWindow.TITLE_LABEL_HEIGHT;
    new UIButton(4, yPos, width - 8, 20)
    .setParameter(output.enabled)
    .setActiveLabel("Enabled")
    .setInactiveLabel("Disabled")
    .addToContainer(this); 
    yPos += 24;
    new UISlider(4, yPos, width - 8, 20)
    .setParameter(output.brightness)
    .addToContainer(this);
  }
}

class CarBodyWalls extends UICameraComponent {
  protected void onDraw(UI ui) {
    stroke(#555555);
    fill(#333333);
    pushMatrix();
    translate(model.cx, model.cy-1*FEET, model.cz);
    box(CAR_BODY_LENGTH, CAR_BODY_HEIGHT, model.zRange * .9);
    popMatrix(); 
  }
}

class CarCabinWalls extends UICameraComponent {
  final static int CABIN_LENGTH = 6*FEET;
  final static int CABIN_HEIGHT = 7*FEET;
  final static int ENGINE_HEIGHT = 5*FEET;
  
  float bodyBottom;
  float bodyFront;
  
  protected void onDraw(UI ui) {
    bodyBottom = model.cy - 1*FEET - CAR_BODY_HEIGHT / 2;
    bodyFront = model.cx + CAR_BODY_LENGTH/2;
    stroke(#555555);
    fill(#333333);
    
    // Cabin
    pushMatrix();
    translate(bodyFront + CABIN_LENGTH/4, bodyBottom+CABIN_HEIGHT/2, model.cz);
    box(CABIN_LENGTH/2, CABIN_HEIGHT, model.zRange * .9);
    popMatrix();
    
    // Engine
    pushMatrix();
    translate(bodyFront + CABIN_LENGTH*3/4, bodyBottom+ENGINE_HEIGHT/2, model.cz);
    box(CABIN_LENGTH/2, ENGINE_HEIGHT, model.zRange * .9);
    popMatrix();
  }
}

static class UIEffect extends UIWindow {
  UIEffect(UI ui, LXEffect effect, float x, float y) {
    super(ui, effect.getClass().getSimpleName().toUpperCase(), x, y, 140, 72);
    float yPos = 24;
    float xPos = 4;
    int i = 0;
    for (LXParameter p : effect.getParameters()) {
      if (p instanceof LXListenableNormalizedParameter) {
        LXListenableNormalizedParameter parameter = (LXListenableNormalizedParameter) p;  
        new UIKnob(xPos, yPos).setParameter(parameter).addToContainer(this);
        xPos += 34;
        if (++i > 4) {
          break;
        }
      }
    }
  }
}

