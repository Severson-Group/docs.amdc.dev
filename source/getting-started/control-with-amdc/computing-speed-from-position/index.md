# Computing Speed from Position

## Background

Most motor control applications also require the user to compute rotor speed. This is typically done by processing the position signal. There are several ways to calculate speed from position, of varying accuracy and implementation complexity, and the most common approaches are now presented.

### Difference Equation Approach

A simple, but naive, way to do this would be to compute the discrete time derivative of the position signal in the controller as shown below. This can be referred to as $\Omega_\mathrm{raw}$.

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

To obtain a no-lag estimate of the rotor speed, users may create an observer [[2]](#enc-ref-1), which implements a mechanical model of the rotor as shown below.

```{image} resources/observer-figure.svg
:alt: Observer Figure
:width: 600px
:align: center
:class: only-light
```

```{image} resources/observer-figure-dark.svg
:alt: Observer Figure
:width: 600px
:align: center
:class: only-dark
```

The estimate of rotor speed is denoted by $\Omega_\text{sf}$. To implement this observer, the user needs to know the system parameters:

- `J`: the inertia of the rotor
- `b` the damping coefficient of the rotor.

It is also necessary to provide the electromechanical torque, $T_\mathrm{em}$ as input to the mechanical model.

The `PI` portion of the observer closes the loop on the speed, with $\Omega_\text{raw}$ being the reference input. The recommended tuning approach is as follows:

$$
K_\mathrm{p} = \omega_\mathrm{sf}b, K_\mathrm{i} = \omega_\mathrm{sf}J
$$

This tuning ensures a pole zero cancellation in the closed transfer function, resulting in a unity transfer function for speed tracking under ideal parameter estimates of `J` and `b`.  An observer bandwidth of 10 Hz is typical of most systems, but similar to the low pass filter approach, users may need to alter this based on the unique aspects of their system.

## References

(enc-ref-1)=

1. R. D. Lorenz and K. W. Van Patten, "High-resolution velocity estimation for all-digital, AC servo drives," in IEEE Transactions on Industry Applications, vol. 27, no. 4, pp. 701-705, July-Aug. 1991, doi: [10.1109/28.85485](https://doi.org/10.1109/28.85485).
