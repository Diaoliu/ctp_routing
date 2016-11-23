#include <Timer.h>
#include "../lib/ctp.h"

configuration SenseAppC {} 
implementation 
{ 
  components SenseC, MainC, LedsC
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components SensirionSht11C() as Sensor;
  components ActiveMessageC, new AMSenderC(AM_TYPE);
  components new AMReceiverC(AM_TYPE);
  components CC2420ActiveMessageC;
  components ActiveMessageAddressC;

  SenseC.Boot -> MainC;
  SenseC.Leds -> LedsC;
  SenseC.TimerSense -> Timer0;
  SenseC.TimerSync -> Timer1;
  SenseC.Read -> Sensor.Humidity;

  Sensec.CC2420Packet -> CC2420ActiveMessageC;
  Sensec.ActiveMessageAddress -> ActiveMessageAddressC;

  SenseC.Packet -> AMSenderC;
  SenseC.AMPacket -> AMSenderC;
  SenseC.AMControl -> ActiveMessageC;
  SenseC.AMSend -> AMSenderC;
  SenseC.AMReceive -> AMReceiverC;
}
