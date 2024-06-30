# Encoder Feedback

## Background

Encoders provide rotor position feedback to the control system in a motor drive. This document describes a method to convert the raw readings of an encoder into meaningful position information which can be used by the contrl algorithm. Next, useful methods to obtain rotor speed from the measured position is presented. For more information on how an encoder works and how they may be interfaced with the AMDC please refer to this [document](https://docs.amdc.dev/hardware/subsystems/encoder.html#).

## Calibration

Incremental encoders are typically used with the AMDC and have a fixed number of counts per revolution `CPR` (for example, `CPR = 1024`). The user needs to provide code that interfaces to the AMDC's drivers to read the encoder count and convert it into usable angular information that is suitable for use within the control code.

### Obtaining encoder count and translating it into rotor position

The recommended approach to reading the shaft position from the encoder is illustrated in the figure below:

<img src="./resources/EncoderCodeBlockDiargam.svg" width="100%" align="center"/>

As a first step, the user may use the AMDC `drv/encoder` driver module `encoder_get_position()` to get the count of the encoder reading. The`drv/encoder` driver module also has a function called `encoder_get_steps()` which gives the incremental change in the encoder position. Whereas, `encoder_get_position()` gives the actual position of the shaft and this can be converted to rotor position in radians.

 Next, the user needs to verify if the encoder count is increasing or decreasing with counter-clock wise rotation of shaft. This may be done manually by rotating the shaft and observing the trend of the reported position with respect to the direction of rotation. In the figure, the signal `CCW` indicates this directionality. It must be  set to `1`, if the encoder count increases with the counter clockwise rotation of shaft and `0` otherwise. Additionally, the user needs to provide the encoder offset, `offset` and the encoder counts per revolution, `ENCODER_COUNT_PER_REV`. A method to get the value of offset is described in the next [subsection](#finding-the-offset). Using all of this quantities, the obtained count can be translated into angular position using a simple linear equation.  Note that, this document follows the convention of a positive rotor angle in the counter clockwise direction of shaft rotation while caclulating rotor position from the count signal.
 
 Finally, the user must ensure that angle is within the bounds of $0$ and $2\pi$ by appropriately wrapping the `rotor position` signal using the `mod` function. This is shown in the final block in the diagram.

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
    theta_m_enc = fmod(theta_m_enc,PI2);
    return theta_m_enc;
}
```



### Finding the offset

The example code shown above makes uses of an encoder offset value, `enc_theta_m_offset`. It is necessary for the user to find this offset experimentally for their machine. For synchronous machines, this offset is the count value measured by the encoder when the d-axis of the rotor is aligned with the phase U winding axis of the stator. 

To determine the appropriate offset value, eliminate any source of load torque on the shaft and apply a large current vector at 0 degrees ($I_u = I_0$, $I_v = I_w = -\frac{1}{2} I_0$). This should cause the rotor to align with the phase U winding axis. The offset value can now be obtained as `enc_theta_m_offset = encoder_get_position()`. Alternately, the user may also inject a current along the d-axis using the AMDC [Signal Injection](https://docs.amdc.dev/getting-started/user-guide/injection/index.html) module. While injecting d-axis current, the user must ensure that the rotor position is set to zero in the control code. 

After obtaining the offset, the user needs to set the variable `enc_theta_m_offset` to the appropriate value in the `task_get_theta_m()` function. 

To ensure that the obtained encoder offset is correct, the user may perform additional validation. For a permanent magnet synchronous motor, this can be done as follows:

1. Spin the motor up-to a steady speed under no load conditions
1. Measure the d-axis voltage commanded by the current regulator
1. Repeat the experiment for a few different rotor speeds
1. Plot the d-axis voltage against the rotor speed
1. The d-axis voltage should be close to zero for all speeds, if the offset is tuned correctly
1. In-case there is an error in the offset value, a significant speed dependent voltage will appear on the d-axis voltage. In this case, the user may have to re-measure the encoder offset.



## Computing Speed from Position

The user needs to compute a rotor speed signal from the obtained position signal to be used in the control algorithm. There are several ways to do this. 

### Difference Equation Approach

A simple, but naive, way to do this would be to compute the discrete time derivative of the position signal in the controller as shown below. This can be referred to as $\Omega_{raw}$.

$$
\Omega_\text{raw}[k] = \frac{\theta_m[k] - \theta_m[k-1]}{T_s} 
$$


Unfortunately, using this approach results in noise in $\Omega_\text{raw}$ due to the derivative operation and the digital nature of the incremental encoder. 

### Low Pass Filter Approach

To solve this, _a low pass filter_ may be applied to this signal. This is shown below to obtain a filtered speed, $\Omega_\text{lpf}$.

$$
 \Omega_\text{lpf}[k] =  \Omega_\text{raw}[k](1 - e^{\omega_b T_s}) + \Omega_\text{lpf}[k-1]e^{\omega_b T_s}
$$

### Observer Approach

To obtain a no-lag estimate of the rotor speed, users may create an observer [[1]](#1), which implements a mechanical model of the rotor as shown below. 

<img src="./resources/ObserverFigure.svg" width="100%" align="center"/>


The estimate of rotor speed is denoted by $\Omega_\text{sf}$. To implement this observer, the user needs to know the system parameters:
- `J`: the inertia of the rotor  
- `b` the damping coefficient of the rotor. 

It is also necessary to provide the electromechanical torque, $T_{em}$ as input to the mechanical model. 

The `PI` portion of the observer closes the loop on the speed, with $\Omega_\text{raw}$ being the reference input. The recommended tuning approach is as follows:
$$
K_p = \omega_{sf}b, K_i = \omega_{sf}J
$$

This tuning ensures a pole zero cancellation in the closed transfer function, resulting in a unity transfer function for speed tracking under ideal parameter estimates of `J` and `b`.  An observer bandwidth of 10 Hz is typical of most systems, but similar to the low pass filter approach, users may need to alter this based on the unique aspects of their system.


# References
<a id="1"></a> 1.  R. D. Lorenz and K. W. Van Patten, "High-resolution velocity estimation for all-digital, AC servo drives," in IEEE Transactions on Industry Applications, vol. 27, no. 4, pp. 701-705, July-Aug. 1991, doi: 10.1109/28.85485. keywords: {Servomechanisms;Optical feedback;Optical signal processing;Transducers;Signal resolution;Velocity measurement;Position control;Feedback loop;Velocity control;Noise reduction}

