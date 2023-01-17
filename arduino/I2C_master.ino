// DEPFET PS OVP board test
//
// configures and polls the OVP periodically via I2C and send the readback data via serial port
//
// HK 2023

#include <Wire.h>
#include <Streaming.h>

#define OVP_I2C_ADD 0x3c
#define BYTES_TO_READ 8

void setup() {
  Wire.begin();        // join i2c bus (address optional for master)
  Serial.begin(9600);  // start serial for output
}

void WriteOVP()
{
  Wire.beginTransmission(OVP_I2C_ADD); // transmit to device #8
  Wire.write(0x04);        // address offset 
  Wire.write(0x00);        // conf register
  Wire.write(0x00);        // mask[7:0]
  Wire.write(0x00);        // mask[15:8]
  Wire.write(0x00);        // mask[23:16]
  Wire.endTransmission();    // stop transmitting  
}

void ReadOVP()
{
  Wire.beginTransmission(OVP_I2C_ADD); // transmit to device #8
  Wire.write(0x00);        // address offset ???
  Wire.endTransmission();    // stop transmitting  
  Wire.requestFrom(OVP_I2C_ADD, BYTES_TO_READ);    // request BYTES_TO_READ bytes from slave device
}

void loop() 
{
  int i = 0;
  WriteOVP();
  delay(1);
  ReadOVP();

  while (Wire.available())  // slave may send less than requested
  {
    unsigned char c = Wire.read(); // receive a byte as character
    i ++;
    if (i == BYTES_TO_READ)
      break;

    Serial << _WIDTHZ(_HEX(c), 2);   // print the hex formated bytes
    if (i < 7)
      Serial << "_" ;     // byte separators for readability
        
  }
  Serial << endl;;
  delay(500);
}
