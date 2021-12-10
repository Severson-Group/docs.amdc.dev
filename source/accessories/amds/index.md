# Advanced Motor Drive Sensing (AMDS)

Advanced motor drives often require a lot of sensors.
Cue the AMDS.

**GitHub Repository:** [Severson-Group/AMDS](https://github.com/Severson-Group/AMDS)

![](images/AMDS.png)

## Introduction

AMDS stands for **Advanced Motor Drive Sensing**.

The AMDS is a complete embedded platform which is designed for motor drive sensing.
It features a modular slotted design which makes it flexible and adaptable for the research environment.
The platform PCBs include: (i) mainboard with slots, and (ii) three distinct sensor card designs aimed specifically for motor drive sensing.

The AMDS includes a dedicated MCU which samples up to 8 sensor cards which are installed in its slots.
The user can implement custom filters in the MCU, such as low-pass or high-pass.
A robust differential digital link is used to send sampled data to the host device.

## AMDS + AMDC

The AMDS is designed to work directly with the GPIO expansion ports of the AMDC.
However, it is a complete system which could be interfaced to any other host device, assuming the correct drivers are implemented in the host firmware.

## Specifications

- Up to 8 sensor cards

  - High voltage
  - Low voltage
  - Current

- Synchronous sensor sampling to PWM carrier waveform (up to 100 kHz)
- Data request rate up to 10 kHz to host device

```{toctree}
:hidden:

firmware/index
mainboard/index
sensor-cards/index
```