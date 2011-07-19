#include <XBee.h>
#include "Emon.h"

//#define _DEBUG_ 1

// XBee
XBee xbee = XBee();

uint8_t payload[20] = {};
uint8_t payloadPointer = 0;

XBeeAddress64 addr64 = XBeeAddress64(0x0013a200, 0x40665db3);
ZBTxRequest zbTx = ZBTxRequest(addr64, payload, sizeof(payload));
ZBTxStatusResponse txStatus = ZBTxStatusResponse();

// Emon
EnergyMonitor emon;  //Create an instance

void setup() {
  xbee.begin(38400);
  
  emon.setPins(4,3);                                 //Energy monitor analog pins
  //emon.calibration( 1.116111611, 0.128401361, 2.3);  //Energy monitor calibration
  emon.calibration( 0.285315, 0.128401361, 2.3);
}

void loop()
{
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
  
  delay(10000);
}

void addToPayload(double f) {
  byte * b = (byte *) &f;
  payload[payloadPointer++] = b[0];
  payload[payloadPointer++] = b[1];
  payload[payloadPointer++] = b[2];
  payload[payloadPointer++] = b[3];
}
