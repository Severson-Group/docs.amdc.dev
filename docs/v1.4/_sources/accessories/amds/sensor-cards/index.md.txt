# Sensor Cards

Three sensor cards are available.
Users are welcome and encouraged to design addition sensor cards.

All sensor cards are dc/ac capable with 16-bit ADC.

| Metric | [Current](./current/index.md) | [High Voltage](./high-voltage/index.md) | [Low Voltage](./low-voltage/index.md) |
| --- | --- | --- | --- |
| Image | ![](current/images/amds_current_card.png) | ![](high-voltage/images/amds_hv_card.png) | ![](low-voltage/images/amds_lv_card.png) |
| Sensor Device | LEM LA 55-P | LEM LV 25-P | TI INA143UA |
| Range (peak) | $\pm$70 A | 10-500 V | $\pm$10 V |
| Accuracy (\%) | $\pm$0.65 | $\pm$0.8 | $\pm$0.05 |
| Nonlinearity (\%) | $<$0.15 | $<$0.2 | $<$0.001 |
| Bandwidth (kHz) | 200 | 25 | 150 |

```{toctree}
:hidden:

high-voltage/index
low-voltage/index
current/index
```