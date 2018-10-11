
/*
 * This is the main sketch for the TPE station controller. 
 * Recieves commands from iOS app and controls coaster motors. 
 * 
 * Created by Mitchell Sweet for the Rochester Institute of Technology Theme Park Enthusiasts. 
 * 
 * Copyright © 2018 Mitchell Sweet
 */ 

 #include <Servo.h> 

 Servo gateController; // Servo for opening and closing station gates. 
 Servo liftMotor; // CIM motor to control chain lift. 
 const int dispatchMotor = 6; // Pin for motor in station which controls dispatch system. 
 const int gatePin = 10; 
 const int liftPin = 5; 
 const int sensorPin = 3; 
 const int estopPin = 2;

 int liftSpeed = 90; // Current speed for the lift, initalized to 90 for dead stop. 
 int gateClosed = 145; //TODO: Find the correct closed position for the gate system. 
 int gateOpen = 95; //TODO: Find the correct open position for the gate system. 

void setup() {
  gateController.attach(gatePin); // Attatch the gate servo to PWM pin 3.
  liftMotor.attach(liftPin); // Attatch the lift motor to PWM pin 5.
  pinMode(LED_BUILTIN, OUTPUT); // Set the builtin LED. 
  pinMode(dispatchMotor, OUTPUT); // Attatch the dispatch motor to its correct pin.
  pinMode(sensorPin, INPUT_PULLUP); // Attatch the sensor pin to the sensor. 
  pinMode(estopPin, INPUT); // Attatch the Estop pin to the Estop button. 
  attachInterrupt(digitalPinToInterrupt(sensorPin), sensorTrigger, CHANGE); // Attatch interrupt to the sensor. 
  attachInterrupt(digitalPinToInterrupt(estopPin), eStop, CHANGE); // Attatch interrupt to the estop button. 
  gateController.write(gateClosed); 
  liftMotor.write(90);
  digitalWrite(dispatchMotor, LOW); 
  Serial.begin(9600); 
  digitalWrite(LED_BUILTIN, LOW);
}

void loop() {
  char command = 'X'; 
  if (Serial.available()) {
    command = Serial.read(); // Set the command to the character typed into the serial port.
  }

  switch(command) {
    case '1': 
       setLiftSpeed(93); 
    break; 
    case '2':
       setLiftSpeed(96);
    break; 
    case '3':
       setLiftSpeed(99);
    break; 
    case '4':
       setLiftSpeed(102);
    break; 
    case '5':
       setLiftSpeed(105);
    break; 
    case '6':
       setLiftSpeed(108);
    break;
    case '7':
       setLiftSpeed(111);
    break; 
    case '8':
       setLiftSpeed(114);
    break; 
    case '9':
       setLiftSpeed(117);
    break; 
    case '0':
       setLiftSpeed(125); 
    break;
    case 'S':
       setLiftSpeed(90); 
    break;
    case 'D':
       dispatch(); 
    break;
    case 'O':
       openGates(); 
    break;
    case 'C':
       closeGates();
    break; 
    case 'E':
    // E-stop
       setLiftSpeed(90); 
       gateController.write(gateClosed); 
       digitalWrite(dispatchMotor, LOW); 
    break;
    case 'T':
    // Test connection 
    Serial.println("Recieved");
    break;
    case 'X':
      // Default, do nothing. 
    break;
  }
  command = 'X'; 
}

/*
 * Takes in an integer between 0 and 180 to ramp the chain lift speed to. 
 */
void setLiftSpeed(int speed) {
  digitalWrite(LED_BUILTIN, LOW);
  Serial.println("Setting lift speed...");

  if (speed > liftSpeed) {
    for (int pos = liftSpeed; pos <= speed; pos += 1) {
      liftMotor.write(pos); 
      delay(100); 
    }
  }
  else {
    for (int pos = liftSpeed; pos >= speed; pos -= 1) {
      liftMotor.write(pos); 
      delay(100); 
    }
  }
  liftSpeed = speed; 
  Serial.println("Lift speed set."); 
}

/*
 * Activates the dispatch motor for enough time for the train to dispatch the station. 
 */
void dispatch() {
  Serial.println("Dispatching...");
  digitalWrite(dispatchMotor, HIGH); 
  delay(3500); 
  digitalWrite(dispatchMotor, LOW); 
  Serial.println("Dispatched."); 
}

/*
 * Opens the station gates.
 */
void openGates() {
  gateController.write(gateOpen);
  Serial.println("Open");
}

/*
 * Closes the station gates.
 */
void closeGates() {
  gateController.write(gateClosed);
  Serial.println("Closed");
}

/*
 * Called by the station sensor interrupt. 
 */
void sensorTrigger() {
  int sensorState = digitalRead(sensorPin); 
  if (sensorState == 1) {
    delay(500);
    if (sensorState == 1) {
      Serial.println("departed"); 
    }
  }
  else if (sensorState == 0) {
    delay(500); 
    if (sensorState == 0) {
      Serial.println("arrived");
    }
  }
}

void eStop() {
  liftMotor.write(90); 
  digitalWrite(LED_BUILTIN, HIGH);
  Serial.println("STOPPED");
}









