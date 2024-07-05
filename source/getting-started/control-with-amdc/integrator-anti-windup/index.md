# Integrator Anti-Windup

This article describes how to evaluate performance of anti-windup. A windup might occur when the controller with an integrator faces limitations on the manipulated variables, leading to degraded system response and stability. The effectiveness of anti-windup strategy depends on the duration of the windup and how extreme it is.  Therefore, simulating realistic scenarios of windup and anti-windup performance is crucial to investigate specific scenarios that are likely to be encountered since perfect anti-windup is unachievable.

## How to think about performance of anti-windup?

### Block Diagram with Saturation

Generally, the primary components of a control diagram are the controller and plant. The controller provides a manipulated variable to actuate the plant model. Practically, manipulated variables are limited by the actuator’s capability. The figure below illustrates a practical block diagram considering the saturation block, demonstrating the physical limitations of the actuator input.

```{image} images/control-diagram-sat.svg
    :align: center
```

In this example, a simple plant model of 1/(s+1) is employed, with the saturation block located before the plant. Note the saturation block produces an output signal bounded to the upper saturation value of `+Limit` and lower saturation value of `-Limit`. This system can be analyzed from following perspectives:

1. Current regulation: 
    - Plant input: Voltage reference
    - Output: Current
    - Physical limitation: The realistic output voltage is restricted by the capability of the DC power supply

2. Speed control: 
    - Plant input: q-axis current command
    - Output: Rotational speed of the electric machinery
    - Physical limitation: The practical output current is limited by the coil current density, typically 8 A/mm^2 (air-cooling).

3. Temperature control: 
    - Plant input: Heat
    - Output: Resulting system temperature
    - Physical limitation: The heater’s power rating (e.g., 1 kW) limits the actuator.

In this example, the PI controller is employed to achieve the desired system response. The PI gains are set to achieve the first response with a bandwidth of 10 Hz, i.e., $K_p = 2\pi \times 10$, and $K_i = 2\pi \times 10$. 

In practice, the manipulated variables are physically limited: For example, the manipulated variable of  [current regulation](../../../applications/current-control/index.md) is voltage reference with a restriction of DC power supply. As another example, in [speed control](../../../applications/speed-control/index.md), the manipulated variable is the $q$-axis current, which is also limited by the current density of coils. Therefore, the control diagram can be rewritten, separating the plant into a saturation block and plant.

```{image} images/control-diagram-sat.svg
    :align: center
```

The difference between these figures is only whether the saturation block exists after the controller. Note the saturation block produces an output signal bounded to the upper saturation value of `+Limit` and lower saturation value of `-Limit`. 

Let’s take a look at the simulation result of current regulation with a three-phase voltage source inverter with/without a DC-link limit of `12 V`. Therefore, the plant has a known input saturation limit as `Limit = 12/2 = 6 V`.  

```{image} images/compareSat1.svg
    :align: center
```

In this simulation, a continuous PI controller is used, and a step current of 10 A in the $q$-axis is generated as a reference. Also, the resistance and the inductance are 0.25 $\Omega$ and 500 $\mu$H, respectively. As you can see, the current regulation works right if there is no saturation block, whereas overshoot occurs if a saturation block exists. The following figure shows the output of the integrator. If the saturated block exists, errors are accumulated, and it takes 0.01 sec to converge, a condition known as an integral windup.

Now let’s see the voltage reference in the previous and the post saturation block.

```{image} images/compareSat2.svg
    :align: center
```

The voltage reference in the previous saturation block (denoted as `preSat`) instantaneously goes to around 15 V outside the DC-link range. On the other hand, the voltage reference in the post saturation block (denoted as `postSat`) is limited to 6 V due to the DC-link restriction. Even though the saturation block exists, the controller ignores it. Therefore, there is a possibility the PI controller provides the higher voltage after getting the higher error, which causes the windup. As a result, it takes some time to get the output to converge after the integrator accumulates lots of values.

## Different methods

To avoid the integral windup, the method known as anti-windup needs to be utilized. Now, the PI controller is shown in the figure below. Note that the integrator includes the anti-windup. 

```{image} images/control-diagram-overview.svg
    :align: center
```

In the anti-windup methods, if the manipulated variable reaches the `Limit`, the integrator is to keep the integrated value from increasing past the specified limit. There are multiple ways to implement integrator anti-windup, however, two different methods are introduced here, i.e., the integrator should do either:

1. Turn the integrator off to avoid accumulating the value further known as a **clamping method** or
2. Subtract a specific value from the integrator known as a **back-tracking method**.


## Implementation

These two methods of clamping and back-tracking are now explained in detail.

### clamping (continuous)

The block diagram of the continuous integrator with the clamping method is shown below.

```{image} images/anti-windup-clamping_con.svg
    :scale: 65%
    :align: center
```

 The idea of the clamping method itself is straightforward, i.e., if the manipulated variable reaches the `Limit`, the integrator stops the accumulation of the value. However, the implementation of clamping is slightly complicated. Here is the workflow of clamping:

**Step 1.** Compare the sign of the `preSat` and the `Error`. And then, if both signs are equal, the block outputs 1. If not, the block outputs 0.

**Step 2.** Compare the `preSat` and `postSat`. If these values are not equal, i.e., the manipulated variable reaches saturation, the block outputs 1. If they are equal, then no saturation takes place, and the block outputs 0.

