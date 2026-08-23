# Eddy Current Sensor Driver

This driver is used to control and configure the AMDC Eddy Current Sensor IP core in the FPGA through the AXI4-Lite interface.

## Files
All files for the eddy current sensor driver are in the AMDC-Firmware driver directory ([`sdk/app_cpu1/common/drv/`](https://github.com/Severson-Group/AMDC-Firmware/tree/develop/sdk/app_cpu1/common/drv)).


```
drv/
|-- eddy_current_sensor.c
|-- eddy_current_sensor.h
```

## Connecting and Enabling 

The eddy current sensor adapter board should be connected to one of the GPIO ports on the AMDC with a DB-15 cable. Additionally, the firmware driver must be routed to the connected port via the GPIO Mux (AMDC REV D) or GP3IO Mux (AMDC REV E). See the documentation on the GPIO muxes [here](/firmware/arch/drivers/gpio-mux.md).

As of AMDC Firmware release v1.3, sensors must also be enabled in the [Timing Manager](/firmware/arch/timing-manager) as follows, to be triggered for periodic data sampling:

```C
void timing_manager_enable_sensor(sensor_e sensor)
```
This function enables a sensor in the timing manager for period data sampling. To enable an eddy current sensor for a given GPIO port _N_, "_EDDY_N_" should passed in as the argument for _sensor_.

## Driving the Eddy Current Sensor

```C
void eddy_current_sensor_init(void)
```

This function is called by the BSP and initializes all eddy_current_sensor IP to use the default timing parameters (SCLK frequency and propogation delay).

```C
void eddy_current_sensor_set_timing(uint32_t base_addr, uint32_t sclk_freq_khz, uint32_t propogation_delay_ns)
```
This function can be used to override the default timing parameters for a given eddy current sensor instance.

```C
double eddy_current_sensor_read_x_voltage(uint32_t base_addr)
```

This function reads the X data from the IP data register. The returned data is sign extended 2's compliment 18-bit data.

```C
double eddy_current_sensor_read_y_voltage(uint32_t base_addr)
```

This function reads the Y data from the IP data register. The returned data is sign extended 2's compliment 18-bit data.

## Example Code

```C
///////////////////////////////////
//  In app_controller.c  
///////////////////////////////////

#include "drv/timing_manager.h"

// Other includes and app functions...

void app_controller_init() 
{
  // Set GPIO port 1 on AMDC to eddy current sensor
#if (USER_CONFIG_HARDWARE_TARGET == AMDC_REV_D)
  gpio_mux_set_device(0, 1);
#elif (USER_CONFIG_HARDWARE_TARGET == AMDC_REV_E ) || (USER_CONFIG_HARDWARE_TARGET == AMDC_REV_F)
  gp3io_mux_set_device(GP3IO_MUX_1_BASE_ADDR, 2);
#endif

  // Enable eddy current sensor in timing manager
  timing_manager_enable_sensor(EDDY_1);

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

  // Read X and Y positional data as voltage
  double voltage_x = eddy_current_sensor_read_x_voltage(EDDY_CURRENT_SENSOR_1_BASE_ADDR);
  double voltage_y = eddy_current_sensor_read_y_voltage(EDDY_CURRENT_SENSOR_1_BASE_ADDR);


  // Use the positional data
  my_bearing_control_function(voltage_x, voltage_y);

  return;
}
```