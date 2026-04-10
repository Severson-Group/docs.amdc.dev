# Tutorial: Autogen

- **Goal:** Generate Autogen code based on Simulink model.
- **Complexity:** 3 / 5
- **Estimated Time:** 40 min

This tutorial goes over:

- Organization of your repository to store the Simulink Autogen codebase
- Creation a Simulink simulation model to generate Autogen code
- Control implementation using the AMDC hardware

## Tutorial Requirements

1. Working AMDC hardware
2. Completion of the ["Voltage Source Inverter" tutorial](../vsi/)
3. Read ["Control with AMDC Using Simulink Autogen" article](../../control-with-amdc/autogen/index.md) to understand an overview of Autogen  

## File Organization

The first step is to organize your repository. Create a new `modeling/simulink` folder in your repository and organize the files as shown below:

```markdown
my-AMDC-workspace/               <= master repo
|-- modeling/
|    |-- simulink/               <= Now create this folder
|    |-- cmd_ctrl.h
|-- control/
     |-- AMDC-Firmware/          <= AMDC-Firmware as submodule
     |-- my-AMDC-private-C-code/ <= Your private user C code
         |-- usr/
             | -- controller/    <= Your private user app
                 | -- autogen/   <= Autogen code
```

## Install Required MATLAB/Simulink Toolbox

To develop control code using Simulink Autogen, the following software components are required:

- [MATLAB](https://www.mathworks.com/help/matlab/index.html)
- [Simulink](https://www.mathworks.com/help/simulink/index.html)
- [Simulink Coder](https://www.mathworks.com/help/rtw/index.html)  
- [Embedded Coder](https://www.mathworks.com/help/ecoder/index.html)

Additional toolboxes may be required depending on the specific control design.

## Create a Simulink Model

Now that you create a Simulink model used to generate Autogen code.  

1. In `simulink` folder, create a new MATLAB file (e.g., `setup.m`).
2. In `setup.m`, define `fs = 10e3`, `Ts = 1/fs`, `Tsim = Ts/10`.

User can copy-paste the following MATLAB code:

```MATLAB
fs = 10e3;      % sampling frequency (Hz)
Ts = 1/fs;      % sampling time (sec)
Tsim = Ts/10;   % simulation time (s) 
```

**Need to update the following step to create a duty cycle**

3. Open a blank model of Simulink, and save as `setupModel.slx` in `simulink` folder.
4. Add a `Step` block with the default setting.
5. Add a `Discrete-Time Integrator` block with the default setting.
6. Add a `Rate Transition` block before the integrator. In this block, put `Ts` as a sampling time.
7. Add a `Rate Transition` block after the integrator. In this block, set the sampling time to `-1`.
8. Add a continuous-time `Transfer Fcn` block as a Plant (= 1).
9. Add a `Sum` function and connect each block as shown below.

```{image} images/autogen-model.svg
:alt: Autogen model
:width: 600px
:align: center
```

### Model Setting

1. In `Modeling` tab, press `Model Settings` in `TOP MODEL` section.
    1. Under the `Solver`tree, in the `Solver Selection`, press `Fixed-step`.
    2. Set `Fixed-step-size` as `Tsim`.
2. Go to `Code Generation`.
    1. Click `Browse` for the `System target file`.
    2. Select `ert.tlc Embedded coder`.
    3. In the `Build process` section, check `Generate code only`.
3. Go to `Optimization` under `Code Generation`.
    1. Choose `None` for the `Leverage target hardware instruction set extensions` in the `Target specific optimizations`.
4. Go to `Templates` under `Code Generation`.
    1. Uncheck `Generate an example main program` in the `Custom templates` section.
5. Click `Apply` and `OK`.

### Create a Referenced Model

1. Select the discrete-time integrator, and right-click.
2. Select `Create Subsystem from Selection`.
3. Right-click on the subsystem created. Select `Block parameters (Subsystem)`, check `Treat as atomic unit`, and click `OK`.
4. Right-click on the subsystem and select `Subsystem & Model Reference`. Select `Convert` and click `Referenced Model ...`.
5. In the `Input Parameters` section, define the `New model name` as `integrator`.
6. Click `Apply` and `Convert`.
7. Rename the referenced model block to be `integrator`. The expected Simulink model is shown below:

```{image} images/autogen-model-subsystem.svg
:alt: Autogen model subsystem
:width: 600px
:align: center
```

### Referenced Model Setting

1. Double-click the `integrator` referenced model and click `Model Settings` under `Modeling` tab.
2. Click `Model Settings` in the `REFERENCED MODEL` section.
    1. Set `Fixed-step-size` as `Ts`.
3. Save the Simulink file.

The example of Simulink file along with the referenced model is stored [here](./simulink/).

### Generate C-code

1. Open the `setup.m`.
2. Copy and paste the following code.

```MATLAB
%% Autogen code for the controller
model='integrator';  % name of the controller to be built
slbuild(model);      % generates the Autogen code
oldFolder = cd('C:integrator_ert_rtw\');
% Copy only .c and .h files in autogen folder
command = 'for /r %i in (*.c, *.h) do copy /y %i ..\autogen';
[status, cmdout] = system(command);
cd(oldFolder);
```

3. Run the `setup.m`, and all autogenerated `.c` and `.h` files generated files should be placed within `autogen` folder. Among these generated files, the most relevant are:

- `integrator.c` — implementation of the control logic  
- `integrator.h` — interface definitions (inputs, outputs, function declarations)  

These files define the controller as a callable function with input and output structures, consistent with the execution model described earlier.
4. Now the autogen folder should appear as part of the project within the SDK environment. If not refresh the project.

### Integration with AMDC

Now, the user needs to update the user C code to incorporate the autogen code generated from Simulink. Specifically, this requires modifying `task_controller_clear`, `task_controller_init`, and `task_controller_callback` functions. Within the callback function, the control task executes your developed code at a fixed sampling interval, where you need to include following:

1. Populate inputs (e.g., sampled sensor data)  
2. Call the controller step function
3. Route outputs to actuators (e.g., PWM duty cycles)

The functions that need to be updated for this example are shown below:

`task_controller.c`:

```c
// ...

int task_controller_clear(void)
{
  // ...

  // Clear state struct for Simulink controller
  memset(((void *) &integrator_DW_DW), 0, sizeof(DW_integrator_T));

  // ...
}

int task_controller_init(void)
{
  // ...

  // Initialize Autogen step  
  integrator_initialize();

  // ...
}

void task_controller_callback(void *arg)
{
  // ...

  // Populate inputs
  modelName_U.current = measured_current;  // Inputs to controller
  modelName_U.voltage = measured_voltage;  // Inputs to controller

  // Update controller input parameters
  integrator_U.STEP = STEP;

  // Call Autogen code
  integrator_step();

  // Apply outputs
  set_pwm_duty(modelName_Y.duty);  // Outputs from controller

  // ...
}
```

## Running the AMDC

THIS SECTION WILL BE UPDATED! We want to show the expected result after running the AMDC, logging the duty ratio values.

- After running the AMDC, show the input and output value through logging feature.

## Conclusion

**Congratulations!**

**But we need to update the following!**

You have now built a new user app and created control code for the voltage source inverter.
These techniques can be extended for many more control problems.
Simply modify the control task callback and the command handler to implement new control algorithms.
