/*******************************************************
   Title: Goertzel Fast Sampling
   Author: Aidan Aug
   Date Created: 11/20/21
   Date Updated: 6/4/22
   Description: This code is designed for a teensy 4.0 to sampling at a very
                high sampling rate via the ADC library (switching between the
                two ADC available in the Teensy 4.0).

                The sampled data, with # of samples specified as ADMAX,
                is then processed via a hanning window, and then put into the
                Goertzel Algorithm.

   Resources: https://forum.pjrc.com/threads/60299-1-MSPS-on-a-T4-Is-this-possible
   1MegaSample T4.0 ADC
   MJB   4/2/20
   NOTE:  Proof-of-concept program. In the interest of simplicity
          it uses global variables and simple functions without parameters.

          Sampling runs fast enough at 600MHz that some
          oversampling may be possible to reduce noise

          May be occasional timing glitches if other
          processes such as the tick interrupt, run at higher
          priority than the ADC interval timer.

          The program uses the ADC library from Pedvide.
***************************************************************/

/**************************TEENSY FAST SAMPLING***************************/
#include <ADC.h>
IntervalTimer ADCTimer; // Uses interrupts (stops a process) at specified intervals;

// instantiate a new ADC object
ADC *adc = new ADC();
const int admarkpin  = 1;

#define ADMAX 2048
// "volatile" means its value can change from a concurrent process
volatile uint8_t voltages[ADMAX]; // Stores all readings
volatile uint32_t adcidx;
volatile bool doneflag = false;

/**************************GOERTZEL ALGORITHM***************************/
// Change the following 3 lines accordingly
const float SAMPLING_FREQUENCY = 2702556.62;
const float TARGET_FREQUENCIES[] = {76.2e3, 66.8e3, 63.1e3, 58.1e3, 52.5e3, 46.6e3, 41.3e3, 38.2e3, 33.6e3, 28.4e3, 23.9e3, 20.7e3, 15.8e3, 11.3e3, 8.99e3, 2.96e3, 83.9e3, 80.7e3, 89.3e3, 94.3e3, 102.0e3, 104.0e3, 110.0e3, 120.0e3, 124.0e3, 128.0e3, 137.5e3, 141.0e3, 147.5e3, 151.5e3, 161.0e3, 170.0e3};
const int num_freqs = 32;

float magnitude = 0;
//float magnitudes[num_freqs];

/**************************HANNING WINDOW***************************/
const int N = ADMAX; //for hanning window
//float sum = 0;
float hann[N];

/**************************SENDING RESULTS***************************/
const int save_time = 2; //seconds
const int num_frames = save_time / 0.0024494; //resolution is NOT 1msec -->
float values[num_freqs][num_frames]; //variable to save values of the array
int time_elapsed[num_frames]; //variable to save times per frame in microseconds
int frame = 0;
unsigned long timer; //measure the time
float old_max = 0;
float new_max = 0;
int start_save = 0;
int thres = 1000; //goertzel threshold for "no data"

void setup() {
  /**************************Use ADC library for Fast Sampling***************************/
  while (!Serial) {} // Wait until serial is ready
  pinMode(admarkpin, OUTPUT);
  pinMode(A0, INPUT_DISABLE);
  pinMode(13, OUTPUT);

  // Set values for adc0
  adc->adc0->setAveraging(1); // set number of averages
  adc->adc0->setResolution(8); // set bits of resolution
  adc->adc0->setConversionSpeed(ADC_CONVERSION_SPEED::VERY_HIGH_SPEED); // change the conversion speed
  adc->adc0->setSamplingSpeed(ADC_SAMPLING_SPEED::VERY_HIGH_SPEED); // change the sampling speed

  // Repeat for adc1
  adc->adc1->setAveraging(1);
  adc->adc1->setResolution(8);
  adc->adc1->setConversionSpeed(ADC_CONVERSION_SPEED::VERY_HIGH_SPEED);
  adc->adc1->setSamplingSpeed(ADC_SAMPLING_SPEED::VERY_HIGH_SPEED);

  /**************************HANNING WINDOW***************************/
  // Instatiate hanning window
  for (int i = 0; i < N; i++) {
    hann[i] = 0.5 * (1.0 - cos(2.0 * PI * (float)i / N));
  }
  // get first measurements
  FastSample();
  Goertzel();
  for (int i = 0; i < num_freqs; i++) {
    old_max = max(old_max, values[i][0]);
  }
}

