# Building and Running Firmware

This guide provides step-by-step instructions on how to configure, build, and flash the AMDS firmware onto different hardware targets (e.g., AMDS and 2S).

## Prerequisites

- **IDE:** STM32CubeIDE (or your preferred C/C++ IDE configured for ARM Cortex-M development).
- **Hardware:** ST-Link V2/V3 or equivalent hardware debugger/programmer.
- **Target Board:** Either an AMDS board or AMDS-compatible board.

## Step 1: Open the Project

1. Launch STM32CubeIDE.
2. Go to **File > Open Projects from File System...**
3. Select the directory containing the firmware source code (`AMDS\Mainboard\Firmware\mainboard\`) and click **Finish**.

## Step 2: Set the Build Configuration (Target Macro)

The firmware uses preprocessor macros to conditionally compile the correct peripheral assignments and active sensor masks for your specific board. Two targets are currently supported:

- `AMDS`: This is the standard AMDS hardware as documented on this website.
- `2S`: This is a new target that has only two sensor cards on hardware that is not yet publicly released.

```{tip}
Nearly all users are on AMDS hardware. When in doubt, select the `AMDS` option.
```

1. Right-click on `mainboard` and go to **Build Configuration > Set Active > AMDS or 2S**

*Note: Alternatively, simply select the appropriate active configuration the Build "hammer" dropdown menu.*

## Step 3: Build the Project

1. **Clean** the project to ensure no artifact mix-ups from previous board builds: Go to **Project > Clean...** and select your project.
2. **Build** the project: Click the **Build** (hammer) icon or go to **Project > Build Project**.
3. Check the console output to ensure there are no compilation errors and that the build finishes successfully.

```{important}
If you did not set the build configuration in the previous steps you will see many compilation errors that look like this:

#error "Please define a target board (TARGET_AMDS or TARGET_2S)!"
```

## Step 4: Configure the Run/Debug Settings

1. Connect your ST-Link to your PC and the target board's SWD (Serial Wire Debug) header.
2. Power on the target board.
3. In STM32CubeIDE, go to **Run > Debug Configurations...**
4. Double-click **STM32 Cortex-M C/C++ Application** to create a new configuration.
5. In the **Main** tab, ensure the correct `.elf` file is selected in `C/C++ Application` as either `AMDS/mainboard.elf` or `2S/mainboard.elf`.
6. In the **Debugger** tab, ensure the Debug probe is set to **ST-LINK** and the interface is set to **SWD**.
7. Click **Apply**.

```{image} images/debugger-config-options.svg
:width: 75%
```

## Step 5: Flash and Verify

1. Click **Debug** (or **Run**) from the configuration window to flash the firmware.
2. The IDE will connect to the board, erase the necessary flash sectors, and write the new firmware.
3. Once flashing is complete, if you are in Debug mode, click the **Resume** (play) button to start execution.
4. **Verification:** Observe the board's behavior. Depending on your configuration, verify that the active sensor mask operates correctly (AMDS enables all 8 channels `0xFF`, 2S enables a subset `0x11`) and that UART/DMA streams begin processing as expected.

```{tip}
For the AMDS board, a good indicator that things are running smoothly is the 4 LEDS near the MCU blinking in order.
```

## Switching Between Targets

Because the project shares a single codebase, programming a different target (`AMDS` vs `2S`) is simple:

1. Disconnect the current board and connect the new one.
2. Return to **Step 2** and swap the target macro.
3. Rebuild (**Step 3**) and Flash (**Step 5**).
