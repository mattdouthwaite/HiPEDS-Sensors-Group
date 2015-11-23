#include "mbed.h"
#define NUM_SAMPLES     200
#define SAMPLE_TIME     0.01 // Seconds
#define NUM_TRIGGERS    4 // Number of triggers counted for each revolution

Ticker timer;
int binIndex;

InterruptIn leftSensor(PTA4);
InterruptIn rightSensor(PTA5);
int leftCounts[NUM_SAMPLES];
int rightCounts[NUM_SAMPLES];
float weights[NUM_SAMPLES];

void incLeftCount() {
    leftCounts[binIndex % NUM_SAMPLES]++;
}

void incRightCount() {
    rightCounts[binIndex % NUM_SAMPLES]++;
}

void incBinIndex() {
    binIndex++;
    leftCounts[binIndex % NUM_SAMPLES] = 0;
    rightCounts[binIndex % NUM_SAMPLES] = 0;
}

void initWeights() {
    float timeRate = 0.5; // seconds
    float rate = SAMPLE_TIME / timeRate;
    for (int i = 0; i < NUM_SAMPLES; i++) {
        weights[i] = exp(-rate * (float) i);
    }
    float sum = 0;
    for (int i = 0; i < NUM_SAMPLES; i++) {
        sum += weights[i];
    }
    for (int i = 0; i < NUM_SAMPLES; i++) {
        weights[i] /= sum;
    }
}

extern "C" void rpmInit() {
    for (int i = 0; i < NUM_SAMPLES; i++) {
        leftCounts[i]  = 0;
        rightCounts[i] = 0;
    }
    initWeights();
    leftSensor.fall(&incLeftCount);
    rightSensor.fall(&incRightCount);
    timer.attach(&incBinIndex, SAMPLE_TIME);
}

float getRpm(int* counts) {
    float total = 0;
    for (int i = 0; i < NUM_SAMPLES; i++) {
        total += weights[i] * (float) counts[(binIndex - i) % NUM_SAMPLES];
    }
    float freq = (float) total / SAMPLE_TIME;
    return 60 * freq / NUM_TRIGGERS;
}

extern "C" float getLeftRpm() {
    return getRpm(leftCounts);
}

extern "C" float getRightRpm() {
    return getRpm(rightCounts);
}

extern "C" void rpmRelease() {
    timer.detach();
}