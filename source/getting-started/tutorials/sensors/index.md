# Tutorial: Sensor Configuration, Feedback, & Profiling

- **Goal:** Learn how to use the AMDC Timing Manager to get feedback from sensors
- **Complexity:** 4 / 5
- **Estimated Time:** TODO


## Tutorial Requirements

1. Working AMDC Hardware
2. Completion of the [Hardware Commands](/getting-started/tutorials/hw-commands/index.md) tutorial
3. Completion of the [Voltage Source Inverter](/getting-started/tutorials/vsi/index.md) tutorial
4. Completion of the [Profiling Tasks](/getting-started/tutorials/profiling-tasks/index.md) tutorial

## Introduction 

The timing manager is added in version 1.3 to allow for syncing control tasks and sensor queries to the pwm carrier.

This tutorial provides the source code for:
* extending the functionality of the [Voltage Source Inverter](/getting-started/tutorials/vsi/index.md) into a closed loop control system

## Scheduling and Synchronizing:

![](images/timing.png)

Read [this docs page](/firmware/arch/timing-manager.md) for detailed information on the timing manager

The AMDC synchronizes running tasks and sensor collection to the PWM carrier wave. Every X PWM periods (where X is set by the function timing_manager_set_ratio()), the AMDC will collect data from sensors. In Legacy mode, the AMDC will run control tasks concurrently with sensor collection. In Synchronized mode the AMDC will not run control tasks until the sensor collection is complete. Lets enable Synchronized mode in the `user_config.h` file by setting `USER_CONFIG_ISR_SOURCE` to `1`

```
// Specify the source of the scheduler ISR
// Mode 0: legacy mode - scheduler is triggered based on the PWM carrier events and ratio
//         of carrier frequency to desired control frequency
// Mode 1: synchronized mode - scheduler is triggered when all the enabled sensors are done
//         acquiring their data
#define USER_CONFIG_ISR_SOURCE (1)
```

There are multiple factors that affect when and how fast control tasks run.
 - User set TASK_UPDATES_PER_SEC
 - PWM Frequency
 - timing manager event ratio
 - Sensor collection time (synchronized mode)
 - Control task time (how long it takes for the control task to run)

Consider: Control tasks only have the opportunity to run once every `event_ratio` PWM periods. If the `PWM frequency` / `event_ratio` < `TASK_UPDATES_PER_SEC`, then the control task will run at a slower rate than `TASK_UPDATES_PER_SEC`. Additionally, if the `event_ratio` / `PWM frequency` > Sensor collection time, then the control tasks will never have an opportunity to run (in synchronized mode), since all time will be spent waiting for sensors to finish collecting. This gives us both a lower and upper bound for these parameters. We also have to ensure that 1 / `TASK_UPDATES_PER_SEC` > Control task time, otherwise we are not able to run a control task in the time slot allotted.

Lets enable one of the sensors to start observing the effects of the timing manager. In the `controller_init()` function, enable the ADC (analog to digital converter) with `timing_manager_enable_sensor(ADC)`.

To get data from the ADC, use the function `analog_getf(ANALOG_IN1, &output)`. Read about the analog channel mapping on the [analog input page](/hardware/subsystems/analog.md)

To understand the specific timings of sensor collection and tasks, we need to know the specific numbers of the factors that control tasks.
 - User set `TASK_CONTROLLER_UPDATES_PER_SEC` is set in `task_controller.h`, it is (10000)
 - `PWM frequency` can be set with a hardware command `hw pwm sw`, but the default value is in `common/drv/pwm.h` at (100000.0)
 - timing manager `event ratio` is set in `common/drv/timing_manager.c` in the `timing_manager_init()` function. It is set to `TM_DEFAULT_PWM_RATIO`, which is 10.
 - Sensor collection time for the ADC can be gathered with the hardware command `hw tm time adc` or the C function `timing_manager_get_time_per_sensor(ADC)`. It is around 0.86 microseconds. This will be affected by the ADC clock, which is set in `common/drv/analog.h` to `ANALOG_CLKDIV4`, and can be set by the user with the `analog_set_clkdiv()` function.
 - The control task time can be gathered with the user-made command `ctrl stats print`. We are specifically looking at the Run-Time.

