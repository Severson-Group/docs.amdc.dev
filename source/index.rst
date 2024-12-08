===========================
AMDC Platform Documentation
===========================

.. Table of Contents for the entire site:
   NOTE: these are marked hidden so they are not
   rendered on the home page, but must be here so
   the side bar works!

.. toctree::
   :hidden:
   :caption: GitHub Repositories

   AMDC-Hardware <https://github.com/Severson-Group/AMDC-Hardware>
   AMDC-Firmware <https://github.com/Severson-Group/AMDC-Firmware>

.. toctree::
   :hidden:
   :caption: Getting Started

   getting-started/onboarding
   getting-started/tutorials/index
   getting-started/advanced-tutorials/index
   getting-started/user-guide/index
   getting-started/control-with-amdc/index

.. toctree::
   :hidden:
   :caption: Hardware

   hardware/index
   hardware/obtaining-hardware
   hardware/subsystems/index
   hardware/revisions/index

.. toctree::
   :hidden:
   :caption: Firmware

   firmware/index
   firmware/development/index
   Architecture <firmware/arch/index>
   firmware/xilinx-tools/index

.. toctree::
   :hidden:
   :caption: Accessories

   AMDS <accessories/amds/index>
   accessories/uinverter/index
   DAC <accessories/dac/index>
   accessories/test-board/index


Welcome to the AMDC Platform documentation.
This is an ever-growing collection of knowledge about the AMDC.
Browse the documentation using the links in the sidebar on the left.

.. figure:: /hardware/revisions/rev-d/images/amdc-rev-d-cover.jpg
   :align: center

   Flagship AMDC circuit board forms the core of the AMDC Platform.

**************************
What is the AMDC Platform?
**************************

AMDC stands for Advanced Motor Drive Controller.

The AMDC Platform is a collection of modular open-source hardware and software used for electric drive control.
At the core is the flagship AMDC circuit board which acts as the "brains" of the control platform.
On top of the AMDC hardware, extensive firmware is provided to bring the hardware to life.
Finally, the core AMDC is augmented with introductory tutorials, examples, and auxiliary circuit boards to create a rich learning environment for both researchers and students.

.. admonition:: AMDC Vision

   The AMDC empowers motor control students, researchers, and designers by providing an open-source sandbox for exploring and creating electric motor control platforms.


************
Key Features
************

- **Open-Source:** All hardware design files and firmware are freely available.
- **Easy-to-Use:** Specializes in extreme performance drives but is sufficiently simple to be used as a learning tool for implementing standard motor drives.
- **High-Performance:** Supports high-performance Xilinx real-time processors and programmble logic.
- **Flexible:** Capability (computation power, I/O, proper abstraction layers) to actuate new types of motors, but also standard types of motors.
- **Documentation:** Extensive documentation for understanding all layers of the AMDC.
- **Research-Oriented:** Designed to be used in the research environment.


********
Research
********

The AMDC Platform is designed explicitly for the research environment use-case where flexibility and customizability are critical.
Some example research applications are given below:

*  Levitated motor systems

   *  Bearingless motors
   *  Magnetic bearings

*  Multi-phase motors (m > 3)
*  Advanced control algorithms

   *  Field oriented control
   *  Sensorless control
   *  Harmonic current regulation

*  Wide-bandgap power electronics

   *  PWM switching up to MHz range
  
*  Data logging

********************************
Frequently Asked Questions (FAQ)
********************************

What is the AMDC platform?
   The AMDC platform accelerates development of motor drives, allowing you to reach a working solution faster, while still maintaining complete control of the entire hardware / firmware stack.

Is the AMDC free?
   Yes. The full AMDC platform (both hardware and firmware) is open-source.

Can I use it for commercial projects?
   Yes. Please follow the license provided in the hardware and firmware design source.

Do you offer technical support?
   No. Since the AMDC platform is not a paid project, we do not have the resources to provide 1:1 support. Please read the extensive documentation on this site.

Who created the AMDC Platform?
   `Nathan Petersen <https://nathanpetersen.com/>`_ was the original architect and designer of the AMDC under the direction of `Prof. Eric Severson <https://directory.engr.wisc.edu/ece/Faculty/Severson_Eric/>`_; he designed the `hardware <https://github.com/Severson-Group/AMDC-Hardware>`_ and `firmware <https://github.com/Severson-Group/AMDC-Firmware>`_ and built this `documentation website <https://github.com/Severson-Group/docs.amdc.dev>`_ you are reading.

Who maintains the AMDC Platform?
   The AMDC Platform is actively maintained by students in the `Severson Research Group <https://severson.wempec.wisc.edu/>`_ at the `University of Wisconsin, Madison <https://www.wisc.edu/>`_ in the USA.


********
Citation
********

If you use the AMDC in your research, please cite the following paper about the AMDC:

``N. Petersen and E.L. Severson, "AMDC: Open-Source Control and Sensing Platform for Advanced Electric Motor Drives," 2023 IEEE International Electric Machines and Drives Conference (IEMDC), 2023.``

.. code:: none

   @inproceedings{petersen2023amdc,
     author={Petersen, Nathan and Severson, Eric},
     booktitle={2023 IEEE International Electric Machines and Drives Conference (IEMDC)}, 
     title={AMDC: Open-Source Control and Sensing Platform for Advanced Electric Motor Drives}, 
     year={2023},
     volume={},
     number={},
     pages={1-7}
   }

*******
License
*******

The AMDC project is split into two distinct open-source repositories, hosted on GitHub:

- `AMDC-Firmware <https://github.com/Severson-Group/AMDC-Firmware>`_ is licensed under the **BSD 3-Clause License**.
- `AMDC-Hardware <https://github.com/Severson-Group/AMDC-Hardware>`_ does not include any explicit license.
