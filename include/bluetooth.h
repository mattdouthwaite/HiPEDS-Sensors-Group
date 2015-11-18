void btInit(int baudRate);

int btIsPaired();

void btSendByte(unsigned char data);

void btSendBytes(unsigned char* data, int length);

unsigned char btReceiveByte();

void btDisconnect();