# Python Classes

For programmatic interaction with the AMDC, a basic Python class is provided.

The Python class files are available in: `AMDC-Firmware/scripts/`.

## `AMDC.py`

This is the core class which represents the AMDC.
After instantiating it, users can use it to send commands to the AMDC and read the response.
It supports both UART and Ethernet physical links.

Create a single AMDC object simply by:

```python
from AMDC import AMDC

amdc = AMDC()
```

Next, required configuration is needed depending on if UART or Ethernet is used.

### Configuring UART Mode

```python
# After creating the amdc object...

# Set comm defaults for UART
amdc.setup_comm_defaults('uart')

# Init UART using the specified port (specific to each host PC)
amdc.uart_init('COM1')
```

### Configuring Ethernet Mode

```python
# After creating the amdc object...

# Set comm defaults for UART
amdc.setup_comm_defaults('eth')

# Init ethernet 
amdc.eth_init()

# Set up the default ASCII command socket
s0 = amdc.eth_new_socket('ascii_cmd')
amdc.eth_set_default_ascii_cmd_socket(s0)
```

### Connect / Disconnect

Both UART and Ethernet support notions of connecting and disconnecting from the AMDC.

- `amdc.connect()`
- `amdc.disconnect()`

For UART, this opens and closes the serial connection.

For Ethernet, connect does nothing since sockets are opened at creation.
Disconnect closes all open sockets.

### Sending Commands

After the initial configuration above, the AMDC object can be used without knowledge of the physical link.
Ethernet will simply have higher throughput.
Note that for simple commands, UART and Ethernet will appear to perform nearly the same (that is to say, fast).

To send commands, use the `amdc.cmd(cmd_str)` method where `cmd_str` is the character command text.

The `cmd()` method will send the characters to the AMDC over the configured link, then read the AMDC command response.
The method will block until the response is read, or a timeout is reached (default of 1 second).

The AMDC firmware is configured to run up to one command per time slice.
The default time slice is 100 usec, meaning the maximum theoretical command rate is 10 kHz.
In practice, users can expect command throughput well into the 100s of Hz.

### Customizing the AMDC Communication

The AMDC class supports customization of class parameters to change how the interface performs.

Customize the class after creating the `amdc` object.

#### Commands

- `amdc.comm_cmd_cmd_print` -- print the sending command to the console (default: `True`)
- `amdc.comm_cmd_cmd_print_prepend` -- prepend the sending command print with string (default: `"\t> "`)

#### Responses

- `amdc.comm_cmd_resp_capture` -- capture the response output from the command (default: `True`)
- `amdc.comm_cmd_resp_print` -- print the captured reponse to the console (default: `True`)
- `amdc.comm_cmd_resp_print_prepend` -- prepend the captured command response print with string (default: `""`)

#### Delays

- `amdc.comm_cmd_delay_cmd` -- delay after sending commands for given seconds (default: `0.001`)

## `AMDC_Logger.py`

This class wraps the variable / signal logging module.

View the comprehensive documentation: [](/firmware/modules/logging/index.md).

## `AMDC_LivePlot.py`

This class implements real-time plotting of signals from the AMDC via Ethernet streaming.