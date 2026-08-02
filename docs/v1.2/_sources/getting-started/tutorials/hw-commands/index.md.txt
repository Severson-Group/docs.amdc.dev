# Tutorial: Hardware Commands

- **Goal:** Run built-in commands to control the AMDC drive I/O.
- **Complexity:** 2 / 5
- **Estimated Time:** 30 min

This tutorial goes over:

- Built-in `hw` commands

## Tutorial Requirements

1. Working AMDC hardware
2. Completion of the [blink tutorial](../blink/index.md)
3. Multimeter and/or oscilloscope for validation of I/O

## Background

The `hw` commands, or "hardware" commands, are included in all firmware built for the AMDC.
These are provided to do basic raw I/O manually from the command line.
For example, read an ADC voltage value, set the PWM duty ratio of an output pin, read the encoder position, etc.

Per the `help` message, the included sub-commands are:

- `pwm <on|off>` - Turn on/off PWM switching
- `pwm sw <freq_switching> <deadtime_ns>` - Set the PWM switching characteristics
- `pwm duty <pwm_idx> <percent>` - Set a duty ratio
- `anlg read <chnl_idx>` - Read voltage on ADC channel
- `ild read` - Read the latest packet from ILD1420 sensor
- `enc steps` - Read encoder steps from power-up
- `enc pos` - Read encoder position
- `enc init` - Turn on blue LED until Z pulse found
- `timer <fpga|cpu> now` - Read value from hardware timer
- `led set <led_idx> <r> <g> <b>` - Set LED color (color is 0..255)
- `mux <gpio|sts> <port> <device>` - Map the device driver in the FPGA to the hardware port

## Quick `hw` Command Guide

Common commands:

- `hw pwm ...` sub-commands control the PWM outputs
- `hw anlg ...` sub-command reads the integrated ADC values
- `hw enc ...` sub-commands read the incremental encoder input

Uncommon commands:

- `hw led ...` sub-command sets the RGB LED colors
- `hw timer ...` sub-command prints the current time from either the CPU or FPGA timer
- `hw ild ...` sub-command reads the value of a laser position sensor
- `hw mux ...` sub-command sets the mapping of signal muxes in the FPGA

## Explanation of common `hw` sub-commands

This section describes useful sub-commands, what they do, and their arguments.
Only a subset of commands are described since the others are not commonly used.

### PWM Output

There are three commands for PWM outputs.
By default, the PWM outputs on the AMDC are all disabled (i.e. all gate signals driven low).
Before using PWM, the outputs must be enabled using `hw pwm on`.
Turn them back off using `hw pwm off`.
If you try to turn on PWM output when it is already on, you will get a `FAILURE` command response.
Similarly, turning off when already off results in a failure.

The PWM switching parameters can be set dynamically via the `hw pwm sw ...` command.
This command requires two parameters: the switching frequency (in Hz) and the dead-time (in ns).
By default, the PWM switching parameters are 100 kHz and 100 ns of dead-time.
The allowable range for switching frequency is from about 1.5 kHz to many MHz.
Dead-time is limited to a minimum of 25 ns, but can be arbitarily high.

```{tip}
The PWM switching parameters can only be changed when the PWM output is off.
```

To set the duty ratio of a particular PWM output, the `hw pwm duty ...` command can be used.
The PWM driver in the FPGA is set up to output signals for half-bridges, meaning that a single command of `hw pwm duty ...` will update two output pins on the AMDC.
The high-side switch will be complementary from the low-side switch, and the appropriate dead-time is inserted per the configured switching parameters. 
The PWM index ranges from `0` to `23` -- the top left DB15 connector on the AMDC contains indices `0` to `2`.
The bottom left DB15 connector contains `3` to `5`.
This pattern repeats top-to-bottom, left-to-right, for all 24 outputs legs.
The `percent` parameter ranges from `0.0` to `1.0`.

See the [power stack hardware documentation](/hardware/subsystems/power-stack.md) for more info on the hardware capabilities.

#### Example

Suppose you want to control a buck converter using a single output leg from the AMDC connected to output channel 0.
In this example, the switching frequency should be 250 kHz and dead-time should be 400 ns.
The PWM duty ratio should be 20%.
The follow commands configure the output then turn on the switching.

```
hw pwm sw 250000 400
hw pwm duty 0 0.2
hw pwm on
```

Use your multimeter or oscilloscope to validate the PWM output from the AMDC is working as expected and is controllable using the discussed commands.

### ADC Input

The AMDC has an integrated ADC which samples 8 differential-pair analog inputs synchronous to the PWM carrier waveform (to minimize noise).
The differential input range is -10V to +10V.
To print the current voltage value of an input channel, use `hw anlg read ...`.
The argument for the channel is zero-based, `0` to `7`.

See the [analog hardware documentation](/hardware/subsystems/analog.md) for more info on the hardware capabilities.

#### Example

For example, to read the raw voltage applied to the first analog input:

```
hw anlg read 0
```

### Encoder Input

The AMDC supports incremental encoder input: [`A`, `B`, `Z`] where `A` and `B` are the quadrature-encoded signals and `Z` is a once-per-revolution index pulse.

The FPGA driver for the encoder records the encoder movement using **steps**.
To get the raw steps moved since the FPGA was configured (i.e. since boot), use `hw enc steps`.
For a rotary encoder spinning at positive speed, the steps output will continue to increase until the integer value wraps around.
The steps output is independent of the `Z` index pulse.
This means the steps output is only relative; it cannot be used for absolute position information.

The FPGA also provides a **position** output, analgous to the steps output, but incorporating the `Z` pulse.
In other words, when the `Z` pulse is seen, the FPGA resets the position variable back to 0.
This means the position output can be used as an absolute position signal.
To print this variable, call `hw enc pos`.

```{warning}
The encoder position signal is not defined until the `Z` pulse is seen by the FPGA -- the command (i.e. driver) will output `-1` until a valid position is available.
```

See the [encoder hardware documentation](/hardware/subsystems/encoder.md) for more info on the hardware capabilities.

#### Example

For example, to read the raw encoder position value:

```
hw enc pos
```

### RGB LEDs

```{danger}
The LEDs are VERY bright! Full brightness is not recommended! The below example uses 10/255 = about 4% power for each color channel. Note that the perceived brightness is not linearly related to the color value and power.
```

The AMDC includes 4 RGB LEDs on the PCB.
By default, the firmware cycles blinking patterns on the LEDs to indicate the firmware is running.
The `hw led set ...` command can set an arbilitary color to one LED.
The LED index parameter is zero-based from `0` to `3`.
The color parameters are integers from `0` to `255` -- `0` means off, `255` means full on.

#### Example

For example, to turn on all four LEDs in the following color order: [RED, GREEN, BLUE, WHITE]

```
hw led set 0 10 0 0
hw led set 1 0 10 0
hw led set 2 0 0 10
hw led set 3 10 10 10
```

## Conclusion

**Congratulations!**

You now understand the built-in `hw` commands and how to use them.
These commands are very useful for testing hardware and validating basic functionality.
