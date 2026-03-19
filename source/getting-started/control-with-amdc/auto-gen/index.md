# Control with AMDC Using Simulink Autogen

## Background

Modern motor drive systems rely on real-time embedded controllers such as the AMDC to execute control algorithms. Traditionally, these control algorithms are implemented manually in C/C++, which can be time-consuming and error-prone—especially for complex systems.

Simulink provides a graphical environment for modeling, simulating, and validating control systems. Using Simulink’s **Automatic Code Generation (Autogen)** capability, control algorithms designed in a block-diagram form can be directly converted into C code suitable for embedded deployment.

This workflow offers several key advantages:

- Rapid prototyping of control algorithms  
- Built-in simulation and validation before deployment  
- Reduced implementation errors compared to manual coding  
- Clear visualization of control logic  

In this workflow, Simulink is used to design the controller, and the generated code is integrated into the AMDC firmware to execute in real time.

---

## Autogen Control Workflow

The overall workflow consists of three major steps:

1. **Design controller in Simulink**
2. **Generate C code using Autogen**
3. **Integrate generated code into AMDC**

### Simulink Model Structure

To properly generate code for AMDC, the Simulink model should be organized into three subsystems:

1. **Input/Output (I/O)**  
   Handles signal inputs, outputs, and visualization (e.g., scopes).  
   → *Not included in generated code*

2. **Plant**  
   Represents the physical system (e.g., motor, load).  
   → *Used only for simulation*

3. **Controller**  
   Contains the control logic to be deployed on AMDC  
   → *This is the only part converted into C code*

```
Simulink Model
├── I/O (simulation only)
├── Plant (simulation only)
└── Controller (code generated → AMDC)
```

The controller must be implemented using **discrete-time blocks**, since the AMDC operates in discrete time.

---

## Generated Code and Execution Model

After code generation, Simulink produces C code that represents the controller as a **black-box function**.

### Key Characteristics

- The controller is executed through a single function:

```c
modelName_step();
```

- Inputs and outputs are passed using structs:

```c
modelName_U   // Inputs
modelName_Y   // Outputs
```

### Control Execution in AMDC

The AMDC should call the generated controller at a fixed time interval:

```c
void control_task_callback(void)
{
    // 1. Populate inputs (e.g., sensor readings)
    modelName_U.current = measured_current;
    modelName_U.voltage = measured_voltage;

    // 2. Run controller
    modelName_step();

    // 3. Use outputs (e.g., PWM duty cycles)
    set_pwm_duty(modelName_Y.duty);
}
```

Key points:

- AMDC follows: input → step → output  
- Runs at a fixed timestep  

---

## Development Environment Setup

To use Simulink Autogen with AMDC, the following environment is required:

### Required Software

- MATLAB (latest version recommended)
- Simulink
- Simulink Coder
- Embedded Coder

Additional toolboxes may be required depending on the control design.

---

### Required Simulink Configuration

The following settings must be applied before generating code:

1. **Solver Configuration**
   - Set to **Fixed-step**

2. **Code Generation Target**
   - Set to `ert.tlc` (Embedded Coder target)

3. **Controller Subsystem**
   - Must be:
     - Atomic subsystem
     - Converted to **Referenced Model**

---

### Code Generation

Code is generated using:

```matlab
slbuild('modelName')
```

After generation:

- A folder `modelName_ert_rtw` is created
- Key files:
  - `modelName.c`
  - `modelName.h`

---

### Important Notes

- Only the controller is converted to code  
- Generated code should be reviewed if necessary  
- Do not delete any generated files  
- Folder paths should not contain whitespace  

---

## Integration with AMDC

To integrate the generated code into AMDC:

### 1. Add Generated Code to Project

- Include the autogen folder in:
  - Include paths
  - Source paths

---

### 2. Create Control Task

A dedicated control task should:

- Initialize the controller:

```c
modelName_initialize();
```

- Execute periodically:

```c
modelName_step();
```

---

### 3. Data Flow Mapping

The AMDC is responsible for:

| Step | Description |
|------|------------|
| Input | Read sensor data and populate `modelName_U` |
| Execute | Call `modelName_step()` |
| Output | Route `modelName_Y` to actuators (e.g., PWM) |

---

## Important Considerations

### 1. Discrete-Time Design

All controller blocks must operate in discrete time.

### 2. Fixed Execution Rate

The AMDC must call the controller at a consistent timestep.

### 3. Separation of Concerns

- Simulation (Plant, I/O) ≠ Embedded code (Controller)  
- Only controller logic runs on hardware  

### 4. Code Structure Awareness

- Controller is treated as a black box  
- Only inputs/outputs are accessible  

### 5. Debugging Strategy

- Validate behavior in Simulink first  
- Then verify integration on AMDC  

---

## Example

### Objective

- Read analog input (0–9V)  
- Convert to PWM duty (0–0.9)  
- Apply saturation limits  

### Workflow

1. Build controller in Simulink  
2. Generate code using `slbuild`  
3. Integrate into AMDC control task  

After generation, the following files are used:

```
exampleController.c
exampleController.h
```

These contain the full implementation of the controller logic.

---

## Conclusion

Using Simulink Autogen with the AMDC provides a powerful and efficient workflow for control development.

Key benefits include:

- Faster development cycles  
- Improved reliability through simulation  
- Simplified integration with embedded systems  

This approach allows developers to focus on control design while leveraging automatic tools for code generation and deployment.