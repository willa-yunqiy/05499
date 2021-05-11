import processing.serial.*;
import cc.arduino.*;
import controlP5.*;

/* =============  parameters to check/tune for ============= */
int port = 2; // replace 2 with your arduino board in Arduino.list()
int sensorsNum = 1; // number of sensors
int[] sensorPin = {0, 5};
float voltage = 5;
float R1 = 10;
float Rbuff = 0;
float dataRangeLow = 5;
float dataRangeHigh = 15;
/* =============  parameters to check/tune for ============= */

int[] sensorColors = {color(80, 190, 255), color(246, 80, 255), color(255, 229, 80), color(118, 255, 80)};
int bg_color = color(100, 100, 100);
int bg_w = 800;
int bg_height = 500;
int graph_height = bg_height/sensorsNum;
int graph_width = 500;

Arduino arduino;
ControlP5 cp5;

Table resistances;

int x_coord = 0;
int data_num = 0;
boolean start = false;
 
 void setup()
{
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[port], 57600);
  for (int i=0; i<sensorsNum; i++) {
    arduino.pinMode(sensorPin[i], Arduino.INPUT);
  }
  
  size(800,500);
  background(bg_color);
  noStroke();
  cp5 = new ControlP5(this);
  cp5.addButton("saveCsv").setValue(0).setPosition(680,430).setSize(100,50).setColorBackground(300);
  cp5.addButton("start").setValue(0).setPosition(680,310).setSize(100,50).setColorBackground(300);
  cp5.addButton("pause").setValue(0).setPosition(680,370).setSize(100,50).setColorBackground(300);
  
  resistances = new Table();
  for (int i=0; i<sensorsNum; i++) {
    resistances.addColumn("resistance"+i);
  }
}

void draw()
{
  if (start) {
      println("inside start");
      processData();
      for (int i=0; i<sensorsNum; i++) {
        drawTable(resistances, i, 0, i*graph_height, graph_width, (i+1)*graph_height, dataRangeLow, dataRangeHigh, color(80, 190, 255));
      }
  }
}

void processData() {
  TableRow newRow = resistances.addRow();
  for (int i=0; i<sensorsNum; i++) {
    newRow.setFloat("resistance"+i, readResistance(sensorPin[i]));
  }
  data_num++;
  x_coord++;
}

float readResistance(int sensorPin) {
  float raw = arduino.analogRead(sensorPin);
  float buffer = raw*voltage; // 5 for 5V
  float Vout = buffer/1024.0;
  buffer = (voltage/Vout) - 1;
  float R = R1*buffer - Rbuff;
  println(R);
  return R; // 10 for the 10ohm resistor
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
  TableRow newRow2 = resistances.addRow();
    for (int i=0; i<sensorsNum; i++) {
    newRow1.setFloat("resistance"+i, 0);
    newRow2.setFloat("resistance"+i, 0);
  }
}

float y_coord(float val, float y_lo, float y_hi, float r_hi, float r_lo) {
  println(y_lo-(val-r_lo)/(r_hi-r_lo)*(y_lo-y_hi));
  return y_lo-(r_hi-val)/(r_hi-r_lo)*(y_lo-y_hi);
}

void drawTable(Table table, int col, float x0, float y0, float x1, float y1, float r_hi, float r_lo, color c) { 
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
      point(x_coord, y_coord(table.getRow(data_num-1).getFloat("resistance"+col), y1, y0, r_hi, r_lo));
    }
    else {
      int prev_x_coord = x_coord-1;
      float curr_r = table.getRow(data_num-1).getFloat("resistance"+col);
      float prev_r = table.getRow(data_num-2).getFloat("resistance"+col);
      stroke(c);
      line(x_coord, y_coord(curr_r, y1, y0, r_hi, r_lo), prev_x_coord, y_coord(prev_r, y1, y0, r_hi, r_lo));
    }
  }
}
