class RandomWalker{
  PVector pos, speed, acc;
  
  RandomWalker(){
    pos = new PVector(random(width),random(height));
    speed = new PVector(random(-1,1),random(-1,1));
    acc = new PVector(random(-1,1),random(-1,1));
  }
  
  void update(){
    pos.add(speed);
    speed.normalize();
    speed.add(acc);
    
    
    
    if (pos.x > width) pos.x=0;
    if (pos.x < 0) pos.x=width;
    if (pos.y > height) pos.y=0;
    if (pos.y < 0) pos.y=height;
    
    if (frameCount%50==0){
      acc = new PVector(random(-1,1),random(-1,1));
    }
  }
  
  void display(PGraphics img){
    img.ellipse(pos.x,pos.y,25,25);
  }
  
}
