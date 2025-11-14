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

1. Current measurement range of +/- 55A (rms)
2. Noise immunity
3. Quick adjustment of the sensing range
4. High sensor bandwidth
5. SPI output to interface with the sensor motherboard

## Block Diagram
The high level block diagram of the current sensor card is shown below:

![](images/current-sensor-blockdiagram.svg)

### Current Sensor
LEM LA 55-P current sensor is selected for this design, as it is the only sensor available from LEM with an open aperture and PC pins that can measure +/-55A. 
The open aperture was a requirement as it allows for the range to be easily scaled down just by adding turns to the primary. 
The LA 55-P is a closed loop compensated hall effect transducer that has an accuracy of +/-0.65% and linearity of <0.15% which is quite good compared to other sensors from LEM. 
It has an excellent bandwidth of 200khz and a low impedance current output that is inherently more immune to noise than a high impedance voltage output. 


### Burden Resistor (_R_<sub>_BURDEN_</sub>)
A burden resistor (`R5`) is used to convert the current output of the sensor to a voltage. For a sensing range of 70A, the burden resistance, _R_<sub>_BURDEN_</sub> was calculated using the following equation

_V_<sub>_BURDEN_</sub>  = (_N_<sub>1</sub>/_N_<sub>2</sub>) _I_<sub>_PRIMARY_</sub> _R_<sub>_BURDEN_</sub>

_R_<sub>_BURDEN_</sub>  = (10 V/70 A)*(1000/1) = 143Ω 

The LA 55-P datasheet specifies the burden resistor value must be between 135Ω and 155Ω so a 150Ω resistor was selected.

