// shader adaptaded from python code
// source: https://discourse.processing.org/t/help-creating-organic-looking-blobs/8777/4

import oscP5.*;
import netP5.*;
import blobscanner.*;
  
OscP5 oscP5;
NetAddress myRemoteLocation;

Detector bs;
PImage img;

PGraphics buf;
Ball[] balls;
PShader contrast, blurry;

int amountOfBlobs = 4;

void setup(){
    size(512, 848, OPENGL);
    rectMode(CENTER);
    noStroke();
    smooth(8);
      
    oscP5 = new OscP5(this,12000); // listens at port 12000    
    myRemoteLocation = new NetAddress("127.0.0.1",10000); // sends to port 10000
    
    
    // BlobDetection
    // img which will be sent to detection (a smaller copy of the cam frame);
    img = new PImage(width/4,height/4); 
    bs = new Detector( this, 300 ); // thresshold

    buf = createGraphics(width, height, P2D);
    contrast = loadShader("colFrag.glsl");
    blurry = loadShader("blurFrag.glsl");
    
    blurry.set("sigma", 10.5);
    blurry.set("blurSize", 30);
    
    balls = new Ball[amountOfBlobs];
    for(int i=0; i<amountOfBlobs; i++){
       balls[i] = new Ball();
    }
}
void draw(){
    background(0);
        
    buf.beginDraw();
    buf.background(0,0);
    buf.noStroke();
    
    for (Ball b : balls) {
        b.update();
        b.render();
    }
    
        
    blurry.set("horizontalPass", 1);
    buf.filter(blurry);
    blurry.set("horizontalPass", 0);
    buf.filter(blurry);
    
    // blob detection
    img.copy(buf,0,0,buf.width,buf.height,
             0,0,img.width,img.height);
    bs.imageFindBlobs(img);
    
    OscMessage myMessage = new OscMessage("/blobs");
    myMessage.add(bs.getBlobsNumber()); /* add an int to the osc message */
    oscP5.send(myMessage, myRemoteLocation); 
    
    bs.loadBlobsFeatures();
    try{
      bs.findCentroids();
      //bs.weightBlobs(false);
      for(int i = 0; i < bs.getBlobsNumber(); i++){
        //println("blob #" + i + " is labelled with " + bs.getLabel(i));
        float x = bs.getCentroidX(i)/img.width;
        float y = bs.getCentroidY(i)/img.height;
        //println("centroid ("+x+","+y+")");
        buf.ellipseMode(CENTER);
        buf.stroke(255,0,0);
        buf.noFill();
        buf.ellipse(x*width,y*height,25,25);
        buf.fill(255,0,0);
        buf.textSize(12);
        buf.textAlign(CENTER, CENTER);
        buf.text(str(bs.getLabel(i)),x*width,y*height);
        sendBlobOsc(bs.getLabel(i),x,y);
      }
    }
    catch (ArrayIndexOutOfBoundsException exception) {
    //finally {
      print("finally");
    }
    
    buf.endDraw();
    
    shader(contrast);
    image(buf, 0, 0, width, height);
}             

class Ball{
    PVector loc, vel;
    float radius;
  
    Ball(){
        this.loc = new PVector(random(width), random(height));
        this.vel = PVector.random2D();
        this.radius = random(80, 140);
    }
    
    void update(){
        this.loc.add(this.vel);
        
        if (this.loc.x > width || this.loc.x < 0) this.vel.x *= -1;
        if (this.loc.y > height || this.loc.y < 0) this.vel.y *= -1;
        
        if (frameCount%120==0)
          this.vel = PVector.random2D();

    }
        
    void render(){
        buf.fill(255);
        buf.ellipse(this.loc.x, this.loc.y, this.radius, this.radius);
    }
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
