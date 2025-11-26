# REV E Hardware

![](images/amdc-rev-e-cover.png)

## Quick Links

- [Changelog](https://github.com/Severson-Group/AMDC-Hardware/blob/develop/CHANGELOG.md#rev20210325e)
- [GitHub Milestone](https://github.com/Severson-Group/AMDC-Hardware/milestone/5)
- [Orderable Design Files](https://github.com/Severson-Group/AMDC-Hardware/tree/develop/REV20210325E)

## Description

The 5th revision of the AMDC hardware fixes major issues from the REV D design while adding additional functionality.
Most notably, REV E moves to a unified JTAG and UART serial interface with a robust USB-B connector (square connector commonly used for printers).
This reduces the required host-connected cables to only a single USB cable and optional Ethernet cable.

The number of GPIO expansion ports is doubled, increasing from 2 to 4 ports.
Furthermore, each GPIO port adds an additional lane of differential signaling, increasing from 2/2 to 3/3.
This enables higher GPIO throughput and more advanced interfaces to external PCBs.

```{toctree}
:hidden:

rev-e-bring-up
rev-e-pin-mapping
```