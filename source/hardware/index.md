# Hardware Overview

The AMDC hardware is a collection of circuit board designs which are used to control advanced motor systems. The hardware design is open-source, modular, and research-oriented.

The flagship circuit board is the main AMDC (see latest design [here](https://github.com/Severson-Group/AMDC-Hardware/tree/develop/REV20210325E)) which is a carrier board for the [PicoZed System-on-Module](https://www.avnet.com/wps/portal/us/products/avnet-boards/avnet-board-families/picozed/). The PicoZed is a module itself which contains the core requirements for the [Xilinx Zynq-7000](https://www.xilinx.com/products/silicon-devices/soc/zynq-7000.html) System-on-Chip. The Xilinx Zynq-7000 SoC is a powerful processor with dual-core DSPs and a tightly integrated FPGA.

Extensive firmware support is provided in the [AMDC-Firmware](https://github.com/Severson-Group/AMDC-Firmware) repo which targets this architecture.

## Design Software / Licenses

All PCB designs which are a part of the AMDC Platform are designed in **Altium Designer**.
To contribute and modify PCB designs, the user needs a valid license for Alitum.

However, to order and use the PCBs, the "compiled" design files are provided in the open-source repo.
This includes all the files needed to build the AMDC and get it working.
Therefore, no users of the AMDC Platform need to have access to Altium, only designers and contributors.