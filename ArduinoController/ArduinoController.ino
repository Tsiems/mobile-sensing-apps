/*

Copyright (c) 2012-2014 RedBearLab

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

/*
 *    Chat
 *
 *    Simple chat sketch, work with the Chat iOS/Android App.
 *    Type something from the Arduino serial monitor to send
 *    to the Chat App or vice verse.
 *
 */

//"RBL_nRF8001.h/spi.h/boards.h" is needed in every new project
#include <SPI.h>
#include <EEPROM.h>
#include <boards.h>
#include <RBL_nRF8001.h>

const int BTN_PIN = 4;
const int LED_PIN = 3;
const int SERVO_PIN = 6; 
const int POT_PIN = A0;

void setup()
{  
  // Default pins set to 9 and 8 for REQN and RDYN
  // Set your REQN and RDYN here before ble_begin() if you need
  //ble_set_pins(3, 2);
  
  // Set your BLE Shield name here, max. length 10
  ble_set_name("The Dopest");

  

  pinMode(BTN_PIN,INPUT);
  pinMode(LED_PIN,OUTPUT);
  pinMode(SERVO_PIN, OUTPUT);
  pinMode(POT_PIN, INPUT);
  digitalWrite( LED_PIN, LOW );
  
  // Init. and start BLE library.
  ble_begin();
    
  // Enable serial debug
  Serial.begin(57600);
}

unsigned char buf[16] = {0};
unsigned char len = 0;
String command;
int buttonState = 0;
int potVal = 0;

void loop()
{
  //read from bluetooth low energy
  if ( ble_available() )
  {
    command = "";
    while ( ble_available() ) {
      char c = ble_read();
      command += c; //add each character to the command
    }
    Serial.println(command);

    if( command.substring(0,9) == "Light ON;" ) {
      digitalWrite( LED_PIN, HIGH );
    }
    else if ( command.substring(0,10) == "Light OFF;" ) {
      digitalWrite( LED_PIN, LOW );
    }
    else if ( command.substring(0,5) == "Servo" ) {
        String servoSpeed = command.substring(6,command.indexOf(';'));
        analogWrite(SERVO_PIN, servoSpeed.toInt());
    }

    
    Serial.println();
  }

  //read from serial port
  if ( Serial.available() )
  {
    delay(5);
    
    while ( Serial.available() )
      ble_write(Serial.read());
  }


  //read from button
  int newBtnState = digitalRead(BTN_PIN);
  if( newBtnState != buttonState ) {
    
    buttonState = newBtnState;
    String sendCommand = "BTN " + String(buttonState);
    for( int i = 0; i < sendCommand.length(); i++ ) {
      ble_write( sendCommand[i] );
    }
  }

  //read from pot
  int newPotVal = analogRead(POT_PIN);
  if( newPotVal != potVal ) {
    
    potVal = newPotVal;
    int newBrightness = potVal/4;
    analogWrite(LED_PIN, newBrightness);
    String sendCommand = "POT " + String(potVal);
    for( int i = 0; i < sendCommand.length(); i++ ) {
      ble_write( sendCommand[i] );
    }
  }

  delay(10);
  

  
  
  ble_do_events();
}