void loop() {
  // if the old max was high, and the new max value is below 200, save for 2 seconds
  FastSample();
  Goertzel();
  new_max = 0;
  for (int i = 0; i < num_freqs; i++) {
    new_max = max(new_max, values[i][0]);
  }
//  Serial.print(new_max);
//  Serial.print(',');
//  Serial.println(old_max);
  if ((old_max > thres) && (new_max < thres)) {
    start_save = 1;
  }
  old_max = new_max;

  if (start_save == 1) {
    // if (Serial.read() == "Start") {
    digitalWrite(13, HIGH); //turn on the LED
    for (frame = 0; frame < num_frames; frame++) {
      timer = micros();
      FastSample(); // take measurements
      Goertzel(); // calculate goertzel
      time_elapsed[frame] = micros() - timer;
    }
    digitalWrite(13, LOW); // turn off LED
    //print out the answers
    PlotMagnitudes();
    start_save = 0;
  }
}

/******************************************************
   Read MAXSAMPLES from ADC at 1 microsecond intervals
   Store the results in voltages;
 *****************************************************/
void FastSample(void) {
  /***************Read in the Samples********************/
  adcidx = 0;
  uint8_t value = 0;
  for (int i = 0; i < ADMAX; i++) {
    if (adcidx & 0x01) { //Read ADC0 and restart it
      value = adc->adc0->readSingle();
      adc->adc0->startSingleRead(A0);
    } else  { //Read ADC1 and restart it
      value = adc->adc1->readSingle();
      adc->adc1->startSingleRead(A0);
    }
    if (adcidx < ADMAX) {
      voltages[adcidx++] = value;
    }
  }
}

/******************************************************
   Perform Goertzel on the stored samples in voltages
 *****************************************************/
void Goertzel(void) {
  for (int i = 0; i < N; i++) {
    voltages[i] = (voltages[i] - 1.65) * hann[i]; // apply hann window to voltages and de-meaning
  }

  // Goertzel on voltages for each frequency
  for (int i = 0; i < num_freqs; i++) {
    int k = 0.5 + N * TARGET_FREQUENCIES[i] / SAMPLING_FREQUENCY;
    float omega = 2.0 * PI * k / N;
    float coeff = cos(omega) * 2.0;
    float Q0 = 0;
    float Q1 = 0;
    float Q2 = 0;
    // PROCESS THE SAMPLE
    for (int j = 0; j < N; j++) {
      Q0 = voltages[j] + coeff * Q1 - Q2;
      Q2 = Q1;
      Q1 = Q0;
    }

    magnitude = sqrt(Q1 * Q1 + Q2 * Q2 - coeff * Q1 * Q2);
    //magnitudes[i] = magnitude;
    values[i][frame] = magnitude;
  }
}

/******************************************************
   Plot Goertzel Magnitudes
 *****************************************************/
void PlotMagnitudes(void) {
  for (int frame_num = 0; frame_num < num_frames; frame_num++) {
    for (int q = 0; q < num_freqs; q++) { //print out the values to serial monitor
      Serial.print(values[q][frame_num]);
      Serial.print(',');
      delayMicroseconds(5);
    }
    Serial.print(time_elapsed[frame_num]); //2849 microseconds with 8 bit, 4517 with 10 bit -->
    Serial.print(',');
    delayMicroseconds(5);
  }
  Serial.println();
}
