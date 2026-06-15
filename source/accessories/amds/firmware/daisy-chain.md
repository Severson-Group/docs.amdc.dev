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

The data will arrive on the AMDC `DATA0` and `DATA1` lines in the following arrangment:

| AMDS | Sensor Card                | `DATAx`        | Header | AMDC `AMDC_CH_x_DATA_REG_OFFSET` define |
|:----:|:--------------------------:|:--------------:|:------:|:--------------------------------------: |
| 1    | 1                          | 0              | 0x90   | 1                                       |
|      | 2                          | 0              | 0x91   | 2                                       |
|      | 3                          | 0              | 0x92   | 3                                       |
|      | 4                          | 0              | 0x93   | 4                                       |
|      | 5                          | 1              | 0x90   | 5                                       |
|      | 6                          | 1              | 0x91   | 6                                       |
|      | 7                          | 1              | 0x92   | 7                                       |
|      | 8                          | 1              | 0x93   | 8                                       |
| 2    | 1                          | 0              | 0x94   | 9                                       |
|      | 2                          | 0              | 0x95   | 10                                      |
|      | 3                          | 0              | 0x96   | 11                                      |
|      | 4                          | 0              | 0x97   | 12                                      |
|      | 5                          | 1              | 0x94   | 13                                      |
|      | 6                          | 1              | 0x95   | 14                                      |
|      | 7                          | 1              | 0x96   | 15                                      |
|      | 8                          | 1              | 0x97   | 16                                      |
| 3    | 1                          | 0              | 0x98   | 17                                      |
|      | 2                          | 0              | 0x99   | 18                                      |
|      | 3                          | 0              | 0x9A   | 19                                      |
|      | 4                          | 0              | 0x9B   | 20                                      |
|      | 5                          | 1              | 0x98   | 21                                      |
|      | 6                          | 1              | 0x99   | 22                                      |
|      | 7                          | 1              | 0x9A   | 23                                      |
|      | 8                          | 1              | 0x9B   | 24                                      |

## Hardware

The cabling between each pair of boards runs at the same baudrate (20 Mbps).

Currently released AMDS hardware relies on a daisy chain adapter board placed between each pair of AMDS boards to add the necessary transceivers, as illustrated below. Details on this board can be found in the AMDS git repo's [`AMDS/Accessories/DaisyChainAdapter` directory](https://github.com/Severson-Group/AMDS/tree/develop/Accessories/DaisyChainAdapter).

```{image} images/daisy-chain-adapter.svg
:width: 75%
:align: center
:class: only-light
```

```{image} images/daisy-chain-adapter-dark.svg
:width: 75%
:align: center
:class: only-dark
```

Custom cabling must be used between the daisy chain adapter board and the AMDS board to transpose the UART `RX` and `TX` pins, as listed below. This type of cable can be readily manufactured as a do-it-yourself project, or ordered from a custom cable manufacturer such as [ShowMeCables](https://www.showmecables.com/). The cable should use high density, VGA-style 15 pin connectors to match the AMDS `CON1A` port.

```{table} **Custom Cable** for Daisy Chain Adapter Implementation
:align: center

| DCA Pin | DCA Name      | AMDS Pin | AMDS Name     |
|:-------:|:-------------:|:--------:|:-------------:|
| 1       | 5V_CN         | 1        | 5V_CN         |
| 2       | UARTA_IN_P    | 12       | UARTA_OUT_P   |
| 3       | UARTA_IN_N    | 13       | UARTA_OUT_N   |
| 4       | UARTB_IN_P    | 14       | UARTB_OUT_P   |
| 5       | UARTB_IN_N    | 15       | UARTB_OUT_N   |
| 6       | NC            | 6        | NC            |
| 7       | NC            | 7        | SPI1_IP       |
| 8       | NC            | 8        | SPI1_IM       |
| 9       | NC            | 9        | SPI2_IP       |
| 10      | NC            | 10       | SPI2_IM       |
| 11      | GND_CN        | 11       | GND_CN        |
| 12      | UARTA_OUT_P   | 2        | UARTA_IN_P    |
| 13      | UARTA_OUT_N   | 3        | UARTA_IN_N    |
| 14      | UARTB_OUT_P   | 4        | UARTB_IN_P    |
| 15      | UARTB_OUT_N   | 5        | UARTB_IN_N    |
```

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

## Performance

Daisy chain benchmark testing shows the following complete transmission times from assertion of `SYNC_ADC` to the last bit arriving at the AMDC:

- **24 sensors** (3x AMDS boards, each with 8 sensor cards): `27 us`
- **6 sensors** (3x 2S boards, each with 2 sensor cards): `13.7 us`
