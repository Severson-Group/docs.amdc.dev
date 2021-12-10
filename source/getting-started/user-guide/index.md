# User Guide

The AMDC is more than just a blank embedded platform for running control algorithms.
The open-source firmware provides many libraries and frameworks which can be used to greatly accelerate control development time.

```{important}
Invest your time in learning the capabilites already built into the AMDC firmware. Do not reinvent the wheel!
```

For example:

- Python classes are provided which assist in host-AMDC interactions
- Powerful signal logging capabilites provide critical insight into the embedded controller
- Flexible signal injections allow quick controller testing and validation
- Code profiling easily informs the user of controller run-time loop jitter and execution length to ensure scheduler headroom

Dive into the powerful features already included in the AMDC by browsing this page's subpages.

```{hint}
Think of something that is not implemented that you feel is common for all AMDC users?

Submit a GitHub Issue via the [`AMDC-Firmware`](https://github.com/Severson-Group/AMDC-Firmware) repo with your idea!
```

```{toctree}
:hidden:

host-interface/index
logging/index
injection/index
code-profiling
amds-interface
```