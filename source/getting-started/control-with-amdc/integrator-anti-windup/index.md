# Integrator Anti-Windup

This document describes how to think about performance of anti-windup. A windup might occur when the controller with an integrator has a limitation on the manipulated variables. When integrator windup occurs, it can degrade system response and stability.

## How to think about performance of anti-windup?

Generally, the main components of a control diagram are the controller and plant, as shown in the figure below. The controller provides a manipulated variable to actuate the plant model.

```{image} images/control-diagram.svg
    :align: center
```

In practice, the manipulated variables are physically limited: For example, the manipulated variable of current regulation is voltage reference with a restriction of DC power supply. As another example, in speed control, the manipulated variable is the q-axis current, which is also limited by the current density of coils. Therefore, the control diagram can be rewritten, separating the plant into a saturation block and plant.

```{image} images/control-diagram-sat.svg
    :align: center
```

The difference between these figures is only whether the saturation block exists after the controller. Note the saturation block produces an output signal that is the value of the input signal bounded to the upper saturation value of +Limit and lower saturation value of -Limit. 

Let’s take a look at the simulation result of current regulation with a three-phase voltage source inverter with/without a DC-link limit of 12 V. Therefore, the plant has a known input saturation limit as Limit = 12/2 = 6 V.  

```{image} images/compareSat1.svg
    :align: center
```

In this simulation, a continuous PI controller is used, and a step current of 10 A in the q-axis is generated as a reference. Also, the resistance and the inductance are 0.25 Ohm and 500 uH, respectively. As you can see, the current regulation works right if there is no saturation block, whereas overshoot occurs if a saturation block exists. The following figure shows the output of the integral controller. If the saturated block exists, errors are accumulated, and it takes 0.01 s to converge, a condition known as an integral windup.

Now let’s see the voltage reference in the previous and the post saturation block.

```{image} images/compareSat2.svg
    :align: center
```

The voltage reference in the previous saturation block (denoted as preSat) instantaneously goes to around 15 V outside the DC-link range. On the other hand, the voltage reference in the post saturation block (denoted as postSat) is limited to 6 V due to the DC-link restriction. Even though the saturation block exists, the controller ignores it. Therefore, there is a possibility the PI controller provides the higher voltage after getting the higher error, which causes the windup. As a result, it takes some time to get the output to converge after the integrator accumulates lots of values.

Note: In this simulation, the q-axis current is set as a higher value than the uInverter tutorial to have the voltage saturate intentionally. Make sure that your currents in the coils are within the range of the rated current if you want to demonstrate the voltage windup.


## Different methods

To avoid the integration windup, the method known as “anti-windup” needs to be utilized. Now, the PI controller is shown in the figure below. Note that the integrator includes the anti-windup. 

```{image} images/control-diagram-overview.svg
    :align: center
```

In the anti-windup methods, if the manipulated value reaches the Limit, the integrator is to keep the integrated value from increasing past some specified limit. There are multiple ways to implement integrator anti-windup, however, in this document, two different methods are introduced, i.e., the integrator should do either:
1. Turn the integrator off to avoid accumulating the value further known as the clamping method or
2. Subtract a specific value from the integrator, known as a back-tracking method.


## Implementation

These two methods of clamping and back-tracking are now explained in detail.

### clamping (continuous)

The block diagram of the continuous-time integrator with the clamping method is shown below.

```{image} images/anti-windup-clamping_con.svg
    :align: center
```

 The idea of the clamping method itself is straightforward, i.e., if the manipulated value reaches the Limit, the integrator stops the accumulation of the value. However, the implementation of clamping is slightly complicated. Here is the workflow of clamping:
Step 1. Compare the sign of the preSat and the error. And then, if both signs are equal, the block outputs 1. If not, the block outputs 0.
Step 2. Compare the preSat and postSat. If these values are equal, then no saturation takes place, and the block outputs 0. If they are not equal, i.e., the manipulated variable reaches saturation, and the block outputs 1.
Step 3. The anti-windup output denoted as tracking-signal TR becomes 1 to clamp the integrator only if both outputs of Step 1. and Step 2. are 1. In other words, the integrator clamps integration if the output is saturating AND the error is the same sign as the preSat.
Step 4. If the TR is 1, the input of the integrator becomes 0 as the switch is triggered, i.e., the integrator will effectively shut down the integration during the windup condition.   

Note: Step 2. is recommended to do! For example, if both the error and the preSat are positive, the integrator still adds the output to make it more positive, which causes a worse result. On the other hand, if the error is positive and the preSat is negative, the integrator output brings better results, which works in the direction of canceling the error. Therefore, if the signs of error and preSat are opposite, the anti-windup is not necessary.

### clamping (discrete-time)

The discrete-time PI controller is shown below, where the I gain of Ki becomes KiTs, and the integrator block of 1/s is replaced by 1/(1-z^-1), as opposed to the continuous time equivalency. Note that the backward-Euler method is used in this simulation. Also, the delay block of z^-1 is required after the AND block to avoid the algebraic loop.
```{image} images/anti-windup-clamping_dis.svg
    :align: center
```

### back-tracking (continuous)

The block diagram of the continuous-time integrator with the back-tracking method is shown below. 

```{image} images/anti-windup-back-tracking-con.svg
    :align: center
```

The idea of back-tracking method uses a feedback loop to unwind the internal integrator when the manipulated value hits the Limit. For example, if saturation occurs, TR is calculated as TR = Kb(postSat-preSat) and added into the integrator to avoid the windup. On the other hand, if the saturation does not occur, preSat and postSat must be equal, and TR is 0, i.e., the anti-windup is deactivated.

Note: In general, the feedback gain of Kb is determined by trial and error, depending on the user’s requirements, such as how much overshoot or response-speed you want. There is a paper that shows an example of how to determine the Kb known as a conditioned PI controller. In this literature, the Kb is determined as Kb = Ki/Kp. For detailed information, refer to this paper.

### back-tracking (discrete-time)

Similarly, in the case of a discrete-time PI controller, the I gain of Ki becomes KiTs, and the integrator block of 1/s is replaced by 1/(1-z^-1). Also, the delay block of z^-1 is added after the feedback gain Kb.

```{image} images/anti-windup-back-tracking-dis.svg
    :align: center
```

## Simulink
Here is a Simulink simulation of the discrete-time current regulation without anti-windup, back-tracking, and clamping. The sampling time is set as Ts = 0.0001 sec. In the voltage reference, the voltages are saturated up to 6 V. In the current waveforms, an overshoot occurs without anti-windup. However, in the case of the back-tracking and clamping, the overshoot does not occur, where the response of the back-tracking is comparatively higher. In the integrator output, no overshoots appear in both back-tracking and clamping. Note that accumulation of the value with clamping stops while the voltage is saturated.

```{image} images/result.svg
    :align: center
```

## Handwritten C code

If you want to implement the anti-windup in your experiments, you can have the handwritten C code below. Note that the callback function is executed every sample time of Ts.

### clamping

```C

  const double Ts = 0.0001; // Sampling time [sec]
  const double Kp = 1.57; // P gain
  const double Ki = 785; // I gain
  double Error;
  double I_out; // Integrator output
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

### back-tracking

```C

  const double Ts = 0.0001; // Sampling time [sec]
  const double Kp = 1.57; // P gain
  const double Ki = 785; // I gain
  double Error;
  double I_out; // Integrator output
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
