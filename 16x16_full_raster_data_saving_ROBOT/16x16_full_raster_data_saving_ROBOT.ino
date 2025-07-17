// 16x16 raster scan of TDMA sensor

// Digital pins are d0 through d12, and then d24,d25,d28
// Analog pins are a0 through a9, and then a12,a13,a14,a15,a16,a17
const int save_time = 2; //seconds
const float sampling_rate = 221;//350; //full scans per second = 350 Hz at 8 bit, and 221 Hz at 10 bit
const int num_frames = sampling_rate * save_time; //221*2 = 442 frames
int time_elapsed[num_frames]; //variable to save times per frame in microseconds

const int N = 256; //number of sensors; 16*16
float values[N][num_frames]; //variable to save values of the array
unsigned long timer; //measure the time and print that too
unsigned long total_time; //measure the time and print that too
int adcidx = 0;
int frame_num = 0;
int old_max = 0;
int new_max = 0;
int thres = 700; //threshold for "no data"
int start_save = 0;

// what are the connected digital/analog pins?
int dpins[16] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 24, 25, 28};
//int apins[16] = {A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A12, A13, A14, A15, A16, A17};
int apins[16] = {A9, A8, A7, A6, A5, A4, A3, A2, A1, A0, A17, A16, A15, A14, A12, A13};

void setup() {
  //setup the 16 digital output pins as outputs
  for (int i = 0; i < 16; i++) {
    pinMode(dpins[i], OUTPUT);
  }
  // set all the output pins to low
  for (int i = 0; i < 16; i++) {
    digitalWrite(dpins[i], LOW);
  }
  analogReadResolution(10); //8 bit or 10 bit
  // set the LED pin
  pinMode(13, OUTPUT);

  // get first measurements
  adcidx = 0;
  for (int i = 0; i < 16; i++) { //loop through the output rows
    digitalWrite(dpins[i], HIGH);
    for (int j = 0; j < 16; j++) {
      values[adcidx][frame_num] =  analogRead(apins[j]); //while that pin is high, read the analog columns
      adcidx = adcidx + 1;
    }
    digitalWrite(dpins[i], LOW); // turn that row back to low
  }
  for (int i = 0; i < N; i++) {
    old_max = max(old_max, values[i][0]);
  }
}

void loop() {

  adcidx = 0;
  for (int i = 0; i < 16; i++) { //loop through the output rows
    digitalWrite(dpins[i], HIGH);
    for (int j = 0; j < 16; j++) {
      values[adcidx][frame_num] =  analogRead(apins[j]); //while that pin is high, read the analog columns
      adcidx = adcidx + 1;
    }
    digitalWrite(dpins[i], LOW); // turn that row back to low
  }
  new_max = 0;
  for (int i = 0; i < N; i++) {
    new_max = max(new_max, values[i][0]);
  }
  if ((old_max > thres) && (new_max < thres)) {
    start_save = 1;
  }
//  Serial.print(new_max);
//  Serial.print(',');
//  Serial.println(old_max);
  old_max = new_max;

  if (start_save == 1) {
    digitalWrite(13, HIGH); //turn on the LED
    for (int frame_num = 0; frame_num < num_frames; frame_num++) {
      timer = micros();
      adcidx = 0;
      for (int i = 0; i < 16; i++) { //loop through the output rows
        digitalWrite(dpins[i], HIGH);
        for (int j = 0; j < 16; j++) {
          values[adcidx][frame_num] =  analogRead(apins[j]); //while that pin is high, read the analog columns
          adcidx = adcidx + 1;
        }
        digitalWrite(dpins[i], LOW); // turn that row back to low
      }
      //Save the elapsed time
      time_elapsed[frame_num] = micros() - timer;
    }
    digitalWrite(13, LOW); // turn off LED
    // send the answers
    for (int frame_num = 0; frame_num < num_frames; frame_num++) {
      for (int q = 0; q < N; q++) { //print out the values to serial monitor
        Serial.print(values[q][frame_num]);
        Serial.print(',');
        delayMicroseconds(5);
      }
      Serial.print(time_elapsed[frame_num]); //2849 microseconds with 8 bit, 4517 with 10 bit -->
      Serial.print(',');
      delayMicroseconds(5);
    }
    Serial.println();
    start_save = 0;
  }
}
