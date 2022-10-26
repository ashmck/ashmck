//MOUSE DESIGN CODE: FIRST LAP (20SECONDS)
// last editted 04/05/2022
// BY BARTEK MACHNIK, ASHLEIGH MCKENNA AND LUKE MOORES

#define motorR 6 // Right motor pin
#define motorL 5 // Left motor pin
#define L A6 // Left sensor pin
#define R A7 // Right sensor pin

float posL,posR,error,PID,errorLast,time1,time2,timeDiff,deriv,integral;

unsigned long loopTime; // The time the code for
unsigned long startTime = 0; // The start time, initially 0

double offset ; // Initiallises offset, the default pwm input to motors which is adapted using PID to achieve a differential-drive architecture 
//90 at 5.07V up the hill (5.02V by end of testing) 

double kp = 0.3, kd = 0.2, ki = 0;// proportional gain, derivative gain and integral gain constant values respectively

void setup() {
  // set up code, runs onces
  pinMode(motorL, OUTPUT); // defines left motor pin as Arduino output
  pinMode(motorR, OUTPUT);  // defines right motor pin as Arduino output
  pinMode(L, INPUT); // defines left sensor pin as Arduino input
  pinMode(R, INPUT); // defines right sensor pin as Arduino input

}


void loop()
{
  unsigned long loopTime = millis() - startTime; //Calculate the time since last time the cycle was completed

  if (loopTime <= 1500){ // If the elapsed time is less than 1.5 seconds, the speed should be 0 to perform a standing start
    offset = 0;
  }
  
  else if (loopTime > 1500 && loopTime <= 15000) //If the elapsed time is between 1.5 seconds and 15 seconds
  {
    offset = 70; //Increase pwm input to 70 to create a reasonable speed around the first turning leg of the race
  }
  else if (loopTime > 15000 && loopTime <= 18000) //DRS zone: on the straight boost the speed to decrease lap time
  {
    offset = 170;
    
  }
  else if (loopTime > 18000 && loopTime <= 25000) { // If the elapsed time is between 18 and 25 seconds 
    offset = 115; // decrease the pwm so that it can get up the hill but can remain in control for the final bend
  }
  
  posL = analogRead(L); // The left sensor value is read by the Arduino
  posR = analogRead(R); // The right sensor value is read by the Arduino
    
  error = posL - posR;// The error between the sensors is found. If error is zero this means that the left and right sensor are equidistant from the wire: meaning the mouse is central
  
  time2 = time1; // previous time is set to current time 
  time1 = millis();// time is measured using millis()
  timeDiff = time1 - time2; // The time difference is found, how long the code takes to run
  deriv = (error - errorLast)/timeDiff; // Derivative is found for the PID controller. This will be the dampening value which uses the patterns of the future oscillations to reduce them and achieve the target more quickly.
  integral += (error * timeDiff); //Integral is also found for the PID. This should predict the past oscillations and make sure the final value has 0 error. 
  errorLast = error; // The last error is made equal to the first error to remember it for the next iteration

  PID = kp * error + kd * deriv + ki*integral; // PID controller constants are multiplied by the error, derivative and integral: This creates the final PID value

  if (PID>offset ){ //Limiting code to prevent create a minimum PID value, and therefore minimum speed equal to that at the offset pwm. 
    PID = offset ;
  }
  else if (PID < (-1*offset)){
    PID = -1*offset;
  }

  analogWrite(motorL, offset - PID);  
  //If the PID value is positive, implying that the right sensor is picking up less than the left sensor, the left motor will slow down by PID. This moves the right sensor closer to the wire.
  //If it the PID value is  negative, implying that the left sensor is picking up less than the right sensor, the left motor will speed up by PID. This moves the left sensor closer to the  wire.
  
  analogWrite(motorR, offset + PID);
  //If the PID value is positive, implying that the right sensor is picking up less than the left sensor, the right motor will speed up by PID. This moves the right sensor closer to the wire.
  //If it the PID value is  negative, implying that the left sensor is picking up less than the right sensor, the right motor will slow down by PID. This moves the left sensor closer to the  wire.

  delay(1); //delay the code so that the derivative term has time to work

  
}
