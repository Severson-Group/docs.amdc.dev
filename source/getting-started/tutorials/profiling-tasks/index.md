# Tutorial: Profiling Tasks

- **Goal:** Determine code performance by using task timing statistics.
- **Complexity:** 2 / 5
- **Estimated Time:** 20 min

This tutorial builds on the previous VSI tutorial.
It guides the user on profiling the real-time timing of the VSI control code to ensure it can be operated successfully.

In general, it goes over:

- Enabling built-in task profiling feature
- Profiling run time and loop time of a control task

## Tutorial Requirements

1. Working AMDC hardware
2. Completion of the [VSI tutorial](../vsi/index.md)

## Introduction

Real-time control code must meet strict real-time timing constraints.
As a user, knowing how long your control code takes to run is critically important to ensure the stability of the real-time scheduler.
Furthermore, the timing stats can help validate that the discrete-time controller is running as expected.

Estimating the embedded code timing performance is very hard to do via simulation, so typically, running the code on the hardware processor is the best way to determine the real-time timing performance.

## Step 1: AMDC code profiling capabilities

The AMDC firmware has built-in support for profiling task execution timing.

Before continuing with this tutorial, read the [](/getting-started/user-guide/task-profiling.md) document.
This will explain the capabilites and process of profiling code on the AMDC.

## Step 2: Turn on profiling for the VSI task

Now that you understand the code profiling capabilities built into the AMDC firmware, we will use it to profile the VSI control code written in the previous tutorial.

We will only enable task profiling for the VSI control task, not all system tasks.

To do this, update the controller `init()` function:

`task_controller.c`:

```C
#include "sys/task_stats.h"

// ...

int task_controller_init(void)
{
    // ...
    task_stats_enable(&tcb.stats);
    // ...
}

// ...
```

Next, add task functions which wrap the `print()` and `reset()` functions for the timing stats:

`task_controller.c`:

```C
// ...
void task_controller_stats_print(void)
{
    task_stats_print(&tcb.stats);
}

void task_controller_stats_reset(void)
{
    task_stats_reset(&tcb.stats);
}
// ...
```

Do not forget to also add these new functions to the header file!

These are the only change required in the code to enable profiling of the VSI control task.

## Step 3: Add command to print timing results

If we stopped now, the timing stats would be recorded, but there would be no way to see the values.

To see the results, add the following `ctrl stats ...` subcommand to the VSI control command:

`cmd/cmd_ctrl.c`:

```C
// ...

static command_help_t cmd_help[] = {
    // ...
    { "stats print", "Print stats to screen" },
    { "stats reset", "Reset the task timing stats" },
    // ...
};

// ...

int cmd_ctrl(int argc, char **argv)
{
    // ...

    if (argc == 3 && STREQ("stats", argv[1])) {
        if (STREQ("print", argv[2])) {
            task_controller_stats_print();
            return CMD_SUCCESS;
        }

        if (STREQ("reset", argv[2])) {
            task_controller_stats_reset();
            return CMD_SUCCESS;
        }
    }

    // ...

    return CMD_INVALID_ARGUMENTS;
}

// ...
```


## Step 4: Profile the VSI control code

The code is ready for testing!

1. Run the code on the AMDC hardware.
2. Enable the VSI controller code so that task timing stats are collected (i.e., `ctrl init`)
3. Stop the task to freeze the timing results (i.e., `ctrl deinit`)
4. Print the timing stats to the terminal: `ctrl stats print`

Note the differences between the **run time** and **loop time**.

The loop time has some jitter, but the mean value should be exactly 100 usec since the VSI controller task is running at 10 kHz.
The loop time variance should also be very small.

The run time tells you how long it takes to run the VSI controller callback function.
Since the function must compute several trig functions, the time will be non-zero.
However, it should be trivially small compared to the overall time slice of 100 usec (i.e., < 10% of the time slice).

## Step 5: [optional] Determine if compiler optimization affects code timing

```{note}
This step is **optional**, but helps you build insight into how compiler optimization affects code timing performance.
```

The default optimization level for the C-code in the AMDC is `-O2`, which is fairly heavily optimized.
However, there are other possible compiler optimization levels:

- `-O0` -- none
- `-O1` -- minor
- `-O2` -- standard for deployment
- `-O3` -- agressive

Read more about compiler optimization in `gcc` at [this link](https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html).

Experiment with changing the AMDC optimization level and reprofiling the VSI control task.
Are there major changes to run-time performance based on compiler optimization levels?
Does each level give equal improvement to code speed?

Compiler optimization is a *very* complex subject and its own area of active research.
Explaining how and why the code performance changes between optimization levels is difficult!

## Conclusion

**Congratulations!**

You have now profiled the run time and loop time performance of a real control task.

In general, you do not need to be profiling your control code all the time.
Only when you write new control code should you ensure it does not break the real-time capabilites of the firmware.