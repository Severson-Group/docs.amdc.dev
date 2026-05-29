# Encoder Driver

This driver is used to configure and read the AMDC Encoder IP core in the FPGA through the AXI4-Lite interface. Read more about the [encoder hardware here](/hardware/subsystems/encoder.md).

## Files
All files for the encoder driver are in the AMDC-Firmware driver directory ([`sdk/app_cpu1/common/drv/`](https://github.com/Severson-Group/AMDC-Firmware/tree/develop/sdk/app_cpu1/common/drv)).


```
drv/
|-- encoder.c
|-- encoder.h
```

## Enabling the Encoder

As of AMDC Firmware release v1.3, sensors must be enabled in the [Timing Manager](/firmware/arch/timing-manager) as follows, to be triggered for periodic data sampling:

```C
void timing_manager_enable_sensor(sensor_e sensor)
```
This function enables a sensor in the timing manager for period data sampling. To enable the encoder "_ENCODER_" should passed in as the argument for _sensor_.

## Retrieving Encoder Data

The encoder data (total raw *steps* since FPGA startup and absolute rotation *position*) is sampled and reported both instantaneously and at PWM-carrier events (via the timing manager triggers). C code functions exist in the driver to read both the instantaneous and PWM-synced  values.

```C
void encoder_init(void);
```
This function is called by the BSP and initializes the encoder IP to use the default value for pulses per revolution.

```C
void encoder_set_pulses_per_rev_bits(uint32_t bits);
void encoder_set_pulses_per_rev(uint32_t pulses);
```
These functions can be used to override the number of encoder pulses per revolution, specified as bits or pulses respectively.

```C
void encoder_get_steps(int32_t *steps);
void encoder_get_position(uint32_t *position);
```
These functions can be used to retrieve the encoder data, raw steps or absolute position. These functions will return the requested data as it was sampled at the last timing manager trigger, synchronized with the PWM carrier. 

```C
void encoder_get_steps_instantaneous(int32_t *steps);
void encoder_get_position_instantaneous(uint32_t *position);
```
These functions can be used to retrieve the encoder data, raw steps or absolute position. These functions will return the requested data "instantaneously" (within the last 5ns FPGA clock).

```C
void encoder_find_z(void);
```
Triggers the state machine which detects the encoder Z-pulse, which is used to find the absolute position.


## Example Code

```C
///////////////////////////////////
//  In app_controller.c  
///////////////////////////////////

#include "drv/timing_manager.h"

// Other includes and app functions...

void app_controller_init() 
{
  // Enable eddy current sensor in timing manager
  timing_manager_enable_sensor(ENCODER);

  // More Initialization code...

  return;
}
```

```C
///////////////////////////////////
//  In task_controller.c   
//////////////////////////////////

#include "drv/encoder.h"

// Other includes and functions...

void task_controller_callback(void *arg)
{
  // Other callback code...

  // Read the absolute encoder position as of the previous timing manager trigger
  uint32_t pos;
  encoder_get_position(&pos);

  // Use the positional data
  my_bearing_control_function(pos);

  return;
}
```