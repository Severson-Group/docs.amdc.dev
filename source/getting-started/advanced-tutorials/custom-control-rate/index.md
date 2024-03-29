# Tutorial: Custom Control Rate

- **Goal:** Run control tasks at any desired rate.
- **Complexity:** 3 / 5
- **Estimated Time:** 30 min

This tutorial explains the best approach for configuring the AMDC `v1.0` firmware to run user control tasks at any given rate.
Nuances of the firmware architecture are discussed which impact control code execution.

## Tutorial Requirements

1. Working AMDC hardware
2. Completion of the [VSI tutorial](/getting-started/tutorials/vsi/index.md)
3. Review of the `v1.0` firmware [system architecture documentation](/firmware/arch/system)
4. Review of the [signal logging framework](/getting-started/user-guide/logging/index) built-in to the AMDC

## Background

The AMDC `v1.0` firmware uses a simple **time triggered cooperative (TTC) scheduler** that has no task preemption.
Read more about the system firmware design [here](/firmware/arch/system).
The key implication of this architectural decision is that care must be taken to ensure control code runs as desired: no jitter, no over-runs, and at the desired rate.

By default, the firmware uses a 10 kHz scheduler time quantum, meaning all tasks running on the system must complete within 100 us.
If a task takes too long, the system "overruns" which introduces significant jitter in the task execution timing.
Therefore, users must configure the AMDC firmware for the best chance of zero overruns and very little timing jitter.
The remainder of this document explains how to do this.

## Verification of Timing

The most important part of running real-time control code is knowing if it indeed is running as expected.
Therefore, during all hardware testing, it is highly advised to **always** be measuring and logging the execution timing data for the control task.
Recall that the averaged task timing data can be recorded and viewed using the built-in system task timing statistics framework which is presented in the [profiling tasks tutorial](/getting-started/tutorials/profiling-tasks/index).
However, data per each task execution is more useful for timing verification.

To record fine grain timing data, instrument your code task callback function as shown below.
This uses the `drv/cpu_timer` module for ultra-high-precision timing: on-chip timer with 1.5 ns resolution and small access latency.

```C
#include "drv/cpu_timer.h"

// ...

double LOG_control_looptime = 0;
double LOG_control_runtime = 0;
static uint32_t last_now_start = 0;
void task_control_callback(void *arg)
{
    // Compute and log the loop time for this task
    uint32_t now_start = cpu_timer_now();
    uint32_t looptime = now_start - last_now_start;
    last_now_start = now_start;
    LOG_control_looptime = cpu_timer_ticks_to_usec(looptime);

    // .....
    // Here is where your control code runs
    // .....

    // Compute and log the run time for this task
    uint32_t now_end = cpu_timer_now();
    uint32_t runtime = now_end - now_start;
    LOG_control_runtime = cpu_timer_ticks_to_usec(runtime);
}
```

After the code has been instrumented, the [Signal Logging framework](/getting-started/user-guide/logging/index) can be used to view the controller task run-time and loop time:
 - `LOG_control_runtime` -- run time in &micro;sec
 - `LOG_control_looptime` -- loop time in &micro;sec

## Firmware Configuration

There are several things to change in the firmware configuration to run the control task at arbitrary rates, for example, 50 kHz, etc.
Even when running at the default 10 kHz, the items below should be completed to ensure the best timing performance of the code.

The following examples assume a 50 kHz control rate, but users are free to use different frequencies.

### 1. Update system tick frequency

In the `usr/user_config.h` file, set the desired control rate:

```C
#define SYS_TICK_FREQ (50000)
```

This sets the entire AMDC firmware tick frequency to the given value, which enables the controller to run that fast as well.

### 2. Update task callback frequency

Update the header file for the control task and set the callback frequency to 50 kHz.

### 3. Register controller task using high priority

By default, tasks registered with the scheduler are appended to the end of the task list which gets executed each time slice.
This can introduce large amounts of timing jitter in the control task.

To force the control task to run first during the time quantum, register the task using the high priority API:

```C
scheduler_tcb_register_high_priority(&tcb);
```

### 4. Disable time quantum checking

Since the user will be monitoring the timing performance using the log variables which were configured above, there is no need to force the AMDC firmware to stop execution if any timing overruns occur.

In the `usr/user_config.h` file, disable overrun protection:

