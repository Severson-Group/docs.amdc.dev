# Host Interface

This document explains the interfaces available for interaction between the AMDC and the host.

## Physical Layer

The AMDC has **two** available host interface physical layers:

1. USB-UART
2. Ethernet

Both options support almost identical features, however, Ethernet has higher performance and is the preferred option.
USB-UART is supported for simple use cases and debugging.

```{tip}
Invest the time to get Ethernet working between the AMDC and your test environment host PC.
It will save countless hours over the long term and make the AMDC much easier and more enjoyable to use.
```

### USB-UART

USB-UART refers to the typical character-based "serial" interface common to most embedded platforms.
On the host side, USB-UART appears as a USB device which emulates the [classic serial (COM) port](https://en.wikipedia.org/wiki/COM_(hardware_interface)).
On the AMDC side, USB-UART appears as standard UART RX/TX data lines which go to the UART peripheral of the processor.
Hence, most of the firmware and docs refer to the USB-UART interface as simply UART.

The UART interface is fairly slow and not very robust.
However, it is easy to set up and use.

#### Setting Up UART on Host PC

The only required set-up is the drivers for converting the USB device into a serial port:

- On `REV D` hardware, follow the instructions outlined near the end of [this document](/firmware/xilinx-tools/building-and-running-firmware.md).
- On `REV E` hardware, the host should already have the drivers installed.

### Ethernet

The AMDC also supports [Gigabit Ethernet](https://en.wikipedia.org/wiki/Gigabit_Ethernet).
Compared to the UART interface, Ethernet is much faster and very robust.
It is the preferred host interface.

#### Setting Up Ethernet on Host PC

Setting up Ethernet from the host side is a bit harder than UART.

First, you will need a dedicated Gigabit Ethernet jack.
Using a USB-to-Ethernet adapter is recommended for portability, but make sure it supports the link speeds you want to use (e.g., try [this](https://www.amazon.com/Cable-Matters-Ethernet-Adapter-Supporting/dp/B00BBD7NFU/) USB 3.0 to Ethernet adapter which supports 10/100/1000 Mbps).

When using the Ethernet interface to the AMDC, the AMDC acts as the server and the host PC is the client.
The AMDC server does not use DHCP, meaning you must give a static IP address to your host PC on the dedicated network adapter.
The AMDC server is hard-coded to IP address `192.168.1.10`.
You must statically define your client PC IP address to an address which is *not* the AMDC address, e.g., `192.168.1.8`.

For ease-of-use, consider renaming the network exposed from the dedicated network adapter as "AMDC" so it is clear on your PC what is what.

To determine the link speed used by the AMDC and the host network adapter, check the UART output a few seconds after boot-up of the AMDC firmware.
If the Ethernet link is successful, the link speed will be printed in Mbps (1000 means Gigabit Ethernet speeds).

## Usage

There are also **two** ways to use the interface between the host and AMDC:

1. Manual interface via serial terminal software *(UART only)*
2. Programmatic interface via Python, typically via Jupyter notebook *(UART or Ethernet)*

The following table summarizes the acceptable combinations:

| Usage | UART | Ethernet |
|---|---|---|
| Manual Terminal | ✔ | ❌ |
| Programmatic via Python | ✔ | ✔ |

### Manual Interface With Terminal Software

This is the easiest way to get started with the AMDC.
This simply involves plugging in a single cable for USB-UART and opening a serial terminal program on your host PC.
Note that this usage does not support Ethernet.

Some possible host terminal software includes:

- Xilinx SDK integrated terminal
- Tera Term
- PuTTY

There are many other host software options available.

Follow the [Blink tutorial](/getting-started/tutorials/blink/index.md) for more detailed instructions on using the manual terminal interface via UART.

### Programmatic Interface With Python

For complex experiments and systems (i.e., most users), the programmatic interface method is preferred and should be used.
This can be done via either UART or Ethernet, and is typically done using a Jupyter Notebook environment.
The `AMDC-Firmware` repo contains Python classes which encapsulate the functionality of AMDC-host interfacing.

The Python wrapper class for the AMDC is documented [here](./python-wrapper.md).

The most basic way to think about the programmatic method is simply automating typing commands on the serial terminal.
For example, typing `hw pwm on` and `[ENTER]` into the terminal program is the same as running `amdc.cmd("hw pwm on")` in Python.

At the simplest level, the benefits of using Python already start to appear, such as dynamically changing command arguments.

Consider an experiment where a levitated object is moved by 10 um every second and data is collected from an oscilloscope.
This is trivial to implement in Python:

```python
# Specifiy set point in microns
xx_ref = [0, 10, 20, 30, 40]

# Send command to AMDC with the set point in meters
for x_ref in xx_ref:
    amdc.cmd("ctrl set {}".format(x_ref * 1e-6))
    time.sleep(1)
```

This simple automated experiment would be very tedious to type in by hand via the serial console, while ensuring consistent timing.
However, Python scripting makes it easy.

```{toctree}
:hidden:

python-wrapper
```