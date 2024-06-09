# Current Sensor Calibration

## Background

Motor drives typically require current sensors to provide feedback to the control system. This document describes a method to calibrate the current sensors to a linear model during commissioning of a motor drive. The calibration is characterized by two parameters, a gain and an offset.

Current sensors are transducers which produce an output signal (either current or voltage) proportional to the primary current flowing through the sensor. There are different types of current sensors relying on different physical phenomenons such as shunt resistors and hall-effect. For the purpose of this document, the specific type of sensor does not matter---just that the output signal is linear with the primary current, and that it is measurable by the control system. The current sensor needs to be calibrated against an appropriate reference before it can be used in the control system. This reference is a known, trusted current sensor, such as a precision digital multimeter (preferred), hall-effect current clamp, or the setpoint of a DC power supply. While the manufacturer datasheet provides nominal parameters, calibration of the current sensor is necessary to get accurate measurements to account for any deviation due to process variation.

## Calibration Method

<img src="./resources/current_sensor_drawing.svg" width="50%" align="center"/>

A method is now provided to calibrate the current sensors connected to a three phase motor drive as shown in the figure. Typically, each phase will have a current sensor associated with it that needs to be calibrated. The same method can be easily extended to any multi-phase machine.

1. Connect the reference curent sensor (i.e. precision digital multimeter) to the phase U cable of the motor.
1. Set up your AMDC system to enable you to log the raw reading of the drive's current sensor attached to phase U. It is recommended to use the AMDC's logging functionality so that data can be collected over a period of time (e.g. 100 ms) and post-processed to find the average value.
1. Record the drive's sensor reading when there is no current flowing through phase U. _Hint:_ remember to calculate this value as the average of a period of time.
1. Cause a "small" curent to flow through phase U (i.e., apply a voltage across phase U). The value of current is left to the discretion of the user based on the system nominal ratings.
1. Record the drive's sensor reading as well as the reference sensor's reading of the current flowing through the phase U cable.
1. Progressively increase the phase U current and record the readings. Do this over the full range of rated current, both positive and negative. 
1. Tabulate the measurements as shown in this example [`exp_data.csv` file](./resources/exp_data.csv).
1. Fit a linear expression of the form $\text{Reading [V]} = \text{Gain [V/A]} \times \text{Current [A]} + \text{Offset [V]}$ to the obtained measurements. This [example Jupyter notebook](./resources/current_sensor_calibration.ipynb) is provided to illustrate the process.
1. Repeat the exercise for phases U and V of the system

An example of the results are shown in the plot below. The obtained gain and offset can be used directly in the control code to convert the sensor reading into the actual current measurement.


<img src="./resources/fit.svg" width="50%" align="center"/>

```{tip}
Be sure to conduct the calibration process over the full range of current data (both positive and negative current) to account for any variation in the current sensor reading due to directionality of current.
```

## Use of Calibration data

The below codeblock can be utilized by the user to convert between raw measurements from the sensor and the actual currents.

```C
#define GAIN 0.621 // Gain from curve fit
#define OFFSET 4.739 // Offset from curve fit

double current_measurement; // Actual current measurement, to be used in control algorithm

current_measurement = (sensor_reading - OFFSET)/GAIN;  // sensor_reading is the raw measurement and needs to be obtained by the user

```

## Conclusion

A method to calibrate the current sensors has been presented. The user is also given hints on how the output of the calibration process maybe used in the control code.
