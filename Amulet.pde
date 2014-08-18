// This is meant to be used as a singleton and is instantiated in TitanicsEnd.pde
class Amulet {
  BooleanParameter heartbeatMode;
  LXListenableParameter symbolIndex;
  Amulet() { } 
  
  void setup() {
    heartbeatMode = new BooleanParameter("HEART", false);
  } 
}

void keyPressed() {
  println(keyCode);
  if (keyCode == 34) {
    println("hit right");
  } 
  if (keyCode == 33) {
    println("hit left");
  } 
  if(keyCode == 66) {
    amulet.heartbeatMode.toggle();
  }
}

