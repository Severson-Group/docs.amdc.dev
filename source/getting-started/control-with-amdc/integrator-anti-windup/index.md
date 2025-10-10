# Integrator Anti-Windup

This article describes how to evaluate performance of anti-windup. A windup might occur when the controller with an integrator faces limitations on the manipulated variables, leading to degraded system response and stability. The effectiveness of anti-windup strategy depends on the duration of the windup and how extreme it is.  Therefore, simulating realistic scenarios of windup and anti-windup performance is crucial to investigate specific scenarios that are likely to be encountered since perfect anti-windup is unachievable.

## Exploring Windup Phenomena in Integrators

### Block Diagram with Saturation

Generally, the primary components of a control diagram are the controller and plant. The controller provides a manipulated variable to actuate the plant model. Practically, manipulated variables are limited by the actuator’s capability. The figure below illustrates a practical block diagram considering the saturation block, demonstrating the physical limitations of the actuator input.

```{image} images/control-diagram-sat.svg
    :align: center
```

In this example, a simple plant model of 1/(s+1) is employed, with the saturation block located before the plant. Note the saturation block produces an output signal bounded to the upper saturation value of `+Limit` and lower saturation value of `-Limit`. This system can be analyzed from following perspectives:

1. Current regulation:
    - Plant input: Voltage command
    - Output: Current
    - Physical limitation: The realistic output voltage is restricted by the capability of the DC power supply

2. Speed control:
    - Plant input: $q$-axis current command
    - Output: Rotational speed of the electric machinery
    - Physical limitation: The practical output current is limited by the coil current density, typically 8 A/mm<sup>2</sup> (air-cooling).

3. Temperature control:
    - Plant input: Heat
    - Output: Resulting system temperature
    - Physical limitation: The heater’s power rating (e.g., 1 kW) limits the actuator.

In this example, the PI controller is employed to achieve the desired system response. The PI gains are set to achieve the first response with a bandwidth of 10 Hz, i.e., $K_p = 2\pi \times 10$, and $K_i = 2\pi \times 10$.

### Technical Challenges on Windup

This section provides the practical challenges from the actuator’s input limitations, especially on the command tracking and disturbance suppression. A definition of windup will be introduced.

#### Command Tracking without/with Actuator Limitations

Let us analyze the simulation result with the block diagram above to investigate the technical challenges on windup. Two scenarios are compared here:  one “without saturation block” and one “with the saturation block”. The objective of this analysis is to evaluate the impact of its saturation block on the output performance. Assume a step command of 1 is generated as a reference at 0.2 seconds and the plant has a known input saturation limit defined as `Limit = 10`.  

```{image} images/Output_sat_c.svg
    :align: center
    :width: 600
```

```{image} images/Iout_sat_c.svg
    :align: center
    :width: 600
```

As observed, the command can track correctly without saturation block, whereas overshoot with slow response occurs is present when the saturation block. The second figure shows the output of the integrator. With the saturated block, errors are accumulated, leading to delayed convergence, a condition known as an integral windup.

Next, let us examine the manipulated variable in the previous and the post saturation block.

```{image} images/preSat_postSat.svg
    :align: center
    :width: 600
```

In the previous saturation block (`preSat`), the manipulated variable instantaneously exceeds 60, beyond the saturation range of 10. On the other hand, the voltage reference in the post saturation block (`postSat`) is limited to 10.  As demonstrated in this example, the controller disregards the presence of the saturation block because it has no information about real-world saturation occurrences. Consequently, the PI controller may provide a higher manipulated variable after getting the higher error, which causes the windup.

#### Disturbance Suppression without/with Actuator Limitations

Disturbances can degrade the system by introducing unexpected/rapid changes. Let us examine if disturbances affect on the behavior of the integrator. In this scenario, the command is set as 0, and the disturbance of 15 (i.e., higher value than `Limit = 10`) is injected at 0.2 seconds and end at 0.3 seconds, requiring the disturbance to be suppressed and the output to track back to 0.

```{image} images/Disturbance.svg
    :align: center
    :width: 600
```

