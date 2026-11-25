# GPIO Port Mux Driver

This driver is used to configure the GPIO mux IP core in the FPGA through the AXI4-Lite interface.

A physical GPIO port on the AMDC could be connected to one of many external devices. Therefore, a selector mux is necessary to pick which driver (AMDS, eddy current sensor, etc) should control the GPIO port.

## Files

All files for the GPIO mux driver are in the AMDC-Firmware driver directory ([`sdk/app_cpu1/common/drv/`](https://github.com/Severson-Group/AMDC-Firmware/tree/develop/sdk/app_cpu1/common/drv)).

```
drv/
|-- gpio_mux.c
|-- gpio_mux.h
|-- gp3io_mux.c
|-- gp3io_mux.h
```

## Configuring the GPIO Port Mux

The function used to connect a driver to a GPIO Port via the GPIO Mux depends on the revision of the AMDC hardware used:

### AMDC REV E and beyond

On AMDC REV E and beyond, the **GP3IO mux** IP is used to map drivers to the physical GPIO port. The following function can be used to configure the GPIO port mapping:

```C 
void gp3io_mux_set_device(port, device);
```

where *port* should be replaced by *GP3IO_MUX_N_BASE_ADDR*, *N* being the GPIO port number (1-4), and *device* should be the number in this list of the connected device:

1. AMDS
2. Eddy Current Sensor
3. ILD1420 Proximity Sensor
4. GPIO Direct (direct pin control)

### AMDC REV D

On AMDC REV D, the **GPIO mux** IP is used to map drivers to the physical GPIO port. The following function can be used to configure the GPIO port mapping:

```C 
void gpio_mux_set_device(port, device);
```

where *port* should be replaced by the GPIO port number (0 for physical port 1, 1 for physical port 2), and *device* should be the number in this list of the connected device:

1. Eddy Current Sensor
2. AMDS
3. ILD1420 Proximity Sensor 1
4. ILD1420 Proximity Sensor 2
5. GPIO Direct (direct pin control, physical GPIO Port 1)
6. GPIO Direct (direct pin control, physical GPIO Port 2)

## CLI Commands

Both GPIO mux interfaces can be configured at runtime using commands entered in the command line interface. The command follows the form `hw mux gpio <port> <device>` where `<port>` and `<device>` specify which device driver is connected to which GPIO physical port.

