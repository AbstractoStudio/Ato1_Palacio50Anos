class RandomWalker{
  PVector pos, speed, acc;
  
  RandomWalker(){
    pos = new PVector(random(width),random(height));
    speed = new PVector(random(-1,1),random(-1,1));
    acc = new PVector(random(-1,1),random(-1,1));
    acc.mult(5);
  }
  
  void update(){
    pos.add(speed);   
    
    if (pos.x > width || pos.x < 0) speed.x*=-1;;
    if (pos.y > height || pos.y < 0) speed.y*=-1;
  }
  
  void display(PGraphics img){
    img.ellipse(pos.x,pos.y,50,50);
  }
  
}
