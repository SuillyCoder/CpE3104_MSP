<h1>CPE3104 MSP: AC CONTROL SYSTEM</h1>

<img width="1083" height="651" alt="image" src="https://github.com/user-attachments/assets/afdfbbe4-80b8-429c-9dfb-cd73ed0096a1" />

</br>
In compliance with the requirements of the course: CpE3104-Microprocessors, we were tasked to design a microprocessor-based system of a given prompt. My team was tasked to design a uP-Based Air Conditioning (AC) Control System, which allows the user to change and view the temperature in real-time, as well as set various modes to set the AC Fan to various speeds, depending on the preference. The system also allows for the user to control the swinging of the AC System, similar to how you would in an actual one. The system also allows the user to switch between timer and thermo mode. Thermo mode has a real-time temperature reading system, while the Timer mode has a real-time countdown, expiry, and system shutdown system. A button to power the system on and off has also been implemented for easier control of the syste's operations.
</br>

<img width="1489" height="600" alt="image" src="https://github.com/user-attachments/assets/70d52a84-2679-4f6e-ba49-6950ed172090" />

</br>
The system had to utilize both low-level IC's and various I/O peripherals in order for it to carry out its specific requirements. Specifically, the components used for this project were the following:

<h3>MEMORY AND ADDRESS IC'S</h3>
<ul>
  <li>8086 Microprocessor</li>
  <li>74LS373 Address Latch</li>
  <li>74LS257 Data Latch</li>
  <li>74LS138 3-8 Line Decoder</li>
</ul>

<h3>PERIPHERAL ICS</h3>
<ul>
  <li>8255 Programmable Peripheral Interface IC</li>
  <li>8253 Programmable Interval Timer IC</li>
  <li>L293D Motor Driver ICs</li>
  <li>ADC0808 8-Lined Analog to Digital Converer IC</li>
</ul>

<h3>I/O PERIPHERALS</h3>
<ul>
  <li>LM044L 16x4 LCD</li>
  <li>LM35 Temperature Sensor</li>
  <li>Unipolar Stepper Motor</li>
  <li>Unipolar Servo Motor</li>
  <li>DC Motor</li>
  <li>2-Bit Dipswitch</li>
  <li>Tactile Push Button</li>
</ul>

</br>

<h2>VERSION LOG: </h2>

<h3>Version 1</h3>
<img width="1552" height="713" alt="image" src="https://github.com/user-attachments/assets/da3ed918-4f7d-40b1-86ce-bdee061259a2" />
<ul>
  <li>Initial Memory Interfacing Set Up</li>
  <li>Iniital Address Decoding Setup</li>
  <li>Initial I/O Interfacing Setup</li>
</ul>

<h3>Version 2</h3>
<img width="1557" height="814" alt="image" src="https://github.com/user-attachments/assets/90e54e94-a919-47b0-9f86-d0ab766e8c76" />
<ul>
  <li>Mode-Setting and SubMode Setting Feature Implemented</li>
  <li>Switching between Timer and Thermo Feature Implemented</li>
  <li>Addition of a Servo Motor for swing actuator</li>
</ul>

<h3>Version 3</h3>
<img width="1541" height="754" alt="image" src="https://github.com/user-attachments/assets/647a67e4-be11-46de-a2b5-4983e660238d" />
<ul>
  <li>Interfaced motors using L293D motor drivers</li>
  <li>Separated the compressor motor as a separate DC Motor</li>
  <li>Added in a switch next to the 8086 uP for System Activation</li>
  <li>LCD Display does not work now for some reason</li>
</ul>

<h3>Version 4</h3>
<img width="1426" height="824" alt="image" src="https://github.com/user-attachments/assets/fb0bfcd1-fb46-4511-a5f6-34e2f3441c46" />
<ul>
  <li>LCD Displays stuff now</li>
  <li>Integrated feature to read input from LM35 and display corresponding temperature</li>
  <li>The conversion algorithm makes the readings weird. We gotta work on that.</li>
</ul>