### We can now draw our timing diagram with exact parameters:

![](images/tmVSI.svg)

We can see that we are sampling the sensors once per control task. That's because our event ratio of 10 fits perfectly with the ratio between the PWM frequency and our control task's frequency. This is the gold standard. In this tutorial we will experiment with changes to the parameters of the timing manager and observe the effects on control task timings.

## Experiment 1 - Ratio is too large

If we increase the timing manager's `event ratio`, we can cause the control task to run at less than 10Khz. Lets increase it to 20 by putting `timing_manager_set_ratio(20)` in the `controller_init()` function.

```
void app_controller_init(void)
{
    // Enable data sampling for ADC
    timing_manager_enable_sensor(ADC);
    // set timing manager event ratio
    timing_manager_set_ratio(20);
    // Register "ctrl" command with system
    cmd_controller_register();
}
```

Now use the command `ctrl stats print` to view the loop time (after doing `ctrl init`).

![](images/tmVSI20.svg)

```
Task Stats:
Loop Num:	26806 samples
Loop Min:	193.78 usec
Loop Max:	206.22 usec
Loop Mean:	200.00 usec
Loop Var:	0.02 usec
Run Num:	26932 samples
Run Min:	3.25 usec
Run Max:	4.23 usec
Run Mean:	3.41 usec
Run Var:	0.00 usec
```

The loop time is how much time there is between successive executions of the control task. It should be 1 / `TASK_CONTROLLER_UPDATES_PER_SEC`, but in this case it is double of that. That indicates that the control task is only running at half of `TASK_CONTROLLER_UPDATES_PER_SEC`.

Making the timing manager's `event ratio` too high is one way that control tasks can be slowed down past their target `TASK_CONTROLLER_UPDATES_PER_SEC`.

## Experiment 2 - Multiple sensor samples per control task

By decreasing the timing manager's `event ratio`, we can cause multiple sensor samples to occur before one cycle of the control task.

Here's the timing diagram using an `event ratio` of 1.

![](images/tmVSI1.svg)

There are 10 sensor samples for every control task. Lets look at the stats:

```
Task Stats:
Loop Num:	48373 samples
Loop Min:	80.46 usec
Loop Max:	119.44 usec
Loop Mean:	100.00 usec
Loop Var:	0.24 usec
Run Num:	48624 samples
Run Min:	9.85 usec
Run Max:	17.02 usec
Run Mean:	10.25 usec
Run Var:	1.40 usec
```

The loop time has returned to 100.00 usec. The timing manager is not slowing down the rate of the control task anymore.

But the Run time has increased significantly. Why is that?

The answer is that I have no idea. Ask Patrick

## Experiment 3 - Changing PWM frequency

Another way to impact loop time is to change the PWM frequency. Lets return to the situation with an event ratio of 10, but this time modify the PWM ratio from 100KHz to 50KHz. We can do this by adding the code `pwm_set_switching_freq(50000)` to our init function (remember to `#include "drv/pwm.h"` at the top of the file).

```
void app_controller_init(void)
{
    // Enable data sampling for ADC
    timing_manager_enable_sensor(ADC);
    // set timing manager event ratio
    timing_manager_set_ratio(20);
    // set PWM frequency
    pwm_set_switching_freq(50000);
    // Register "ctrl" command with system
    cmd_controller_register();
}
```

```
Task Stats:
Loop Num:	8349 samples
Loop Min:	193.91 usec
Loop Max:	206.22 usec
Loop Mean:	200.00 usec
Loop Var:	0.05 usec
Run Num:	8475 samples
Run Min:	3.24 usec
Run Max:	4.00 usec
Run Mean:	3.37 usec
Run Var:	0.00 usec
```

The loop time is back to 200us. Here is the timing diagram:

![](images/tmVSI50.svg)

## TODO

ISR Generation mode: Legacy vs New Mode
- when it makes an impact
- how to use the `is_sensor_done` in a loop to poll/stall in Legacy Mode
