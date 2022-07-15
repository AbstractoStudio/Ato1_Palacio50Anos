import oscP5.*;
import netP5.*;
import org.openkinect.processing.*;

OscP5 oscP5;
NetAddress blobPosAddress,blobAmountAddress;

boolean twoKinects = true;

// Kinects
Kinect2 kinect2_A;
Kinect2 kinect2_B;

// Depth image (two Kinects stacked (512x848[(248*2)])
PImage depthImg;
PGraphics depthBlobs;

// Background Substraction
int numPixels;
int [] backgroundPixels;

// Depth calculate in mm (2000mm = 2m)
int minDepth =  1700;
int maxDepth =  1830;
int incDepth = 10;

// Blob vars
int blobCounter = 0;
int maxLife = 5;
int minSize=250;
int maxSize=5000;
color trackColor; 
float threshold = 50;
float distThreshold = 15;
ArrayList<Blob> blobs = new ArrayList<Blob>();

// 
// Warning msg: [DepthPacketStreamParser::onDataReceived] not all subsequences received ...
// https://github.com/shiffman/OpenKinect-for-Processing/issues/93
//void settings(){
//  size(512, 848);
//  PJOGL.profile=1; 
//}

void setup() {
  size(512, 848);
    
  oscP5 = new OscP5(this, 12000);

  blobPosAddress = new NetAddress("127.0.0.1", 10000);
  blobAmountAddress = new NetAddress("127.0.0.1", 10001);
    
  trackColor = color(255, 255, 255);
  
  depthBlobs = createGraphics(512, 848);
  
  kinect2_A = new Kinect2(this);
  kinect2_A.initDepth();
  kinect2_A.initDevice(0);
  if(twoKinects){
    kinect2_B = new Kinect2(this);
    kinect2_B.initDepth();
    kinect2_B.initDevice(1);
  }
  // Blank image
  depthImg = new PImage(kinect2_A.depthWidth, kinect2_A.depthHeight*2); // 512x848pixels
  
  // bg sub
  numPixels = kinect2_A.depthWidth * kinect2_A.depthHeight*2;
  backgroundPixels = new int[numPixels];
}

void draw() {
  // Draw the raw image
  //image(kinect2_A.getDepthImage(), 0, 0);
  
  thresholdKinects();
  // Draw the thresholded image
  depthImg.updatePixels();
  fastblur(depthImg,2);
  backgroundSubstraction();
    
  ArrayList<Blob> currentBlobs = new ArrayList<Blob>();

  // Begin loop to walk through every pixel
  for (int x = 0; x < depthImg.width; x++ ) {
    for (int y = 0; y < depthImg.height; y++ ) {
      int loc = x + y * depthImg.width;
      // What is current color
      color currentColor = depthImg.pixels[loc];
      float r1 = red(currentColor);
      float g1 = green(currentColor);
      float b1 = blue(currentColor);
      float r2 = red(trackColor);
      float g2 = green(trackColor);
      float b2 = blue(trackColor);

      float d = distSq(r1, g1, b1, r2, g2, b2); 

      if (d < threshold*threshold) {

        boolean found = false;
        for (Blob b : currentBlobs) {
          if (b.isNear(x, y)) {
            b.add(x, y);
            found = true;
            break;
          }
        }

        if (!found) {
          Blob b = new Blob(x, y);
          currentBlobs.add(b);
        }
      }
    }
  }

  for (int i = currentBlobs.size()-1; i >= 0; i--) {
    if (currentBlobs.get(i).size() < minSize || currentBlobs.get(i).size() > maxSize) {
      currentBlobs.remove(i);
    }
  }

  // There are no blobs!
  if (blobs.isEmpty() && currentBlobs.size() > 0) {
    println("Adding blobs!");
    for (Blob b : currentBlobs) {
      b.id = blobCounter;
      blobs.add(b);
      blobCounter++;
    }
  } else if (blobs.size() <= currentBlobs.size()) {
    // Match whatever blobs you can match
    for (Blob b : blobs) {
      float recordD = 1000;
      Blob matched = null;
      for (Blob cb : currentBlobs) {
        PVector centerB = b.getCenter();
        PVector centerCB = cb.getCenter();         
        float d = PVector.dist(centerB, centerCB);
        if (d < recordD && !cb.taken) {
          recordD = d; 
          matched = cb;
        }
      }
      matched.taken = true;
      b.become(matched);
    }

    // Whatever is leftover make new blobs
    for (Blob b : currentBlobs) {
      if (!b.taken) {
        b.id = checkFreeId(blobs);
        blobs.add(b);
      }
    }
  } else if (blobs.size() > currentBlobs.size()) {
    for (Blob b : blobs) {
      b.taken = false;
    }


    // Match whatever blobs you can match
    for (Blob cb : currentBlobs) {
      float recordD = 1000;
      Blob matched = null;
      for (Blob b : blobs) {
        PVector centerB = b.getCenter();
        PVector centerCB = cb.getCenter();         
        float d = PVector.dist(centerB, centerCB);
        if (d < recordD && !b.taken) {
          recordD = d; 
          matched = b;
        }
      }
      if (matched != null) {
        matched.taken = true;
        matched.become(cb);
      }
    }

    for (int i = blobs.size() - 1; i >= 0; i--) {
      Blob b = blobs.get(i);
      if (!b.taken) {
        if (b.checkLife()) {
          blobs.remove(i);
        }
      }
    }
  }

  depthBlobs.beginDraw();
  depthBlobs.background(0,0);
  for (Blob b : blobs) {
    b.show(depthBlobs);
    b.sendOsc();
  } 
  depthBlobs.endDraw();
  
  image(depthImg, 0, 0);
  image(depthBlobs, 0, 0);  
  
  OscMessage myMessage = new OscMessage("/blobs");
  myMessage.add(blobs.size()); /* add an int to the osc message */
  oscP5.send(myMessage, blobAmountAddress); 

  fill(255,0,0);
  text("THRESHOLD: [" + minDepth + ", " + maxDepth + "]", 10, 36);
  text("FPS: " + frameRate, 10, 56);
}

