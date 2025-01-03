# Timing Manager

This page serves to document the operation and configuration of the AMDC Timing Manager, a system-level IP responsible for aligning sensor sampling, feedback, and control task execution to the PWM-carrier peak/valley for predicatable control and EMI minimization.

The primary audience of this documentation is the AMDC development/maintainers team, but can also be a good reference for users of the platforms seeking to better understand the timing system of the AMDC to better optimize their control.

## Behaviour

The Timing Manager has the followings logical inputs and outputs:

| **Inputs**                    | **Outputs**         |
|-------------------------------|---------------------|
| PWM Carrier (peaks & valleys) | Sensor Trigger      |
| User Event Ratio              | Scheduler Interrupt |
| Sensor Enable Statuses        |                     |
| Sensor Done Statuses          |                     |

### Inputs

#### PWM Carrier

The timing manager receives the peaks and valleys of the switching PWM triangle carrier, as these times are when EMI noise is least-disruptive to the sensor interfaces. The user can configure the timing manager to trigger sensor sampling on every _N_ peaks and/or valleys. The default is 100 kHz PWM frequency, with the timing manager sending a trigger every 10 valleys, or at a 10 kHz frequency.

#### User Event Ratio

The User Event Ratio is the ratio "_every N_" PWM carrier events should trigger the sensors and control task; i.e. the user could override the default ratio of 10, and request that the sensors instead be sampled every 20 valleys. 

#### Sensor Enable Statuses

The timing manager must wait to schedule control tasks until all the user's desired sensors have reported back their data. Therefore the user must enable all their desired sensors within the timing manager so it knows which sensors to wait for and which to ignore.

#### Sensor Done Statuses

Each enabled sensor will be triggered to sample by the timing manager at qualifying PWM carrier events. When a sensor is triggered, its `done` status is reset to 0, until that sensor completes its sampling, makes its new data available, and re-asserts its `done` status to 1 for the timing manager. 

```{important}
When creating new drivers for sensors, the sensor driver's done signal that is reported back to the Timing Manager MUST:

- Be reset to 1
- AND guarantee that the will be done eventually (possibly even time-out)

or else the Timing Manager will never generate the scheduler interrupt, and all code will freeze!
```

### Outputs

#### Sensor Trigger

Once all enabled sensors are done sampling, the timing manager knows it can send out this trigger to restart the sensors once again at the next PWM carrier event that is a multiple of the User Event Ratio.

#### Scheduler Interrupt

Once all enabled sensors are done sampling, the manager sends an interrupt from the FPGA to the processor which unblocks the scheduler so that control tasks may be scheduled for execution. If no sensors are enabled, the timing manager will generate the scheduler interrupt immediately on the qualifying PWM carrier event, since it does not have to wait for any sensors to report as done.


### Timing Diagram

The following diagram shows the behavior of these events: triggers, sensors reporting as done, and generation of scheduler interrupts:

```{figure} images/timing.png
:alt: Timing Manager timing diagram
:figwidth: 100%
:width: 600em
:align: left
```

The diagram shows how the Timing Manager receives the PWM Carrier high and low events. The diagram shows the operation for the Timing Manager configured to trigger every three carrier valleys (trigger on `carrier_low` only, with a 3:1 ratio).

When the first `carrier_low` occurs, the timing manager flushes the PWM duty ratios and triggers the three enabled sensor interfaces to begin sampling. Sensor 1 reports that it is done acquiring new data practically immediately, with Sensor 3 reporting done shortly thereafter. 

After a while, Sensor 2 reports done as well. Since all three sensors have reported done (`all_done`), the timing manager generates the scheduler interrupt from the FPGA to the ARM processor, and the scheduler code takes control of the processor and begins scheduling control task code to run.

The control code will run, update the PWM duty ratios, and eventually yield the processor back to the scheduler. Ideally, all tasks that need to be scheduled to run in this timeslice will complete with some time left before the third (the 3:1 ratio, in this example) `carrier_low` event, where the cycle will begin again. If the tasks are not all able to complete, the ratio may have to be increased.


## Triggering Modes

The Timing Manager can be configured to trigger sensors in one of two modes:
- Automatic - triggering on every valid PWM carrier event (as defined by the PWM peak/valley configuration and the User Event Ratio) automatically **(default)**
- Manual - a single trigger mode useful for debugging, where the user can send a command via the command interface to queue a single trigger, which will be sent out by the Timing Manager at only the next qualifying event

This configuration can be done via the C driver interface (given below).


## Scheduler ISR Modes

The Timing Manager can be configured to generate a scheduler interrupt in one of two modes:
- "Legacy" Mode: The scheduler interrupt is generated only based on the PWM configuation and user ratio, and does not wait for sensor interfaces to report `done`. To maintain backwards-compatibility, this is the **default** setting. 
- "Post-Sensor" Mode: The scheduler interrupt is only generated when all sensors enabled via the Timing Manager report `done`. If no sensors are enabled, the scheduler interrupt is generated in the way as the Legacy Mode.

