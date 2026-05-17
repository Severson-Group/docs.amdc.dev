# AMDS Daisy Chain

This document outlines the architecture, setup, and salient details of the AMDS's Daisy Chain capability.

## Overview

The AMDC and AMDS allow up to three AMDS boards to be daisy chained together on each of the AMDC's GPIO ports, as shown below.

```{image} images/daisy-chain.svg
:width: 100%
```

Each AMDS can run the same firmware, and does not need to know it is in a daisy chain. To each AMDS, the board "downstream" from it (i.e., the board with a lower number in the image above) appears as `master`.

## Theory of Operation

Upon receiving a `SYNC_ADC` signal, the AMDS performs the following operations:

1. Assert `SYNC_ADC` on its upstream port
2. Collect and transmit sensor card ADC data as described in the [AMDC firmware article](index.md).
3. Process data received on its incoming `DATA0` and `DATA1` ports from any upstream AMDS boards
    - Header packets are incremented by `0x04`
    - Data is transmitted to the corresponding downstream port; for example, if the packet arrived via the upstream  `DATA0` port, it will go out the downstream `DATA0` port

## Hardware

The cabling between each pair of boards runs at the same baudrate (20 Mbps).

Currently released AMDS hardware relies on a daisy chain adapter board placed between each pair of AMDS boards to add the necessary transceivers. Details on this board can be found in the AMDS git repo's [`AMDS/Accessories/DaisyChainAdapter` directory](https://github.com/Severson-Group/AMDS/tree/develop/Accessories/DaisyChainAdapter).

Custom cabling must be used between AMDS boards to transpose the UART `RX` and `TX` pins.

## Architecture

### Direct Memory Access (DMA) for Receiving Data

To ensure near zero-CPU overhead when receiving incoming UART data, the firmware utilizes DMA streams to receive `DATA0` and `DATA1` data from upstream AMDS boards.

- **Circular Buffers**: Incoming daisy-chain data is placed into `DAISY_RX1_Pool` and `DAISY_RX2_Pool`, both of which are 256-byte circular buffers (`AMDS_RX_BUF_SIZE`). Utilizing a 256-byte size allows for 8-bit integer math to handle wrap-around without complex modulo logic.
- **Error Recovery**: In high-noise environments, UART hardware errors (Parity, Overrun, Noise, or Frame errors) can cause the hardware to drop the `DMAR` (DMA Receiver) bit, halting the stream. The UART Interrupt Service Routines (ISRs) actively monitor for these flags, clear them, and immediately re-enable the DMA requests to ensure continuous stream operation without resetting the device.

### Processing Data from Upstream AMDS Devices

Data received from upstream devices is processed immediately after transmitting all data collected from local sensor cards. This is handled by the `process_routing()` function. The timing of this code is carefully optimized to minimize the total transmit time to the AMDC across the enitre link.

Implementation details:

- **Collection of Complete Packets**: The code attempts to collect complete three byte packets prior to processing. Wait timeouts are implemented.
- **Dual-Stream Optimization**: If both UART streams have at least a full 3-byte packet ready, the logic processes them completely interleaved. This keeps both hardware TX lines saturated simultaneously.
- **Single-Stream Optimization**: If only one UART has a 3 byte packet (i.e., a different number of packets are broadcast due to `active_sensor_mask != 0xFF` on an upstream AMDS), the code follows a Single-Stream Fast Path.
- **Fall-Back, Slow Path**: If a packet gets fragmented across a DMA boundary or becomes misaligned, the system reverts to a 1-byte-at-a-time State Machine (the "Slow Path") to recover the stream.
- **Thread-safe Invocation**: The AMDS attempts to broadcast all DMA data within a single call to `process_routing()` from the `SYNC_ADC` interrupt context. However, if this times out, the firmware provides a fall-back path: the main `while(1)` loop constantly checks `drv_uart_has_dma_data()` and invokes `process_routing()` in a thread-safe manner if any further data arrives.
