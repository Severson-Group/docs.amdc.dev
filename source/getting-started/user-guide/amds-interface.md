# AMDS Interface

This document describes the built-in AMDC drivers which can be used to interface with the AMDS.

```{attention}
Before attempting to use these drivers, make sure to read about the AMDS in [its documentation](/accessories/amds/index.md).
```

## Configure AMDS Hardware

First, the AMDS hardware needs to be configured:

1. Supply 24V power to the AMDS via the screw terminals (LEDs should illuminate)
2. Install the four jumpers which select "daisy-chain" operation of the sensor cards. The daisy-chain mode is marked as `D` on the silkscreen.
3. Install the sensor cards. Since each SPI input is configured as daisy-chain, you need to populate the lower-number sensor cards before the higher, i.e., install 1 before 5. If you do not install the lower-number sensor card, the second sensor card in the daisy chain will not work!

Now that the hardware is configured, the AMDC firmware must be configured.

## Enable AMDS Support

By default, the AMDS drivers are not compiled into the C-code.

To enable, update the `usr/user_config.h` file and set the following define to `1`:

```C
#define USER_CONFIG_ENABLE_MOTHERBOARD_SUPPORT (1)
```
## Command Line Interface

Once the above #define is declared, the hardware will enable an AMDS interface app, this will show up as a set of `mb` commands at bootup. To enable AMDS usage in this app, we need to first route the mux to the appropriate ports. This is done through the `hw mux gpio <port> <device>` command call. 

```{important}
AMDC Rev-D HW and earlier

* `<port>` is `1-2` 
    * For Rev-D hardware utilizing this command interface, the AMDS should be connected to the top #1 port!
* `<device>` should be set to `2` for the AMDS connection

Once the `gpio_mux` is routed we can now make inquiries to the AMDS for data. This is done through the `mb <idx> XXXX` command structure described in the `help` interface. 

*  `<idx>` should be set to `0`
```

```{important}
AMDC Rev-E HW and later
* `<port>` is `1-4` 
* `<device>` should be set to `1` for the AMDS connection
    
Once the `gpio_mux` is routed we can now make inquiries to the AMDS for data. This is done through the `mb <idx> XXXX` command structure described in the `help` interface. 

*  `<idx>` ranges from  `0-3` and should correspond to the port #-1 
```

Try `mb 0 adc on` followed by the `mb 0 samples` command for the latest ADC poll. 
The `counters` command is helpful for debugging connection issues. AMDC keeps several counters to indicate how the hardware is performing. For each byte of data transmitted from the AMDS to AMDC, on counter is incremented within the AMDC's FPGA.
Try `mb 0 counters` and see the outputs. The value of `V` should be non-zero if the connection is active!
`V` is "valid" means the byte of data recieved is valid.
`C` is "corrupt" when the full data byte was recieved, but the UART parity check fails (typically due to noise, emi, etc).
`T` is "timeout" when the AMDC expected a byte from the AMDS, but it never showed up! Thhis happens continuously when the cable is unplugged.

## Configure GPIO/GP3IO Mux in Code

Since the AMDS can be plugged into any of the GPIO ports, the AMDC needs to be configured for the appropriate GPIO port.

```{important}
AMDC Rev-D and earlier utilizing gpio_mux

Use the `gpio_mux` FPGA IP block to configure the routing path. 

Place the header file in the custom user app .c file

```C
#include "drv/gpio_mux.h"
```
Place the code below into your custom user app init function. Modify the the first variable in the function call to match the physical port connection joining the AMDC with the AMDS.  Note this is zero index and the GPIO port per the silk screen is 1's indexed!

```C
    // Configure GPIO mux
    // 0: top port on AMDC
    // 1: bot port on AMDC, ect
    // GPIO_MUX_DEVICE1: Eddy current I/O IP block in the FPGA
    // GPIO_MUX_DEVICE2: AMDS interface I/O IP block in the FPGA
       gpio_mux_set_device(0, GPIO_MUX_DEVICE2);
```

```{important}
AMDC Rev-E and later utilizing gp3io_mux

Similar process as above, except the file and function call are now `gp3io`, and the `_DEVICE#` has swapped.

Include the header file in the custom user app .c file

```C
#include "drv/gp3io_mux.h"
```
Place the code below into your custom user app init function. Modify the `GP3IO_MUX_#_ADDR` define to match the physical port connection joining the AMDC with the AMDS.

```C
    // Set up GPIO mux for the AMDS board
    // GP3IO_MUX_1_BASE_ADDR means top AMDC port
    // GP3IO_MUX_DEVICE1 is AMDS IP block
    // GP3IO_MUX_DEVICE2 is Eddy Current Sensor IP block
       gp3io_mux_set_device(GP3IO_MUX_2_BASE_ADDR, GP3IO_MUX_DEVICE1);
```


## Trigger Sampling

The AMDC firmware drivers trigger AMDS sensor sampling synchronous to both the peak and valley of the PWM carrier triangle wave.
When AMDS support is enabled, the sampling is automatically enabled.

## Request Data

The sampled data on the AMDS must be transferred to the AMDC.
This operation can occur in the background by setting the following define to `1` in the `usr/user_config.h` file:

```C
#define USER_CONFIG_ENABLE_MOTHERBOARD_AUTO_TX (1)
```

The `AUTO_TX` mode triggers the data to be sent to the AMDC **after** all tasks have executed in the time slice.
By definition, this causes a one sample delay in the sensed data used by the control algorithm.
However, it ensures that consistent new data is always available to the control task.
For most applications, this is acceptable.

If one sample delay is not acceptable for your application, keep the `AUTO_TX` mode disabled (i.e. set the define to `0`).
You must manually request data at the start of the control task, and then wait for the data to arrive before running the controller.
This reduces the time usable to compute the controller outputs since requesting and transmitting data from the AMDS is not instantaneous.

To request new data from the AMDS, call `motherboard_request_new_data()` from `drv/motherboard`.
The FPGA IP core currently does not expose a signal indicating when the data returns from the AMDS and is valid.
A skilled FPGA developer could alter the `amdc_motherboard` IP core to expose the signals `is_dout_valid0` and `is_dout_valid1` implemented in the `hdl/..._AXI.v` module.
For now, the `AUTO_TX` mode should be used.

## Use Sampled Data

User code can read the raw 16-bit signed integer value as sampled on the AMDS sensor cards by using the following driver:

```C
int motherboard_get_data(mb_channel_e channel, int32_t *out);
```

Note that `get_data()` is **non-blocking** -- it will return the latest valid data that the AMDS sent, but will not trigger new data to be sent.
This matches how the integrated ADCs work on the AMDC.

For example, in a task callback:

```C
void task_callback(void)
{
    // ...

    // Read in integer value sampled on the AMDS from channel 1:
    int32_t out;
    int err = motherboard_get_data(MB_IN1, &out);

    // Now, "out" contains the sign-extended 16-bit sampled value

    // ...
}
```
