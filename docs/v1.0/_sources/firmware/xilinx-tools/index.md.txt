# Xilinx Tools

The AMDC firmware is built on top of the Xilinx toolchain.
The Xilinx tools are manditory for all users; without them, the AMDC does not function.

## Toolchain Version

The AMDC firmware and documentation uses Vivado 2019.1 **only**. All users are expected to have this verison installed.

From 2019.2 onwards, Xilinx has moved to the Vitis software platform.
The AMDC will be updated to Vitis at some point, but for now, we will stick with 2019.1 and the SDK environment.

## Useful Xilinx Documentation

Xilinx provides **exceptional** documentation for their products which is browsable via the [Documentation Portal](https://docs.xilinx.com/).

Unfortunately, for new users of the Xilinx products, it can be **very** overwhelming to find the right documentation resources.
Many product features are described in multiple documents from different view points, so it can be hard to understand which prospective applies to your specific application.
For example, the Zynq SoC bootloader documentation is described in three different prospectives: hardware designers, bootloader developers, and application developers. Only the application developer docs are useful to users of the AMDC platform.

```{tip}
Xilinx has so much documentation available (literally 100s of PDFs, each 10-100s of pages long) that they offer a desktop program called [Documentation Navigator](https://www.xilinx.com/support/documentation-navigation/overview.html) which helps users explore all the documents. This tool is also offered as an online [Documentation Portal](https://docs.xilinx.com/). Alternatively, a simple online search engine (e.g. Google) can be used to find relevant docs.
```

The following is a curated list of documentation from Xilinx which has been found helpful in working with the AMDC platform.

### Zynq-7000 SoC

- [Zynq-7000 SoC Technical Reference Manual (TRM)](https://docs.xilinx.com/v/u/en-US/ug585-Zynq-7000-TRM)
- [Xilinx Power Estimator User Guide](https://docs.xilinx.com/v/u/2020.1-English/ug440-xilinx-power-estimator)
- [Zynq-7000 SoC PCB Design Guide](https://docs.xilinx.com/v/u/en-US/ug933-Zynq-7000-PCB)

### Vivado IP

- [Vivado Design Suite Tutorial: Creating and Packaging Custom IP](https://docs.xilinx.com/r/en-US/ug1119-vivado-creating-packaging-ip-tutorial)
- [Xilinx Vivado IP Integrator Step-by-Step](https://docs.xilinx.com/v/u/en-US/xapp1162)
- [Packaging Custom AXI IP for Vivado IP Integrator](https://docs.xilinx.com/v/u/en-US/xapp1168-axi-ip-integrator)
- [Methods for Integrating AXI4-based IP Using Vivado IP Integrator](https://docs.xilinx.com/v/u/en-US/xapp1204-integrating-axi4-ip-using-ip-integrator)

### Dual Core

- [Simple AMP: Bare-Metal System Running on Both Cortex-A9 Processors Application Note](https://docs.xilinx.com/v/u/en-US/xapp1079-amp-bare-metal-cortex-a9)
- [Simple AMP Running Linux and Bare-Metal System on Both Zynq Processors Application Note](https://docs.xilinx.com/v/u/en-US/xapp1078-amp-linux-bare-metal)

```{toctree}
:hidden:

installing-xilinx-tools
building-and-running-firmware
flashing
create-private-repo
create-user-app
dual-core
low-level-debugging
```
