# Current

This document describes the design considerations and implementation details for the current card.
A block diagram is presented and each component is discussed in detail. Specifications of each component are provided based on the datasheet.

## Relevant Hardware Versions

REV C

```{image} images/amds_current_card.png
:height: 500px
```

## Design Requirements and Considerations

The current measurement card was designed to the following specifications:

1. Current measurement range
2. Noise immunity
3. Quick adjustment of the sensing range
4. High sensor bandwidth
5. SPI output to interface with the sensor motherboard

## Block Diagram

The high level block diagram of the current sensor card is shown below:

```{image} images/current-sensor-blockdiagram.svg
:class: only-light
```

```{image} images/current-sensor-blockdiagram-dark.svg
:class: only-dark
```

### Current Sensor

To measure a wide range of currents, an open-aperture current sensor is preferred because it allows the measurement range to be adjusted for lower currents by passing multiple turns of the primary conductor through the aperture. A low-impedance current output is also inherently more immune to noise than a high-impedance voltage output. The LEM LA 55-P and LA 100-P current sensors offer these features with PC pins. The following tables summarize key specifications of these sensors:

| Parameters                                                       |            LA 55-P |            LA 100-P |
|:-----------------------------------------------------------------|-------------------:|--------------------:|
| Primary nominal RMS current                                      | 50 A<sub>rms</sub> | 100 A<sub>rms</sub> |
| Primary current, measuring range                                 |         $\pm$ 70 A |         $\pm$ 150 A |
| Burden resistor range                                            | 135 - 155 $\Omega$ |     0 - 33 $\Omega$ |
| Secondary turns, _N_<sub>2</sub>                                 |               1000 |                2000 |
| Turns ratio for _N_<sub>1</sub>, _N_<sub>1</sub>/_N_<sub>2</sub> |             1/1000 |              1/2000 |
| Accuracy                                                         |        $\pm$ 0.65% |         $\pm$ 0.45% |
| Linearity                                                        |            < 0.15% |             < 0.15% |
| Bandwidth                                                        |            200 kHz |             200 kHz |

```{note}
The LA 100 series has three variants, LA 100-P, LA 100-P/SP13, and LA 100-TP, that users must be careful about when ordering. The sensor gains of each of these variants are different, which has implications for the choice of the burden resistor. The rest of this document is specific to the LA 100-P variant.
```

#### Burden Resistor (_R_<sub>_BURDEN_</sub>)

A burden resistor (`R5`) is used to convert the current output of the sensor to a voltage. The burden resistance, _R_<sub>_BURDEN_</sub> was calculated using the following equation

_V_<sub>_BURDEN_</sub>  = (_N_<sub>1</sub>/_N_<sub>2</sub>) _I_<sub>_PRIMARY_</sub> _R_<sub>_BURDEN_</sub>

_R_<sub>_BURDEN_</sub>  = (_V_<sub>_BURDEN_</sub>/_I_<sub>_PRIMARY_</sub>)*(_N_<sub>2</sub>/_N_<sub>1</sub>)

