# Drivers

## Purpose of Drivers

Why does the code base use "drivers"? What are these things?

## Under the Hood

At a highish level, what does a driver do under the hood? How does it interface with the FPGA?

## Examples

Looking at examples is helpful -- here are some common drivers that the user will access frequently.

### Reading Analog Values from ADC

There are 16 ADC channels which provide analog input into the AMDC. Each channel supports +/- 10V inputs. To read the analog voltage on these inputs, the `drv/analog.c` driver is used. The user code simply calls a driver function which returns the voltage value. You might expect it to work like the following: Imagine I have 5V applied to the ADC on channel 1. Then,

``` C
float voltage = analog_read(channel_1); // voltage should now equal 5.0
```

You'll be happy to find that the actual driver code functions almost the same as this. However, if the user asks for a channel which is not valid (i.e., `channel_100`), the driver should indicate this is an error. To do this, the driver function return value is the error indicator. To get the analog voltage value, the user supplies the driver function with a memory address where it should put the analog voltage value. For the same example as above:

``` C
// Create variables to use
int err;
float voltage;

// Call driver function
err = analog_read(channel_1, &voltage);

// Now:
// - 'err' will be the return status of the driver function
// - 'voltage' should equal 5.0
```

We are almost to the final code which you will use in your applications. However, you will find that the function `analog_read(...)` does not exist. Instead, there are two functions: `analog_geti(...)` and `analog_getf(...)`. The first gets the ADC voltage value as an `int` while the second retreives it as a `float`. The `analog_geti(...)` variant is lower-level; it outputs the actual value returned by the ADC. **The `analog_getf(...)` variant should be used most of the time; it returns the actual voltage on the ADC input.**

Also, you will find that `channel_1` does not exist. Instead, you should use the [enumeration](https://www.geeksforgeeks.org/enumeration-enum-c/) provided in `drv/analog.h`. The mapping between enumeration and ADC channel is nearly 1:1 -- use `ANALOG_IN1` for channel 1, `ANALOG_IN2` for channel 2, etc.

So, the final version of the code you will use is as follows:
``` C
// Create variables to use
int err;
float voltage;

// Call driver function
err = analog_getf(ANALOG_IN1, &voltage);

// Now, you have your output
```

### Writing PWM Duty Ratios

The `drv/pwm.c` driver contains user functions to control the PWM interface. The approach to using this driver is similar to `drv/analog.c`, with one major difference:

The timing of when duty ratio updates are applied is viewed as a critical aspect of precision motor controls. The driver provides options to either apply the updates immediately, synchronize the updates with the [timing manager interrupt](/firmware/arch/timing-manager.md), or apply them on the next carrier peak/valley.

This is done by calling the following function:

```C
err = pwm_set_duty_latching_mode(mode);
```

With mode options

```C
typedef enum {
    PWM_LATCH_MODE_TIMING_MANAGER = 0, // Update duty ratios at next timing manager trigger (default)
    PWM_LATCH_MODE_PWM,                // Update duty ratios at next PWM carrier peak/valley
    PWM_LATCH_MODE_IMMEDIATE           // Update duty ratios immediately (next FPGA clock rise)
} pwm_latch_mode;
```

### Reading Encoder Values

Similar to steps for reading voltages, but with `drv/encoder.c` driver.


```{toctree}
:hidden:

gpio-mux
status-mux
encoder
eddy-current-sensor
```