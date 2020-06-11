#!/bin/bash

TICK_DELAY=1
MOVEMENT_SENSOR_GPIO=${2-4}
MOVEMENT_SENSOR_LOW_VALUE=0
MOVEMENT_SENSOR_HIGH_VALUE=1
GPIO_VALUE=
PROTECTOR_ARMED_FILE=${3-"./armed"}
PROTECTOR_VERIFICATION_DELAY=5
SMS_RECIPIENT=${1}
SMS_ALARM_MSG="!! ALARM !! Something is moving in the basement!"

function tick(){
  echo "....tick"
  local moved=$(hasSomethingMoved)
  if [ $moved == "true" ]
  then
   tryProtect
  fi
}

function setUpSensorGpio(){
  echo $MOVEMENT_SENSOR_GPIO > /sys/class/gpio/export
  GPIO_VALUE="/sys/class/gpio/gpio${MOVEMENT_SENSOR_GPIO}/value"

  echo "GPIO: ${MOVEMENT_SENSOR_GPIO} set up as a movment sensor input."
  echo "The sensor value will be read from ${GPIO_VALUE}."
}

function setUpProtectionFiles(){
  touch -a $PROTECTOR_ARMED_FILE
  echo "Information about if the protector is armed is keeped in the file: ${PROTECTOR_ARMED_FILE}."
}

function tryProtect(){
  local isArmed=$(isProtectorArmed)
  if [ $isArmed == "false" ]
  then
    echo "Protector is not armed. Alarm will not be sent!"
    return 0
  fi

  echo "Verify if after ${PROTECTOR_VERIFICATION_DELAY} seconds something is still moving"
  sleep $PROTECTOR_VERIFICATION_DELAY

  local moved=$(hasSomethingMoved)
  if [ $moved == "true" ]
  then
    sendAlarm
  fi
}

function sendAlarm(){
  echo "Sending alarm to: ${SMS_RECIPIENT}."
  echo $SMS_ALARM_MSG
  echo $SMS_ALARM_MSG | sudo gammu sendsms TEXT $SMS_RECIPIENT
}

function isProtectorArmed(){
  local isArmed=$(cat $PROTECTOR_ARMED_FILE)
  if [ $isArmed == "1" ]
  then
    echo "true"
  else
    echo "false"
  fi
}

function hasSomethingMoved(){
  local value=$(readSensorValue)
  if [ $value == $MOVEMENT_SENSOR_HIGH_VALUE ]
  then
    echo "true"
  else
    echo "false"
  fi
}

function readSensorValue(){
  cat $GPIO_VALUE
}

setUpSensorGpio
setUpProtectionFiles

while true
do
  tick
  sleep $TICK_DELAY
done