This configuration must be set before code compilation and flashing using the `USER_CONFIG_ISR_SOURCE` definition in `usr/user_config.h`.

```{warning}
When the scheduler checks to see if a task should be scheduled in scheduler_run(), the task's measured loop time is subtracted from the desired loop time. If the former is larger than the latter, the result will be negative and obviously the task should be scheduled. However, it is possible with floating point numbers that the measured loop time will be *just less* than the target loop time, in which case the subtraction result will be a very small positive number. We still want the task to be run in this case, so instead of checking if the subtraction result is less than 0, we check that it is less than a very small positive variance value. This variance has been defaulted to 60ns, but if a user is running their AMDC with "abnormal" timing settings, the magnitude of the tolerance may need to be overridden in user_config.h
```

## Driver Interface

```C
// Initialization functions
void timing_manager_init(void);
int timing_manager_interrupt_system_init(void);
```

These functions are used to initialize the Timing Manager to the default start-up configuration (no sensors enabled, trigger generation every 10 PWM Carrier valleys), and to enable the FPGA-ARM interrupt for the scheduler. The initialization is handled in `main.c`.

```C
// Automatic and Manual Triggering Mode 
void timing_manager_set_mode(trigger_mode_e mode);
trigger_mode_e timing_manager_get_mode(void);
void timing_manager_send_manual_trigger(void);
uint32_t timing_manager_get_trigger_count(void);
```

These functions are used to modify the trigger and debug the sensor interface. The trigger can be put into a single-trigger "Manual Mode" where the user can request that one trigger be sent at only the next PWM event, instead of all qualifying events ("Automatic Mode").

```C
// PWM event configuration
void timing_manager_trigger_on_pwm_both(void);
void timing_manager_trigger_on_pwm_high(void);
void timing_manager_trigger_on_pwm_low(void);

// Set/get User Event Ratio
void timing_manager_set_ratio(uint32_t ratio);
uint32_t timing_manager_get_ratio(void);
```

The functions allow the user to modify the PWM event configuration. By default, sensors are triggered every 10 PWM carrier valleys (`pwm_low`); however with these functions, the Timing Manager can be configured to align triggers to any multiple of PWM carrier peaks and/or valleys.

```C
// Enable/Disable sensors
void timing_manager_select_sensors(uint16_t enable_bits);
void timing_manager_enable_sensor(sensor_e sensor);
```

These functions are commonly used to set which sensor interfaces the Timing Manager should send triggers through to. Sensors can be enabled one-at-a-time with the `timing_manager_enable_sensor()` function, or in a batch by passing the proper value to `timing_manager_select_sensors()`. To disable triggering on all sensor interfaces, pass zero to this function: `timing_manager_select_sensors(0)`.

```C
// Check 'done' status of sensors
bool timing_manager_is_sensor_done(sensor_e sensor);
bool timing_manager_are_sensors_all_done(void);
```

These functions allow the user to check which sensor interfaces are done sampling new data.

```C
// Interrupt and Scheduler Interface
void timing_manager_isr(void *intc_inst_ptr);
void timing_manager_clear_isr(void);
void timing_manager_set_scheduler_source(void);
double timing_manager_get_tick_delta(void);
double timing_manager_expected_tick_delta(void);
```

These functions deal with the Timing Manager->Scheduler (FPGA->ARM) interrupt. `timing_manager_isr()` and `timing_manager_clear_isr()` are interrupt service routine (which starts the scheduler) and the interrupt clear function, respectively.

`timing_manager_set_scheduler_source()` is called during Timing Manager initialization, and configure the scheduler interrupt to either be generated in sync with the trigger (Legacy Mode), or after the sensors have all reported done (Post-Sensor Mode), depending on the value of `#define USER_CONFIG_ISR_SOURCE` in `user_config.h`.

`timing_manager_get_tick_delta()` reports the true measured time in microseconds between ISR calls for the scheduler, which needs to know the elapsed time for proper control. `timing_manager_expected_tick_delta()` reports what this time *should be* based on the user's configuration of the Timing Manager, which is needed in `log.h` to determine the logging task's update frequency.

It is not recommended for users to mess with these functions directly unless the impacts of doing so are understood!

```C
// Measure sensors' data acquisition time
double timing_manager_get_time_per_sensor(sensor_e sensor);
void timing_manager_sensor_stats(void);
statistics_t *timing_manager_get_stats_per_sensor(sensor_e sensor);
```

These functions allow the user to access statistics for each sensor interface, namely the data acquisition time in microseconds, via `timing_manager_get_time_per_sensor()`. 
