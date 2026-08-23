# REV D Hardware

![](images/amdc-rev-d-cover.jpg)

## Quick Links

- [Changelog](https://github.com/Severson-Group/AMDC-Hardware/blob/develop/CHANGELOG.md#rev20200129d)
- [GitHub Milestone](https://github.com/Severson-Group/AMDC-Hardware/milestone/4)
- [Orderable Design Files](https://github.com/Severson-Group/AMDC-Hardware/tree/develop/REV20200129D)

## Description

The 4th revision of the AMDC hardware is a major design change compared to the previous hardware design.
REV D introduces a drastically smaller PCB form factor with a more compact layout.
The PCB stack-up is increased from 4 to 6 layers to accomidate the smaller PCB area.
Overall, the layout component density is increased to about 50% -- much higher than previous revisions.

Functionally, the REV D design removes half the integrated analog input channels, reducing from 16 to 8 differential inputs.
This saves space, but also limits the hardware capabilities since advanced motor drives often require many more than 8 analog inputs.
To that end, an external sensing platform is designed which integrates with the AMDC via the new GPIO expansion ports.

```{toctree}
:hidden:

rev-d-bring-up
rev-d-errata
rev-d-pin-mapping
```