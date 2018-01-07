import java.awt.*;
import java.util.*;
import processing.video.*;
import jp.nyatla.nyar4psg.*;

HashMap <String, TextField> fields = new HashMap<String, TextField>();
int unitX;
int unitY;
int scrollY = 0;
Score score;
Capture cam; // 動画
MultiMarker nya;
boolean isAr = true;
int VIDEO_H = 100;

void setup() {
  size(800, 700);
  unitX = width / 40;
  unitY = (height - VIDEO_H) / 40;

  setLayout(null);
  
  //Text File
  score=new Score("data/score.tja");

  //Text Fields
  fields.put("bpm", new TextField(score.getBpm()));
  fields.put("title", new TextField(score.getTitle()));
  fields.put("offset", new TextField(score.getOffset()));
  fields.get("bpm").setBounds(unitX*21, unitY*2, unitX*8, unitY*2);
  fields.get("title").setBounds(unitX*1, unitY*2, unitX*18, unitY*2);
  fields.get("offset").setBounds(unitX*31, unitY*2, unitX*8, unitY*2);
  for (Map.Entry field : fields.entrySet()) {
    fields.get(field.getKey()).setFont(new Font("Century", Font.PLAIN, 24));
    add(fields.get(field.getKey()));
  }
  
  cam = new Capture(this, width, width*3/4);
  cam.start();
  
  nya = new MultiMarker(this, width, width*3/4, "camera_para.dat", NyAR4PsgConfig.CONFIG_PSG);
  nya.addNyIdMarker(0,20);
  nya.addNyIdMarker(1,20);
  nya.addNyIdMarker(2,20);
  nya.addNyIdMarker(3,20);
  nya.addNyIdMarker(4,20);
  nya.addNyIdMarker(5,20);
  nya.addNyIdMarker(6,20);
  nya.addNyIdMarker(7,20);
} 

void draw() {
  score.updateHead();
  background(255);

  score.display();

  //Text Box
  noStroke();
  fill(0);
  rect(unitX*0, unitY*0, unitX*40, unitY*5);

  //Text
  fill(255);
  text("TITLE", unitX*1, unitY*2);
  text("BPM", unitX*21, unitY*2);
  text("OFFSET", unitX*31, unitY*2);

  //上ボタンの描画とクリック判定
  fill(200);
  if (mousePressed && mouseX > 0 && mouseX < unitX*40 && mouseY > unitY*5 && mouseY < unitY*8) {
    strokeWeight(3);
    stroke(255, 255, 0);
    score.scrollY(1);
  } else {
    noStroke();
  }
  rect(unitX*0, unitY*5, unitX*40, unitY*2);
  
  //下ボタンの描画とクリック判定
  fill(200);
  if (mousePressed && mouseX > 0 && mouseX < unitX*40 && mouseY > unitY*38 && mouseY < unitY*40) {
    strokeWeight(3);
    stroke(255, 255, 0);
    score.scrollY(-1);
  } else {
    noStroke();
  }
  rect(unitX*0, unitY*38, unitX*40, unitY*2);
  
  // カメラでうつしている画像の細長い真ん中を表示する
  PImage tmp = cam.get(0, 250, width, 100);
  image(tmp, 0, height - VIDEO_H); // カメラの様子を画面下に描いている
}

void mousePressed() {
  score.checkEditingPart(mouseX, mouseY);
  score.edit(mouseX, mouseY);
  score.updateHead();
}

void keyPressed() {
  if (keyCode == UP) score.scrollY(1);
  if (keyCode == DOWN) score.scrollY(-1);
  if (keyCode == ENTER) score.turnEditing();
}

//カメラの映像が更新されるたびに、最新の映像を読み込む
void captureEvent(Capture camera) {
  camera.read();
  nya.detect(cam);
}
