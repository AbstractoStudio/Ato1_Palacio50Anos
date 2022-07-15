import org.openkinect.processing.*;

boolean twoKinects = false;

// Kinects
Kinect2 kinect2_A;
Kinect2 kinect2_B;

// Depth image
PImage depthImg_A;
PImage depthImg_B;

// Depth calculate in mm (2000mm = 2m)
int minDepth =  100;
int maxDepth =  2000;

// 
// Warning msg: [DepthPacketStreamParser::onDataReceived] not all subsequences received ...
// https://github.com/shiffman/OpenKinect-for-Processing/issues/93
//void settings(){
//  size(512, 848);
//  PJOGL.profile=1; 
//}

void setup() {
  size(512, 848);
  kinect2_A = new Kinect2(this);
  kinect2_A.initDepth();
  kinect2_A.initDevice(0);
  if(twoKinects){
    kinect2_B = new Kinect2(this);
    kinect2_B.initDepth();
    kinect2_B.initDevice(1);
  }
  // Blank image
  depthImg_A = new PImage(kinect2_A.depthWidth, kinect2_A.depthHeight); // 512x424pixels
  if(twoKinects) depthImg_B = new PImage(kinect2_B.depthWidth, kinect2_B.depthHeight); // 512x424pixels
}

void draw() {
  // Draw the raw image
  //image(kinect2_A.getDepthImage(), 0, 0);
  
  thresholdKinect();
  
  // Draw the thresholded image
  depthImg_A.updatePixels();
  image(depthImg_A, 0, 0);
  image(depthImg_A, 0, kinect2_A.depthHeight);

  fill(255,0,0);
  text("THRESHOLD: [" + minDepth + ", " + maxDepth + "]", 10, 36);
}

void thresholdKinect(){
  
  // Threshold the depth image
  int[] rawDepth = kinect2_A.getRawDepth();
  
  
  for (int i=0; i < rawDepth.length; i++) {
    if (rawDepth[i] >= minDepth && rawDepth[i] <= maxDepth) {
      depthImg_A.pixels[i] = color(255);
    } else {
      depthImg_A.pixels[i] = color(0);
    }
  }
}

// Adjust the angle and the depth threshold min and max
void keyPressed() {
  if (key == 'a') {
    minDepth = constrain(minDepth+100, 0, maxDepth);
  } else if (key == 's') {
    minDepth = constrain(minDepth-100, 0, maxDepth);
  } else if (key == 'z') {
    maxDepth = constrain(maxDepth+100, minDepth, 1165952918);
  } else if (key =='x') {
    maxDepth = constrain(maxDepth-100, minDepth, 1165952918);
  }
}
