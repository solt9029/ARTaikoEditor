import java.awt.*;
import java.util.*;
import processing.video.*;
import jp.nyatla.nyar4psg.*;

HashMap <String, TextField> fields = new HashMap<String, TextField>();

// 単位
int unitX;
int unitY;

int scrollY = 0;
Score score;
Capture cam; // 動画
MultiMarker nya;
boolean isAr = false;

// カメラの大きさ（最終的にVIDEO_WとVIDEO_Hに広がる）
int CAMERA_W = 640;
int CAMERA_H = 480;

int VIDEO_H;
int VIDEO_W;

// 認識部分の高さと幅
int REC_W;
int REC_H;

void setup() {
  size(800, 1200, P3D);
  
  VIDEO_W = width;
  VIDEO_H = VIDEO_W * 3 / 4;
  
  REC_W = VIDEO_W - 10 * 2;
  REC_H = VIDEO_H - 100 * 2;
  
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
  
  // ここにtrycatchでisArの判定を書く
  try {
    cam = new Capture(this, 640, 480);
    cam.start();
    isAr = true;
  } catch (Exception e) {
    println(e);
  }
  
  // IDマーカーを登録する
  nya = new MultiMarker(this, 640, 480, "camera_para.dat", NyAR4PsgConfig.CONFIG_PSG);
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
  
  image(cam, 0, height-VIDEO_H, VIDEO_W, VIDEO_H); // カメラの様子を画面下に描いている
  
  // 認識部分
  stroke(0, 255, 65);
  strokeWeight(10);
  noFill();
  for (int y = 0; y < 2; y++) {
    for (int x = 0; x < 4; x++) {
      rect((width-REC_W)/2+REC_W/4*x, height-VIDEO_H+(VIDEO_H-REC_H)/2+REC_H/2*y, REC_W/4, REC_H/2);
    }
  }
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
  
  int [] markers = new int [score.EDIT_NOTE_NUM];
  
  for (int i = 0; i < score.EDIT_NOTE_NUM; i++) {
    if (nya.isExistMarker(i)) {
      markers[i] = 0;
      continue;
    }
    
    markers[i] = 1;
  

    // 出来ればパラメータで書きたいねここら辺
    PImage recImg = cam.get(8, 80, 624, 320);
    
    int redValue = 0;
    int greenValue = 0;
    int blueValue = 0;
    
    for (int y = 160*(i/4); y < 160*((i/4)+1); y++) {
      for (int x = 156*(i%4); x < 156*((i%4)+1); x++) {
        redValue += red(recImg.pixels[x + y * 624]);
        greenValue += green(recImg.pixels[x + y * 624]);
        blueValue += blue(recImg.pixels[x + y * 624]);
      } 
    }
    redValue = redValue / (160 * 156);
    greenValue = greenValue / (160 * 156);
    blueValue = blueValue / (160 * 156);
    if (blueValue > redValue + 10) {
      markers[i] = 2;
    }
  }
  
  score.edit(markers);
}
