# ECE 372 Lab 6
Authors: Rachel & Ali

Objective of the lab is to continue using interrupts. We will also use the timer module and 
output compare. 

In this lab, we will use the timer module for two purposes:

1. Use flag polling loop to create a delay to turn the speaker on the board on/off periodically.
To do so, we use the TOF timer overflow flag that sets itself every time the 16-bit TCNT register 
overflows. We use 8 for the timer prescale. In an infinite loop, every time the flag is set, we toggle
the speaker.

2. Use output compare interrupt on one of the 8-channels to maintain a 4-bit counter that updates 
every 1 second, and is displayed on the PORT B LEDs. Make the counter count to 30000 (approx. 
equivalent to 10ms) to trigger and interrupt. After 100 interrupts (100*10ms = 1 sec.)
update the counter.