int checkFreeId(ArrayList<Blob> currentBlobs) {
  IntList ids;
  ids = new IntList();
  for (Blob b : currentBlobs)
    ids.append(b.id);
  for (int id=0; id<4; id++)
    if (!ids.hasValue(id)) return id; 
  return 99;
}

void backgroundSubstraction(){
  // Difference between the current frame and the stored background
    int presenceSum = 0;
    for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
      // Fetch the current color in that location, and also the color
      // of the background in that spot
      color currColor = depthImg.pixels[i];
      color bkgdColor = backgroundPixels[i];
      // Extract the red, green, and blue components of the current pixel's color
      int currR = (currColor >> 16) & 0xFF;
      int currG = (currColor >> 8) & 0xFF;
      int currB = currColor & 0xFF;
      // Extract the red, green, and blue components of the background pixel's color
      int bkgdR = (bkgdColor >> 16) & 0xFF;
      int bkgdG = (bkgdColor >> 8) & 0xFF;
      int bkgdB = bkgdColor & 0xFF;
      // Compute the difference of the red, green, and blue values
      int diffR = abs(currR - bkgdR);
      int diffG = abs(currG - bkgdG);
      int diffB = abs(currB - bkgdB);
      // Add these differences to the running tally
      presenceSum += diffR + diffG + diffB;
      // Render the difference image to the screen
      depthImg.pixels[i] = color(diffR, diffG, diffB);
      // The following line does the same thing much faster, but is more technical
      //pixels[i] = 0xFF000000 | (diffR << 16) | (diffG << 8) | diffB;
    }
    depthImg.updatePixels(); // Notify that the pixels[] array has changed
}

void thresholdKinects(){
  
  // Threshold the depth image
  int[] rawDepth = kinect2_A.getRawDepth();
    
  for (int i=0; i < rawDepth.length; i++) {
    if (rawDepth[i] >= minDepth && rawDepth[i] <= maxDepth) {
      depthImg.pixels[i] = color(255);
    } else {
      depthImg.pixels[i] = color(0);
    }
  }
  
  if (twoKinects){   
    // Threshold the depth image
    int[] rawDepth2 = kinect2_B.getRawDepth();
      
    for (int i=0; i < rawDepth2.length; i++) {
      if (rawDepth2[i] >= minDepth && rawDepth2[i] <= maxDepth) {
        depthImg.pixels[rawDepth.length+i] = color(255);
      } else {
        depthImg.pixels[rawDepth.length+i] = color(0);
      }
    } 
  }
}

