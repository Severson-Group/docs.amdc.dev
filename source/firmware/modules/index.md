# Modules

The core AMDC firmware comes with several additional modules (i.e. libraries) which can be used by users.
These modules are optional and are not enabled by default.

To enable the modules, change the `#define` symbols located in `usr/user_config.h`.
By default, the defines are set to `0` meaning the feature is not enabled.
Enable by changing to `1`.


```{toctree}
:hidden:

logging/index
injection/index
code-profiling
amds-interface
```