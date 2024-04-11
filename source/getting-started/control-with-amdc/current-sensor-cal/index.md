# Current Sensor Calibration

## Background

Current sensors provide the necessary current measurement feedback to the control system in a motor drive. This document describes a method to calibrate the current sensors during commissioning of the motor drive, and arrive at the calibration parameters, gain and offset .Current sensor is a transducer which produces a voltage signal proportional to the current flowing through the sensor. There are different types of current sensors relying on different physical phenomenons such as a shunt resistor and hall-effect type current sensors. For the purpose of this document no assumption is made on the type of sensor system used. The current sensor needs to be calibrated against an appropriate reference before they can be used in the control system. While the manufacturer datasheet maybe relied up on to get nominal parameters, calibration of the current sensor is necessary to get accurate measurements to account for any deviation due to process variation.

## Method

<img src="./resources/current_sesnor_drawing.svg" width="100%" align="center"/>

The method described below assumes that the user is in the process of commisioninig a three phase motor drive and hence wants to calibrate the current sensors. Typically, each phase in a 3 phase motor will have a current sensor associated with it. Hence each of the three current sensors need to be calibrated. The same method maybe extended to any multi-phase machines. The method is described below

1. Connect a current clamp to the phase U cable of the motor. A typical current clamp which can be used for this experiment is pictured below.
1. Hook up the current clamp to an oscilloscope so that the reading of the current clamp can be monitored in real-time.
1. Log the raw reading of the current sensor using the logging functionality in the AMDS. Incase the user is using AMDS, the AMDS driver functions can be used to get the sensor reading.
1. First, note the sensor reading when no current is flowing through phase U.
1. Next, apply a differential open loop voltage on phase U to cause some some current to flow through phase U cable. The value of voltage is left to the discretion of the user based on the system nominal ratings.
1. Note down the sensor reading as well as the true current flowing through phase U cable using the current clamp.
1. Progressively increase the applied voltage and note down the readings. It is recommended to go up until the rated value of the current is flowing through phase U cable
1. Tabulate the measurements as shown in table below.
1. Fit a linear expression of the form $\text{Reading [V]} = \text{Gain [V/A]} \times \text{Current [A]} + \text{Offset [V]}$ to the obtained measurements
1. For the data presented, the fitted equation is $\text{Reading [V]} = 0.6228 \times \text{Current [A]} + 4.7303$.
1. Now the obtained gain and offset can be used in the control code to convert the sensor reading into the actual current measurement.
1. Repeat the exercise for phases U and V of the system



| Actual Current [A]|Sensor Reading [V]|
| --- | --- |
 | 0 |4.703 |
 | 2.95 |6.60|
| 6.06 |8.53 |
| 9.44 |10.58|
| 16.68 |15.10 |
| 24.5 |20.00 |

```{tip}
It is a good idea to have negative currents in the data points as well to account for any variation in the current sensor due to directionality of current.
```


## Conclusion

A method to calibrate the current sensors has been presented. The user is also given hints on how the output of the calibration process maybe used in the control code.
