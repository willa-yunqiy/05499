import processing.serial.*;
import cc.arduino.*;
import controlP5.*;

/* =============  parameters to check/tune for ============= */
int port = 2; // replace 2 with your arduino board in Arduino.list()
int sensorsNum = 1; // number of sensors
int[] sensorPin = {0, 1, 2, 3};
float voltage = 5;
float R1 = 10;
float Rbuff = 0;
float dataRangeLow = 5;
float dataRangeHigh = 15;
int diffMultiplier = 100;
int meanfilterSize = 10;
int medianfilterSize = 100;
float[] downThreshold = {0.5, 0.5, 0.5};
float[] upThreshold = {0.5, 0.5, 0.5};
/* ========================================================= */

// constants
int[] neutralColors = {color(6, 76, 117), color(111, 1, 117), color(128, 109, 0), color(20, 92, 0)};
int[] pressedDownColors = {color(80, 190, 255), color(246, 80, 255), color(255, 229, 80), color(118, 255, 80)};
int[] pressedUpColors = {color(214, 240, 255), color(253, 207, 255), color(255, 245, 191), color(207, 255, 194)};
int bg_color = color(100, 100, 100);
int bg_w = 900;
int bg_h = 900;
int graph_height = bg_h/sensorsNum;
int graph_width = bg_w/9*6;
int ind_height = 100;
int ind_gap = 20;
int ind_width = (bg_w - graph_width - ind_gap*(sensorsNum+1))/sensorsNum;
int[] fitlerCoeff = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
final int UP = 0;
final int MID = 1;
final int DOWN = 2;
final int TURNUP = 0;
final int TURNMID = 1;
final int TURNDOWN = 2;
final int NOCHANGE = 3;

// variables
int x_coord = 0;
int data_num = 0;
boolean start = false;
boolean rawValue = false;
boolean lowPassFilter = false;
boolean difference = false;
boolean meanDiff = false;
boolean medianmeanDiff = false;
boolean upDownLine = false;

Arduino arduino;
ControlP5 cp5;
Table resistances;
Table filteredR;
Table diffFilteredR;
Table mdfR; // mean of difference of lowpass filtered resistance
Table mmdfR; // median of mean of difference of lowpass filtered resistance
FloatList median_list;
boolean[] isUp;
boolean[] isDown;
int[] sensorChange;
int[] sensorState;

void setup()
{
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[port], 57600);
  for (int i=0; i<sensorsNum; i++) {
    arduino.pinMode(sensorPin[i], Arduino.INPUT);
  }
  
  size(900,900);
  background(bg_color);
  noStroke();
  cp5 = new ControlP5(this);
  cp5.addButton("saveCsv").setValue(0).setPosition(780,830).setSize(100,50).setColorBackground(300);
  cp5.addButton("start").setValue(0).setPosition(780,710).setSize(100,50).setColorBackground(300);
  cp5.addButton("pause").setValue(0).setPosition(780,770).setSize(100,50).setColorBackground(300);
  cp5.addButton("reset").setValue(0).setPosition(780,650).setSize(100,50).setColorBackground(300);
  cp5.addToggle("rawValue").setPosition(800,610).setSize(50,20).setColorBackground(300);
  cp5.addToggle("lowPassFilter").setPosition(800,570).setSize(50,20).setColorBackground(300);
  cp5.addToggle("difference").setPosition(800,530).setSize(50,20).setColorBackground(300);
  cp5.addToggle("meanDiff").setPosition(800,490).setSize(50,20).setColorBackground(300);
  cp5.addToggle("medianmeanDiff").setPosition(800,450).setSize(50,20).setColorBackground(300);
  cp5.addToggle("upDownLine").setPosition(800,410).setSize(50,20).setColorBackground(300);
  
  resistances = new Table();
  for (int i=0; i<sensorsNum; i++) {
    resistances.addColumn("resistance"+i);
  }
  filteredR = new Table();
  for (int i=0; i<sensorsNum; i++) {
    filteredR.addColumn("resistance"+i);
  }
  diffFilteredR = new Table();
  for (int i=0; i<sensorsNum; i++) {
    diffFilteredR.addColumn("resistance"+i);
  }
  mdfR = new Table();
  for (int i=0; i<sensorsNum; i++) {
    mdfR.addColumn("resistance"+i);
  }
  mmdfR = new Table();
  for (int i=0; i<sensorsNum; i++) {
    mmdfR.addColumn("resistance"+i);
  }

  median_list = new FloatList();
  isUp = new boolean[sensorsNum];
  isDown = new boolean[sensorsNum];
  sensorState = new int[sensorsNum];
  sensorChange = new int[sensorsNum];
  for (int i=0; i<sensorsNum; i++) {
    isUp[i] = false;
    isDown[i] = false;
    sensorState[i] = MID;
    sensorChange[i] = NOCHANGE;
  }
}

