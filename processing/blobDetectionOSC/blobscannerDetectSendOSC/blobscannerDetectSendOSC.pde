import oscP5.*;
import netP5.*;
import blobscanner.*;

Detector bs;
  
OscP5 oscP5;
NetAddress myRemoteLocation;

PImage img;

PGraphics fullCanvas;

RandomWalker[] walkers;
int maxWalkers = 5;

void setup() {
  size(512, 848);
  fullCanvas = createGraphics(512,848);
  oscP5 = new OscP5(this,12000);
  
  myRemoteLocation = new NetAddress("127.0.0.1",10000);
  
  // BlobDetection
  img = new PImage(51,84);
  bs = new Detector( this, 255 );
  
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
  //fastblur(img,1);
  bs.imageFindBlobs(img);
  bs.loadBlobsFeatures();
  try{
    bs.findCentroids();
    //bs.weightBlobs(false);
    for(int i = 0; i < bs.getBlobsNumber(); i++){
      println("blob #" + i + " is labelled with " + bs.getLabel(i));
      println("centroid ("+bs.getCentroidX(i)+","+bs.getCentroidY(i)+")");
      sendBlobOsc(bs.getLabel(i),bs.getCentroidX(i)/51,bs.getCentroidY(i)/84);
    }
  }
  catch (ArrayIndexOutOfBoundsException exception) {
  //finally {
    print("finally");
  }
  
  fullCanvas.endDraw();
  image(fullCanvas,0,0);
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
