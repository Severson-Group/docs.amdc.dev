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

## Supported Hardware

There are several revisions of the flagship AMDC PCB design which are compatible with the supplied firmware.
The hardware revisions are denoted by single letters: ``A`` is the first revision, ``B`` is the second, etc.
Each AMDC hardware revision improves and changes the design, striving towards a more robust hardware platform.

The latest revision is the ``REV E`` PCB design.
This is the 5th revision and is considered stable.
Note that the AMDC firmware supports both ``REV D`` and ``REV E`` hardware.
Previous hardware revisions (i.e. ``REV A``, ``REV B``, and ``REV C``) are no longer supported.