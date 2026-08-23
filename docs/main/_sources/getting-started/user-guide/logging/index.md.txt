# Signal Logging

```{toctree}
:hidden:

Buffered <buffered>
Streaming <streaming>
```

This document describes the "logging" features built into the core AMDC firmware.
Logging simply means recording variables over time from inside the firmware and retreiving the sampled values.
The capability to log variables from inside the C-code is absolutely essential to debugging complex control algorithms, as well as validating correct behavior.

```{seealso}
Signal logging pairs nicely with [](../injection/index.rst)!
```

## Types of Logging

The AMDC supports two methods of logging data:

1. [Buffered](./buffered.md)
2. [Streaming](./streaming.md)

Each method has its pros and cons.
Furthermore, the appropriate method for each user will change over time.
For example, during initial control development and bring-up, streaming might make more sense, but after the controller matures, buffered logging might work better.
For demos, streaming-based logging is a powerful way to give the audience insight into the inner workings of the controller.
Understanding how to log via both methods will provide the most flexibility.

The general logging flow can be broken into two parts:

1. Elements common to both methods (buffered and streaming)
2. Elements specific to one method

The remainder of this page will describe the common elements for signal logging.
For the elements specific to each method, check out the respective subpage.

## Internal Workings

Understanding the internal architecture of the logging framework (`sys/log`) can help better explain the features and reasoning behind the features.
A brief summary is provided below.

For each C-code variable which should be logged, e.g. `LOG_x`, a slot is allocated within the logging engine.
This slot contains metadata as well as a large memory array.
When buffered logging starts, the value of the logged variable (e.g. `LOG_x`) is copied into the memory buffer at the specified sampling interval.
Once buffered logging is done, this large array of samples can be transfered from the AMDC to the host via the command-line interface.

For streaming-based logging, the same principles apply as buffered logging, however, the large memory buffer goes unused.
Instead, when log streaming is started, the registered variables are sampled and directly streamed from the AMDC to the host.

```{danger}
By default, the AMDC system runs tasks at a 10 kHz rate, resulting in a period between callbacks of 100 µs. For integer periods, the logging system works as expected.

However, if you change the timing configuration of the AMDC and are running tasks at a frequency that results in a non-integer period in microseconds, then the time interval between samples reported back to the Python interface for logging will be truncated. The system will still function, logging will still happen at the expected/desired rate. However, the logged data returned to the host will use the truncated time interval, resulting in an incorrect time vector. Users should be aware of this and fix the time vector themselves accordingly.

For example, a control/sample rate of 22 kHz results in a period of 45.4545 µs (not an integer). After dumping the logged data to the host, the time vector will be based on the truncated interval of 45 µs, i.e., `t = 0, 45, 90, ...` µs.

This is a known limitation of the `v1` codebase and will be fixed in the `v2` release.
```

### Specifications

By default, the logging framework can record up to 32 different variables at one time (i.e., 32 slots).

#### Buffered

For each variable, the framework can store a maximum of 100k samples (default configuration).
Once the log buffer is full, the logging system automatically stops writing data (even if logging is still enabled).
The logging engine *does not* use a circular buffer approach.

#### Streaming

If only the streaming-based logging is used, the only relevant specification is the maximum variable slots; the sample buffers are not used (although, still allocated to memory).

#### Specification Modifications

The defaults above (32 slots at 100k sample depth) can easily be configured by the user via the `usr/user_config.h` file.
Simply uncomment the slots and sample depth defines to override the default values.
Note that the maximum memory available is limited, so users must keep the product of `slots` and `sample depth` reasonable (i.e. less than 100s of MB).
For example, the user could change the settings to be 128 variables at 25k sample depth.

(c-code-modifications)=
## C-Code Modifications

The logging framework has been designed specifically to limit the amount of changes users have to make to their C-code to log variables of interest. The only modifications that users need to make to their C-code are as follows:

1. Enable the logging feature using the config file `usr/user_config.h`. This is located in the `usr/` folder of your private C code. Set the following define variable to `1`:

```C
#define USER_CONFIG_ENABLE_LOGGING (1)
```

Note that it is set to 0 (logging disabled) by default.

2. For every variable that you want to log within your C code, create a new global variable with the same name prepended by `LOG_` (note that it is case sensitive).
For example, if you have a variable `foo` in your code that you would like to log, create a new global variable of the same type called `LOG_foo`.
Note that the total logging variable name length is limited to 32 characters (including the `LOG_` prefix) due to how the CLI command parsing works.

3. Update all global logging variables wherever desired by assigning the local variable to the global variable (e.g. `LOG_foo = foo;`)

