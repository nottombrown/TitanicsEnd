// Imports!
import heronarts.lx.*;
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

final static String FCSERVER_HOST = "127.0.0.1";
final static int FCSERVER_PORT = 7890;

final static float VEHICLE_HEIGHT = 9.5*FEET;

// Global engine objects
Model model;
P2LX lx;

void setup() {
  // Processing config
  size(800, 600, OPENGL);

  // LX engine instance
  lx = new P2LX(this, model = new Model());

  // Patterns
  final LXPattern[] patterns;
  lx.setPatterns(patterns = new LXPattern[] {
    new IteratorTestPattern(lx),
    new Bouncing(lx),
    new AuroraBorealis(lx),
    new Warp(lx),
    new Periodicity(lx),
    new ParameterWave(lx),
    // ...add your new patterns here
  });
  for (LXPattern pattern : patterns) {
    pattern.setTransition(new DissolveTransition(lx).setDuration(1000));
  }

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
    .setRadius(22*FEET)
    .setTheta(PI/12)
    .setPhi(-PI/24)
    .addComponent(new UIPointCloud(lx).setPointWeight(2))
    .addComponent(new CarBodyWalls())
    .addComponent(new CarCabinWalls())
  );
  lx.ui.addLayer(new UIChannelControl(lx.ui, lx, 4, 4));
  lx.ui.addLayer(new UIOutputControl(lx.ui, output, 4, 332));
}

void draw() {
  // Wipe background, engine takes care of the rest
  background(#191919);
}

static class UIOutputControl extends UIWindow {
  public UIOutputControl(UI ui, LXOutput output, float x, float y) {
    super(ui, "OUTPUT (" + FCSERVER_HOST + ":" + FCSERVER_PORT + ")", x, y, UIChannelControl.DEFAULT_WIDTH, 72);
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
    box(model.xRange, VEHICLE_HEIGHT, model.zRange * .9);
    popMatrix();
  }
}

class CarCabinWalls extends UICameraComponent {
  final static int CABIN_LENGTH = 6*FEET;
  final static int CABIN_HEIGHT = 7*FEET;
  final static int ENGINE_HEIGHT = 5*FEET;
  
  float bodyBottom;
  
  protected void onDraw(UI ui) {
    bodyBottom = model.cy - 1*FEET - VEHICLE_HEIGHT / 2;
    stroke(#555555);
    fill(#333333);
    
    // Cabin
    pushMatrix();
    translate(model.xRange + CABIN_LENGTH/4, bodyBottom+CABIN_HEIGHT/2, model.cz);
    box(CABIN_LENGTH/2, CABIN_HEIGHT, model.zRange * .9);
    popMatrix();
    
    // Engine
    pushMatrix();
    translate(model.xRange + CABIN_LENGTH*3/4, bodyBottom+ENGINE_HEIGHT/2, model.cz);
    box(CABIN_LENGTH/2, ENGINE_HEIGHT, model.zRange * .9);
    popMatrix();
  }
}
