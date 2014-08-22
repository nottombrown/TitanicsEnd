/** Base class for block related patterns */
class BlockBase extends LXPattern {
  final BasicParameter speed = new BasicParameter("SPEED", 0.25*SECONDS, 0.01*SECONDS, 5*SECONDS);
  final BasicParameter blockWidth = new BasicParameter("BLOCKWIDTH", 40, 10, model.xRange);
  final BasicParameter blockHeight = new BasicParameter("BLOCKHEIGHT", 40, 10, model.yRange);

  final BooleanParameter randomColor = new BooleanParameter("RANDOMCOLOR",false);
  final BasicParameter hueBase = new BasicParameter("HUE", 50, 0, 100);
  final BasicParameter hueRange = new BasicParameter("HUERANGE", 20, 0, 50);
  
  int[] _blockColors;
  double _totalTime = 0;
  int _currentStep = 0,_currentBlock=0;
  
  int _numBlocks,_numBlocksX,_numBlocksY;
  
  PGraphics _g;
  
  BlockBase(LX lx) {
    super(lx);
    addParameter(speed);
    addParameter(blockWidth);
    addParameter(blockHeight);
    

    int colorStep=10;
    int numColors=100/colorStep;
    _blockColors=new int[numColors];
    for(int h=0,index=0;h<100;h+=colorStep,index++) {
      _blockColors[index]=h;
    }
    
    _g = createGraphics(int(model.xRange), int(model.yRange));
  }
  
  public void run(double deltaMs) {
    _totalTime += deltaMs;
    _currentStep = floor((float)_totalTime / speed.getValuef());

    _numBlocksX = ceil(model.xRange/blockWidth.getValuef());
    _numBlocksY = ceil(model.yRange/blockHeight.getValuef());
    _numBlocks=_numBlocksX*_numBlocksY;
    _currentBlock=_currentStep%_numBlocks;
    
        
    PImage img=drawImage();
    mapImageToPoints(img);
  }
  
  /** Main pattern draw function */
  PImage drawImage() {
    // Override this
    return g.get();
  }
  
  /** Writes the given image to the LED points */
  protected void mapImageToPoints(PImage img) {
    for (LXPoint p : model.points) {
      int ix, iy;
      if (p.z > 0) {
        ix = int((model.xRange - p.x - 5*FEET) / model.xRange * img.width); 
        iy = int(p.y / model.yRange * img.height); 
      }
      else {
        ix = int(p.x / model.xRange * img.width); 
        iy = int(p.y / model.yRange * img.height); 
      }
      int band = int(abs(int(p.x / blockWidth.getValuef()) - _numBlocksX / 2.) + abs(int(p.y / blockHeight.getValuef()) - _numBlocksY / 2.));
      colors[p.index] = beatHelpers.beatBrighten(img.get(ix, iy), 75, band);
    }
  }
  
  /** Generates a random color depending on options */
  int generateColor(int lastColor) {
    int newColor;
    do {
      if(randomColor.isOn()) {
        newColor=(int)random(100);
      } else {
        newColor=floor(random(hueRange.getValuef())-hueRange.getValuef()/2+hueBase.getValuef()+100)%100;
      }
    } while(abs(lastColor-newColor)<10 && hueRange.getValuef()<=20); // Make sure color is different enough
    
    return newColor;
  }
}

/** Left/Right block shifting pattern */
class BlockShift extends BlockBase {
  int[] _blockColors;
  int _lastBlock=0;
  
  BlockShift(LX lx) {
    super(lx);
    
    
    addParameter(hueBase);
    addParameter(hueRange);
    addParameter(randomColor);
    
    speed.setValue(300.0f);
  }
    
