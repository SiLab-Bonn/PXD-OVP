// DEPFET PS OVP board test
//
// configures and polls the OVP periodically via I2C and send the readback data via serial port
//
// HK 2023 / PA 2023

#include <Wire.h>
#include <Streaming.h>
#include <ctype.h>

#define OVP_I2C_ADD 0x3c
#define BYTES_TO_READ 8
#define FW_VERSION "2.2"

const int OVP_STATUS_PIN = 2;

int OVP_state      = 1;
int last_OVP_state  = 1;
int flag = 0; 
uint16_t counter = 0;  

unsigned char confReg;
unsigned char mask0;
unsigned char mask1;
unsigned char mask2;
unsigned char fault;
unsigned char stat0;
unsigned char stat1;
unsigned char stat2;

void setup() {
  Wire.begin();        // join i2c bus (address optional for master)
  Serial.begin(9600);  // start serial for output
  pinMode(OVP_STATUS_PIN, INPUT);
  attachInterrupt(digitalPinToInterrupt(OVP_STATUS_PIN), LogReading, FALLING);  // check on OVP_IO_STAT pin

  Serial << "OVP board interface, FW version: " << FW_VERSION << endl;
}


void LogReading(){
  OVP_state = digitalRead(OVP_STATUS_PIN);
  if (OVP_state == 0) { 
      flag=0;     
  }
  else {
    flag=1;
    counter++;  // single event transient counter
  }

}

void WriteOVP()
{
  Wire.beginTransmission(OVP_I2C_ADD); // transmit to device #8
  Wire.write(0x04);         // address offset 
  Wire.write(confReg);      // conf register
  Wire.write(mask0);        // mask[7:0]
  Wire.write(mask1);        // mask[15:8]
  Wire.write(mask2);        // mask[23:16]
  Wire.endTransmission();   // stop transmitting  
}

void ReadOVP()
{
  unsigned char byteCount = 0;

  Wire.beginTransmission(OVP_I2C_ADD); // transmit to device #8
  Wire.write(0x00);         // address offset 
  Wire.endTransmission();   // stop transmitting  
  Wire.requestFrom(OVP_I2C_ADD, BYTES_TO_READ);    // request BYTES_TO_READ bytes from slave device
  
  while ((Wire.available()) && (byteCount < BYTES_TO_READ))  // slave may send less than requested
  {
    unsigned char c = Wire.read(); // receive a byte as character
    switch (byteCount)
    {
      case 0: fault = c; break;
      case 1: stat0 = c; break;
      case 2: stat1 = c; break;
      case 3: stat2 = c; break;
      case 4: confReg = c; break;
      case 5: mask0 = c; break;
      case 6: mask1 = c; break;
      case 7: mask2 = c; break;
      default: break;
    }
    byteCount ++;
  }  
}

void ReadSerial()
{
  unsigned char byteCount = 0;
  char charBuf[2] = "0";
  unsigned char temp;
  char rc;
  boolean endTransmission = false;

  do 
  {
    while (Serial.available() < 1)  // wait for new character
      ;
    rc = Serial.read();
    Serial << rc; // echo received data  

    if ((rc == '\r') || (rc == '\n'))  // LF or CR received which terminates the transfer
      endTransmission = true;

    if (isxdigit(rc)) // HEX character received
    { // keep the last two received digits
      if (charBuf[1] != '\0')  // don't copy buffer for first digit
        charBuf[0] = charBuf[1];  
      charBuf[1] = rc;
    }
    else if ((rc == ' ') || endTransmission)  // field separator found or LF or CR received
    {
      if (charBuf[1] != '\0')  // something valid received?
      {
        temp = strtol(charBuf, 0, 16);
        switch (byteCount)
        {
          case 0: confReg = temp; break; 
          case 1: mask0   = temp; break;
          case 2: mask1   = temp; break;
          case 3: mask2   = temp; break;
          default: break;
        }
      }
      if (endTransmission)  // everything received, reset counter
        byteCount = 0;
      else
        byteCount ++;  
      charBuf[0] = '0';   // prepare buffer for next word: pad with '0' to cope with single digits reads
      charBuf[1] = '\0';  // 0-termination
    }
  } while ((byteCount < 4) && !endTransmission);  // do this until all bytes are processed or end of transmission received
}

void WriteSerial()
{
  unsigned char byteCount = 0;
  
  Serial << _WIDTHZ(_HEX(fault), 2)   << " "  // send the hex formatted bytes
         << _WIDTHZ(_HEX(stat0), 2)   << " "
         << _WIDTHZ(_HEX(stat1), 2)   << " "
         << _WIDTHZ(_HEX(stat2), 2)   << " "
         << _WIDTHZ(_HEX(confReg), 2) << " "
         << _WIDTHZ(_HEX(mask0), 2)   << " "
         << _WIDTHZ(_HEX(mask1), 2)   << " "
         << _WIDTHZ(_HEX(mask2), 2)   << " "
         << digitalRead(OVP_STATUS_PIN) << " "
         << counter << endl;
}


void ProcessSerial() 
{
  char rc;
  
  while (Serial.available() > 0)
  {
    rc = Serial.peek();  // get byte from serial port
    if ((rc == '\n') || (rc == '\r')) // start transfer data from OVP to serial port
    {
      Serial.read();
      ReadOVP();
      WriteSerial();
    }
    else   // start transfer data from serial port to OVP
    {
      ReadSerial();
      WriteOVP();
    }
  }
}


void loop() 
{
  ProcessSerial();
  OVP_state = digitalRead(OVP_STATUS_PIN);
  if (OVP_state != last_OVP_state) {
    if (OVP_state == 0) { 
      Serial.println("OVP");            
      }
    last_OVP_state = OVP_state;
  }
  delay(100);
}
