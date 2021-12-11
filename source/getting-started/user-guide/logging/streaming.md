# Signal Logging (Streaming)

This document explains how to use the streaming logging features in the firmware.

```{Important}
**Streaming is only available when using the Ethernet physical link to the AMDC!**
```

The instructions pick up where the [](/getting-started/user-guide/logging/index.md) document left off.
Before starting the instructions below, make sure you have completed the common logging steps desribed in [](/getting-started/user-guide/logging/index.md).

```{attention}
The streaming logging instructions below assume you have already:

1. Instrumented your C-code for logging
2. Registered the variables via the Python logging class
```

## Introduction

The streaming logging method is designed specifically for real-time signal plotting and data logging.
To that end, the entire streaming interface is wrapped in a real-time plotting class which manages all streaming-related code.

The real-time plotting library is called `AMDC_LivePlot.py`.

It is is available in the `AMDC-Firmware/scripts/` folder.

## `AMDC_LivePlot.py`

The `AMDC_LivePlot` class wraps the streaming interface to the AMDC.
Each instance of the `AMDC_LivePlot` class maps to a single variable in the AMDC firmware.
The class handles two main things:

1. Streaming socket interface from the AMDC where data signals flow
2. Real-time plotting built on top of the `matplotlib` animation capability

The user does not need to be aware of how the class works.
The class can automatically create a streaming socket, capture the data, and plot it -- all in real-time.

## Python Interface for Streaming Logging

Using the streaming-based logging features is completely encapsulated via the Python class `AMDC_LivePlot.py` which is available in the `AMDC-Firmware/scripts/` folder.

### 1. Register variables

This step should have already been performed, as explained in [](./index.md).

```{note}
For streaming data, you **should not** start a buffered log.
Simply registering the variables is enough.
```

### 2. Import the class

```Python
from AMDC_LivePlot import AMDC_LivePlot
```

### 3. Change Jupyter Notebook to support interactive plotting

The live plotting capabilities require interactive plots in Jupyter notebooks.

Run the following magic:

```Python
%matplotlib notebook
```

To go back to static inline plots:

```Python
%matplotlib inline
```

### 4. Create an `AMDC_LivePlot` object

To stream variable `LOG_foo` from the AMDC:

```Python
plot = AMDC_LivePlot(logger, 'foo')
```

The constructor above takes two optional arguments:

- `update_interval_ms` -- how often to redraw the `matplotlib` figure (default is `100`)
- `window_sec` -- "look-back" period for plotting data; data before the window is discarded (default is `1`)

The default arguments above redraw the plot at 10 Hz and keep the last one second of data on the plot.

```{attention}
After creating the `AMDC_LivePlot` object, the graph will immediately start drawing and updating.
However, **no data will appear** since the actual data streaming is decoupled from the plotting.
```

### 5. Start streaming data from the AMDC

The `AMDC_LivePlot` is ready to start receiving data and plotting it.

Start streaming data via:

```Python
plot.start_stream()
```

After calling this method, the plot should immediately start showing data.
After `window_sec` time has elapsed, the x-axis of the plot will start scrolling and old data will be removed.
The latest data is always on the far right of the plot.

The x-axis shows the number of seconds that the AMDC has been running.
It will continually increase until the seconds variable wraps in the firmware.
The wrapping is not supported in the plotting library.

### 6. Stop streaming data from the AMDC

The AMDC will continuously stream data until it is told to stop:

```Python
plot.stop_stream()
```

The user must manage the starting and stopping of data streaming themselves!
If the interactive plot is closed, data streaming will still occur in the background.

```{caution}
Even if the Python kernel is restarted, the AMDC will **still** stream data, resulting in buffer overruns since the host is not reading in data.
Make sure to stop streaming before stopping the kernel.
```

## Performance

A total of **four** streams are available at one time from the AMDC.
Since each `AMDC_LivePlot` only supports a single variable, this means that only **four** variables can be streamed at once.

The AMDC firmware and host Python library support data streaming at the full sample rate possible: 10 kHz.
However, be aware that the `matplotlib` plot is completely redrawn each update.
Plotting a one second window period with 10k data points is slow, so the refresh rate will be limited.

For responsive plots, either reduce the sampling rate (e.g., try 10-100 Hz) or reduce the window period (e.g., try 10 ms).

```{note}
The performance limitations above are not hard limits; they are simply due to the code implementation.

Future improvements are planned which will support an arbitrary number of variables per stream, and any number of streams.
The true limit is simply the ~1 Gb/s throughput of the Ethernet link (likely already reduced due to the Python `socket` library overheads; probably more than 200 Mb/s but less than 1 Gb/s).

For plotting performance, future improvments will implement [blitting](https://matplotlib.org/stable/tutorials/advanced/blitting.html) which will drastically improve plot update rate.
```

## Copy-Paste Example

This example shows how to stream the built-in log variables from the `blink` user app.

It is assumed to be run in a Jupyter notebook; each cell is marked via comments in the code.

```Python

##### CELL START #####
%matplotlib notebook

##### CELL START #####
from AMDC import AMDC
from AMDC_Logger import AMDC_Logger, find_mapfile
from AMDC_LivePlot import AMDC_LivePlot

##### CELL START #####
USE_ETHERNET = True

if not USE_ETHERNET:
    amdc = AMDC()
    amdc.setup_comm_defaults('uart')
    amdc.uart_init('COM6')
else:
    amdc = AMDC()
    amdc.setup_comm_defaults('eth')
    amdc.eth_init()
    s0, s0_id = amdc.eth_new_socket('ascii_cmd')
    amdc.eth_set_default_ascii_cmd_socket(s0)

##### CELL START #####
mfpath = find_mapfile(r'C:\Users\Nathan\Documents\GitHub\AMDC-Firmware\sdk\app_cpu1')
logger = AMDC_Logger(amdc, mfpath)

##### CELL START #####
logger.sync()
logger.info()

##### CELL START #####
logger.unregister_all()
samples_per_sec = 100
logger.register('vsi_a', var_type = 'double', samples_per_sec = samples_per_sec)
logger.register('vsi_b', var_type = 'float', samples_per_sec = samples_per_sec)
logger.register('vsi_c', var_type = 'int', samples_per_sec = samples_per_sec)

##### CELL START #####
p1 = AMDC_LivePlot(logger, 'vsi_a', window_sec = 1)
p1.start_stream()
p1.show()

##### CELL START #####
p2 = AMDC_LivePlot(logger, 'vsi_b', window_sec = 1)
p2.start_stream()
p2.show()

##### CELL START #####
p3 = AMDC_LivePlot(logger, 'vsi_c', window_sec = 1)
p3.start_stream()
p3.show()

##### CELL START #####
p1.stop_stream()
p2.stop_stream()
p3.stop_stream()
```