class RandomWalker{
  PVector pos, speed;
  float size;
  
  RandomWalker(){
    pos = new PVector(random(width),random(height));
    speed = new PVector(random(-1,1),random(-1,1));
    speed.mult(2);
    size = random(5,150);
  }
  
  void update(){
    pos.add(speed);   
    
    if (pos.x > width*1.5 || pos.x < -width*0.5) speed.x*=-1;;
    if (pos.y > height*1.5 || pos.y < -height*0.5) speed.y*=-1;
  }
  
  void display(PGraphics img){
    img.ellipse(pos.x,pos.y,size,size);
  }
  
}
