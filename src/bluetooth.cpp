#include "mbed.h"
//#include "bluetooth.h"

//Serial bt(USBTX, USBRX);
Serial bt(PTE0, PTE1);
unsigned char lastByte = 0;

extern "C" void btInit(int baudRate) {
    bt.baud(baudRate);
}

extern "C" int btIsPaired() {
    return 1;
}

extern "C" void btSendByte(unsigned char data) {
    bt.putc(data);
}

extern "C" void btSendBytes(unsigned char* data, int length) {
    for (int i = 0; i < length; i++) {
        bt.putc(data[i]);
    }
}

extern "C" unsigned char btReceiveByte() {
    if (bt.readable()) {
        lastByte = bt.getc();
    }
    return lastByte;
}

extern "C" void btDisconnect() {
    delete bt;
}