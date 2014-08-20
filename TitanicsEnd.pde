// Imports!
import heronarts.lx.*;
import heronarts.lx.audio.*;
import heronarts.lx.model.*;
import heronarts.p2lx.*;
import heronarts.p2lx.ui.*;
import heronarts.p2lx.ui.control.*;
import ddf.minim.*;
import oscP5.*;

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

LXPattern[] patterns;

// Global engine objects
Model model;
P2LX lx;
FrequencyGate beat;
GraphicEQ eq;
OscP5 oscP5;
NetAddressList netAddressList = new NetAddressList();

final int listeningPort = 10001;
final int broadcastPort = 9001;

final String connectPattern = "/server/connect";
final String disconnectPattern = "/server/disconnect";

final String changePatternPattern = "/server/changepattern";
final String changeParamPattern = "/server/changeparam";

final String statePattern = "/broadcast/state";

// Global 
Amulet amulet = new Amulet();

void setup() {
  // Processing config
  size(800, 600, OPENGL);
  
  // LX engine instance
  lx = new P2LX(this, model = new Model());  
  
  // Set up the amulet
  amulet.setup();
  
  // Patterns
  lx.setPatterns(patterns = new LXPattern[] {
    new Plasma(lx),
    new Dance(lx),
    new Grow(lx),
    new HyperCube(lx),
    new Logo(lx),
    new Fire(lx),
    new InfiniteSmileys(lx),
    new TextScroller(lx),
    new Tribal(lx),
    new Tunnel(lx),
    new BubbleBeats(lx),
    new FuzzyBeats(lx),
    new Warp(lx),
    new Strobe(lx),
    new Pulse(lx),
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
  
  final Heartbeat heartbeat;
  lx.addEffect(heartbeat = new Heartbeat(lx));
  
  // Audio detection
  eq = new GraphicEQ(lx.audioInput(), 4);
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
  
  // OSC Control
  oscP5 = new OscP5(this, listeningPort);
  
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
        
        // for custom pattern-specific controls (nothing coded yet)
        lx.getPattern().controlChangeReceived(cc);
        
        int param = cc.getCC() - 14;
        if (param >= 0 && param < 10) {
          // assumes basic parameter
          ((BasicParameter) lx.getPattern().getParameters().get(param)).setNormalized(cc.getValue() / 127.);
        }
        
        //Broadcast message with current pattern / param states
        oscP5.send(currentStateMessage(-1), netAddressList);
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
    .addComponent(new UIPointCloud(lx).setPointWeight(2))
    .addComponent(new CarBodyWalls())
    .addComponent(new CarCabinWalls())
  );
  lx.ui.addLayer(new UIChannelControl(lx.ui, lx, 4, 4));
  lx.ui.addLayer(new UIBeatDetect(lx.ui, beat, 4, 326));
  lx.ui.addLayer(new UIOutputControl(lx.ui, output, 4, 518));
  lx.ui.addLayer(new UIEffect(lx.ui, beatMask, width - 144, 4));
  lx.ui.addLayer(new UIEffect(lx.ui, heartbeat, width - 144, 4));
  lx.engine.setThreaded(false);
  
  lx.tempo.bpm.setValue(120);
}

// Respond to OSC Events
void oscEvent(OscMessage theOscMessage) { 
  /* print the address pattern and the typetag of the received OscMessage */ 
  print(" addrpattern: "+theOscMessage.addrPattern()); 
  println(" typetag: "+theOscMessage.typetag()); 
  
  int newPatternIndex = -1;
  
  /* check if the address pattern fits any of our patterns */
  if (theOscMessage.addrPattern().equals(connectPattern)) {
    String theIPaddress = theOscMessage.netAddress().address();
    connect(theIPaddress);
    //Send message to netAddress with current pattern / param states
    oscP5.send(currentStateMessage(newPatternIndex), new NetAddress(theIPaddress, broadcastPort));
  }
  else if (theOscMessage.addrPattern().equals(disconnectPattern)) {
    disconnect(theOscMessage.netAddress().address());
  }
  /**
   * if pattern matching was not successful, then broadcast the incoming
   * message to all addresses in the netAddresList. 
   */
  else {
    //Change pattern or param
    if (theOscMessage.addrPattern().equals(changePatternPattern)){
      int patternIndex = ((Number)theOscMessage.arguments()[0]).intValue();
      lx.goPattern(patterns[patternIndex]);
      newPatternIndex = patternIndex;
    }
    else if (theOscMessage.addrPattern().equals(changeParamPattern)) {
      String paramName = (String)theOscMessage.arguments()[0];
      float newValue = ((Number)theOscMessage.arguments()[1]).floatValue();
      lx.getPattern().getParameter(paramName).setValue((double)newValue);
    }
    //Broadcast message with current pattern / param states
    oscP5.send(currentStateMessage(newPatternIndex), netAddressList);
  }
}

// Create OSC message from current state
OscMessage currentStateMessage(int newPatternIndex) {
  OscMessage message = new OscMessage(statePattern);
  LXPattern activePattern;
  if (newPatternIndex == -1) {
    activePattern = lx.getPattern();
  }
  else {
    activePattern = patterns[newPatternIndex];
  }
  message.add("active pattern");
  message.add(activePattern.getName());
  for (LXParameter param : activePattern.getParameters()) {
    if (param instanceof BasicParameter) {
      BasicParameter basicParam = (BasicParameter)param;
      message.add("begin param");
      message.add(basicParam.getLabel());
      message.add(basicParam.getValuef());
      message.add((float)basicParam.range.v0);
      message.add((float)basicParam.range.v1);
    }
  }
  message.add("all patterns");
  for (LXPattern pattern : patterns) {
    message.add(pattern.getName());
  }
  return message;
}

// Subscribe OSC device to broadcasts
void connect(String theIPaddress) {
  if (!netAddressList.contains(theIPaddress, broadcastPort)) {
    netAddressList.add(new NetAddress(theIPaddress, broadcastPort));
    println("### adding "+theIPaddress+" to the list.");
  } else {
    println("### "+theIPaddress+" is already connected.");
  }
  println("### currently there are "+netAddressList.list().size()+" remote locations connected.");
}

// Unsubscribe OSC device from broadcasts
void disconnect(String theIPaddress) {
  if (netAddressList.contains(theIPaddress, broadcastPort)) {
    netAddressList.remove(theIPaddress, broadcastPort);
    println("### removing "+theIPaddress+" from the list.");
  } else {
    println("### "+theIPaddress+" is not connected.");
  }
    println("### currently there are "+netAddressList.list().size());
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
  final static int NUM_PORT_BACK_STRIPS = 12;

  protected void onDraw(UI ui) {
    stroke(#555555);
    fill(#333333);
    pushMatrix();
    translate(NUM_PORT_BACK_STRIPS * Model.STRIP_SPACING + CAR_BODY_LENGTH/2, model.cy-1*FEET, model.cz);
    box(CAR_BODY_LENGTH, CAR_BODY_HEIGHT, model.zRange * .9);
    popMatrix(); 
  }
}

class CarCabinWalls extends UICameraComponent {
  final static int CABIN_LENGTH = 6*FEET;
  final static int CABIN_HEIGHT = 7*FEET;
  final static int ENGINE_HEIGHT = 5*FEET;
  final static int NUM_PORT_BACK_STRIPS = 12;
  
  float bodyBottom;
  float bodyFront;
  
  protected void onDraw(UI ui) {
    bodyBottom = model.cy - 1*FEET - CAR_BODY_HEIGHT / 2;
    bodyFront = NUM_PORT_BACK_STRIPS * Model.STRIP_SPACING + CAR_BODY_LENGTH;
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

