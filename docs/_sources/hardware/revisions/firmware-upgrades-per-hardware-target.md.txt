# Firmware Upgrades Per Hardware Target

This document should be referenced when changing hardware targets.
Each revision of the AMDC hardware is slightly different, so the user code might need to be modified.
Note that the hardware targets are almost interchangable, minus the small changes listed below.

Most changes occur automatically in the core firmware by simplying `define`ing the appropriate hardware target in the `usr/user_config.h` file.

For example, to target AMDC REV F hardware, make sure the following code exists in your `usr/user_config.h` file:

```C
// Set hardware target to AMDC REV F
#define USER_CONFIG_HARDWARE_TARGET AMDC_REV_F
```

The supported targets are: `AMDC_REV_D`, `AMDC_REV_E`, and `AMDC_REV_F`.

## AMDC REV D

AMDC REV D is the baseline supported hardware target.

This hardware revision contains major errata (documented [here](./rev-d/rev-d-errata.md)), which prompted Revision E.
The errata does not affect the firmware operation.

Compile code with `AMDC_REV_D` as the hardware target.

## AMDC REV E

AMDC REV E is actively supported.

This hardware revision addresses the REV D errata, and the REV E firmware has been upgraded significantly from REV D to be more user-configurable. 

Compile code with `AMDC_REV_E` as the hardware target.

## AMDC REV F

AMDC REV F is the latest hardware target and is actively supported.

The hardware is a minor update from REV E, and the REV F firmware is identical to REV E.

Compile code with `AMDC_REV_F` as the hardware target.