**Step 3.** The anti-windup output denoted as tracking-signal `TR` becomes 1 to clamp the integrator only if both outputs of **Step 1.** and **Step 2.** are 1. In other words, the integrator clamps integration if the output is saturating AND the `Error` is the same sign as the `preSat`.

If the `TR` is 1, the input of the integrator becomes 0 as the switch is triggered, i.e., the integrator will effectively shut down the integration during the windup condition.   

```{note}
**Step 1.** is recommended to do! For example, if both the `preSat` and the `Error` are positive, the integrator still adds the output to make it more positive, which causes a worse result. On the other hand, if the `preSat` is negative and the `Error` is positive, the integrator output brings better results, which works in the direction of canceling the error. Therefore, if the signs of `preSat` and `Error` are opposite, the anti-windup is not necessary.
```

### clamping (discrete-time)

The discrete-time PI controller is shown below, where the I gain of $K_i$ becomes $K_iT_s$, and the integrator block of $1/s$ is replaced by $1/(1-z^{-1})$, as opposed to the continuous time equivalency. Note that the backward-Euler method is used in this document. Also, the delay block of $z^{-1}$ is required after the AND block to avoid the algebraic loop.

```{image} images/anti-windup-clamping_dis.svg
    :scale: 65%  
    :align: center
```

### back-tracking (continuous)

The block diagram of the continuous integrator with the back-tracking method is shown below. 

```{image} images/anti-windup-back-tracking-con.svg
    :scale: 65%
    :align: center
```

The idea of back-tracking method is to use a feedback loop to unwind the internal integrator when the manipulated variable hits the `Limit`. For example, if saturation occurs, `TR` is calculated as `TR = Kb(postSat-preSat)` and added into the integrator to avoid the windup, where $K_b$ is a feedback gain of the back-tracking. On the other hand, if the saturation does not occur, `preSat` and `postSat` must be equal, and `TR` is 0, i.e., the anti-windup is deactivated.

```{tip}
In general, the feedback gain of $K_b$ is determined by trial and error, depending on the user’s requirements, such as how much overshoot or response-speed they want. There is a paper that shows an example of how to determine the $K_b$ known as a `conditioned PI controller`. In this literature, the $K_b$ is determined as $K_b = K_i/K_p$. For detailed information, refer to [this paper](https://www.sciencedirect.com/science/article/pii/000510988790029X).
```

### back-tracking (discrete-time)

Similarly, in the case of a discrete-time PI controller, the I gain of $K_i$ becomes $K_iT_s$, and the integrator block of $1/s$ is replaced by $1/(1-z^{-1})$. Also, the delay block of $z^{-1}$ is added after the feedback gain $K_b$.

```{image} images/anti-windup-back-tracking-dis.svg
    :scale: 65%
    :align: center
```

## Simulink
Here is a Simulink simulation of the discrete-time current regulation without anti-windup, back-tracking, and clamping. 

```{image} images/result.svg
    :align: center
```

The sampling time is set as $T_s = 0.0001$ sec. In the voltage reference, the voltages are saturated up to 6 V, where the voltages converge faster in back-tracking and clamping. In the current waveforms, an overshoot occurs without anti-windup. However, in the case of the back-tracking and clamping, the overshoot does not occur, where the response of the back-tracking is comparatively higher. In the integrator output, no overshoots appear in both back-tracking and clamping. Note that accumulation of the value with clamping stops while the voltage is saturated.

## Handwritten C code

If you want to implement the anti-windup in your experiments, you can have the handwritten C code below. Note that the callback function is executed every sample time of $T_s$.

### clamping

```C
const double Ts = 0.0001; // Sampling time [sec]
const double Kp = 1.57; // P gain
const double Ki = 785; // I gain
double Error;
double I_out;
const double Limit;
double preSat;
double postSat;
int Error_sign;
int preSat_sign;
int TR;

void task_clamping_callback(void *arg)
{
    // clamping
    if (TR) {
        I_out = 0;
    } else {
        I_out += Ki * Ts * Error;
    }

    // PI controller
    preSat = Kp * Error + I_out;

    // Saturate
    if (preSat > Limit) {
        postSat = Limit;
    } else if (preSat < -Limit) {
        postSat = -Limit;
    } else {
        postSat = preSat;
    }

    //  Sign of the Error
    if (Error > 0.0) {
        Error_sign = 1.0;
    } else if (Error < 0.0) {
        Error_sign = -1.0;
    } else {
        Error_sign = 0;
    }
    //   Sign of the preSat
    if (preSat > 0.0) {
        preSat_sign = 1.0;
    } else if (preSat < 0.0) {
        preSat_sign = -1.0;
    } else {
        preSat_sign = 0;
    }

    // Logic: AND
    TR = ((Error_sign == preSat_sign) && (preSat != postSat));
}
```

### back-tracking

```C
const double Ts = 0.0001; // Sampling time [sec]
const double Kp = 1.57; // P gain
const double Ki = 785; // I gain
double Error;
double I_out;
const double Limit;
double preSat;
double postSat;
const double Kb = 0.05; // back-tracking gain (= Ki*Ts/Kp)
double TR;

void task_back_tracking_callback(void *arg)
{
    // I controller
    I_out = (Ki * Ts * Error + I_out) + TR;

    // PI controller
    preSat = Kp * Error + I_out;

    // Saturate
    if (preSat > Limit) {
        postSat = Limit;
    } else if (preSat < -Limit) {
        postSat = -Limit;
    } else {
        postSat = preSat;
    }

    // back-tracking
    TR = (postSat - preSat) * Kb;
}
```