### Current Sensor Gain
The LA 55P has a conversion ratio of _N_<sub>1</sub>:_N_<sub>2</sub> = 1:1000, where _N_<sub>1</sub> is the primary turns (the number of turns the user passes through the sensor's window) and _N_<sub>2</sub> is the secondary turns. With the chosen _R_<sub>_BURDEN_</sub> and _N_<sub>1</sub> = 1, the current sense circuitry has a current-voltage gain of 1/7 [V/A]. 

To use the sensor in a lower current range, the user can increase the number of primary turns without the need to modify any other parts of the circuit. As an example, to sense currents in the range of +/- 7 A, _N_<sub>1</sub> = 10 can be used.

### Voltage Reference (LDO)
The voltage reference, _V_<sub>_REF_</sub> is needed for the ADC. As 5V is readily available, and the LDO will have a minimum drop out voltage,  _V_<sub>_REF_</sub> = 4.5V was chosen (beginning with board revision C). The LDO selected was `REF5045` from Texas Instruments, which can take a 5V input and provide a 4.5V reference output. This has an accuracy of 0.1% and low noise of 3μVpp/V.

### Op Amp Stage

A non-inverting level translation circuit is implemented using Op Amps as shown here:

![](images/current-sensor-opamp-stage.svg)

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

The final design is implemented so that $I_{\rm PRIMARY} = -70A$ results in $V_{\rm out} \approx 0V$ and $I_{\rm PRIMARY} = 70A$ results in $V_{\rm out} \approx 5V$.

```{attention}
As the op-amp output voltage approaches the supply rails, it tends to distort and behave nonlinearly. It is recommended to limit the output voltage to stay within 0.2V to 4.5V for best performance. The user is advised to consider their required current measurement range with the [final voltage expressions](final-primary-current-to-adc-input-voltage-relationship) to select an appropriate number of [primary turns](current-sensor-gain).
```

### First Order Anti-Aliasing Filter
A first order RC filter is implemented on the output of the op amp circuit. The cutoff frequency was set at 48kHz and the following equations was used for the computation:

$$f_c = \frac{1}{2\pi RC} $$

**Note:** The cutoff frequency can easily be changed by swapping out `R3`.

### Analog to Digital Converter

A single-ended ADC was selected. The ADC used is the Texas Instruments [ADS8860](https://www.ti.com/product/ADS8860). It is a pseudo-differential input, SPI output, SAR ADC. 
The maximum data throughput for a single chip is 1 MSPS but decreases by a factor of N for N devices in the daisy-chain. 
The input voltage range is 0-$V_{\rm REF}$. The positive input pin of the ADC `AINP` is connected to the output of the low pass filter, and the negative input pin `AINN` is connected to `GND`.

#### Relationship Between Input and ADC voltage

From the equations provided in the [Op Amp Stage](#op-amp-stage) section, the relationship between the measured current $I_{\rm PRIMARY}$ and the input voltage of ADC $V_{\text{ADC}}$ can be calculated for each revision of the current sensor board as follows:

##### General Expression

$$
V_{\text{out}} = \left[\frac{R_{a} R_{b} (R_{a} + R_{\text{BURDEN}})}{(R_{a} R_{b} + R_{a} R_{c} + R_{b} R_{c})(R_{a} + R_{\text{BURDEN}}) - R_{\text{BURDEN}} R_{b} R_{c}}\right] V_{\text{ref}} + \left[\frac{R_{a} R_{\text{BURDEN}} R_{b} R_{c}}{(R_{a} R_{b} + R_{a} R_{c} + R_{b} R_{c})(R_{a} + R_{\text{BURDEN}}) - R_{\text{BURDEN}} R_{b} R_{c}}\right]\left(\frac{N_1}{N_2} I_{\text{PRIMARY}}\right)
$$

$$
I_{\text{PRIMARY}} = \frac{N_2}{N_1} \cdot \frac{V_{\text{out}} - \left[\frac{R_{a} R_{b} (R_{a} + R_{\text{BURDEN}})}{(R_{a} R_{b} + R_{a} R_{c} + R_{b} R_{c})(R_{a} + R_{\text{BURDEN}}) - R_{\text{BURDEN}} R_{b} R_{c}}\right] V_{\text{ref}}}{\left[\frac{R_{a} R_{\text{BURDEN}} R_{b} R_{c}}{(R_{a} R_{b} + R_{a} R_{c} + R_{b} R_{c})(R_{a} + R_{\text{BURDEN}}) - R_{\text{BURDEN}} R_{b} R_{c}}\right]}
$$



##### Revision B

In this design, $V_{\rm REF}$ = 5V, $R_{\rm BURDEN}$ = 150Ω, $R_{\rm a}$ = 10kΩ, $R_{\rm b}$ = 8.45kΩ, $R_{\rm c}$ = 4.64kΩ, resulting in:

$$
I_{\text{PRIMARY}} = (V_{\text{ADC, RevB}} - 2.4922) \times 29.4118 \qquad {\rm [A]}
$$

##### Revision C
In this design, $V_{\rm REF}$ = 4.5V, $R_{\rm BURDEN}$ = 150Ω, $R_{\rm a}$ = 10kΩ, $R_{\rm b}$ = 10.7kΩ, $R_{\rm c}$ = 4.12kΩ, resulting in:

$$
I_{\text{PRIMARY}} = (V_{\text{ADC, RevC}} - 2.5126) \times 29.4118 \qquad \mathrm{[A]}
$$

### Connectors
- There are two screw terminals `P5` and `P6` to connect the conductor in which the current is to be measured
- A screw terminal block `P1` is used to connect the +-15V supply for the current sensor
- A BNC terminal is available to directly measure the output across the burden resistor _R_<sub>_BURDEN_</sub>

## Footprints
A user may want to change some of the passive components based on the range required and the RC filter cutoff frequency desired. The footprints of passive components that may need to be replaced i.e, the burden resistor (`R5`), the resistors in the Op Amp stage, and the RC filter components is provided here for quick reference. Note that these footprints are imperial codes and **not metric codes**.

| Component | Footprint |
| ---- | ----- |
| R3   |  0603|
| R4   | 0603 |
| R5 | 2512 |
| R6 | 0603 |
| R8 | 0603 |
| C5 | 0603 |


## Datasheets
- [Current Sensor](https://github.com/Severson-Group/AMDS/blob/develop/CurrentCard/datasheets/LA55P_Current%20Sensor.pdf)
- [Op Amp](https://github.com/Severson-Group/AMDS/blob/develop/CurrentCard/datasheets/OPA320_OpAmp.pdf)
- [Voltage Reference (LDO)](https://github.com/Severson-Group/AMDS/blob/develop/CurrentCard/datasheets/REF5045_LDO.pdf)
- [Analog to Digital Converter](https://github.com/Severson-Group/AMDS/blob/develop/CurrentCard/datasheets/ADS_8860_ADC.pdf)
