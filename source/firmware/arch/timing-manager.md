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

The User Event Ratio is the ratio "_every N_" PWM carrier events; i.e. the user could override the default ratio of 10, and request that the sensors instead be sampled every 20 valleys. 

#### Sensor Enable Statuses

The timing manager must wait to schedule control tasks until all the user's desired sensors have reported back their data. Therefore the user must enable all their desired sensors within the timing manager so it knows which sensors to wait for and which to ignore.

#### Sensor Done Statuses

Each enabled sensor will be triggered to sample by the timing manager at qualifying PWM carrier events. When a sensor is triggered, its `done` status is reset to 0, until that sensor completes its sampling, makes its new data available, and re-asserts its `done` status to 1 for the timing manager. 

### Outputs

#### Sensor Trigger

Once all enabled sensors are done sampling, the timing manager knows it can send out this trigger to restart the sensors once again at the next qualifying PWM carrier event.

#### Scheduler Interrupt

Once all enabled sensors are done sampling, the manager sends an interrupt from the FPGA to the processor which unblocks the scheduler so that control tasks may be scheduled for execution. If no sensors are enabled, the timing manager will generate the scheduler interrupt immediately on the qualifying PWM carrier event, since it does not have to wait for any sensors to report as done.


### Timing Diagram

The following diagram shows the behaviour of these events: triggers, sensors reporting as done, and generation of scheduler interrupts:

```{figure} images/timing.png
:alt: Timing Manager timing diagram
:figwidth: 100%
:width: 600em
:align: left
```













## Triggering Modes

Automatic vs Manual


## Scheduler Modes

Legacy vs New

## Driver Interface

```C
int timing_manager_interrupt_system_init(void);
void timing_manager_init(void);

// Mode: Automatic vs Manual Triggering
void timing_manager_set_mode(trigger_mode_e mode);
trigger_mode_e timing_manager_get_mode(void);
void timing_manager_send_manual_trigger(void);
uint32_t timing_manager_get_trigger_count(void);

// Set/get user ratio
void timing_manager_set_ratio(uint32_t ratio);
uint32_t timing_manager_get_ratio(void);

// Enable sensors
void timing_manager_select_sensors(uint16_t enable_bits);
void timing_manager_enable_sensor(sensor_e sensor);

// Check done status of sensors
bool timing_manager_is_sensor_done(sensor_e sensor);
bool timing_manager_are_sensors_all_done(void);

// PWM trigger
void timing_manager_trigger_on_pwm_both(void);
void timing_manager_trigger_on_pwm_high(void);
void timing_manager_trigger_on_pwm_low(void);

// Timing acquisition
void timing_manager_isr(void *intc_inst_ptr);
void timing_manager_set_scheduler_source(void);
double timing_manager_get_tick_delta(void);
double timing_manager_expected_tick_delta(void);
double timing_manager_get_time_per_sensor(sensor_e sensor);
void timing_manager_sensor_stats(void);
statistics_t *timing_manager_get_stats_per_sensor(sensor_e sensor);
void timing_manager_clear_isr(void);
```


