# AMDS Interface

This document describes the built-in AMDC drivers which can be used to interface with the AMDS.

```{attention}
Before attempting to use these drivers, make sure to read about the AMDS in [its documentation](/accessories/amds/index.md).
```

## Configure AMDS Hardware

First, the AMDS hardware needs to be configured:

1. Supply 24V power to the AMDS via the screw terminals (LEDs should illuminate)
2. Install the four jumpers which select "daisy-chain" operation of the sensor cards. The daisy-chain mode is marked as `D` on the silkscreen.
3. Install the sensor cards. Since each SPI input is configured as daisy-chain, you need to populate the lower-number sensor cards before the higher, i.e., install 1 before 5. If you do not install the lower-number sensor card, the second sensor card in the daisy chain will not work.

Now that the hardware is configured, the AMDC firmware must be configured.

## Enable AMDS Support

By default, the AMDS drivers are not compiled into the C-code.

To enable, update the `usr/user_config.h` file and set the following define to `1`:

```C
#define USER_CONFIG_ENABLE_AMDS_SUPPORT (1)
```

### Command Line Interface

Once the above #define is declared, the hardware will enable an AMDS interface app, this will show up as a set of `amds` commands at bootup. To enable AMDS usage in this app, we need to first route the mux to the appropriate ports. This is done through the `hw mux gpio <port> <device>` command call. 

#### AMDC REV D

- `<port>` is `1-2` -- for REV D hardware utilizing this command interface, the AMDS should be connected to the top #1 port.
- `<device>` should be set to `2` for the AMDS connection

Once the `gpio_mux` is routed, we can now make inquiries to the AMDS for data. This is done through the `amds <port> XXXX` command structure described in the `help` interface. Note that `<port>` should be set to `0`.

#### AMDC REV E and beyond

- `<port>` is `1-4` 
- `<device>` should be set to `1` for the AMDS connection
    
Once the `gpio_mux` is routed, we can now make inquiries to the AMDS for data. This is done through the `amds <port> XXXX` command structure described in the `help` interface. Note that `<port>` ranges from `1-4` and should correspond to the GPIO port number your AMDS is connected to.

### Configure GPIO/GP3IO Mux in Code

Since the AMDS can be plugged into any of the GPIO ports, the AMDC needs to be configured for the appropriate GPIO port.

#### AMDC REV D

Use the `gpio_mux` FPGA IP block to configure the routing path. 

Place the header file in the custom user app .c file

```C
#include "drv/gpio_mux.h"
```

Place the code below into your custom user app init function. Modify the the first variable in the function call to match the physical port connection joining the AMDC with the AMDS.  Note this is zero-indexed and the GPIO port per the silk screen is one-indexed.

```C
// Configure GPIO mux
// 0: top port on AMDC
// 1: bot port on AMDC
// GPIO_MUX_DEVICE1: Eddy current I/O IP block in the FPGA
// GPIO_MUX_DEVICE2: AMDS interface I/O IP block in the FPGA
gpio_mux_set_device(0, GPIO_MUX_DEVICE2);
```

#### AMDC REV E and beyond

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

## Requesting and Retrieving Data from the AMDS

Triggering data acquisition on the AMDS is done via the AMDC Timing Manager. After enabling the AMDS (on the correct port) via the Timing Manager, the AMDS will be included when all enabled sensors are triggered by the Timing Manager. Sensors are triggered in sync with the peaks and/or valleys of the PWM carrier. To learn more about how to enable sensors and how to configure triggering, please read the documentation for the [Timing Manager](/firmware/arch/systems.md).

After the AMDS is triggered to begin sampling, each sensor card populated on the AMDS will sample and provide the data the the processor on the mainboard. As soon as the mainboard has collected all the data from the sensor cards, the mainboard will automatically send all the data back to the AMDC, where the data for each sensor card will be made available in the corresponding channel's data register. To learn more about the firmware interface between the AMDC and AMDS please see the [AMDS Firmware documentation](/accessories/amds/firmware/index.md), and the AMDC driver code ([FPGA code](https://github.com/Severson-Group/AMDC-Firmware/tree/develop/ip_repo/amdc_amds_1.0) and [C driver](https://github.com/Severson-Group/AMDC-Firmware/blob/develop/sdk/app_cpu1/common/drv/amds.c)). 