  PImage drawImage() {
    if(_blockColors==null || _blockColors.length!=_numBlocksX) {
      _blockColors=new int[_numBlocksX];
      int lastColor=generateColor(0);
      for(int i=0; i<_numBlocksX;i++) {
        lastColor=_blockColors[i]=generateColor(lastColor);
      }
    }
    
    if(_lastBlock != _currentBlock) {
      // Shift colors
      for(int i=0; i<_blockColors.length-1;i++) {
        _blockColors[i]=_blockColors[i+1];
      }
      _blockColors[_blockColors.length-1]=generateColor(_blockColors[_blockColors.length-1]);
      _lastBlock=_currentBlock;
    }
    
    float interp=(float)(_totalTime-_currentStep*speed.getValuef())/speed.getValuef();
    
    _g.colorMode(HSB, 100);
    
    _g.beginDraw();
    _g.noStroke();
    _g.background(0,0,0);
    
    
    float mInterp=(cos(interp*PI)+1)/2;
    for(int x=0; x<_numBlocksX; x++) {
      for(int y=0; y<_numBlocksY; y++) {
        int blockIndex=x+y*_numBlocksX;
        _g.fill(_blockColors[x],100,100);
        _g.rect(
          (x+mInterp)*blockWidth.getValuef(),
          y*blockHeight.getValuef(),
          blockWidth.getValuef(),
          blockHeight.getValuef()
        );
        
      }
    }
    
    _g.endDraw();
    return _g.get();
  }
}

import java.util.Random;

/** Random rotating blocks */
class BlockRandom extends BlockBase {
  final BasicParameter decay = new BasicParameter("DECAY", 0.025, 0.005, 1);
  
   int _lastColor=0;
   int[] _blockOrder;
   int _lastBlock=0;
   int[] _blockBrightness;
   int[] _blockColor;
     
   BlockRandom(LX lx) {
    super(lx);
    
    addParameter(hueBase);
    addParameter(hueRange);
    addParameter(randomColor);
    addParameter(decay);

    speed.setValue(25.0f);
  }
  
  
  public void run(double deltaMs) {
    super.run(deltaMs);
    
    if(_blockOrder==null || _blockOrder.length != _numBlocks) {
      _blockOrder=new int[_numBlocks];
      _blockBrightness=new int[_numBlocks];
      _blockColor=new int[_numBlocks];
      
      
      for(int i=0; i<_numBlocks;i++) {
        _blockOrder[i]=i;
        _blockBrightness[i]=0;
        _blockColor[i]=floor(random(100));
      }
      
      shuffleArray(_blockOrder);
    }
    
    
    for(int i=0; i<_numBlocks;i++) {
      int brightnessDelta=floor((float)(100*(deltaMs*decay.getValuef()/speed.getValuef())));
      _blockBrightness[i]=max(0,_blockBrightness[i]-brightnessDelta);
    }
        
  }
  
  PImage drawImage() {    
    // Check for state changes
    if(_blockOrder==null || _blockOrder.length!=_numBlocks) {
      return _g.get();
    }
    
    if(_currentBlock!=_lastBlock) {
      _lastBlock=_currentBlock;
      
      int newBlock=_blockOrder[_currentBlock];
      
      _lastColor=_blockColor[newBlock]=generateColor(_lastColor);
      _blockBrightness[newBlock]=100;
      
      if(_currentBlock==0) {
        shuffleArray(_blockOrder);
      }
    }
    
    float interp=(float)(_totalTime-_currentStep*speed.getValuef())/speed.getValuef();
    
    _g.colorMode(HSB, 100);
    
    _g.beginDraw();
    _g.noStroke();
    _g.background(0,0,0);
        
    for(int x=0; x<_numBlocksX; x++) {
      for(int y=0; y<_numBlocksY; y++) {
        int blockIndex=x+y*_numBlocksX;
        _g.fill(_blockColor[blockIndex],100,_blockBrightness[blockIndex]);
        _g.rect(
          x*blockWidth.getValuef(),
          y*blockHeight.getValuef(),
          blockWidth.getValuef(),
          blockHeight.getValuef()
        );
        
      }
    }  
    _g.endDraw();
    return _g.get();
  }
  
