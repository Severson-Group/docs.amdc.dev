# Encoder Feedback

## Background

Encoders are used to determine the rotor position and speed, and are the typical method of feedback to the control system in a motor drive. This document explains how to use the AMDC's encoder interface to extract high quality rotor position and speed data.

For more information:

- on how encoders work and are interfaced with the AMDC, see the [encoder hardware subsystem page](https://docs.amdc.dev/hardware/subsystems/encoder.html#)
- on the driver functionality included with the AMDC firmware, see the [encoder driver architecture page](https://docs.amdc.dev/firmware/arch/drivers/encoder.html).

## Rotor Position

The AMDC supports [incremental encoders with quadrature ABZ outputs](https://en.wikipedia.org/wiki/Incremental_encoder#Quadrature_outputs) and a fixed number of counts per revolution `CPR` (for example, `CPR = 1024`). The user needs to provide code that interfaces to the AMDC's drivers to read the encoder count and convert it into usable angular information that is suitable for use within the control code.

### Configuring the encoder

Upon powerup, the AMDC configures the encoder to a default number of pulses per revolution. This is handled in `encoder.c` as part of the standard firmware package. When using an encoder that has a different number pulses per revolution, the user must inform the driver by calling `encoder_set_pulses_per_rev()`.

Example code for a 10 bit encoder:

``` C
#define USER_ENCODER_PULSES_PER_REV_BITS (10)
#define USER_ENCODER_PULSES_PER_REV (1 << USER_ENCODER_PULSES_PER_REV_BITS)

int task_user_app_init(void)
{
    encoder_set_pulses_per_rev(USER_ENCODER_PULSES_PER_REV);
    
    // other user app one-time initialization code
    // ...
```

```{tip}
The AMDC provides a convenience function that can be used as an alternate to `encoder_set_pulses_per_rev()` when the encoder is specified as a number of bits: `encoder_set_pulses_per_rev_bits(USER_ENCODER_PULSES_PER_REV_BITS).` 
```

### Converting the encoder count into rotor position

The recommended approach to reading the shaft position from the encoder is illustrated in the figure below:

<img src="./resources/EncoderCodeBlockDiagram.svg" width="100%" align="center"/>

As a first step, the user may use the AMDC `drv/encoder` driver module function `encoder_get_position()` to get the count of the encoder reading. The`drv/encoder` driver module also has a function called `encoder_get_steps()` which gives the incremental change in the encoder position. Whereas, `encoder_get_position()` gives the actual position of the shaft and this can be converted to rotor position in radians.

 Next, the user needs to verify if the encoder count is increasing or decreasing with counter-clock wise rotation of shaft. This may be done manually by rotating the shaft and observing the trend of the reported position with respect to the direction of rotation. In the figure, the signal `CCW` indicates this directionality. It must be  set to `1` if the encoder count increases with counter clockwise rotation of shaft and `0` otherwise. Additionally, the user needs to provide the encoder offset, `offset`, and the encoder counts per revolution, `ENCODER_COUNT_PER_REV`. A method to get the value of offset is described in the next [subsection](#finding-the-offset). Using all of these quantities, the obtained count can be translated into angular position using a simple linear equation.  Note that this document follows the convention of a positive rotor angle in the counter clockwise direction of shaft rotation while calculating rotor position from the count signal.
 
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

The example code shown above makes use of an encoder offset value, `enc_theta_m_offset`. For synchronous machines, this offset is the count value measured by the encoder when the d-axis of the rotor is aligned with the phase U winding axis of the stator. This value typically needs to be found experimentally for each motor/encoder pair because it depends on how the encoder was aligned when it was coupled to the motor's shaft. This section provides a procedure to determine `enc_theta_m_offset`. 

#### Step 1: Determine approximate offset

The approximate encoder offset can be found using the following simple procedure without feedback control:

1. Set the `enc_theta_m_offset` to 0 in the control code `task_get_theta_m()`.
2. Eliminate any source of load torque on the shaft.
3. Align the rotor with the phase U winding axis by applying a large current vector at 0 degrees ($I_u = I_0$, $I_v = I_w = -\frac{1}{2} I_0$). This could be accomplished by:
    1) Using a DC power supply, or
    2) Injecting a current command on the d-axis using the AMDC [Signal Injection](/getting-started/user-guide/injection/index.rst) module with `theta_m_enc` fixed to 0.
4. Record the current encoder position and use this as the offset value: `enc_theta_m_offset = encoder_get_position();`.
5. Update the variable `enc_theta_m_offset` to the appropriate value in `task_get_theta_m()`.

#### Step 2: Determine precise offset

Friction and cogging torque in the motor decrease the accuracy of the estimate in Step 1. The precise offset can be found by fine-tuning the `enc_theta_m_offset` from Step 1 while using closed-loop control to rotate the shaft at significant speed. This can be done as follows:

1. Configure the AMDC for closed-loop speed and DQ current control and configure the operating environment to allow for quick edits to `enc_theta_m_offset` and for measuring the d-axis voltage commanded by the current regulator. Consider [adding a custom command](/getting-started/tutorials/vsi/index.md#command-template-c-code) and using [logging](/getting-started/user-guide/logging/index.md) to accomplish this.
2. Command the motor to rotate in steady speed under no load conditions. Use the estimated `enc_theta_m_offset` obtained in Step 1.
3. Determine the value of `enc_theta_m_offset` that results in the d-axis voltage being closest to 0V. Do this by monitoring the d-axis voltage while adjusting `enc_theta_m_offset` gradually until the sign of the d-axis voltage flips.
4. Repeat step 3 at several speeds.
5. For each offset value, average the d-axis voltage values for different speeds and select the offset with the lowest average d-axis voltage.
6. Plot the d-axis voltage with the selected offset against the different rotor speeds. The d-axis voltage should be close to zero for all speeds, if the offset is tuned correctly.
7. In-case there is an error in the offset value, a significant speed-dependent voltage will appear on the d-axis voltage. In this case, the user may have to re-measure the encoder offset.

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

Here, $T_{\rm s}$ is the control sample rate and $\omega_b$ is the low pass filter bandwidth. The user must select this bandwidth to obtain a sufficiently clean speed signal.  The optimal bandwidth to use is going to vary based on the motor system. Typically, a bandwidth of 10 Hz is a reasonable starting point. This can be reduced if the speed signal remains too noisy, or increased for higher speed controls. 

Note that this low pass filter approach will always produce a lagging speed estimate due to phase delay in the filter transfer function. This may be unacceptable higher performance motor control algorithms.

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