void draw()
{
  if (start) {
      println("inside start");
      processData();
      for (int i=0; i<sensorsNum; i++) {
        if (rawValue)
          drawTable(resistances, i, 0, i*graph_height, graph_width, (i+1)*graph_height, 
            dataRangeLow, dataRangeHigh, pressedDownColors[i]); 
        if(lowPassFilter)
          drawTable(filteredR, i, 0, i*graph_height, graph_width, (i+1)*graph_height, 
            dataRangeLow, dataRangeHigh, 0);
        if(difference)
          drawTable(diffFilteredR, i, 0, i*graph_height, graph_width, (i+1)*graph_height, 
            -10, 10, pressedDownColors[i]); //128
        if(meanDiff)
          drawTable(mdfR, i, 0, i*graph_height, graph_width, (i+1)*graph_height, 
            -10, 10, 255);
        if(medianmeanDiff)
          drawTable(mmdfR, i, 0, i*graph_height, graph_width, (i+1)*graph_height, 
            -10, 10, 64);
        int dirChange = checkDir(mdfR, mmdfR, i);
        if(upDownLine){
          if (dirChange == TURNDOWN){
            stroke(255);
            strokeWeight(2);
            line(x_coord, i*graph_height, x_coord, (i+1)*graph_height); // line
          }
          if (dirChange == TURNUP){
            stroke(0);
            strokeWeight(2);
            line(x_coord, i*graph_height, x_coord, (i+1)*graph_height); // line
          }
        }
      }
  }
  drawPressVis();
}

void drawPressVis() {
  int leftPad = graph_width + ind_gap;
  strokeWeight(0);
  for (int i = 0; i< sensorsNum; i++) {
    fill(neutralColors[i]);
    if (sensorState[i] == MID && sensorChange[i] == TURNDOWN){
      sensorState[i] = DOWN;
    }
    else if (sensorState[i] == MID && sensorChange[i] == TURNUP){
      // sensorState[i] = UP;
      sensorState[i] = MID;
    }
    else if (sensorState[i] == DOWN && sensorChange[i] == TURNUP){
      sensorState[i] = MID;
    }
    else if (sensorState[i] == UP && sensorChange[i] == TURNDOWN){
      sensorState[i] = MID;
    }

    if (sensorState[i] == DOWN) fill(pressedDownColors[i]);
    if (sensorState[i] == UP) fill(pressedUpColors[i]);
    if (sensorState[i] == MID) fill(neutralColors[i]);
    rect(leftPad+i*(ind_gap+ind_width), ind_gap, ind_width, ind_height);
  }
}

void processData() {
  float r;
  TableRow newRow = resistances.addRow();
  TableRow newFRow = filteredR.addRow();
  TableRow newDRow = diffFilteredR.addRow();
  TableRow newMRow = mdfR.addRow();
  TableRow newMMRow = mmdfR.addRow();

  for (int i=0; i<sensorsNum; i++) {
    r = readResistance(sensorPin[i]);
    newRow.setFloat("resistance"+i, r);
    // print(lowPassFilter(resistances, i, fitlerCoeff));
    newFRow.setFloat("resistance"+i, lowPassFilter(resistances, i, fitlerCoeff));
    // print(diffMultiplier*diff(filteredR, i));
    newDRow.setFloat("resistance"+i, diffMultiplier*diff(filteredR, i));
    newMRow.setFloat("resistance"+i, meanFilter(diffFilteredR, meanfilterSize,i));
    newMMRow.setFloat("resistance"+i, medianFilter(mdfR, medianfilterSize,i));
  }

  data_num++;
  x_coord++;
}

