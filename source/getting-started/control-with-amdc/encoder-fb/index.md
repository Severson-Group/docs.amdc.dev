# Encoder Feedback

## Background

Encoders provide the rotor position feedback to the control system in a motor drive. This document describes a method to convert the raw readings of an encoder into meaningful position information which can be used by the contrl algorithm. Consequently, few techniques to derive the rotor speed from the measured position is also proposed. For more information on how an encoder works and how they may be interfaced with the AMDC please refer to this [document](https://docs.amdc.dev/hardware/subsystems/encoder.html#).

## Calibration

Incremental encoders which are typically used with AMDC have a fixed number of counts per revolution (for example, 1024) and is denoted by `CPR`. The user needs needs to convert the count into usable angular information which maybe used in the code.

### Converting from raw counts to angle information

As a first step, the user may use the AMDC `enc` driver function `encoder_get_position()` to get the count of the encoder reading. Next, the user needs to verify if the encoder count is increasing or decreasing with counter-clock wise rotation of shaft. This may be done by manually rotating the shaft, if it is feasible. This document assumes a positive rotor angular position in the counter clockwise (CCW) direction of shaft rotation. Using this information, along with the offset and total encoder counts per revolution, the obtained count can be translated into angular position using a simple linear equation. Care must be taken by the user to ensure that angle is within the bounds of `0` and `2 $\pi$` by appropriately wrapping the variable.

Example code for when encoder count is increasing with CCW rotation of shaft:
```C
double task_get_theta_m(void)
{
    // Get raw encoder position
    uint32_t position;
    encoder_get_position(&position);

    // Encoder count per revolution
    ENCODER_COUNT_PER_REV = 1024;

    // Angular position to be computed
    double theta_m_enc;

    enc_theta_m_offset = 100;

    // Convert to radians
    theta_m_enc = (double) PI2 * ( ( (double)position - enc_theta_m_offset )/ (double) ENCODER_COUNT_PER_REV);

    // Wrapping to ensure within bounds
    while (theta_m_enc < 0) {
        theta_m_enc += PI2;
    }
    return theta_m_enc;
}
```

Example code for when encoder count is decreasing with CCW rotation of shaft:
```C
double task_get_theta_m(void)
{
    // Get raw encoder position
    uint32_t position;
    encoder_get_position(&position);

    // Encoder count per revolution
    ENCODER_COUNT_PER_REV = 1024;

    // Angular position to be computed
    double theta_m_enc;

    enc_theta_m_offset = 100;

    // Convert to radians
    theta_m_enc = (double) PI2 * ( ( (double)ENCODER_COUNT_PER_REV - (double)1 -(double)position + enc_theta_m_offset )/ (double) ENCODER_COUNT_PER_REV);


    // Wrapping to ensure within bounds
    while (theta_m_enc > PI2) {
        theta_m_enc -= PI2;
    }
    return theta_m_enc;
}
```

### Finding the offset

The example code shown above makes uses of an encoder offset value. It is necessary for the user to find this offset experimentally for their machine. For synchronous machines, this offset is the count value measured by the encoder when the rotor d-axis is aligned with the phase U of the stator. 

To get the rotor to align with the phase U of stator the user may have some current flow through phase U and out of phase V and phase W. Alternately, the user may also inject some Id current with the AMDC injection function but with the rotot position set to 0.

- Converting from raw counts to "theta"
- Direction: +/- depending on phase connections
- Sync machines: dq offset

## Computing Speed from Position

- LPF
- State Filter
- Observer

Anirudh will added content here...