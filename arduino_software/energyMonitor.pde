#include <XBee.h>
#include <EEPROM.h>
#include "Emon.h"

//#define _DEBUG_ 1

#define ISCONFVALUE 123 // Value to check if calibration is saved on EEPROM
#define EEPROM_ADDR_VCAL 1
#define DEFAULT_VCAL 0.270418
#define EEPROM_ADDR_ICAL 5
#define DEFAULT_ICAL 0.170732
#define EEPROM_ADDR_PHASECAL 9
#define DEFAULT_PHASECAL 2.3
#define EEPROM_ADDR_SEND_EACH 13
#define DEFAULT_SEND_EACH 10000

// XBee
XBee xbee = XBee();

uint8_t payload[20] = {};
uint8_t payloadPointer = 0;

XBeeAddress64 addr64 = XBeeAddress64(0x0013a200, 0x40665db3);
ZBTxRequest zbTx = ZBTxRequest(addr64, payload, sizeof(payload));
ZBTxStatusResponse txStatus = ZBTxStatusResponse();
// Response
XBeeResponse response = XBeeResponse();
ZBRxResponse rx = ZBRxResponse();

// Emon
EnergyMonitor emon;  //Create an instance

int sendEach;
float VCAL;
float ICAL;
float PHASECAL;

void setup() {
  xbee.begin(38400);

  emon.setPins(2,3); //Energy monitor analog pins
  
  byte isConfigured;

  isConfigured = EEPROM.read(0);
  if (isConfigured == ISCONFVALUE) {
    recalibrateFromEEPROM();
  } else {
    VCAL = DEFAULT_VCAL;
    ICAL = DEFAULT_ICAL;
    PHASECAL = DEFAULT_PHASECAL;
    sendEach = DEFAULT_SEND_EACH;
    EEPROM_writeFloat(EEPROM_ADDR_VCAL, VCAL);
    EEPROM_writeFloat(EEPROM_ADDR_ICAL, ICAL);
    EEPROM_writeFloat(EEPROM_ADDR_PHASECAL, PHASECAL);
    EEPROM_writeInt(EEPROM_ADDR_SEND_EACH, sendEach);
    EEPROM.write(0, ISCONFVALUE);
    emon.calibration(VCAL, ICAL, PHASECAL);
  }

  //emon.calibration( 1.116111611, 0.128401361, 2.3);  //Energy monitor calibration
  //emon.calibration( 1, 1, 1);

}

void loop()
{
  xbee.readPacket();
  if (xbee.getResponse().isAvailable()) {
    if (xbee.getResponse().getApiId() == ZB_RX_RESPONSE) {
      xbee.getResponse().getZBRxResponse(rx);
      if (rx.getOption() == ZB_PACKET_ACKNOWLEDGED) {
        byte type = 0;
        // Types:
        // 0x01 = Set VCAL
        // 0x02 = Set ICAL
        // 0x03 = Set PHASECAL
        // 0x04 = Set DELAY to send packets
        type = rx.getData(0);
        switch (type) {
          case 0x01:
            if (rx.getDataLength() == 5) {
              float value = 0.0;
              byte* p = (byte*)(void*)&value;
              for (int i = 1; i <= sizeof(value); i++)
                *p++ = rx.getData(i);
              EEPROM_writeFloat(EEPROM_ADDR_VCAL, value);
              recalibrateFromEEPROM();
            }
            break;
          case 0x02:
            if (rx.getDataLength() == 5) {
              float value = 0.0;
              byte* p = (byte*)(void*)&value;
              for (int i = 1; i <= sizeof(value); i++)
                *p++ = rx.getData(i);
              EEPROM_writeFloat(EEPROM_ADDR_ICAL, value);
              recalibrateFromEEPROM();
            }
            break;
          case 0x03:
            if (rx.getDataLength() == 5) {
              float value = 0.0;
              byte* p = (byte*)(void*)&value;
              for (int i = 1; i <= sizeof(value); i++)
                *p++ = rx.getData(i);
              EEPROM_writeFloat(EEPROM_ADDR_PHASECAL, value);
              recalibrateFromEEPROM();
            }
            break;
          case 0x04:
            if (rx.getDataLength() == 3) {
              int value = 0.0;
              byte* p = (byte*)(void*)&value;
              for (int i = 1; i <= sizeof(value); i++)
                *p++ = rx.getData(i);
              EEPROM_writeInt(EEPROM_ADDR_SEND_EACH, value);
            }
            break;
        }
      }
    }
  }

  emon.calc(20,2000);
  payloadPointer = 0;
#ifdef _DEBUG_
  Serial.println();
  Serial.print(emon.realPower);
  Serial.print(' ');
  Serial.print(emon.apparentPower);
  Serial.print(' ');
  Serial.print(emon.powerFactor);
  Serial.print(' ');
  Serial.print(emon.Vrms);
  Serial.print(' ');
  Serial.println(emon.Irms);
#endif
  addToPayload(emon.realPower);
  addToPayload(emon.apparentPower);
  addToPayload(emon.powerFactor);
  addToPayload(emon.Vrms);
  addToPayload(emon.Irms);
  xbee.send(zbTx);

  /*
  if (xbee.readPacket(500)) {
        // got a response!

        // should be a znet tx status            	
    	if (xbee.getResponse().getApiId() == ZB_TX_STATUS_RESPONSE) {
    	   xbee.getResponse().getZBTxStatusResponse(txStatus);
    		
    	   // get the delivery status, the fifth byte
           if (txStatus.getDeliveryStatus() == SUCCESS) {
            	// success.  time to celebrate
             	//flashLed(statusLed, 5, 50);
           } else {
            	// the remote XBee did not receive our packet. is it powered on?
             	//flashLed(errorLed, 3, 500);
           }
        }      
    } else {
      // local XBee did not provide a timely TX Status Response -- should not happen
      //flashLed(errorLed, 2, 50);
    }
    */
  
  delay(sendEach);
}

void addToPayload(float f) {
  byte * b = (byte *) &f;
  payload[payloadPointer++] = b[0];
  payload[payloadPointer++] = b[1];
  payload[payloadPointer++] = b[2];
  payload[payloadPointer++] = b[3];
}

void EEPROM_writeFloat(int ee, float value) {
  byte* p = (byte*)(void*)&value;
  for (int i = 0; i < sizeof(value); i++)
    EEPROM.write(ee++, *p++);
}

float EEPROM_readFloat(int ee) {
  float value = 0.0;
  byte* p = (byte*)(void*)&value;
  for (int i = 0; i < sizeof(value); i++)
    *p++ = EEPROM.read(ee++);
  return value;
}

void EEPROM_writeInt(int ee, int value) {
  byte* p = (byte*)(void*)&value;
  for (int i = 0; i < sizeof(value); i++)
    EEPROM.write(ee++, *p++);
}

int EEPROM_readInt(int ee) {
  int value = 0;
  byte* p = (byte*)(void*)&value;
  for (int i = 0; i < sizeof(value); i++)
    *p++ = EEPROM.read(ee++);
  return value;
}

void recalibrateFromEEPROM() {
    VCAL = EEPROM_readFloat(EEPROM_ADDR_VCAL);
    ICAL = EEPROM_readFloat(EEPROM_ADDR_ICAL);
    PHASECAL = EEPROM_readFloat(EEPROM_ADDR_PHASECAL);
    sendEach = EEPROM_readInt(EEPROM_ADDR_SEND_EACH);
    emon.calibration(VCAL, ICAL, PHASECAL);
}

