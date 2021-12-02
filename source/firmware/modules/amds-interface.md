# AMDS Interface

This document describes the built-in AMDC drivers which can be used to interface with the AMDS.

*Before attempting to use these drivers, make sure to read about the AMDS in [its documentation](/accessories/amds/index.md).*

## Enable AMDS Support

By default, the AMDS drivers are not compiled into the C-code.

To enable, update the `usr/user_config.h` file and set the following define to `1`:

```C
#define USER_CONFIG_ENABLE_MOTHERBOARD_SUPPORT (1)
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