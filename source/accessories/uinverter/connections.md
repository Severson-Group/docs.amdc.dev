# uInverter Board Connections

This document describes the connections on the uInverter board.
For detailed review of the board, please refer to the schematics in the `AMDC-Hardware` repo.

## Connections with the AMDC

### PWM

The PWM connector on the uInverter board uses [DB15 connector](https://www.digikey.com/en/products/detail/amphenol-icc-fci/ICD15S13E6GV00LF/1090326), similar to the Drive Outputs connector on the AMDC.
Three-phase PWM signals `A+`, `B+`, `C+` generated on the AMDC are carried over to the uInverter on this connector `CONN2` - `PWM`.

| Pin # |  uInverter 		| AMDC		  |
|-------| ------------------|-------------|
| 1     | `PWM A+`			| `PWM_1`     |
| 2     | `No connect`		| `PWM_2`     |
| 3     | `PWM B+`  		| `PWM_3`     |
| 4     | `No connect`		| `PWM_4`     |
| 5     | `PWM C+`    		| `PWM_5`     |
| 6     | `No connect`		| `PWM_6`     |
| 7     | `GND`      		| `GND`       |
| 8     | `No connect`    	| `STS_A`     |
| 9     | `No connect`    	| `STS_B`     |
| 10    | `No connect`    	| `STS_C`     |
| 11    | `No connect`    	| `STS_D`     |
| 12    | `No connect`    	| `VPS`       |
| 13    | `No connect`    	| `VDD`       |
| 14    | `No connect`    	| `GNDPS`     |
| 15    | `No connect`    	| `GND`       |  



### Analog

For providing feedback of current and voltage (analog sensing), the uInverter board uses the [RJSAE connector](https://www.digikey.com/en/products/detail/amphenol-icc-commercial-products/RJSAE-5385-02/1242709) similar to the [analog connector on the AMDC](https://docs.amdc.dev/hardware/subsystems/analog.html).
Three phase current signals and the DC link voltage signal generated on the uInverter are fed back to the AMDC using connector `CONN3` - `ANALOG SENSING`.

```{image} images/uInverter_analog_conn.jpg
:width: 500px
:class: align-left
```

| Pin Number | `uInv Conn 1`      | `AMDC Analog Conn 1` |  `uInv Conn 2`   		| `AMDC Analog Conn 2` 		
|------------|  -----					    |--------				  	| ------	 			 			|-----						
| 1 		 | `ISENSE_A`     				| `Analog P1` 			  	| `ISENSE_C`     		 			| `Analog P3` 				
| 2 		 | ` GND    ` 					| `Analog N1` 			  	| ` GND    `     		 			| `Analog N3` 				
| 3 		 | `VCC+    `  					| +15V 				  	 	| `No Connect    `     		 			| +15V 						
| 4 		 | ` GND    ` 					| `GND`				  	 	| ` GND    `     		 			| `GND` 						
| 5 		 | `VCC-    ` 					| -15V 				  	 	| `No Connect    `     		 			| -15V 						
| 6 		 | ` GND    ` 					| `GND` 				  	| ` GND    `     		 			| `GND` 					
| 7 		 | `ISENSE_B`     				| `Analog P2` 			  	| `VDC_SENSE`     		 			| `Analog P4` 				
| 8 		 | `GND     ` 					| `Analog N2` 			  	| `GND     `     		 			| `Analog N4` 			

## External Connections

### DC Voltage Connector

The 12V DC supply uses a barrel jack connector with ground-center as marked on the PCB.
Here is the [link to the datasheet of the connector](https://www.digikey.com/en/products/detail/cui-devices/PJ-037AH/1644547).

Here is an example of a usable [12V wall-wart connector](https://www.digikey.com/en/products/detail/phihong-usa/PSAA30R-120-R-CNR1/3061648).
A phoenix connector `J7` is also provided for an alternative 12V supply connection.  

### Jumper connection

The phase connection Phoenix connectors are normal-closed (NC) connections.
Hence, jumpers should be used to short ONLY the following connectors - `J1, J2, J3, J4, J5 and J6`.
Here is a link to an example [phoenix contact jumper](https://www.digikey.com/en/products/detail/phoenix-contact/3030161/2263931?s=N4IgTCBcDaIMwAZEEYBsyQF0C%2BQ).  

For more details, please refer to the schematics.
