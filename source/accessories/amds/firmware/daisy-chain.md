# AMDS Daisy Chain

This document outlines the architecture, setup, and salient details of the AMDS's Daisy Chain capability.

## Overview

The AMDC and AMDS allow up to three AMDS boards to be daisy chained together on each of the AMDC's GPIO ports, as shown below.

```{image} images/daisy-chain.svg
:width: 100%
```

Each AMDS board can run the same firmware, and does not need to know it is in a daisy chain. The cabling between each pair of boards runs at the same baudrate (20 Mbps).

Currently released AMDS hardware relies on a daisy chain adapter board placed between AMDS's to add the necessary transceivers. Details on this board can be found in the AMDS git repo's [`AMDS/Accessories/DaisyChainAdapter` directory](https://github.com/Severson-Group/AMDS/tree/develop/Accessories/DaisyChainAdapter).

## Multi-Target Firmware Project (Custom Build Configurations)

The firmware is designed to operate on multiple target hardware platforms using a single, unified codebase.

- **Target Definitions**: The firmware uses `TARGET_AMDS` and `TARGET_2S` preprocessor macros to conditionally compile board-specific configurations.
- **Dynamic Peripheral Assignment**: Depending on the selected target, the system correctly configures the corresponding hardware peripherals. For example, `TARGET_AMDS` utilizes `UART4` and `UART5` for the Daisy Chain RX lines, while `TARGET_2S` relies on `USART6` and `USART1`.
- **Custom Run Configurations**: You can program either an AMDS or other devices without creating separate project branches, simply by toggling the target macro in your build/run configurations.

## Direct Memory Access (DMA) Setup for Receiving Data

To ensure zero-CPU overhead when receiving incoming UART data, the protocol utilizes DMA streams.

- **Circular Buffers**: Incoming daisy-chain data is placed into `DAISY_RX1_Pool` and `DAISY_RX2_Pool`, both of which are 256-byte circular buffers (`AMDS_RX_BUF_SIZE`). Utilizing a 256-byte size allows for 8-bit integer math to handle wrap-around without complex modulo logic.
- **Error Recovery**: In high-noise environments, UART hardware errors (Parity, Overrun, Noise, or Frame errors) can cause the hardware to drop the `DMAR` (DMA Receiver) bit, halting the stream. The UART Interrupt Service Routines (ISRs) actively monitor for these flags, clear them, and immediately re-enable the DMA requests to ensure continuous stream operation without resetting the device.

## Selective Channel Transmitting

To optimize processing and transmission bandwidth, the system supports disabling unused sensor channels.

- **Active Sensor Mask**: A global variable `active_sensor_mask` acts as a bitmask where `1 = Active` and `0 = Inactive`.
- **Target Defaults**: By default, `TARGET_AMDS` activates all 8 channels (`0xFF`), while `TARGET_2S` activates a subset of channels (`0x11`).

## Modified Sample-and-Transmit Fast Path

The firmware bypasses standard abstraction overhead to achieve low latency during critical sampling and transmission windows via the `adc_sample_and_transmit_fast_path` function.

- **Hardware Cycle Counting**: Rather than using `NOP` loops for the mandatory 1300ns ADC wait time, the fast path uses the Cortex-M7 DWT Cycle Counter (`DWT->CYCCNT`) for deterministic waiting.
- **Instruction Interleaving**: The code optimizes wait states by starting SPI reads, and transmitting UART header bytes (`0x90`) while the CPU is waiting for the SPI RX buffers to fill.

## Process Routing Architecture

Handling high-speed daisy-chained data relies on the `try_process_routing()` and `process_routing()` implementations.

- **Thread-safe Invocation**: The main `while(1)` loop constantly checks `drv_uart_has_dma_data()` and invokes `try_process_routing()`. This wrapper uses an atomic lock (`is_routing_active`) to safely avert reentrancy without stalling the CPU or permanently blinding interrupts.
- **Dual-Stream Optimization**: Inside `process_routing()`, if both UART streams have at least a full 3-byte packet ready, the logic processes them completely interleaved. This keeps both hardware TX lines saturated simultaneously.
- **Single-Stream and Slow Path**: If one UART runs slightly faster, it employs a Single-Stream Fast Path. If a packet gets fragmented across a DMA boundary or becomes misaligned, the system reverts to a 1-byte-at-a-time State Machine (the "Slow Path") to recover the stream automatically.