```{image} images/Output_sat_d.svg
    :align: center
    :width: 600
```

In the transient response of `Output` when the disturbance ends, it is observed that with the saturation block, there is a larger negative overshoot and slower convergence to 0 compared to the case without the saturation block. This is because the integrator continues to integrate error caused by the disturbance.

## Anti-Windup Techniques

To avoid the integral windup, the mitigation strategy known as the anti-windup strategy is now introduced. The block diagram incorporating an integrator with the anti-windup is shown in the figure below.

```{image} images/control-diagram-overview.svg
    :align: center
```

In the anti-windup methods, if the manipulated variable reaches the specified `Limit`, the integrator is to keep the integrated value from increasing past the specified limit. There are multiple ways to implement integrator anti-windup, however, two common methods are introduced here:

1. [**Clamping**](#clamping): Turn off the integrator to stop further accumulation of the value. This can be divided into two methods, i.e., [simple clamping](#simple-clamping) and [advanced clamping](#advanced-clamping).

2. [**Back-tracking**](#back-tracking): Subtract a specific value from the integrator.

These two methods are now explained in detail.

### Clamping

Clamping is a straightforward anti-windup strategy where the integrator is simply "clamped" to prevent it from exceeding a certain limitation, which is called simple clamping in this article. Advanced clamping, on the other hand, is a more sophisticated from simple clamping that engages only under specific conditions.

### Simple Clamping

The simple version of clamping simply stops integrating when `preSat` $\neq$ `postSat`. The block diagram of the integrator with the simple clamping method is shown below.

```{image} images/anti-windup-simple-clamping.svg
    :align: center
    :width: 70%
```

Here is a Simulink simulation of the no anti-windup and simple clamping.

#### Command Tracking

```{image} images/Output_simple_c.svg
    :align: center
    :width: 600
```

```{image} images/postSat_simple_c.svg
    :align: center
    :width: 600
```

```{image} images/Iout_simple_c.svg
    :align: center
    :width: 600
```

In the `Output` waveforms, an overshoot is observed when there is no anti-windup. However, with the simple clamping method, the overshoot is eliminated. In the `postSat`, the manipulated variables are saturated up to 10, where the manipulated variable converge more rapidly in the simple clamping. In the integrator output, no overshoots are present when using simple clamping.

#### Disturbance Suppression

```{image} images/Disturbance.svg
    :align: center
    :width: 600
```

```{image} images/Output_simple_d.svg
    :align: center
    :width: 600
```

From the disturbance suppression simulation results, it is evident that the overshoot and convergence are significantly improved when the simple clamping method is employed.

### Advanced Clamping

Now, the advanced version of clamping is introduced as shown below the block diagram.

```{image} images/anti-windup-advanced-clamping.svg
    :align: center
    :width: 70%
```

In the advanced clamping method, the behavior itself is essentially similar to that of simple clamping. However, it includes an additional condition as a trigger of anti-windup, i.e., clamping occurs only when the signs of the `Error` and `preSat` are the same. Here is the workflow of the advanced clamping:

**Step 1.** Compare the `preSat` and `postSat`. If these values are not equal, i.e., the manipulated variable reaches saturation, the block outputs 1. If they are equal, then no saturation takes place, and the block outputs 0 -- this is the same purpose of the simple clamping.

**Step 2.** Compare the sign of the `preSat` and the `Error`. And then, if both signs are equal, the block outputs 1. If not, the block outputs 0 -- this is the additional condition  necessary for advanced clamping.

**Step 3.** The anti-windup output denoted as tracking-signal `TR` becomes 1 to clamp the integrator only if both outputs of **Step 1.** and **Step 2.** are 1. In other words, the integrator clamps integration if the output is saturating AND the `Error` is the same sign as the `preSat`.

If the `TR` is 1, the input of the integrator becomes 0 as the switch is triggered, i.e., the integrator will effectively shut down the integration during the windup condition.

Here is a Simulink simulation of the no anti-windup, simple clamping, and advanced clamping.

```{image} images/Output_advanced_c.svg
    :align: center
    :width: 600
```

```{image} images/postSat_advanced_c.svg
    :align: center
    :width: 600
```

```{image} images/Iout_advanced_c.svg
    :align: center
    :width: 600
```

Notice that the above assumptions cause the simple and advanced clamping to behave identical in this example.

Based on this, a highly specific scenario is now introduced where advanced clamping demonstrates better performance. Here is simulation scenario to demonstrate the superiority of advanced clamping than simple clamping:

**Initial State**: A disturbance of 5 causes the system to saturate and stabilize at -1 output.

**Controller Behavior**: At 5 seconds, the controller set point starts toggling around the saturated output.

Here are simulation results based on the above scenarios:

```{image} images/Disturbance_advanced_better.svg
    :align: center
    :width: 600
```

```{image} images/Output_advanced_better.svg
    :align: center
    :width: 600
```

```{image} images/Iout_advanced_better.svg
    :align: center
    :width: 600
```

From the `Output` result, when the controller set point drops below the output, the advanced clamping method avoids integrating, allowing for effective unwinding. On the other hand, the simple clamping continues to integrate, which may not handle unwinding as effectively as the advanced method. _However_, this can be observed only if the proportional gain of $K_p$ is very small ($= 0.0002*2\pi \times 10$ in this case), which is not commonly preferred, especially if the PI controller is tuned for pole-zero cancellation.
Significant differences in the advanced clamping only appear when the system saturates **AND** signs are different from error vs control output, which is uncommon since the difference in signs usually moves out immediately. Therefore, the highly specific scenario where the system stays in saturation during this flip in signs is necessary to clearly make the advanced method better. This suggests that the effort to implement the advanced clamping version is probably not worth it for the typical motor control systems.

### Back-tracking

The idea of back-tracking method is to use a feedback loop to unwind the internal integrator when the manipulated variable hits the `Limit`. The block diagram of the integrator with the back-tracking method is shown below.

```{image} images/anti-windup-back-tracking.svg
    :align: center
    :width: 70%
```

For example, if saturation occurs, `TR` is calculated as `TR = Kb(postSat-preSat)` and added into the integrator to avoid the windup, where $K_b$ is a feedback gain of the back-tracking. On the other hand, if the saturation does not occur, `preSat` and `postSat` must be equal, and `TR` is 0, i.e., the anti-windup is deactivated.

```{tip}
The selection of $K_b$ is highly nuanced upon the specific event being managed. Making an incorrect choice for $K_b$ can lead to the clamping method better. In practice, the feedback gain of $K_b$ is determined by trial and error, depending on the user’s requirements, such as how much overshoot or response-speed they want. There is a paper that shows an example of how to determine the $K_b$ known as a `conditioned PI controller`. In this literature, the $K_b$ is determined as $K_b = K_i/K_p$. For detailed information, refer to [this paper](https://www.sciencedirect.com/science/article/pii/000510988790029X).
```

Here is a Simulink simulation of the no anti-windup, simple clamping, advanced clamping, and back-tracking.

#### Command Tracking

```{image} images/postSat_back_c.svg
    :align: center
    :width: 600
```

```{image} images/Output_back_c.svg
    :align: center
    :width: 600
```

```{image} images/Iout_back_c.svg
    :align: center
    :width: 600
```

From the `Output` waveform, it is evident that the back-tracking technique marginally improves its response than clamping.

#### Disturbance Suppression

```{image} images/Disturbance.svg
    :align: center
    :width: 600
```

```{image} images/Output_back_d.svg
    :align: center
    :width: 600
```

The disturbance suppression results demonstrate that both the clamping and the back-tracking methods improved the performance. Interestingly, the clamping methods is better to suppress disturbance than the back-tracking in this example. It should be noted that these results were achieved using the back-tracking gain of $K_b = K_i/K_p$, which might be required to adjust based on the specific condition and simulation outcomes.

The anti-windup methods introduced in this article can be implemented by running the Simulink model provided [here](https://github.com/Severson-Group/docs.amdc.dev/source/getting-started/control-with-amdc/integrator-anti-windup).
