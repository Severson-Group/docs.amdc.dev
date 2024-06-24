# Encoder Feedback

## Background

Encoders provide the rotor position feedback to the control system in a motor drive. This document describes a method to convert the raw readings of an encoder into meaningful position information which can be used by the contrl algorithm. Consequently, few techniques to derive the rotor speed from the measured position is also proposed. For more information on how an encoder works and how they may be interfaced with the AMDC please refer to this [document](https://docs.amdc.dev/hardware/subsystems/encoder.html#).

## Calibration

Incremental encoders which are typically used with AMDC have a fixed number of counts per revolution (for example, 1024) and is denoted by `CPR`. The user needs needs to convert the count into usable angular information which maybe used in the code.

### Converting from raw counts to angle information

As a first step, the user may use the AMDC `enc` driver function `encoder_get_position()` to get the count of the encoder reading. Next, the user needs to verify if the encoder count is increasing or decreasing with counter-clock wise rotation of shaft. This may be done by manually rotating the shaft and logging the position reported. This document assumes a positive rotor angular position in the counter clockwise (CCW) direction of shaft rotation. Using this information, along with the offset and total encoder counts per revolution, the obtained count can be translated into angular position using a simple linear equation. Care must be taken by the user to ensure that angle is within the bounds of 0 and 2 $\pi$ by appropriately wrapping the variable.

Example code to convert encoder to angular position in radians:
```C
double task_get_theta_m(void)
{
    // Get raw encoder position
    uint32_t position;
    encoder_get_position(&position);

    int ENCODER_COUNT_PER_REV, CCW;
    double enc_theta_m_offset;

    // User to set encoder count per revolution
    ENCODER_COUNT_PER_REV = 1024;

    // Set 1 if encoder count increases with CCW rotation of shaft, Set 0 if encoder count increases with CW rotation of shaft
    CCW = 1; 

    // Angular position to be computed
    double theta_m_enc;

    // User to set encoder offset
    enc_theta_m_offset = 100;


    // Convert to radians
    if (CCW){
        theta_m_enc = (double) PI2 * ( ( (double)position - enc_theta_m_offset )/ (double) ENCODER_COUNT_PER_REV);
    }
    else{
            theta_m_enc = (double) PI2 * ( ( (double)ENCODER_COUNT_PER_REV - (double)1 -(double)position + enc_theta_m_offset )/ (double) ENCODER_COUNT_PER_REV);
    }
    
     // Mod by 2 pi
    theta_m_enc = fmod(theta_m_enc,PI2 );
    return theta_m_enc;
}
```



### Finding the offset

The example code shown above makes uses of an encoder offset value. It is necessary for the user to find this offset experimentally for their machine. For synchronous machines, this offset is the count value measured by the encoder when the rotor d-axis is aligned with the phase U of the stator. 

To get the rotor to align with the phase U of stator the user may have some current flow through phase U and out of phase V and phase W. Alternately, the user may also inject some current along the d-axis using the AMDC injection function but with the rotor position overridden by the user to 0. After obtaining the offset, the user needs to set the variable `enc_theta_m_offset` to the appropirate value in the `task_get_theta_m()` function. 

The encoder offset maybe validated during operation of a permanent magnet synchrnous motor as follows:
1. Spin the motor up-to a steady speed under no load conditions
1. Measure the d-axis voltage commanded by the current regulator
1. Repeat the experiment for a few different motor speeds
1. Plot the d-axis voltage against the motor speed
1. The d-axis voltage if the offset is tuned correctly should be close to zero for all speeds.
1. In-case there is an error in the offset value, a significant speed dependent voltage will appear on the d-axis voltage



- Converting from raw counts to "theta"
- Direction: +/- depending on phase connections
- Sync machines: dq offset

## Computing Speed from Position

The user needs to compute a rotor speed signal from the obtained position signal to be used in the control algorithm. There are several ways to do this. A simple and straightforward way to do this would be to compute the discrete time derivative of the position signal in the controller as shown below. This can be referred to as $\Omega_{raw}$.


$\Omega_{raw}$ will be a choppy signal due to the derivative operation. A low pass filter may be applied to this signal as shown below to a filtered speed, $\Omega_{lpf}$. The user may select an appropriate bandwidth for the low pass filter. However, this signal will always be a lagging estimate of the actual rotor speed due to low pass filter characterstics. 

An observer which implements a mechanical model of the rotor as shown below will produce a no-lag estimate of the rotor speed.
- LPF
- State Filter
- Observer

Anirudh will added content here...