# Encoder Feedback

## Background

Encoders provide rotor position feedback to the control system in a motor drive. This document describes a method to convert the raw readings of an encoder into meaningful position information which can be used by the contrl algorithm. Consequently, few techniques to derive the rotor speed from the measured position are also proposed. For more information on how an encoder works and how they may be interfaced with the AMDC please refer to this [document](https://docs.amdc.dev/hardware/subsystems/encoder.html#).

## Calibration

Incremental encoders which are typically used with AMDC have a fixed number of counts per revolution (for example, 1024) and is denoted by `CPR`. The user needs needs to write some code to obtaine the encoder count at a given instance and tconvert the count into usable angular information which can be used within the control code.

### Obtaining encoder count and translating it into rotor position

<img src="./resources/EncoderCodeBlockDiargam.svg" width="60%" align="center"/>

As a first step, the user may use the AMDC `enc` driver function `encoder_get_position()` to get the count of the encoder reading. Next, the user needs to verify if the encoder count is increasing or decreasing with counter-clock wise rotation of shaft. This may be done by manually rotating the shaft and observing the trend of the reported position with respect to the direction of rotation. This document follows the convention of a positive rotor angle in the counter clockwise (CCW) direction of shaft rotation. Using this information, along with the offset and total encoder counts per revolution, the obtained count can be translated into angular position using a simple linear equation. The user must ensure that angle is within the bounds of 0 and 2 $\pi$ by appropriately wrapping the variable using the `mod` function.

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

The example code shown above makes uses of an encoder offset value. It is necessary for the user to find this offset experimentally for their machine. For synchronous machines, this offset is the count value measured by the encoder when the d-axis of the rotor is aligned with the phase U winding of the stator. 

To get the rotor to align with the phase U winding, the user may have some current flow through phase U and out of phase V and phase W. This can done by using a DC supply, with phase U connected to the positive terminal and phases V and W connected to the negative terminal. Alternately, the user may also inject some current along the d-axis using the AMDC injection function, but with the rotor position overridden by the user to 0. After obtaining the offset, the user needs to set the variable `enc_theta_m_offset` to the appropirate value in the `task_get_theta_m()` function. 

To ensure that the obtained encoder offset is correct, the user may perform additional validation. For a permanent magnet synchronous motor, this can be done as follows:

1. Spin the motor up-to a steady speed under no load conditions
1. Measure the d-axis voltage commanded by the current regulator
1. Repeat the experiment for a few different motor speeds
1. Plot the d-axis voltage against the motor speed
1. The d-axis voltage if the offset is tuned correctly, should be close to zero for all speeds.
1. In-case there is an error in the offset value, a significant speed dependent voltage will appear on the d-axis voltage



## Computing Speed from Position

The user needs to compute a rotor speed signal from the obtained position signal to be used in the control algorithm. There are several ways to do this. A simple and straightforward way to do this would be to compute the discrete time derivative of the position signal in the controller as shown below. This can be referred to as $\Omega_{raw}$.
$$
\Omega_\text{raw}[k] = \frac{\theta_m[k] - \theta_m[k-1]}{T_s} 
$$


$\Omega_\text{raw}$ will be a choppy and noisy signal due to the derivative operation. A low pass filter may be applied to this signal as shown below to get a filtered speed, $\Omega_\text{lpf}$. The user may select an appropriate bandwidth, $\omega_b$ for the low pass filter to eliminate the noise introduced by the derivative operation. However, this signal will always be a lagging estimate of the actual rotor speed due to the characterstics of a low pass filter. 

$$
 \Omega_\text{lpf}[k] =  \Omega_\text{raw}[k](1 - e^{\omega_b T_s}) + \Omega_\text{lpf}[k-1]e^{\omega_b T_s}
$$

An observer which implements a mechanical model of the rotor as shown below will produce a no-lag estimate of the rotor speed, denoted by $\Omega_\text{sf}$. To implement an observer, the user needs to know the system parameters - `J` - the inertia of the rotor shaft and `b` - the damping coefficient of the rotor shaft. Further, to obtain a no-lag estimate it is necessary to provide the electromechanical torque, $T_{em}$ as input to the mechanical model. The `P-I` part of the observer closes the loop on the speed with $\Omega_\text{raw}$ being the reference input. The recommended tuning approach is as follows:

$$
K_p = \omega_{sf}b, K_i = \omega_{sf}J
$$

This tuning ensures a pole zero cancellation in the closed transfer function, resulting in a unity transfer function for speed tracking under ideal parameter estimates of `J` and `b`

<img src="./resources/ObserverFigure.svg" width="75%" align="center"/>
