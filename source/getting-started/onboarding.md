# Onboarding

This document describes the steps to get going on the AMDC Platform.
The target audience is a new user of the AMDC; these steps assume the user has never used the AMDC before.

**Welcome to the AMDC Platform!**

## 1. Obtaining Hardware

The first step is obtaining a working AMDC control circuit board.

All the design files for the hardware are open-source, meaning that anyone can build an AMDC circuit board.
As of now, the AMDC is not a commercially available product; it is not sold as a complete unit.

The Severson Research Group stocks a supply of built and tested AMDCs which group members can use.
For group members, check out the AMDC Board Log spreadsheet to find an available AMDC.

For external users not a part of the Severson Research Group, the only way to acquire a working AMDC is by ordering and assembling the blank PCB and components.
This is clearly an involved process which should only be attempted by individuals skilled in PCB ordering and bring-up.
Detailed documentation is provided to aid in the ordering and bring-up process, but in general, users are on their own. 
See the dedicated page on this documentation site for [Obtaining Hardware](/hardware/obtaining-hardware.md).
No 1:1 technical support is available from the Severson Research Group to external users.

```{tip}
Check out the extensive documentation about the AMDC hardware available [in the hardware section of this website](/hardware/index.md).
```

## 2. Install Development Tools

After obtaining the AMDC hardware, the next step is installing the required development tools.

The required development tools are:

- Version control software: git
- Xilinx Vivado 2019.1 and SDK
- Python environment with Jupyter notebooks

As of now, these tools can be used without any licenses. No licensed software is required to use the AMDC.
The user is expected install the Xilinx tools using [these instructions](/firmware/xilinx-tools/installing-xilinx-tools.md).
The installation of git and Python is not covered in these docs; please refer to the main websites for those tools.

## 3. Introductory Tutorials

The baseline AMDC firmware is meant to be a launching point for user code development.
Several introductory tutorials are provided to help users understand how the AMDC Platform works.
Follow each tutorial, in order.

Access the tutorials [here](tutorials/index.md) or by clicking the right arrow at the bottom of this page.

%## 4. Example Applications
%
%Finally, example open-source applications are provided to show the user the intended way of using the AMDC.
%
%- 3-phase current regulation
%- ~PMSM motor control~