## Use Sampled Data

After the data has been transmitted back to the AMDC from the AMDC, it can be used by the user application.
User code can read the raw 16-bit signed integer value as sampled on the AMDS sensor cards by using the following driver:

```C
int amds_get_data(uint8_t port, amds_channel_e channel, int32_t *out)
```

Note that `get_data()` is **non-blocking** -- it will return the latest data that the AMDS sent, but will not trigger new data to be sent. This matches how the integrated ADCs work on the AMDC.

**NOTE**: The AMDS driver will make *all* data received from the mainboard available, even if the data became corrupted during transmission back to the AMDC.

Therefore, the user should also make use of the `check_data_validity()` function to verify that the data returned by `get_data()` was not corrupted during transmission. This function will return a byte (eight bits) where each bit represents the data validity for one of the eight channels on the AMDS. If this function returns 255, that implies that all channels returned valid data:

```C
uint8_t amds_check_data_validity(uint8_t port)
```

For example, in a task callback:

```C
void task_callback(void)
{
    // ...

    int32_t out;

    // Check validity of latest data for the AMDS plugged into GPIO port 2
    uint8_t valid = amds_check_data_validity(2);

    if (valid & AMDS_CH_1_VALID_MASK != 0) {
        // Yay! Channel 1's data is valid
        // Read in integer value sampled on the AMDS (plugged into GPIO port 2) from channel 1:
        int err = amds_get_data(2, AMDS_CH_1, &out);

        // Now, "out" contains the sign-extended 16-bit sampled value
    }
    else {
        // Else, you decide what to do if a given channel did not provide valid data this cycle

        // ...
    }

    // ...
}
```



## Debugging

The AMDS-AMDC digital interface sometimes needs debugging if valid data does not appear from the AMDC drivers.

### Trigger a Single Transmission

*In the following commands, replace `1` with the GPIO port number of your AMDS board.*

1. Turn off automatic sensor triggering by switching the Timing Manager mode: `hw tm mode MANUAL`
2. Instruct the timing manager to send a single sensor trigger on the next PWM carrier peak/valley: `hw tm send_trigger`
3. Print the validity of the new sample data: `amds 1 valid`
4. Print the received sample data to the terminal: `amds 1 data`

The process above allows for scope-level debugging since you are manually triggering everything to happen.

### AMDS Driver Counters

The AMDC uses a FPGA IP block for the AMDS interface driver.
It keeps track of the performance of the digital link to the AMDS via several counters in the FPGA.
For each byte of data transmitted from the AMDS to AMDC, one counter is incremented within the FPGA driver.

At any time, you can read the counters via: `amds 1 counters` (or, programmatically via the associated C code API)

- `V` is "valid" and means the byte of data received is valid.
- `C` is "corrupt" when the full data byte was received, but the UART parity check fails (typically due to noise, EMI, etc).
- `T` is "timeout" when the AMDC expected a byte from the AMDS, but it never showed up. This happens continuously when the cable is unplugged.

The value of `V` should be non-zero if the connection is active.
Each time you read the counters, the value of `V` should increment.

Note that, since the UART link has two data lines, a separate 16-bit counter is used for each data line.
The `counters` command returns both counters concatenated into a 32-bit value.
For example, if the value is `0x0002` for the first UART data line and `0x0003` for the second UART data line, the counter will appear as: `0x00020003`.

#### Example

Consider running this experiment: the AMDS-AMDC link is working and you are reading valid data. Then, the cable comes unplugged.

- When the link is working, the `V` counter will continuously be incrementing (and wrapping around at the 16-bit limit)
- As the cable comes unplugged, chances are, it will occur during some byte transmission. This will cause a corrupt data byte and the `C` counter will increment a few times based on exactly how the cable became unplugged.
- After the cable is fully unplugged, the AMDC views every byte requested as a timeout, so the `T` counter will continuously increment. The other counters should remain frozen in their last value.
