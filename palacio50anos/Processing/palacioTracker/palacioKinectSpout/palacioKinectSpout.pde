import spout.*;
import org.openkinect.processing.*;

boolean twoKinects = true;

// Kinects
Kinect2 kinect2_A;
Kinect2 kinect2_B;

// Syphon
PGraphics canvas;
Spout spout;

void setup() {
  size(512, 848, P3D);
  
  spout = new Spout(this); 
  spout.setSenderName("Processing Spout");
  spout.createSenderBuffer(256);  
    
  kinect2_A = new Kinect2(this);
  kinect2_A.initDepth();
  kinect2_A.initDevice(0);
  if(twoKinects){
    kinect2_B = new Kinect2(this);
    kinect2_B.initDepth();
    kinect2_B.initDevice(1);
  }
  
}

void draw() {
  spout.waitFrameSync(spout.getSenderName(), 67);  
  background(0);
  // Draw the raw image
  image(kinect2_A.getDepthImage(), 0, 0);
  if(twoKinects)
    image(kinect2_B.getDepthImage(), 0, kinect2_A.depthHeight);
  
  spout.sendTexture();
}
