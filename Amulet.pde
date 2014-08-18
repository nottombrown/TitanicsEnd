

// This is meant to be used as a singleton and is instantiated in TitanicsEnd.pde
class Amulet {
  BooleanParameter heartbeatMode;
  Amulet() { } 
  
  void setup() {
    heartbeatMode = new BooleanParameter("HEART", false);
  } 
}

// I don't like this as a global. 
// Is there a way to listen for keypresses from within the Amulet class?
void keyPressed() {
  if(keyCode == 66) {
    amulet.heartbeatMode.setValue(true);
  }
}

void keyReleased() {
  if(keyCode == 66) {
    amulet.heartbeatMode.setValue(false);
  }
}

