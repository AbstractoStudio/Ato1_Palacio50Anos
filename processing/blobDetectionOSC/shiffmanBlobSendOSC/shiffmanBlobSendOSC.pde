// adapted from: https://github.com/CodingTrain/website/blob/a46902dcd25fbfd524d2cc349f2350a3687d45c7/Tutorials/Processing/11_video/sketch_11_10_BlobTracking_lifespan/sketch_11_10_BlobTracking_lifespan.pde
import oscP5.*;
import netP5.*;

  
OscP5 oscP5;
NetAddress myRemoteLocation;

PImage img;
PGraphics fullCanvas;

int blobCounter = 0;
int maxLife = 50;
color trackColor; 
float threshold = 50;
float distThreshold = 15;

RandomWalker[] walkers;
int maxWalkers = 4;

ArrayList<Blob> blobs = new ArrayList<Blob>();

void setup() {
  size(512, 848);
  fullCanvas = createGraphics(512,848);
  oscP5 = new OscP5(this,12000);
  
  myRemoteLocation = new NetAddress("127.0.0.1",10000);
  
  // BlobDetection
  // img which will be sent to detection (a smaller copy of the cam frame);
  img = new PImage(width,height); 
  
  trackColor = color(255, 255, 255);
  
  walkers = new RandomWalker[maxWalkers];
  for (int i=0;i<maxWalkers;i++)
    walkers[i] = new RandomWalker();
}

void draw() {
  background(0);
  
  fullCanvas.beginDraw();
  fullCanvas.background(0);
  fullCanvas.fill(255);
  fullCanvas.noStroke();
  for (RandomWalker r : walkers)
    r.display(fullCanvas);
  
  img.copy(fullCanvas,0,0,fullCanvas.width,fullCanvas.height,
           0,0,img.width,img.height);
  
  ArrayList<Blob> currentBlobs = new ArrayList<Blob>();
  
  // Begin loop to walk through every pixel
  for (int x = 0; x < img.width; x++ ) {
    for (int y = 0; y < img.height; y++ ) {
      int loc = x + y * img.width;
      // What is current color
      color currentColor = img.pixels[loc];
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
    if (currentBlobs.get(i).size() < 500) {
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
        b.id = blobCounter;
        blobs.add(b);
        blobCounter++;
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

  for (Blob b : blobs) {
    b.show(fullCanvas);
    b.sendOsc();
  } 

  
  fullCanvas.endDraw();
  image(fullCanvas,0,0);
  
  
  OscMessage myMessage = new OscMessage("/blobs");
  myMessage.add(blobs.size()); /* add an int to the osc message */
  oscP5.send(myMessage, myRemoteLocation); 
  
  for (RandomWalker r : walkers)
    r.update();
}

void sendBlobOsc(int id,float x, float y) {
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
  
  oscP5.send(myBundle, myRemoteLocation); 
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
}

void keyPressed() {
  if (key == 'a') {
    distThreshold+=5;
  } else if (key == 'z') {
    distThreshold-=5;
  }
  if (key == 's') {
    threshold+=5;
  } else if (key == 'x') {
    threshold-=5;
  }


  println(distThreshold);
}

float distSq(float x1, float y1, float x2, float y2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1);
  return d;
}


float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) +(z2-z1)*(z2-z1);
  return d;
}
