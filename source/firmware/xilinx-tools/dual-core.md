# Dual Core

This document provides a background on dual-core programs running on the Xilinx Zynq-7000 SoC.
This does not have to be read or understood by users of the AMDC; the dual-core apps in the common AMDC code already work in dual-core mode.
However, if a user wants to build a new dual-core system from scratch, this document explains how.

## References

There are surprisingly few resources online about dual-core operation of the Xilinx Zynq-7000 SoC.
Below is a brief summary list:

- The main reference for this doc is the Xilinx application note [XAPP1079](https://www.xilinx.com/support/documentation/application_notes/xapp1079-amp-bare-metal-cortex-a9.pdf) from 2014 written by John McDougall. This [Xilinx wiki page](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842504/XAPP1079+Latest+Information) gives updates to XAPP1079 as the dev software evolves.
- The [Xilinx Zynq-7000 SoC Technical Reference Manual (TRM)](https://www.xilinx.com/support/documentation/user_guides/ug585-Zynq-7000-TRM.pdf) discusses dual-core operation extensively, but does not provide many actionable ideas. In fact, the TRM is written almost exclusively from the prospective of dual-core operation! But, it is >1800 pages long; good luck reading it.
- For information about running Linux on dual-core, check out [XAPP1078](https://www.xilinx.com/support/documentation/application_notes/xapp1078-amp-linux-bare-metal.pdf)

## Definitions

**Symmetric Multi-Processing (SMP):**
SMP refers to multi-core operation where the same exact executable is running on many cores at the same time.
This is used by all modern OS's (e.g. Windows, Linux) which allows the scheduler to abstract the multi-core system.

**Asymmetric Multi-Processing (AMP):**
AMP refers to multi-core operation where independent executables run on each core.
Each executable can operate completely independently, however, they must be aware that shared resources exist between the cores.
The programmer must be careful to ensure the cores cooperate in terms of the shared resources (e.g. peripherals, memory, etc).

**CPU0 vs. CPU1:**
In all Xilinx documentation and on the AMDC platform, the two cores of the Zynq-7000 SoC are named `CPU0` and `CPU1`.
CPU0 is the main core and boots first, thus it is responsible for configuring shared resources.
CPU1 acts as the secondary core.

**On-Chip Memory (OCM):**
The Xilinx Zynq-7000 SoC uses off-chip DRAM memory modules to form the bulk RAM which is used by the applications (i.e. 1 GB of RAM).
The SoC also has tightly coupled memory called on-chip memory (OCM) which is integrated into the SoC package (i.e. on die).
This memory is 256 KB and is accessible with low latency from both cores.

*SMP is not used in the core AMDC firmware; only AMP is used.*

## Dual-Core Programs

Dual-core operation (AMP) requires two seperate executables being built from Xilinx SDK, meaning two seperate SDK application projects.
Each application project requires its own BSP project, since each BSP must specify on which core it will run.
Both BSPs use the same hardware wrapper project. In total, **five** distinct SDK projects are required for dual-core operation.

### Create the BSPs

Ensure the AMDC hardware wrapper project exists as exported from Vivado.
Then, create two BSP projects as usual, but append `_cpuX` to each:

- `amdc_bsp_cpu0` should target CPU0
- `amdc_bsp_cpu1` should target CPU1

Update `amdc_bsp_cpu1` to build with extra compiler flags: `-DUSE_AMP=1`.
Using the "Board Support Package" window, append this flag to the "extra_compiler_flags" via the "drivers > ps7_cortexa9_1" tab.

```{warning}
Forgetting to set the extra compiler flag will result in a dual-core program that does not work!
```

### Create the Applications

Create two application projects, each one targetting one of the BSPs.
Name the applications: `app_cpu0` and `app_cpu1`; CPU0 runs `app_cpu0` and couples with `amdc_bsp_cpu0`, similiar for CPU1.
If this is your first time trying dual-core, start with simple "Hello World" programs.

#### Configure DRAM Memory Regions

By default, the linker script for both `app_cpu0` and `app_cpu1` will allocate the full RAM region to both apps.
This is not valid and would result in the applications stepping on each other.
To avoid this, manually update the linker script `lscript.ld` for each application to seperate out the RAM regions.

- `app_cpu0`: update `ps7_ddr_0` memory region: base address: `0x00100000`, size: `0x1FF80000`
- `app_cpu1`: update `ps7_ddr_0` memory region: base address: `0x20080000`, size: `0x1FF80000`

The size is computed as half the default size of the RAM.

For advanced users, feel free to split the address space as two non-equal parts if one core has higher memory requirements (e.g. for buffered logging of an insane amount of data).

```{warning}
Forgetting to split the memory address space will cause undefined behavior.

The programs will run on the processor, but the memory will become corrupt!
```

#### Disable OCM Caching

CPU0 and CPU1 will most likely communicate with each other via OCM.
With this expectation, we will default to turning off caching to OCM for both cores so that no coherency issues arise.
The latency to OCM is small enough that the determinism advantage is worth the performance degradation.

On the Zynq-7000, the OCM is 256 KB is size, however, we will only use a 64 KB chunk.
Therefore, we will turn off caching to this 64 KB chunk.

On both cores (i.e. `app_cpu0` and `app_cpu1`) in the first part of the `main()` function, call the following Xilinx driver code:

```C
#include "xil_mmu.h"

int main(void) {
    // ...

    // Disable cache on OCM
    // S=b1 TEX=b100 AP=b11, Domain=b1111, C=b0, B=b0
    Xil_SetTlbAttributes(0xFFFF0000, 0x14de2);

    // ...
}
```

### Enable Bootloader Support

Dual-core operation is easily started via the debugging environment with JTAG, but this is not available when booting from flash.
When booting from flash, CPU0 starts automatically from the bootloader.
However, CPU0 must manually start CPU1.
For more information on the start-up process, consult the references linked above.

To start CPU1 from CPU0, add the following to `app_cpu0`'s `main()` function:

```C
#include "xil_cache.h"
#include "xil_io.h"
#include "xil_mmu.h"

void main() {
    // ...

    #if 1
        // This code is required to start CPU1 from CPU0 during boot.
        //
        // This only applies when booting from flash via the FSBL.
        // During development with JTAG loading, these low-level
        // calls in this #if block are not needed! However, we'll
        // keep them here since it doesn't affect performance...

        // Write starting base address for CPU1 PC.
        // It will look for this address upon waking up
        static const uintptr_t CPU1_START_ADDR = 0xFFFFFFF0;
        static const uint32_t CPU1_BASE_ADDR = 0x20080000;
        Xil_Out32(CPU1_START_ADDR, CPU1_BASE_ADDR);

        // Waits until write has finished
        // DMB = Data Memory Barrier
        dmb();

        // Wake up CPU1 by sending the SEV command
        // SEV = Set Event, which causes CPU1 to wake up and jump to CPU1_BASE_ADDR
        __asm__("sev");
    #endif

    // ...
}
```