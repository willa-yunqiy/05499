import processing.serial.*;
import cc.arduino.*;
import controlP5.*;

int sensorPin = 0;
float R1 = 10;
int bg_color = color(100, 100, 100);

Arduino arduino;
ControlP5 cp5;

Table resistances;
int x_coord = 0;
int data_num = 0;
boolean start = false;
 
 void setup()
{
  //println(Arduino.list());
  // replace 2 with your arduino board in Arduino.list()
  arduino = new Arduino(this, Arduino.list()[2], 57600);
  arduino.pinMode(sensorPin, Arduino.INPUT);
  
  size(800,500);
  background(bg_color);
  noStroke();
  cp5 = new ControlP5(this);
  cp5.addButton("saveCsv").setValue(0).setPosition(680,430).setSize(100,50).setColorBackground(300);
  cp5.addButton("start").setValue(0).setPosition(680,310).setSize(100,50).setColorBackground(300);
  cp5.addButton("pause").setValue(0).setPosition(680,370).setSize(100,50).setColorBackground(300);
  
  resistances = new Table();
  resistances.addColumn("resistance");
}

void draw()
{
  if (start) {
      println("inside start");
      processData();
      drawTable(resistances, 0, 0, 600, 300, 25, color(80, 190, 255));
  }
}

void processData() {
  TableRow newRow = resistances.addRow();
  newRow.setFloat("resistance", readResistance());
  data_num++;
  x_coord++;
  
}

float readResistance() {
  float raw = arduino.analogRead(sensorPin);
  float buffer = raw*5; // 5 for 5V
  float Vout = buffer/1024.0;
  buffer = (5/Vout) - 1;
  println(R1*buffer);
  return R1*buffer; // 10 for the 10ohm resistor
}

public void controlEvent(ControlEvent theEvent) {
  println(theEvent.getController().getName());
}

public void saveCsv() {
  saveTable(resistances, "data/resistances.csv");
}

public void start() {
  start = true;
}

public void pause() {
  start = false;
  TableRow newRow1 = resistances.addRow();
  newRow1.setFloat("resistance", 0);
  TableRow newRow2 = resistances.addRow();
  newRow2.setFloat("resistance", 0);
}

float y_coord(float val, float y_lo, float y_hi, int r_hi, int r_lo) {
  return y_lo-(val-r_lo)/(r_hi-r_lo)*(y_lo-y_hi);
}

void drawTable(Table table, float x0, float y0, float x1, float y1, float scale, color c) { 
  if (x_coord > x1) {
    background(bg_color);
    x_coord = 0;  
  }
  
  //stroke(255);
  //strokeWeight(3);
  //line(x0, (y0+y1)/2, x1, (y0+y1)/2); // draws the x axis
  
  if (start) {
    strokeWeight(1);
    if (x_coord < 2) {
      stroke(c);
      point(x_coord, y_coord(table.getRow(data_num-1).getFloat("resistance"), y1, y0, 14, 8));
    }
    else {
      int prev_x_coord = x_coord-1;
      float curr_r = table.getRow(data_num-1).getFloat("resistance");
      float prev_r = table.getRow(data_num-2).getFloat("resistance");
      stroke(c);
      line(x_coord, y_coord(curr_r, y1, y0, 14, 8), prev_x_coord, y_coord(prev_r, y1, y0, 14, 8));
    }
  }
}
