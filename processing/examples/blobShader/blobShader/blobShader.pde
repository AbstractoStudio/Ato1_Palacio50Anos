// adaptaded from python code
// source: https://discourse.processing.org/t/help-creating-organic-looking-blobs/8777/4

PGraphics buf;
Ball[] balls;
PShader contrast, blurry;

int amountOfBlobs = 4;

void setup(){
    
    size(512, 848, OPENGL);
    rectMode(CENTER);
    noStroke();
    smooth(8);

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
    buf.background(190, 0);
    buf.noStroke();
    
    for (Ball b : balls) {
        b.update();
        b.render();
    }
        
    blurry.set("horizontalPass", 1);
    buf.filter(blurry);
    blurry.set("horizontalPass", 0);
    buf.filter(blurry);
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
    }
        
    void render(){
        buf.fill(255);
        buf.ellipse(this.loc.x, this.loc.y, this.radius, this.radius);
    }
}
