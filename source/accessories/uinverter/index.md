# uInverter

The uInverter (micro-inverter) board is an accessory for the AMDC.
The purpose of this board is to serve as a low-cost, micro-level prototype board to demonstrate three-phase current regulation using the AMDC.
It uses a 12V DC supply to drive a three phase RL load circuit to emulate a motor.

## Features

- Three phase AC current and DC bus voltage sensing feedback to AMDC.
- Test points to measure voltages at various locations in the supply as well as load circuits.
- BNC connector to directly measure the current waveforms on an oscilloscope conveniently.

![PCB 3D](images/uInverter3D.jpg)

```{toctree}
:hidden:

Hardware Design <hardware-design>
Connections <connections>
RL Estimation <rl-est/index>
```