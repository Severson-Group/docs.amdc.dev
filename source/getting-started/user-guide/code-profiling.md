# Code Profiling

This document explains how to profile C-code run-time timing while running on the AMDC.

```{attention}
This discussion is limited to overall task timing -- profiling small snippets of code is not discussed.
```

## Introduction

Real-time systems require that the embedded code meets strict real-time timing constraints.
The AMDC firmware is designed in a cooperative approach, meaning that the real-time guarantees of the system depend on the (good) behavior of the user code.
Period tasks are used to run control code, and these tasks must execute quick enough such that the total scheduler time slice is not overrun.

For more information on the architecture of the AMDC firmware, check out the [](/firmware/arch/index.md) documentation.

## What is Code Profiling?

Since there are no formal guarentees baked into the firmware, the only way to ensure the real-time capability of the code is not comprimised is by profiling its execution.
In other words, by running tasks and recording statistics on how long they took to run, basic analysis can be performed on the real-time capability of the code.

For example, if it is measured that a particular task takes 200 usec on averge to run, clearly, the system scheduler cannot use a time-slice of 100 usec -- it would be overrun every time!
The 200 usec run-time task would have a maximum run frequency of 5 kHz.

Fortunantely, the core AMDC firmware makes it easy to profile a task's run-time timing performance to judge how fast it runs.

### Run Time vs. Loop Time

There are two metrics which are important for real-time code:

1. Run time
2. Loop time

**Run time** refers to how long a piece of code takes to run.
Since each line of code corresponds to assembly instructions, the run time captures how long it takes the processor to execute all relevant instructions.

**Loop time** refers to the time elapsed *between* execution of the profiled code.
For periodic tasks, the loop time ought to be exactly the requested interval (e.g., for 10 kHz, loop time should be 100 usec).
However, the loop time will not be perfectly constant due to scheduling jitter.
The amount of acceptable jitter depends on the application.

The scheduler framework built into the AMDC firmware, `sys/scheduler`, is set up to easily measure both task run time and loop time.

## Profiling All Tasks

By default, task profiling is disabled in the firmware.

To enable, set the following define to `1` in the `usr/user_config.h` file:

```C
#define USER_CONFIG_ENABLE_TASK_STATISTICS_BY_DEFAULT (1)
```

This tells the scheduler to automatically record timing statistics for each task.
Note that, in addition to user tasks, this will profile all system-level tasks as well.
Since addition code must be executed to record the timing statistics, profiling the code necessarily has some timing overhead.

```{attention}
Profiling code introduces a small overhead to the system scheduler timing, resulting in slightly less overall timing slack.
```

### Only Profiling Specific Tasks

If profiling all registered tasks is not acceptable, do not set the above define to `1` -- keep it as `0`.

Instead, manually enable task timing statistics for a specific task.
To do this, use the `task_stats_enable()` function as follows:

`my_user_task.c`:

```C
#include "sys/task_stats.h"

void task_setup(void) {
    // ...
    task_stats_enable(&tcb.stats);
    // ...
}
```

Note that `tcb` refers to the local task variable which is required for every task.

## Viewing Timing Results

After enabling task timing statistics, the system scheduler will automatically record the timing for tasks.
This occurs in the background without any user interaction.

To view the results, print the timing data to the host terminal via `task_stats_print()`:

`my_user_task.c`:

```C
#include "sys/task_stats.h"

...

void print_my_timing_stats(void) {
    // ...
    task_stats_print(&tcb.stats);
    // ...
}

...
```

Note that `tcb` refers to the local task variable which is required for every task.

Now, you simply need to call the `print_my_timing_stats()` function.
Typically, this is done using a command.
For example, in the `blink` example, the command `blink stats print` is used to call the print function in the C code.

## Reset Timing

After recording the timing statistics for a while, you might want to reset the stats:

```C
task_stats_reset(&tcb.stats);
```

This resets the mean/min/max timing values, etc.

In the `blink` example, the command `blink stats reset` does this.

## Profiling Accuracy

Internally, the profiling framework uses the FPGA timer driver to measure time (i.e., `drv/fpga_timer`).
Therefore, the timing resolution is limited to the FPGA clock cycle time (5 ns).

Furthermore, reading the FPGA timer register value takes some time due to the latency across the on-chip AXI bus.
Therefore, the profiling accuracy is limited to 5 ns resolution, but inherently adds a few 100 ns due to the AXI latency.

This is **not** compensated internally by the profiling framework.
The user must account for this extra time.

```{seealso}
The CPU timer driver, `drv/cpu_timer`, can be used for more accurate timing.

It has a resolution of about 1.5 ns and much lower latency than the AXI bus.
```
