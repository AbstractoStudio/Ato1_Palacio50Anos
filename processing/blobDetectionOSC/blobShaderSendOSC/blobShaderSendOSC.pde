// shader adaptaded from python code
// source: https://discourse.processing.org/t/help-creating-organic-looking-blobs/8777/4

import oscP5.*;
import netP5.*;
import blobDetection.*;
  
OscP5 oscP5;
NetAddress myRemoteLocation;

BlobDetection theBlobDetection;
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
    img = new PImage(51,84); 
    theBlobDetection = new BlobDetection(img.width, img.height);
    theBlobDetection.setPosDiscrimination(true);
    theBlobDetection.setThreshold(0.2f); // will detect bright areas whose luminosity > 0.2f;

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
    theBlobDetection.computeBlobs(img.pixels);
    drawBlobsAndEdges(true,false,buf);
    detectBlobAndSendOSC();
    
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


// ==================================================
// drawBlobsAndEdges()
// ==================================================
void detectBlobAndSendOSC()
{
  Blob b;
  println(theBlobDetection.getBlobNb()+" blobs detected!");
  
  OscMessage myMessage = new OscMessage("/blobs");
  myMessage.add(theBlobDetection.getBlobNb()); /* add an int to the osc message */
  oscP5.send(myMessage, myRemoteLocation); 
    
  for (int n=0 ; n<theBlobDetection.getBlobNb() ; n++){
    b=theBlobDetection.getBlob(n);
    if (b!=null){
      float centerX = b.xMin+b.w/2;
      float centerY = b.yMin+b.h/2;
      sendBlobOsc(n,centerX,centerY);
    }
  }
}

// ==================================================
// drawBlobsAndEdges()
// ==================================================
void drawBlobsAndEdges(boolean drawBlobs, boolean drawEdges, PGraphics full)
{
  noFill();
  Blob b;
  EdgeVertex eA,eB;
  for (int n=0 ; n<theBlobDetection.getBlobNb() ; n++)
  {
    b=theBlobDetection.getBlob(n);
    if (b!=null)
    {
      // Edges
      if (drawEdges)
      {
        full.strokeWeight(3);
        full.stroke(0,255,0);
        for (int m=0;m<b.getEdgeNb();m++)
        {
          eA = b.getEdgeVertexA(m);
          eB = b.getEdgeVertexB(m);
          if (eA !=null && eB !=null)
            full.line(
              eA.x*width, eA.y*height, 
              eB.x*width, eB.y*height
              );
        }
      }

      // Blobs
      if (drawBlobs)
      {
        full.strokeWeight(1);
        full.stroke(255,0,0);
        full.noFill();
        full.rect(
          b.xMin*width,b.yMin*height,
          b.w*width,b.h*height
          );
      }

    }

      }
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

}
