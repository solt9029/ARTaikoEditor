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
MultiMarker [] nyas;
boolean isAr = false;

// カメラの大きさ（最終的にVIDEO_WとVIDEO_Hに広がる）
int CAMERA_W = 640;
int CAMERA_H = 480;

int VIDEO_H;
int VIDEO_W;

// ビデオで見たときの認識部分の高さと幅
int REC_W;
int REC_H;

// マーカー1つ辺りの画面上の面積
int MARKER_W;
int MARKER_H;

void setup() {
  size(800, 1200, P3D);
  
  VIDEO_W = width;
  VIDEO_H = VIDEO_W * 3 / 4;
  
  REC_W = VIDEO_W - 10 * 2;
  REC_H = VIDEO_H - 100 * 2;
  
  unitX = width / 40;
  unitY = (height - VIDEO_H) / 40;
  
  MARKER_W = 156;
  MARKER_H = 160;

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
    cam = new Capture(this, CAMERA_W, CAMERA_H);
    cam.start();
    isAr = true;
  } catch (Exception e) {
    println(e);
  }
  
  // IDマーカーを登録する
  nyas = new MultiMarker [score.EDIT_NOTE_NUM];
  for (int i = 0; i < nyas.length; i++) {
    nyas[i] = new MultiMarker(this, 156, 160, "camera_para.dat", NyAR4PsgConfig.CONFIG_PSG);
    for (int n = 0; n < 3; n++) {
      nyas[i].addNyIdMarker(n, 27);
    }
  }
} 

void draw() {
  // score.updateHead();
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
  
  // 認識部分
  stroke(0, 255, 65);
  strokeWeight(10);
  noFill();
  for (int y = 0; y < 2; y++) {
    for (int x = 0; x < 4; x++) {
      rect((width-REC_W)/2+REC_W/4*x, height-VIDEO_H+(VIDEO_H-REC_H)/2+REC_H/2*y, REC_W/4, REC_H/2);
    }
  }
  
  // cam.availableの確認は必要でしょうか？→これを入れるとちらついちゃうんだよね、出来れば入れたくない
//  if (!cam.available()) {
//     return; 
//  }
  cam.read();

  image(cam, 0, height-VIDEO_H, VIDEO_W, VIDEO_H); // カメラの様子を画面下に描いている
  
  int [] markers = new int [score.EDIT_NOTE_NUM];
  
  for (int i = 0; i < score.EDIT_NOTE_NUM; i++) {
    PImage detectImg = cam.get(8+156*(i%4), 80+160*(i/4), 156, 160);
    nyas[i].detect(detectImg);
    
    // 0~7までのIDマーカーがその場所で見つかったら、空白とする
    for (int n = 0; n < 3; n++) {
      if (!nyas[i].isExistMarker(n)) {
        continue;
      }
      markers[i] = n;
    }
  }
  
//  if (nyas[0].isExistMarker(0)) {
//    nyas[0].beginTransform(0);
//    scale(0.03);
//    modelDonChan();
//    nyas[0].endTransform();
//  }
  
  score.edit(markers);
}

void mousePressed() {
  score.checkEditingPart(mouseX, mouseY);
  score.edit(mouseX, mouseY);
  // score.updateHead();
}

void keyPressed() {
  if (keyCode == UP) score.scrollY(1);
  if (keyCode == DOWN) score.scrollY(-1);
  if (keyCode == ENTER) score.turnEditing();
}

void pillar(float length, float radius1, float radius2) {
  float x, y, z; //座標
  pushMatrix();

  //上面の作成
  beginShape(TRIANGLE_FAN);
  y = -length / 2;
  vertex(0, y, 0);
  for (int deg = 0; deg <= 360; deg = deg + 10) {
    x = cos(radians(deg)) * radius1;
    z = sin(radians(deg)) * radius1;
    vertex(x, y, z);
  }
  endShape();

  //底面の作成
  beginShape(TRIANGLE_FAN);
  y = length / 2;
  vertex(0, y, 0);
  for (int deg = 0; deg <= 360; deg = deg + 10) {
    x = cos(radians(deg)) * radius2;
    z = sin(radians(deg)) * radius2;
    vertex(x, y, z);
  }
  endShape();

  //側面の作成
  beginShape(TRIANGLE_STRIP);
  for (int deg =0; deg <= 360; deg = deg + 5) {
    x = cos(radians(deg)) * radius1;
    y = -length / 2;
    z = sin(radians(deg)) * radius1;
    vertex(x, y, z);

    x = cos(radians(deg)) * radius2;
    y = length / 2;
    z = sin(radians(deg)) * radius2;
    vertex(x, y, z);
  }
  endShape();

  popMatrix();
}

void modelTaiko(String taiko) {
  noStroke();
  
  color bodyColor = color(0, 0, 0);
  color faceColor = color(0, 0, 0);
  
  if (taiko.equals("don")) {
    bodyColor = color(93, 192, 189);
    faceColor = color(244, 58, 0);
  } else if (taiko.equals("ka")) {
    bodyColor = color(244, 58, 0);
    faceColor = color(93, 192, 189);
  }
  
  // 胴体
  fill(255);
  pillar(300, 100, 100);
  fill(bodyColor);
  pillar(260, 101, 101);
  
  // 顔の赤色
  pushMatrix();
    translate(0, 151, 0);
    rotateX(radians(90));
    fill(faceColor);
    ellipse(0, 0, 160, 160);
  popMatrix();
  
  // 目
  pushMatrix();
    translate(20, 152, 43);
    rotateX(radians(90));
    fill(0);
    ellipse(0, 0, 40, 40);
  popMatrix();
  
  // 目
  pushMatrix();
    translate(20, 152, -43);
    rotateX(radians(90));
    fill(0);
    ellipse(0, 0, 40, 40);
  popMatrix();
  
  // 腕
  pushMatrix();
    rotateZ(radians(90));
    rotateY(radians(90));
    
    pushMatrix();
      translate(80, 125, 100);
      rotateZ(radians(-30));
      fill(255);
      pillar(100, 5, 20);
      translate(0, 50, 0);
      sphere(35);
    popMatrix();
    
    pushMatrix();
      translate(-80, 125, 100);
      rotateZ(radians(30));
      fill(255);
      pillar(100, 5, 20);
      translate(0, 50, 0);
      sphere(35);
    popMatrix();
    
    pushMatrix();
      translate(80, 125, -100);
      rotateZ(radians(-30));
      fill(255);
      pillar(100, 5, 20);
      translate(0, 50, 0);
      sphere(35);
    popMatrix();
    
    pushMatrix();
      translate(-80, 125, -100);
      rotateZ(radians(30));
      fill(255);
      pillar(100, 5, 20);
      translate(0, 50, 0);
      sphere(35);
    popMatrix();
  popMatrix();
  
  // お尻側の赤色
  pushMatrix();
    translate(0, -151, 0);
    rotateX(radians(90));
    fill(faceColor);
    ellipse(0, 0, 160, 160);
  popMatrix();
}

void modelDonChan() {
  modelTaiko("don");
}

void modelKaChan() {
  modelTaiko("ka");
}
