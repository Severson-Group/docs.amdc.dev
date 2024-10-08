# Tutorial: Sensor Configuration, Feedback, & Profiling

- **Goal:** Learn how to use the AMDC Timing Manager to get feedback from sensors
- **Complexity:** 4 / 5
- **Estimated Time:** TODO


## Tutorial Requirements

1. Working AMDC Hardware
2. Completion of the [Hardware Commands](/getting-started/tutorials/hw-commands/index.md) tutorial
3. Completion of the [Voltage Source Inverter](/getting-started/tutorials/vsi/index.md) tutorial

## Introduction 

## Step 1:

## Step 2:

## Step 3:

## Step 4:

## Step 5:

## Conclusion



Enabling/disabling sensors - INCLUDE EXAMPLE OF DOING THIS IN THE USER APP INIT FUNCTION
- Enable in the timing manager with `timing_manager_enable_sensor()`
- If peripheral, still need to configure GPIO port!! i.e. `gp3io_mux_set_device()`

Getting Sensor data
- This depends on which sensor interface(s) is(are) being used 

Profiling sensor acquisition times `timing_manager_get_time_per_sensor()`

ISR Generation mode: Legacy vs New Mode
- when it makes an impact
- how to use the `is_sensor_done` in a loop to poll/stall in Legacy Mode

changing timing settings - PWM freq, peaks/valleys, ratio
- How "bad" settings will affect task loop time

Timing Manager debug features?
- Trigger mode AUTO vs MANUAL?


```{warning}
When the scheduler checks to see if a task should be scheduled in scheduler_run(), the task's measured loop time is subtracted from the desired loop time. If the former is larger than the latter, the result will be negative and obviously the task should be scheduled. However, it is possible with floating point numbers that the measured loop time will be *just less* than the target loop time, in which case the subtraction result will be a very small positive number. We still want the task to be run in this case, so instead of checking if the subtraction result is less than 0, we check that it is less than a very small positive variance value. This variance has been defaulted to 60ns, but if a user is running their AMDC with "abnormal" timing settings, the magnitude of the tolerance may need to be overridden in user_config.h
```
