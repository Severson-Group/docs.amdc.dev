# Signal Logging (Buffered)

This document explains how to use the buffered logging features in the firmware.

The instructions pick up where the [](/getting-started/user-guide/logging/index.md) document left off.
Before starting the instructions below, make sure you have completed the common logging steps described in [](/getting-started/user-guide/logging/index.md).

```{attention}
The buffered logging instructions below assume you have already:

1. Instrumented your C-code for logging
2. Registered the variables via the Python logging class
```

## Python Interface for Buffered Logging

### 1. Empty logged variables:

```Python
logger.empty_all()
```

Empties the log of any old data to prepare for collecting new data.
If you do not do this, the logger will simply append new data to the old data.
This does *not* unregister variables, only empties them.

To empty a single variable:

```Python
logger.empty('foo')
```

### 2. Start logging:

```Python
logger.start()
```

Begins sampling the registered variables at the requested sample rate, and writing the values to the internal memory buffer.

### 3. Stop logging:

```Python
logger.stop()
```

Stops sampling the registered variables.

Typically, you will want to record an event or record data for a set amount of time.
The following example illustrates a common use case:

```Python
logger.empty_all()
logger.start()

# Tell your controller to do something cool
do_something_cool()

# Record data for 1 second after the cool event
time.sleep(1)

logger.stop()
```

### 4. Log for set duration:

If you just want to start logging, wait for a few seconds, and stop logging:

```Python
# Record data for about half second
logger.log(duration = 0.5)
```

The above is exactly equivalent to

```Python
logger.start()
time.sleep(0.5)
logger.stop()
```

This is often used to record steady-state operation of the control system.


### 5. Dump data:

After collecting data (and stopping the logging process), transfer the data to the host:

```Python
data = logger.dump()
```

The output of the `dump()` method is a `pandas.DataFrame` object.
`pandas` is a popular data science library in Python and a `DataFrame` is the primary object that `pandas` works with.
Think of a `DataFrame` like an Excel spreadsheet.
The columns of the `DataFrame` correspond to each logged variable and the index of the dataframe is time.

```{tip}
Invest your time in learning how `pandas` works.
This cannot be stressed enough.
Pandas is very powerful and can make analyzing the logged data much faster and easier.

Make sure you understand how `pandas` stores data, and ensure you can easily manipulate, process, and view the data.

There is an insane amount of resources available to learn `pandas` -- consider starting [here](https://pandas.pydata.org/docs/getting_started/intro_tutorials/index.html).
```

The `dump()` function is powerful and has a lot of optional arguments.
By default, `dump()` will dump out all logged variables.

Depending on the amount of data, this can be time consuming.
Instead, you can also specifiy a subset of variables to dump as follows:

```Python
data = logger.dump(log_vars = 'foo bar')
```

You can also specify a file path and `dump()` will automatically save your data to a `.csv` file.
This is nice to make sure your data persists between experiments.
By default, the `dump()` function appends a timestamp to your file name so that it does not overwrite prior data.

```Python
data = logger.dump(log_vars = 'foo bar', file = 'my_data.csv')
```

Comments can be added to the output CSV file using the optional `comment` parameter:

```Python
data = logger.dump(
    log_vars = 'foo bar',
    file = 'my_data.csv',
    comment = 'the motor appeared to run smooth')
```

### 6. Load back prior logged data:

To load in a previous logged CSV data file:

```Python
data = logger.load('old_data_file.csv')
```

This will load your old data run into a `pandas` `DataFrame`.
The load function is just a thin wrapper around the `pandas` `read_csv()` method and the above line of code is equivalent to:

```Python
data = pd.read_csv('old_data_file.csv', comment = '#', index_col = 't')
```

Loading the data this way sets time to be the index of the `DataFrame` and ignores any comments you may have stored with the data.

### 7. Plot data:

Now that your data is in a `DataFrame`, you can post-process it however you wish.
As motivation for why the `DataFrame` is so powerful for logging and debugging, consider this example. 

Imagine we have recorded (x,y,z) position data from displacement sensors as `pos_x`, `pos_y`, and `pos_z`, as well as measured three phase currents `I_a`, `I_b`, and `I_c`.
We can extract all of the data into a single dataframe `df` and save the data as follows:

```Python
df = logger.dump(file = 'sensed_values.csv')
```

Let's make two quick plots: positions and currents:

1. Plot the first 100 ms of position data, and add a marker so we can see each sampled value. 
We want to plot the positions in micrometers, but the data is stored in meters.

2. Make a similar plot for the currents, with the same time window and marker.

```Python

# Convert position data from meters to um
gain_m_to_um = lambda x: x*1e6

t0 = 0 # [sec]
t1 = 0.1 # [sec]

marker = '.'

ax = df[t0:t1].filter(regex="pos_").apply(gain_m_to_um).plot(marker=marker)
ax.set_ylabel("Position (um)")

ax = df[t0:t1].filter(regex="I_").plot(marker=marker)
ax.set_ylabel("Current (A)")
```

## Copy-Paste Example

The following Python script example shows the full flow of buffered logging on the AMDC.
Users should copy and paste this script to get started.

```{note}
This example assumes UART physical link to the AMDC.
Modify the setup portion for Ethernet via the instructions [here](/getting-started/user-guide/host-interface/python-wrapper.md).
```

```Python
# CHANGE THIS TO YOUR REPO DIRECTORY
repo_dir = r'C:/my/example/path'

# CHANGE THIS TO YOUR AMDC PORT NUMBER
uart_port = 'COM1'

# SET THIS TO PATH OF YOUR USER APPLICATION CODE
user_app_c_code_path = r'C:/my/example/path/my_c_code'

import time
import pathlib as pl
import sys
repo_dir = pl.Path(repo_dir)
scripts_folder = repo_dir / 'AMDC-Firmware' / 'scripts'  
sys.path.append(str(scripts_folder))

from AMDC import AMDC
from AMDC_Logger import AMDC_Logger, find_mapfile

####################
# SETUP LOGGER
####################

amdc = AMDC(port = uart_port)
amdc.connect()

mapfile_path = find_mapfile(repo_dir)
logger = AMDC_Logger(AMDC = amdc, mapfile = mapfile_path)
logger.sync()

####################
# REGISTER VARIABLES
####################

logger.auto_register(user_app_c_code_path)

# View which variables are logged
logger.info()

####################
# COLLECT DATA
####################

# Empty the logger, then record data
logger.empty_all() 
logger.start()

# DATA IS BEING RECORDED
time.sleep(1)

logger.stop()

####################
# DUMP DATA AND PLOT
####################

data = logger.dump(file = 'test_data.csv')
data.plot()
```

```{tip}
For a Jupyter notebook environment, put each section of the code in its own cell so you can run the code in pieces.
```