  void shuffleArray(int[] array) {
    // with code from WikiPedia; Fisher–Yates shuffle 
    //@ <a href="http://en.wikipedia.org/wiki/Fisher" target="_blank" rel="nofollow">http://en.wikipedia.org/wiki/Fisher</a>–Yates_shuffle
   
    Random rng = new Random();
   
    // i is the number of items remaining to be shuffled.
    for (int i = array.length; i > 1; i--) {
   
      // Pick a random element to swap with the i-th element.
      int j = rng.nextInt(i);  // 0 <= j <= i-1 (0-based array)
   
      // Swap array elements.
      int tmp = array[j];
      array[j] = array[i-1];
      array[i-1] = tmp;
    }
  }
}

/** Spiral rotating blocks */
class BlockSpiral extends BlockBase {
  int _lastColor=0;
  int _currentColor=60;
  int _lastCycle=0;
  
  final BooleanParameter shouldReverse = new BooleanParameter("SHOULDREVERSE",true);
  
  BlockSpiral(LX lx) {
    super(lx);
    

    addParameter(hueBase);
    addParameter(hueRange);
    addParameter(randomColor);
    addParameter(shouldReverse);

    randomColor.setValue(true);    
    speed.setValue(12.0f);
    blockWidth.setValue(20.0f);
    blockHeight.setValue(20.0f);
  }
  
  PImage drawImage() {    
    float interp=(float)(_totalTime-_currentStep*speed.getValuef())/speed.getValuef();
    
    
    _g.colorMode(HSB, 100);
    
    _g.beginDraw();
    _g.noStroke();
    _g.background(0,0,0);
    
    int spiralWidth=_numBlocksX/2+1;
    drawSpiral(0,0,spiralWidth,_numBlocksY+1);
    
    _g.pushMatrix();
    _g.translate((spiralWidth-1)*blockWidth.getValuef(),0);
    drawSpiral(0,0,spiralWidth,_numBlocksY+1);
    _g.popMatrix();
    
    _g.endDraw();
    return _g.get();
  }
  
  protected void drawSpiral(int x,int y,int w,int h) {
    
    int i, k = x, l = y, m=w-1,n=h-1;
    int totalBlocks=(w-x)*(h-y);
 
    /*  k - starting row index
        m - ending row index
        l - starting column index
        n - ending column index
        i - iterator
    */
    int count=0;
    while (k < m && l < n) {
        /* Print the first row from the remaining rows */
        for (i = l; i < n; ++i) {
            drawBlock(k,i,count++,totalBlocks);
        }
        k++;
 
        /* Print the last column from the remaining columns */
        for (i = k; i < m; ++i) {
            drawBlock(i,n-1,count++,totalBlocks);
        }
        n--;
 
        /* Print the last row from the remaining rows */
        if ( k < m){
            for (i = n-1; i >= l; --i) {
                drawBlock(m-1,i,count++,totalBlocks);
            }
            m--;
        }
 
        /* Print the first column from the remaining columns */
        if (l < n) {
            for (i = m-1; i >= k; --i) {
                drawBlock(i,l,count++,totalBlocks);
            }
            l++;
        }        
    }
  }
  
  protected void drawBlock(int x, int y,int count, int totalBlocks) {
    int cycleStep=floor(_currentStep/totalBlocks)+1;
    boolean reverse=(cycleStep % 2==0);
    
    if(_lastCycle != cycleStep) {
      _lastColor=_currentColor;
      _currentColor=generateColor(_lastColor);
      _lastCycle=cycleStep;
    }
    
    int spiralBlock=_currentStep%totalBlocks;
    boolean isCurrentColor;
    if(reverse && shouldReverse.isOn()) {
      isCurrentColor = (totalBlocks-count-1) <= spiralBlock;
    } else {
      isCurrentColor = (count <= spiralBlock);
    }
    
    
    _g.fill(isCurrentColor ? _currentColor : _lastColor,100,100);
    _g.rect(
      x*blockWidth.getValuef(),
      y*blockHeight.getValuef(),
      blockWidth.getValuef(),
      blockHeight.getValuef()
    );
  }
}
