/**
 * TouchOSC
 * 
 * Example displaying values received from
 * the "Simple" layout (Page1 only so far)
 * http://hexler.net/touchosc
 *
 */

import oscP5.*;
import netP5.*;
OscP5 oscP5;

float v_fader1 = 0.0f;
float v_fader2 = 0.0f;
float v_fader3 = 0.0f;
float v_fader4 = 0.0f;
float v_fader5 = 0.0f;
float v_toggle1 = 0.0f;
float v_toggle2 = 0.0f;
float v_toggle3 = 0.0f;
float v_toggle4 = 0.0f;

void setup() {
  size(320,440);
  frameRate(25);
  /* start oscP5, listening for incoming messages at port 8000 */
  oscP5 = new OscP5(this,8000);
}

void oscEvent(OscMessage theOscMessage) {

    String addr = theOscMessage.addrPattern();
    float  val  = theOscMessage.get(0).floatValue();
    
    if(addr.equals("/1/fader1"))        { v_fader1 = val; }
    else if(addr.equals("/1/fader2"))   { v_fader2 = val; }
    else if(addr.equals("/1/fader3"))   { v_fader3 = val; }
    else if(addr.equals("/1/fader4"))   { v_fader4 = val; }
    else if(addr.equals("/1/fader5"))   { v_fader5 = val; }
    else if(addr.equals("/1/toggle1"))  { v_toggle1 = val; }
    else if(addr.equals("/1/toggle2"))  { v_toggle2 = val; }
    else if(addr.equals("/1/toggle3"))  { v_toggle3 = val; }
    else if(addr.equals("/1/toggle4"))  { v_toggle4 = val; }
}

void draw() {
    background(0);

    // fader5 + toggle 1-4 outlines
    fill(0);
    stroke(0, 196, 168);  

    rect(17,21,287,55);
    rect(17,369,60,50);
    rect(92,369,60,50);
    rect(168,369,60,50);
    rect(244,369,60,50);

    // fader5 + toggle 1-4 fills
    fill(0, 196, 168);
    rect(17,21,v_fader5*287,55);
    if(v_toggle1 == 1.0f) rect(22,374,50,40);
    if(v_toggle2 == 1.0f) rect(97,374,50,40);
    if(v_toggle3 == 1.0f) rect(173,374,50,40);
    if(v_toggle4 == 1.0f) rect(249,374,50,40);
    
    // fader 1-4 outlines
    fill(0);
    stroke(255, 237, 0);
    rect(17,95,60,255);
    rect(92,95,60,255);
    rect(168,95,60,255);
    rect(244,95,60,255);
    
    // fader 1-4 fills
    fill(255, 237, 0);
    rect(17,95 + 255 - v_fader1*255,60,v_fader1*255);
    rect(92,95 + 255 - v_fader2*255,60,v_fader2*255);
    rect(168,95 + 255 - v_fader3*255,60,v_fader3*255);
    rect(244,95 + 255 - v_fader4*255,60,v_fader4*255);
}