int checkDir(Table data, Table mean, int col){
  float d =  data.getRow(data_num-1).getFloat("resistance"+col);
  float m =  mean.getRow(data_num-1).getFloat("resistance"+col);
  int dir;
  
  if (d+downThreshold[col] < m) { // check if its up
    dir = DOWN;
  }
  else if (d-upThreshold[col] > m) { // check if its up
    dir = UP;
  }
  else {
    dir = MID;
  }
  if (dir == UP && !isUp[col]){
    isUp[col] = true;
    isDown[col] = false;
    sensorChange[col] = TURNUP;
    return TURNUP;
  } 
  if (dir == DOWN && !isDown[col]){
    isUp[col] = false;
    isDown[col] = true;
    sensorChange[col] = TURNDOWN;
    return TURNDOWN;
  } 
  if (dir == MID && (isUp[col] || isDown[col])) {
    isUp[col] = false;
    isDown[col] = false;
    sensorChange[col] = TURNMID;
    return TURNMID;
  } 
  sensorChange[col] = NOCHANGE;
  return NOCHANGE;
}

float lowPassFilter(Table data, int col, int[] coeff) {
  if (data_num == 0) return 0;
  int l = coeff.length;
  float res = 0;
  float div = 0;
  int windowL = min(l, data_num);
  for (int i=0; i<windowL; i++) {
    res += coeff[i]*data.getRow(data_num-1-i).getFloat("resistance"+col);
    div += coeff[i];
  }
  return res/div;
}

float diff(Table data, int col) {
  if (data_num == 0) return 0;
  if (data_num == 1) return data.getRow(data_num-1).getFloat("resistance"+col);
  return data.getRow(data_num-1).getFloat("resistance"+col)-data.getRow(data_num-2).getFloat("resistance"+col);
}

float meanFilter(Table data, int size, int col) {
  float res = 0;
  int arr_len = data_num < size ? data_num : size;
  for (int i = data_num-1; i >= data_num - arr_len; i--){
    res += data.getRow(i).getFloat("resistance"+col);
  }
  return res/arr_len;
}

float medianFilter(Table data, int size, int col) {
  if (data_num == 0) return 0;
  float res;
  int arr_len = data_num < size ? data_num : size;
  for (int i = data_num-1; i >= data_num - arr_len; i--){
    median_list.append(data.getRow(i).getFloat("resistance"+col));
  }
  median_list.sort();
  if (arr_len % 2 == 0){
    res = (median_list.get(arr_len/2)+median_list.get(arr_len/2-1))/2;
  }
  else {
    res = median_list.get(arr_len/2);
  }
  median_list.clear();
  return res;
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
  TableRow newFRow1 = filteredR.addRow();
  TableRow newFRow2 = filteredR.addRow();
  TableRow newDRow1 = diffFilteredR.addRow();
  TableRow newDRow2 = diffFilteredR.addRow();
  TableRow newMRow1 = mdfR.addRow();
  TableRow newMRow2 = mdfR.addRow();
  TableRow newMMRow1 = mmdfR.addRow();
  TableRow newMMRow2 = mmdfR.addRow();
  for (int i=0; i<sensorsNum; i++) {
    newRow1.setFloat("resistance"+i, 0);
    newRow2.setFloat("resistance"+i, 0);
    newFRow1.setFloat("resistance"+i, 0);
    newFRow2.setFloat("resistance"+i, 0);
    newDRow1.setFloat("resistance"+i, 0);
    newDRow2.setFloat("resistance"+i, 0);
    newMRow1.setFloat("resistance"+i, 0);
    newMRow2.setFloat("resistance"+i, 0);
    newMMRow1.setFloat("resistance"+i, 0);
    newMMRow2.setFloat("resistance"+i, 0);
  }
}

public void reset() {
  for (int i=0; i<sensorsNum; i++) {
    isUp[i] = false;
    isDown[i] = false;
    sensorState[i] = MID;
    sensorChange[i] = NOCHANGE;
  }
}

float y_coord(float val, float y_lo, float y_hi, float r_hi, float r_lo) {
  return y_lo-(r_hi-val)/(r_hi-r_lo)*(y_lo-y_hi);
}

void drawTable(Table table, int col, float x0, float y0, float x1, float y1, float r_hi, float r_lo, color c) { 
  if (x_coord > x1) {
    background(bg_color);
    x_coord = 0;  
  }
  
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