// Adjust the angle and the depth threshold min and max
void keyPressed() {
  if (key == 'a') {
    minDepth = constrain(minDepth+incDepth, 0, maxDepth);
  } else if (key == 's') {
    minDepth = constrain(minDepth-incDepth, 0, maxDepth);
  } else if (key == 'z') {
    maxDepth = constrain(maxDepth+incDepth, minDepth, 1165952918);
  } else if (key =='x') {
    maxDepth = constrain(maxDepth-incDepth, minDepth, 1165952918);
  } else if (key == 'b') {
    arraycopy(depthImg.pixels,backgroundPixels); 
  }
}


void sendBlobOsc(int id, float x, float y) {
  OscBundle myBundle = new OscBundle();

  OscMessage myMessage = new OscMessage("/p"+id+"/x");
  myMessage.add(x); /* add an int to the osc message */

  myBundle.add(myMessage);
  myMessage.clear();

  myMessage.setAddrPattern("/p"+id+"/y");
  myMessage.add(y); /* add an int to the osc message */

  myBundle.add(myMessage);
  myMessage.clear();

  myBundle.setTimetag(myBundle.now() + 10000);

  oscP5.send(myBundle, blobPosAddress);
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
}


float distSq(float x1, float y1, float x2, float y2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1);
  return d;
}


float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}

// ==================================================
// Super Fast Blur v1.1
// by Mario Klingemann 
// <http://incubator.quasimondo.com>
// ==================================================
void fastblur(PImage img,int radius)
{
 if (radius<1){
    return;
  }
  int w=img.width;
  int h=img.height;
  int wm=w-1;
  int hm=h-1;
  int wh=w*h;
  int div=radius+radius+1;
  int r[]=new int[wh];
  int g[]=new int[wh];
  int b[]=new int[wh];
  int rsum,gsum,bsum,x,y,i,p,p1,p2,yp,yi,yw;
  int vmin[] = new int[max(w,h)];
  int vmax[] = new int[max(w,h)];
  int[] pix=img.pixels;
  int dv[]=new int[256*div];
  for (i=0;i<256*div;i++){
    dv[i]=(i/div);
  }

  yw=yi=0;

  for (y=0;y<h;y++){
    rsum=gsum=bsum=0;
    for(i=-radius;i<=radius;i++){
      p=pix[yi+min(wm,max(i,0))];
      rsum+=(p & 0xff0000)>>16;
      gsum+=(p & 0x00ff00)>>8;
      bsum+= p & 0x0000ff;
    }
    for (x=0;x<w;x++){

      r[yi]=dv[rsum];
      g[yi]=dv[gsum];
      b[yi]=dv[bsum];

      if(y==0){
        vmin[x]=min(x+radius+1,wm);
        vmax[x]=max(x-radius,0);
      }
      p1=pix[yw+vmin[x]];
      p2=pix[yw+vmax[x]];

      rsum+=((p1 & 0xff0000)-(p2 & 0xff0000))>>16;
      gsum+=((p1 & 0x00ff00)-(p2 & 0x00ff00))>>8;
      bsum+= (p1 & 0x0000ff)-(p2 & 0x0000ff);
      yi++;
    }
    yw+=w;
  }

  for (x=0;x<w;x++){
    rsum=gsum=bsum=0;
    yp=-radius*w;
    for(i=-radius;i<=radius;i++){
      yi=max(0,yp)+x;
      rsum+=r[yi];
      gsum+=g[yi];
      bsum+=b[yi];
      yp+=w;
    }
    yi=x;
    for (y=0;y<h;y++){
      pix[yi]=0xff000000 | (dv[rsum]<<16) | (dv[gsum]<<8) | dv[bsum];
      if(x==0){
        vmin[y]=min(y+radius+1,hm)*w;
        vmax[y]=max(y-radius,0)*w;
      }
      p1=x+vmin[y];
      p2=x+vmax[y];

      rsum+=r[p1]-r[p2];
      gsum+=g[p1]-g[p2];
      bsum+=b[p1]-b[p2];

      yi+=w;
    }
  }
  img.pixels = pix;
  img.updatePixels();
}
