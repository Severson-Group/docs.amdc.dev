# Firmware Upgrades Per Hardware Target

This document should be referenced when changing hardware targets.
Each revision of the AMDC hardware is slightly different, so the user code might need to be modified.
Note that the hardware targets are almost interchangable, minus the small changes listed below.

Most changes occur automatically in the core firmware by simplying `define`ing the appropriate hardware target in the `usr/user_config.h` file.

For example, to target AMDC REV D hardware, make sure the following code exists in your `usr/user_config.h` file:

```C
// Set hardware target to AMDC REV D
#define USER_CONFIG_HARDWARE_TARGET AMDC_REV_D
```

The supported targets are: `AMDC_REV_D` and `AMDC_REV_E`.

## AMDC REV D

This is the baseline supported hardware target.

This hardware revision contains major errata (documented [here](./rev-d/rev-d-errata.md)), which prompted a new revision.
The errata does not affect the firmware operation.

Compile code with `AMDC_REV_D` as the hardware target.

## AMDC REV E

This is the latest hardware target and is actively supported.

Compile code with `AMDC_REV_E` as the hardware target.