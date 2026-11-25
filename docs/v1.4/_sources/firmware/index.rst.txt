=================
Firmware Overview
=================

The AMDC firmware is a collection of embedded system code (written in C and Verilog) which runs on the :doc:`AMDC Hardware </hardware/index>` and controls advanced motor systems.
It is open-source, high-performance, flexible, and research-oriented.

The target processor is the `Xilinx Zynq-7000 SoC <https://www.xilinx.com/products/silicon-devices/soc/zynq-7000.html>`_ which includes both a dual-core DSP and tightly integrated FPGA.
The AMDC firmware utilizes both parts of the processor (DSP + FPGA).