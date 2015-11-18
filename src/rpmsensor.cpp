#include "mbed.h"
#define NUM_SAMPLES     60
#define SAMPLE_TIME     0.01 // Seconds
#define NUM_TRIGGERS    4 // Number of triggers counted for each revolution

InterruptIn sensor(PTA4);
Ticker timer;
int binIndex;
int counts[NUM_SAMPLES];

void incCount() {
    counts[binIndex % NUM_SAMPLES]++;
}

void incbinIndex() {
    binIndex++;
    counts[binIndex % NUM_SAMPLES] = 0;
}

extern "C" void rpmInit() {
    for (int i = 0; i < NUM_SAMPLES; i++) {
        counts[i] = 0;
    }
    sensor.fall(&incCount);
    timer.attach(&incbinIndex, SAMPLE_TIME);
}

extern "C" float getRpm() {
    int total = 0;
    for (int i = 0; i < NUM_SAMPLES; i++) {
        total += counts[i];
    }
    float freq = (float) total / ((float) NUM_SAMPLES * SAMPLE_TIME);
    return 60 * freq / NUM_TRIGGERS;
}

extern "C" void rpmRelease() {
    timer.detach();
}