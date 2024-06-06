# Encoder Feedback

## Background

Encoders provide the rotor position feedback to the control system in a motor drive. This document describes a method to convert the raw readings of an encoder into meaningful position information which can be used by the contrl algorithm. Consequently, few techniques to derive the rotor speed from the measured position is also proposed. For more information on how an encoder works and how they may be interfaced with the AMDC please refer to this [document](https://docs.amdc.dev/hardware/subsystems/encoder.html#).

## Calibration

- Converting from raw counts to "theta"
- Direction: +/- depending on phase connections
- Sync machines: dq offset

## Computing Speed from Position

- LPF
- State Filter
- Observer

Anirudh will added content here...