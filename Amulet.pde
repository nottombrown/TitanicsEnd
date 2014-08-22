// This is meant to be used as a singleton and is instantiated in TitanicsEnd.pde
class Amulet {
  float heartPower;
  BasicParameter heartDecay;
  LXListenableParameter symbolIndex;
  Amulet() { } 
  
  void setup() {
    heartPower = 0.0;
    heartDecay = new BasicParameter("DECAY", 0.03, 0, 0.1);
  } 
  
  void runHeartLoop(double deltaMS) {
     heartPower -= constrain(heartDecay.getValuef(), 0,1);
  }
  boolean heartIsOn(){
    return heartPower > 0;
  }
}

void keyPressed() {
  println(keyCode);

  switch (keyCode) {
  case 27:
  case 116:
    // TODO
    break;

  case 33: // left
    lx.goPrev();
    break;

  case 34: // right
    lx.goNext();
    break;

  case 66: // b
    amulet.heartPower = 1.0;
    //lx.goNext();
    break;
  }

  if (key == ESC) key = 0; // trap ESC so it doesn't quit
}

