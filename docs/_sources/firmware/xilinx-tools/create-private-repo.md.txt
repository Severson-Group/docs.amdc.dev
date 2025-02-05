# Create Private Repo

This document explains the steps needed to set-up a private repo for AMDC firmware development. The following steps outline how to create an overarching private repo which can be cloned from git and has all the needed items to flash an AMDC.

1. Perform all the steps from the [first tutorial](building-and-running-firmware.md), following the "private" code option.
2. Create folders in your repo root (called `$REPO_ROOT` in this doc) for all generated outputs from Vivado and SDK
    1. Create folder `$REPO_ROOT/gen/sdk_gen/`
    2. Create folder `$REPO_ROOT/gen/vivado_gen/`
3. Copy the following from `$REPO_ROOT/AMDC-Firmware/` to `$REPO_ROOT/gen/vivado_gen/`
    1. `hw/`
    2. `amdc/`
4. Copy the following from `$REPO_ROOT/AMDC-Firmware/sdk` to `$REPO_ROOT/gen/sdk_gen/`
    1. `amdc_rev*_wrapper_hw_platform_0/`
    2. `amdc_bsp_cpu0/`
    3. `amdc_bsp_cpu1/`
    4. `amdc_rev*_wrapper.hdf`
    5. `fsbl/`

*Note that the `fsbl` project will only exist if you have previously created a bootloader program, as outlined in the [Flashing AMDC](./flashing.md) document.*

Now, your private repo contains all needed files. Each time you clone it, you will need to follow the following steps to use it.

## Cloning Private Repo / First-Time Set-Up

1. Clone your repo from git
2. Make sure the submodules are checked out (`git submodule update --init` etc)
3. Open SDK
4. Select workspace to reside in local user folder (outside of your private AMDC firmware repo).
5. Import the above projects (`amdc_rev*_wrapper_hw_platform_0`, `amdc_bsp_cpuX`, `fsbl`, your `user_code` project in your private repo, not AMDC-Firmware submodule) (open projects from file system)
6. Wait for them to compile... (it will fail due to not knowing about the `AMDC-Firmware` submodule)
7. To fix the errors, redo the steps from the [previous tutorial](building-and-running-firmware.md), starting at the "Fix common code compilation" section. This links the `common` AMDC-Firmware submodule code to your private project.

You can now use your private repo!