where _N_<sub>1</sub> is the primary turns (the number of turns the user passes through the sensor's window) and _N_<sub>2</sub> is the secondary turns. The selected burden resistor must remain within the range in the sensor datasheet.

#### Current Sensor Gain

The LEM current sensor has a conversion ratios of _N_<sub>1</sub>:_N_<sub>2</sub>. The current-voltage gain across the burden resistor is given by _N_<sub>1</sub>/_N_<sub>2</sub> _R_<sub>_BURDEN_</sub>. The measurement range can be reduced by increasing the number of primary turns without the need to modify any other parts of the circuit. For example, increasing _N_<sub>1</sub> from 1 to 10 allows currents 10 times lower to be measured with the same output voltage range.

### Voltage Reference (LDO)

The voltage reference, _V_<sub>_REF_</sub> is needed for the ADC. As 5V is readily available, and the LDO will have a minimum drop out voltage,  _V_<sub>_REF_</sub> = 4.5 V was chosen (beginning with board revision C). The LDO selected was `REF5045` from Texas Instruments, which can take a 5 V input and provide a 4.5V reference output. This has an accuracy of 0.1% and low noise of 3μVpp/V.

### Op Amp Stage

A non-inverting level translation circuit is implemented using Op Amps as shown here:

```{image} images/current-sensor-opamp-stage.svg
:class: only-light
```

```{image} images/current-sensor-opamp-stage-dark.svg
:class: only-dark
```

This circuit is used to translate the voltage across the burden resistor, which is bipolar (voltage span includes both positive and negative voltages), to the ADC input range of 0-$V_{\rm REF}$.

The output voltage for this circuit can be solved as:

$$
V_{\rm out} = \frac{R_{\rm a} R_{\rm b}}{R_{\rm a} R_{\rm b} + R_{\rm a} R_{\rm c} + R_{\rm b} R_{\rm c}} V_{\rm REF} + \frac{R_{\rm b} R_{\rm c}}{R_{\rm a} R_{\rm b} + R_{\rm a} R_{\rm c} + R_{\rm b} R_{\rm c}} V_{\rm BURDEN}
$$

A more precise expression for $V_{\rm BURDEN}$ can be derived as:

$$
V_{\rm BURDEN} = \frac{R_{\rm a} R_{\rm BURDEN}}{R_{\rm a} + R_{\rm BURDEN}} \left(\frac{N_1}{N_2}\right) I_{\rm PRIMARY} + \frac{R_{\rm BURDEN} }{R_{\rm a} + R_{\rm BURDEN}} V_{\rm out}
$$

The resistor values can be calculated from solving these expressions analytically. However, the algebra gets quite complicated. Instead, these values were computed using the [TI analog engineer's calculator](https://www.ti.com/tool/ANALOG-ENGINEER-CALC).

```{attention}
As the op-amp output voltage approaches the supply rails, it tends to distort and behave nonlinearly. It is recommended to limit the output voltage to stay within 0.2V to 4.5V for best performance. The user is advised to consider their required current measurement range with the [final voltage expressions](#voltage-relationship) to select an appropriate number of [primary turns](#current-sensor-gain).
```

### First Order Anti-Aliasing Filter

A first order RC filter is implemented on the output of the op amp circuit. The cutoff frequency was set at 48kHz and the following equations was used for the computation:

$$f_c = \frac{1}{2\pi RC} $$

**Note:** The cutoff frequency can easily be changed by swapping out `R3`.

### Analog to Digital Converter

A single-ended ADC was selected. The ADC used is the Texas Instruments [ADS8860](https://www.ti.com/product/ADS8860). It is a pseudo-differential input, SPI output, SAR ADC. The maximum data throughput for a single chip is 1 MSPS but decreases by a factor of N for N devices in the daisy-chain. The input voltage range is 0-$V_{\rm REF}$. The positive input pin of the ADC `AINP` is connected to the output of the low pass filter, and the negative input pin `AINN` is connected to `GND`.

#### Relationship Between Input and ADC voltage

From the equations provided in the [Op Amp Stage](#op-amp-stage) section, the general relationship between the measured current $I_{\rm PRIMARY}$ and the input voltage of ADC $V_{\text{ADC}}$ can be calculated, and the relationship for each revision of the current sensor board is provided below:

##### General Expression

$$
I_{\text{PRIMARY}} = \frac{N_2}{N_1} \left[ \frac{ ( R_{a} R_{b} + R_{a} R_{c} + R_{b} R_{c} )(R_{a} + R_{\text{BURDEN}}) - R_{b} R_{c} R_{\text{BURDEN}}}{ R_{a} R_{b} R_{c} R_{\text{BURDEN}}} \right] \left[ V_{\text{ADC}} - \frac{ R_{a} R_{b} (R_{a} + R_{\text{BURDEN}}) }{ ( R_{a} R_{b} + R_{a} R_{c} + R_{b} R_{c} )(R_{a} + R_{\text{BURDEN}}) - R_{b} R_{c} R_{\text{BURDEN}}} V_{\text{REF}} \right] 
$$

### Design

This section presents the relationship between input and ADC voltage for each sensor configuration.

##### LA 55-P

The final design for LA 55-P is implemented so that $I_{\rm PRIMARY} = -70A$ results in $V_{\rm out} \approx 0V$ and $I_{\rm PRIMARY} = 70A$ results in $V_{\rm out} \approx 5V$. For a sensing range of 70 A, the burden resistance _R_<sub>_BURDEN_</sub> can be calculated as _R_<sub>_BURDEN_</sub>  = (10 V/70 A)*(1000/1) = 143 $\Omega$.

##### Revision A, B

In this design, _N_<sub>1</sub>:_N_<sub>2</sub> = 1:1000, $V_{\rm REF}$ = 5V, $R_{\rm BURDEN}$ = 150Ω, $R_{\rm a}$ = 10kΩ, $R_{\rm b}$ = 8.45kΩ, $R_{\rm c}$ = 4.64kΩ, resulting in:

$$
I_{\text{PRIMARY}} = 29.2579 \times (V_{\text{ADC, RevA,B}} - 2.4922) \qquad {\rm [A]}
$$

##### Revision C

In this design, _N_<sub>1</sub>:_N_<sub>2</sub> = 1:1000, $V_{\rm REF}$ = 4.5V, $R_{\rm BURDEN}$ = 150Ω, $R_{\rm a}$ = 10kΩ, $R_{\rm b}$ = 10.7kΩ, $R_{\rm c}$ = 4.12kΩ, resulting in:

$$
I_{\text{PRIMARY}} = 29.4146 \times (V_{\text{ADC, RevC}} - 2.5126) \qquad \mathrm{[A]}
$$

#### LA 100-P

The final design for LA 100-P is implemented so that $I_{\rm PRIMARY} = -150A$ results in $V_{\rm out} \approx 0V$ and $I_{\rm PRIMARY} = 150A$ results in $V_{\rm out} \approx 5V$. Using the LA 100-P requires changing $R_{\mathrm{BURDEN}}$, $R_a$, $R_b$, and $R_c$. To achieve this, the proposed _N_<sub>1</sub>:_N_<sub>2</sub> = 1:2000, $V_{\rm REF}$ = 5V, $R_{\rm BURDEN}$ = 23.2Ω, $R_{\rm a}$ = 1.24kΩ, $R_{\rm b}$ = 2.87kΩ, $R_{\rm c}$ = 1.21kΩ, resulting in: The proposed component values result in the following relationship:

$$
I_{\text{PRIMARY}} = 59.9995 \times (V_{\text{ADC, RevA,B}} - 2.4999) \qquad {\rm [A]}
$$

##### Summary of Sensor Configurations

Finally, a table summarizes the parameters and resulting relationships for all sensor configurations.

| Parameter             | LA 55-P, Rev. A/B | LA 55-P, Rev. C | LA 100-P |
|:----------------------|------------------:|----------------:|---------:|
| $N_1$                 |                 1 |               1 |        3 |
| $N_2$                 |              1000 |            1000 |     2000 |
| $V_{\mathrm{REF}}$    |               5 V |           4.5 V |      5 V |
| $R_{\mathrm{BURDEN}}$ |             150 Ω |           150 Ω |   23.2 Ω |
| $R_a$                 |             10 kΩ |           10 kΩ |  1.24 kΩ |
| $R_b$                 |           8.45 kΩ |         10.7 kΩ |  28.7 kΩ |
| $R_c$                 |           4.64 kΩ |         4.12 kΩ |  1.21 kΩ |

### Connectors

- There are two screw terminals `P5` and `P6` to connect the conductor in which the current is to be measured
- A screw terminal block `P1` is used to connect the +-15V supply for the current sensor
- A BNC terminal is available to directly measure the output across the burden resistor _R_<sub>_BURDEN_</sub>

## Footprints

A user may want to change some of the passive components based on the range required and the RC filter cutoff frequency desired. The footprints of passive components that may need to be replaced i.e, the burden resistor (`R5`), the resistors in the Op Amp stage, and the RC filter components is provided here for quick reference. Note that these footprints are imperial codes and **not metric codes**.

| Component | Footprint |
|-----------|-----------|
| R3        | 0603      |
| R4        | 0603      |
| R5        | 2512      |
| R6        | 0603      |
| R8        | 0603      |
| C5        | 0603      |

## Datasheets

- [Current Sensor (LA 55-P)](https://github.com/Severson-Group/AMDS/blob/develop/CurrentCard/datasheets/LA55P_Current%20Sensor.pdf)
- [Current Sensor (LA 100-P)](https://github.com/Severson-Group/AMDS/blob/develop/CurrentCard/datasheets/LA100P_Current%20Sensor.pdf)
- [Op Amp](https://github.com/Severson-Group/AMDS/blob/develop/CurrentCard/datasheets/OPA320_OpAmp.pdf)
- [Voltage Reference (LDO)](https://github.com/Severson-Group/AMDS/blob/develop/CurrentCard/datasheets/REF5045_LDO.pdf)
- [Analog to Digital Converter](https://github.com/Severson-Group/AMDS/blob/develop/CurrentCard/datasheets/ADS_8860_ADC.pdf)
