# Obtaining Hardware

This document explains how to obtain the AMDC hardware, i.e., the assembled circuit board.

## Open-Source Design

The AMDC hardware design is open-source[^opensource].
All design files are located in the [AMDC-Hardware](https://github.com/Severson-Group/AMDC-Hardware) git repo which is hosted on GitHub.

[^opensource]: All PCB designs are created using [Altium Designer](https://www.altium.com/altium-designer/), which is **not** open-source software.
However, all design files and the "compiled" design output (i.e., gerbers, BOM, etc) are freely available.
Users that do not have access to Alitum can use converter software to open the design files in other software -- for example: [KiCad](https://www.kicad.org/) and its free [alitum2kicad](https://www.kicad.org/external-tools/altium2kicad/) tool.

The design files, schematics, etc can be critical for debugging low-level hardware bugs causing application issues (e.g. analog noise).
Furthermore, other engineers can freely contribute to the AMDC hardware design by creating pull requests which update or add features.

However, for most users of the AMDC hardware, having the hardware design files is not that important.
Instead, most users simply want a physical AMDC to use.

## Obtaining an AMDC

Users can create their own copy of the AMDC by following the steps below.
These steps outline how to find the compiled design files from the git repo, order blank PCBs, order the components, and assemble the board.

### 1. Finding compiled design files

Each version of the AMDC hardware is released as a revision labeled with the snapshot date and a sequential letter.
The format is: `REVyyyymmdd*` where `yyyymmdd` is the date and `*` is the sequential letter.
For example, the 6th revision is called `REV20231005F`.

Each revision of the AMDC hardware has its own `REVxxxx` folder in the git repo.
Within the folder is the compiled design files:

- Schematics (PDF)
- Table of PCB parameters
- Screenshots of PCB design (in 3D)
- Gerbers
- Bill of materials (BOM)
- [optional] Pick and place file

These files are all that is required to order and build a complete AMDC.

For example, the `REVxxxx` folder for the 6th revision, `REV F`, is located on GitHub [at this link](https://github.com/Severson-Group/AMDC-Hardware/tree/develop/REV20231005F).

### 2. Ordering blank PCBs

Now that you have the compiled design files, the next step is ordering blank PCBs.

```{note}
**Experienced Users:** i.e., if you already know how to order PCBs:

All required PCB parameters are listed in table format in the README in the `REVxxxx` folder.
No specialized fab house is needed; the AMDC hardware is designed to be orderable at any common manufacturer.
```

*The following discussion in this section explains how to order PCBs in general -- this is not specific to the AMDC; you can order any PCB following these steps.*

There are a seemingly endless number PCB fab houses who can produce the physical PCBs for the AMDC.
Depending on your location, some PCB fabrication companies might make more sense than others, i.e., for quality, shipping times, cost, etc.
For ordering PCBs from China, [PCBWay](https://www.pcbway.com/) is one example of a reputable fabrication company that is easy to work with.

To order a blank circuit board, you need the *gerber* files.
[Gerber files](https://en.wikipedia.org/wiki/Gerber_format) are simply text files which encode all the layers of the final PCB, such as copper, silkscreen, solder mask, etc.
The PCB manufacturer typically requires a zip file upload for the gerbers.
Create the required zip file by simply zipping the `REVxxxx/gerbers/` folder and uploading to the website.

You will need to specify the circuit board parameters when ordering the PCB, such as size, number of layers, and fabrication processes.
All the required details are listed in table format in the `REVxxxx` folder README file.
In general, no special parameters are needed; the defaults will work.

### 3. Ordering components (BOM)

After ordering the blank PCBs, you need to buy the components to solder onto the PCB.
All the parts are listed in the *Bill of Materials (BOM)*.
The BOM has a row for each unique part number and lists the quantity needed, distributor part number, and brief description.

The BOM file is provided in CSV format and is located in the `REVxxxx` folder.
The distributor part number is given for Digi-Key.
Users can simply upload the BOM file to Digi-Key and it will populate the cart automatically.

A key component of the AMDC to be aware of is the Avnet PicoZed system-on-module (SoM). The PicoZed is the "brains" of the AMDC, and users should be careful to make sure they are ordering the correct model of the PicoZed (7Z030) to ensure compatibility with the open-source AMDC Firmware. A full article on the PicoZed as it pertains to the AMDC can be found [here](/hardware/subsystems/picozed.md).

```{warning}
Most likely, there will be some out-of-stock parts in the BOM which are not available on Digi-Key.
Users should first try to find alternative distributors which have stock.
If there is a global shortage of the specific part, users will need to find suitable alternative parts.
For help, create a post using the GitHub Discussions feature.
```

### 4. Assembling the AMDC

Finally, after obtaining the blank PCB and BOM, it's time for assembly.

Most of the parts on the AMDC are surface mount devices (SMD).
These can be assembled with common hot air reflow processes.
The connectors and other through-hole techology (THT) parts should be soldered using a soldering iron.

#### Tips for 100-pin high-density connectors

The three 100-pin high-density connectors used to interface the PicoZed module to the AMDC are difficult to solder.

While the connectors can *technically* support hot-air reflow, without a *very* accurately controlled oven, the plastic melts.
Instead, we have found good luck using a fine-tip soldering iron on each pin -- do not use soldering paste since it tends to pool under the pins and is very hard to melt.
Just use a spool of solder and carefully go over each pin individually, careful to ensure no shorts between pins.

```{tip}
With lots of patience, the 100-pin connectors are actually not too bad and can be fairly easily soldered by hand.

Make sure to test for shorts before power up!
```

### 5. Powering the AMDC

The AMDC requires a 24V DC power supply.
Benchtop supplies can be used, but it is often easier to use a dedicated wall wart supply.
The recommended wall wart supply and adapters are listed below.
Note that only one of the adapters are needed.

| Description | Digi-Key P/N |
|---|---|
| 24V DC supply | 364-1283-ND |
| Barrel to screw post adapter | 1528-1386-ND  |
| Barrel to alligator clip adapter | 1528-1393-ND  |
