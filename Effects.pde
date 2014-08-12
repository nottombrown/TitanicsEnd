class BeatMask extends LXEffect {
  
  public final BasicParameter amount = new BasicParameter("AMOUNT", 0); 
  
  public BeatMask(LX lx) {
    super(lx);
    addParameter(amount);
  }
  
  public void run(double deltaMs) {
    float scale = lerp(1, beat.getValuef(), amount.getValuef());
    if (scale < 1) {
      LXColor.scaleBrightness(this.colors, scale, null);
    }
  }
}

