// This is meant to be used as a singleton and is instantiated in TitanicsEnd.pde
class Amulet {
  float heartPower;
  BasicParameter heartDecay;
  LXListenableParameter symbolIndex;
  Amulet() { } 
  
  void setup() {
    heartPower = 0.0
    heartDecay = new BasicParameter("DECAY", 0.02, 0, 0.1);
  } 
  void loop(double deltaMS) {
     heart.setValue(heart.getValuef()-heartDecay.getValuef());
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
    amulet.heartPower = 1.0
  }
}

