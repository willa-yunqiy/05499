
// AFTER uploading the code to lilypad
// Go to Tools -> Serial Plotter
// DON'T open serial plotter before the upload is done!
// otherwise it will interfere with the upload
// If it can't find the usb, just upload again and it will probably work

int analogPin = A5;

void setup() {
  // initialize serial communication at 9600 bits per second:
  Serial.begin(9600);
}

// the loop routine runs over and over again forever:
void loop() {
  // read the input on analog pin 0:
  int sensorValue = analogRead(analogPin);
  // Convert the analog reading (which goes from 0 - 1023) to a voltage (0 - 3.7V):
  float voltage = sensorValue * (3.7 / 1023.0);
  // print out the value you read:
  Serial.println(sensorValue);
  delay(20);
}