```C
#define USER_CONFIG_ENABLE_TIME_QUANTUM_CHECKING (0)
```

### 5. Disable system task timing statistics

Once again, since the user is managing the task profiling using log variables, there is no need for the system to also keep track of the timing.
The system task timing statistics add overhead which is not needed.

In the `usr/user_config.h` file, disable system task stats:

```C
#define USER_CONFIG_ENABLE_TASK_STATISTICS_BY_DEFAULT (0)
```

### 6. Set log memory to minimum

To speed up the logging code, reduce the logging framework memory to the minimum required by the application by shrinking the maximum number of log variables and the sample depth per log variable:

For example, when only logging 4 variables for short durations:

```C
#define USER_CONFIG_LOGGING_MAX_NUM_VARIABLES (4)
#define USER_CONFIG_LOGGING_SAMPLE_DEPTH_PER_VARIABLE (1000)
```

## Advanced System Firmware Changes

```{caution}
This section instructs you to update the core AMDC system code.
Only attempt these changes if you are able to revert your code base back to a known working version, i.e., you are appropriately using version control.
```

Due to the time triggered cooperative scheduler in the AMDC firmware, there can be needless timing collisions based on the phasing of different tasks.

Consider 10 independent tasks which need to run every second, i.e., 1 Hz, and each takes 5 usec to execute.
This means all 10 tasks require 50 usec of computation time.
If all the tasks run during the same time slice, this could overrun the scheduler for system tick frequencies faster than $1 / 50~\mu\text{s} = 20~\text{kHz}$.
The clever reader will realize this overrun could easily be prevented by phase shifting the execution of each task by 1 time slice so that the computational load is split more evenly.

By default, each task has an initial phase shift in timing of 0, meaning the above example is prone to happening. However, the user can update the timing offsets of each task to help reduce the chance of scheduler overruns.

### How to update task execution timing offset

Each scheduler `task_control_block_t` struct has a field `last_run_usec` which directly maps to the timing offset. To add a timing offset, simply override this field during initialization. The field has units of usec.

For example, to add an offset of 100 usec to the task:

```C
// task_controller.c

// Scheduler TCB which holds task "context"
static task_control_block_t tcb;

int task_controller_init(void)
{
    if (scheduler_tcb_is_registered(&tcb)) {
        return FAILURE;
    }

    // Fill TCB with parameters
    scheduler_tcb_init(&tcb, task_controller_callback, 
                        NULL, "controller", TASK_CONTROLLER_INTERVAL_USEC);

    // Override the task timing offset
    tcb.last_run_usec = 100;

    // Register task with scheduler
    return scheduler_tcb_register(&tcb);
}
```

Note that the `scheduler_tcb_init()` function resets the `last_run_usec` field to 0, so the user must update the task struct after calling the init function.

### Which tasks to update

Tasks which execute at the system tick frequency should not be updated to add an offset--it makes no sense to update them since they run every time slice no matter what.

All other tasks could be updated to add an execution timing phase shift.

There are numerous system tasks which run on the AMDC in addition to user tasks.
To find all tasks, use the file search feature within the SDK to locate calls to `scheduler_tcb_register()`.

### Good values for the execution timing phase shifts

For the best spread of computational load, each task should be offset so that it runs in its own time slice.
It can be complicated to find suitable offsets for a system with many tasks which all run at different rates.

Consider a simple example system with $N$ tasks which all run at interval $T_{task}$. The system tick interval $T_{sys} < \frac{1}{N} T_{task}$ so that it is possible to schedule the tasks with no collisions.
The offset for task $i$ is denoted $t_i$ and $i = 0,~1,~\ldots,~N-1$.

Then, one offset configuration which eliminates timing collisions is
$t_i = T_{sys}i$
which means each task has its own time slice in which to run.

## PWM Requirements

For `v1.0` AMDC firmware (which is all that exists today), try to keep the PWM switching frequency greater than 2-5x the control rate.
For example, for a control rate of 10 kHz, try to switch at greater than 20 kHz, preferably >50 kHz.

This is due to issues with the ADC sampling logic in the FPGA which cause samples to be missed, resulting in invalid ADC feedback for a given control time step.
If the control rate is too close to the PWM carrier frequency, multiple of the same sampled value will be returned from the ADC driver.