### Example

The following example illustrates one possible use case:

We have a typedef called `Currents_t` that is a struct containing measured currents from each of the three inverter phases. This variable is then updated by the generic `read_currents` function. You could imagine this function is reading in the three current sensors from an inverter. **We wish to log the three phase currents.** To do this, we use the two steps listed above.

First, we create global variables for each of the three currents that we care about. Then, in the callback function, we update the global current variables to equal the measured currents that we care about tracking. Note that in this example we update the global variables within the callback, but you can update them at any point in your code. For example, we could have updated the global variables inside of the `read_currents()` function

```C
double LOG_Ia = 0.0;
double LOG_Ib = 0.0;
double LOG_Ic = 0.0;

typedef struct Currents_t {
    double Ia;
    double Ib;
    double Ic;
} Currents_t;

static Currents_t Iabc = { 0.0, 0.0, 0.0 };

void example_callback_func(void)
{
    // Read currents from sensors
    read_currents(&Iabc);
    
    // Update variables that are being recorded by logging application
    LOG_Ia = Iabc.Ia;
    LOG_Ib = Iabc.Ib;
    LOG_Ic = Iabc.Ic;
}
```

There are no other steps needed in the embedded code running on the AMDC for logging. The only requirement is that you have exposed a global variable and updated it. The rest of the logging system is handling by the system code.

## Terminal Interface

The logging framework exposes several `log` subcommands which are used to interact with the logging process.
While users *could* theoretically use the raw `log` commands themselves, this is highly discouraged.
Instead, a comprehensive Python class is provided which greatly simplies logging.

First, we will discuss the raw terminal interface.
Then, the Python wrapping.

```{important}
Users should never need to use the raw `log` commands directly.
Always use the Python wrapper class!
```

1. `reg` -- registers a new variable for logging
    > **Required Arguments**
    > - `log_var_idx` -- the index that you want the variable to be stored in (must be 0-31). The command will fail if a variable is already registered in the requested slot.
    > - `name` -- name of the variable that you are logging (example: `LOG_foo`)
    > - `memory_addr` -- global memory address of the variable you are logging in decimal format. The reason global variables are created for logging is because their address remains constant at runtime. The memory address can be found in "mapfile.txt" in a hexadecimal format, which is located in the "Debug" folder of the users private c code. After locating the variable's address, you must convert it from hexadecimal to decimal before entering it in the terminal.
    > - `samples_per_sec`  -- the sample rate in samples per second that you wish to record the variable at. Note that not all variables have to have the same sample rate. This generally can range from 1 to 10kHz.
    > - `type` -- data type of the variable being logged. Valid types are: `double`, `float`, `int`

2. `unreg` -- unregisters a variable that you no longer care to log  
    > **Required Arguments**  
    > - log_var_idx -- the index of the variable that you want to unregister (must be 0-31).
    
3. `start` -- starts recording data  
    
4. `stop` -- stops recording data  
    
5. `dump` -- dumps all of the recorded data of a slot out to the serial terminal  
    > **Required Arguments**  
    > - `bin` or `text` -- One of the preceding flags must be set. If `bin` is used, the data will be dumped to the serial terminal in binary format. If `text` is used, the data will be dumped to the serial terminal in human readable text format. Using `bin` is much faster.
    > - `log_var_idx` -- index of the variable that you wish to dump (must be 0-31)
    
6. `empty` -- resets the specified logging slot (calling `dump` after `empty` on the same slot will result in no data being output)  
    > **Required Arguments**  
    > - `log_var_idx` -- index of the variable you wish to reset
    
7. `info` -- prints information about the logging system (registered slots, samples, etc) to the serial terminal  

## Python Interface

