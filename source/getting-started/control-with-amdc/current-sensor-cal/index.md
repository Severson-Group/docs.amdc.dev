# Current Sensor Calibration

## Background

Current sensors provide the necessary current measurement feedback to the control system in a motor drive. This document describes a method to calibrate the current sensors during commissioning of the motor drive

## Current Measurement System

Current sensor is a transducer which produces a voltage signal proportional to the current flowing through the sensor. There are different types of current sensors relying on different physical phenomenons such as a shunt and hall-effect type current sensors. For the purpose of this document no assumption is made on the type of sensor system used. However, it is worth noting that the AMDS accessory board along with the current sensor card makes for a ready sensing solution to be paired with the AMDC.

## Method

The method described below assumes that the user is in the process of commisioninig a three phase motor drive and is hence wanting to calibrate the current sensors. Typically, each phase is 3 phase motor will have a current sensor associated with it. Hence each of the current sensor needs to be calibrated. The same method maybe extended to any multi-phase machines.

1. Connect a current clamp to the phase U of the motor.
1. Hook up the current clamp to an oscilloscope so that the reading of the current clamp maybe monitored in real-time.
1. Log the raw reading of the current sensor. Incase of using AMDS, the AMDS driver functions can be used to get the sensor reading.
1. First, note the sensor reading when no current is flowing through phase A.
1. Next, apply a differential open loop voltage on phase A to result in some current flowing through phase A. The value of voltage is left to the discretion of the user based on the system they are using.
1. Note down the sensor reading as well as the true current flowing through the cable using the current clamp
1. Progressively increase the applied voltage and note down the readings. It is recommended to go up until the rated value of current is flowing through phase cable
1. Tabulate the measurements as shown in table.
1. Fit a linear expression of the form $ \text{Reading [V]} = \text{Gain} \times \text{Current [A]} + \text{Offset [V]}$
1. For the data presented


| Actual Current [A]|Sensor Reading [V]|
| --- | --- |
 | 0 |4.703 |
 | 2.952 |6.602|
| 6.06 |8.53 |
| 9.44 |10.584|
| 16.68 |15.1 |
| 24.5 |20 |

```{tip}
It is a good idea to have negative currents in the data points as well.
```
## Conclusion