<h3>Version 5</h3>
<img width="1554" height="762" alt="image" src="https://github.com/user-attachments/assets/7cee88c9-b5ac-4b40-971e-03df179f4bfd" />
<ul>
  <li>Added buttons to increase and decrease the set time</li>
  <li>The display is still VERY VERY weird</li>
  <li>Temperature conversion is still SOOO WRONG</li>
</ul>

<h3>Version 6</h3>
<img width="1574" height="819" alt="image" src="https://github.com/user-attachments/assets/5e64afc7-3ff6-4845-bbeb-84b9250b7736" />
<ul>
  <li>Found a workaround to read ADC values (taking raw binary value and displaying certain messages depending on the reading)</li>
  <li>Motor actuators are yet to be tweaked with.</li>
</ul>

<h3>Version 7</h3>
<img width="1663" height="599" alt="image" src="https://github.com/user-attachments/assets/6ff1ed1f-1a8b-40ad-92be-c83cebfc8ab9" />
<ul>
  <li>Added in a THIRD 8255 PPI for more I/O Interfacing</li>
  <li>Integrated an 8253 PIT to the system to make timer feature work</li>
  <li>Displays a 'Timer Expired' message upon completion of the timer</li>
  <li>Countdown for decrementing is still slow. Further timer configurations needed.</li>
  <li>Timer integration with motor actuators have still yet to be done.</li>
</ul>

<h3>Version 8</h3>
<img width="1601" height="830" alt="image" src="https://github.com/user-attachments/assets/44a0189a-e5bc-41f9-a152-1652b70c9e57" />
<ul>
  <li>Integrated a "Power Button" that shuts off the entire system</li>
  <li>Timer expiry not only displays corresponding message, stops the Swing Motor from moving</li>
  <li>Power Button only clears LCD (for now). More actuators affected to come</li>
</ul>

<h3>Version 9</h3>
<img width="1593" height="678" alt="image" src="https://github.com/user-attachments/assets/9d855b66-22e3-4cba-80bf-b1b9ac5135c6" />
<ul>
  <li>Timer Expiry now AUTOMATICALLY clears the LCD after some time</li>
  <li>Motor speed optimized (to some extent)</li>
  <li>Other actuators still to be configured to shut down with the Power Button</li>
</ul>

<h3>Version 10</h3>
<img width="1345" height="724" alt="image" src="https://github.com/user-attachments/assets/584c912b-25d9-4471-ad97-61f1ea9e81d2" />
<ul>
  <li>Compressor and Blower Fan Motor now affected with System Shutdown and Power Button (tied to the 3rd PPI)</li>
  <li>Cleaned up and organized simulation system into modularized sections</li>
  <li>Added necessary labels to the necessary sections</li>
</ul>

<h3>Version 11</h3>
<img width="1325" height="410" alt="image" src="https://github.com/user-attachments/assets/7ccebd73-1521-43ce-8f23-cc8394ca4537" />
<ul>
  <li>Fine tuned some bugs in the system</li>
  <li>Added in some comments for Mass Documentation</li>
  <li>COMPLETE READY FOR PROJECT DEFENSE!!!</li>
</ul>

<h3>Version 12</h3>
<img width="1422" height="807" alt="image" src="https://github.com/user-attachments/assets/5e578ab5-dfd9-43fa-89be-70b265ba7676" />
<ul>
  <li>Revisions were needed. Didn't see this coming....</li>
  <li>Added in a second LM35 Temperature Sensor to simulate outside temperature</li>
  <li>Comfigured compressor motor to function in accordance with outside temp and user-set temp</li>
  <li>Interfaced a Fourth PPI and a second ADC for such</li>
</ul>

<h3>Version 13 (FINAL)</h3>
<img width="1500" height="441" alt="image" src="https://github.com/user-attachments/assets/d5d1edb0-e712-457c-93b1-2488baf6782f" />
<ul>
  <li>Adjusted fan motor behavior with mode setting</li>
  <li>Implemented compressor shut-off with timer expiry and power button signalling</li>
  <li>Re-organized project structure</li>
</ul>

</br>
<h3>PROJECT COMPLETION: SUCCESS!!!</h3>