Before you can use the Python interface, you must modify your C-code according to the [C-Code Modifications](#c-code-modifications) section.

Note that in the text that follows, `REPO_DIR` is an alias for the file path to where your repository is located.
`REPO_DIR` contains the `AMDC-Firmware` submodule as well as a the folder containing your user C-code.

### 1. Import needed modules:

To use logging in Python, you must `import` the `AMDC` and `AMDC_Logger` modules from the `scripts` folder of the AMDC-Firmware.
There are two main classes of interest:

1. `AMDC`: class that is found in the `AMDC` module. Responsible for communicating with the AMDC over the physical link
2. `AMDC_Logger`: class that is found in the `AMDC_Logger` module. Responsible for sending logging commands to the AMDC and book keeping

The top of your Python script should look like the following:

```Python
import sys
scripts_folder = r'REPO_DIR\AMDC-Firmware\scripts'
sys.path.append(scripts_folder)

from AMDC import AMDC
from AMDC_Logger import AMDC_Logger, find_mapfile
```

Adding the location of the scripts folder to the `sys.path` variable allows Python to find the `AMDC` and `AMDC_Logger` modules to import them.

After importing the modules, perform the following steps:

### 2. Instantiate an `AMDC` object and connect it to the AMDC:

This depends on the physical link being used, i.e., UART vs. Ethernet.

For detailed instructions about using the `AMDC.py` class, follow the steps [here](/getting-started/user-guide/host-interface/python-wrapper.md).

### 3. Instantiate an `AMDC_Logger` object:

```Python
mapfile_path = find_mapfile(REPO_DIR)
logger = AMDC_Logger(AMDC = amdc, mapfile = mapfile_path)
```

The `AMDC_Logger` object requires two inputs on instantiation: an `AMDC` object (created in step 2), and a file path to where the mapfile is located. You can manually locate and specifiy the location of `mapfile.txt` or you can use the convenience function `find_mapfile()` which takes in the base path of the repository and locates and returns the path to the mapfile.

### 4. Synchronize logger with AMDC:

```Python
logger.sync()
```

This step isn't required but is recommended. It reads the current state of logging in the AMDC and synchronizes Python to that state. It's useful for if you restart your Python session while the AMDC is still on. If you don't do this and variables are are set up for logging in the AMDC, the internal state of Python's book keeping and the AMDC won't align and you'll get unexpected behavior.

### 5. Register variables of interest:  

There are several ways to register variables for logging. One way is as follows:

```Python
logger.register('LOG_foo', samples_per_sec = 1000, var_type = 'double')
```

Note that register has default arguments of `samples_per_sec = 1000` and `var_type = 'double'` so the preceding line could also be accomplished as follows:

```Python
logger.register('LOG_foo')
```

If you have multiple variables that you wish to register with the same type and sample rate you can register them all at the same time. the `AMDC_Logger` class is also smart and sanitizes the input variables so you don't have to prepend `LOG_` to each variable if you don't want. The following snippets of code all accomplish the same task.

```Python
logger.register('LOG_foo LOG_bar LOG_baz') # variable names in one string seperated by white space
logger.register('foo bar baz')             # one string with no LOG_ (this option is probably the fastest/easiest)
logger.register(['foo', 'bar', 'baz'])     # list of variable names
logger.register(('foo', 'bar', 'baz'))     # tuple of variable names
```

There is also a convenient `auto_register()` function that can be used to search your user code for variables of the form `LOG_*` and register them for you automatically. You just give the file path to your app's c code as follows:

```Python
logger.auto_register(path_to_user_app)
```

if you want to check to see which variables the auto register function will register before calling it, you can call the `auto_find_vars()` function as follows:

```Python
log_vars, log_types = auto_find_vars(path_to_user_app)
```

where `log_vars` is a list containing all of the variables found in the user c code and `log_types` is a list containing the corresponding variable types.

### 6. Unregister variables:

Sometimes, you need to unregister a variable to free the logging slot.
This can happen when you are changing experiments or accidentally registered the wrong variable.

To unregister a specific list of variables:

```Python
logger.unregister('foo bar')

...

logger.unregister('LOG_foo LOG_bar')
logger.unregister(['LOG_foo', 'LOG_bar'])
logger.unregister(['foo', 'bar'])
```

Or, to unregister all variables (i.e. reset the logger to a clean slate):

```Python
logger.unregister_all()
```

----

### 7. Buffered vs. Streaming

At this point, the paths diverge for buffered vs. streaming.
Up to now, you have instrumented the C-code for logging, and called the common Python functions to register variables for logging.

To perform the actual logging, you will need to follow the method-specific instructions:

- [Buffered](./buffered.md)
- [Streaming](./streaming.md)


## Function Reference

The following are methods available in the `AMDC_Logger` class:

### Registering / Unregistering

- `register(log_vars, samples_per_sec = 1000, var_type = 'double')`
- `auto_register(root, samples_per_sec = 1000)`
- `unregister(log_vars, send_cmd = True)`
- `unregister_all()`
- `auto_find_vars(root)`

### Empty Log Slots

- `empty(var)`
- `empty_all()`

### Log Status

- `info()`
- `sync()`

### Start / Stop

- `start()`
- `stop()`
- `log(duration = 0.25)`

### Dump Data / Load

- `dump(log_vars = None, file = None, comment = '', timestamp = True, timestamp_fmt = '%Y-%m-%d_H%H-M%M-S%S', how = 'binary', max_tries = 4, print_output = True)`
- `load(file)`
