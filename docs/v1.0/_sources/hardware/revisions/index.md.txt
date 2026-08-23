# PCB Revisions

The AMDC hardware has gone through several revisions of design improvements and modifications.
This website only provides information and documentation for the lastest supported hardware revisions.
For old revisions, check out the [AMDC-Hardware repo](https://github.com/Severson-Group/AMDC-Hardware).

## Version Labels

All circuit boards in the AMDC Platform follow the same revision labeling format for versioning.
Each time the PCB design is frozen for ordering, a revision output folder (e.g., `REVxxxx`) is created and standardized files are added.

The `REVyyyymmdd*` directories represent snapshots of the project that were used to produce a physical PCB.
These directories contain the *Gerber*, *Drill (Excellon format)*, *Bill of Materials (CSV)*, and *Schematic (PDF)* files.

- `REV` indicates a revision of design for manufacturing
- `yyyymmdd` indicates the date on which design was frozen
- `*` (letter) indicates which revision in sequence (A - first, B - second, etc.)

## GitHub Issues and Milestones

The AMDC hardware development is done using GitHub Issues and GitHub Milestones.
Each hardware revision (e.g., `REV E`) has an associated milestone.
Explore the milestones and the related issues in the [GitHub repo](https://github.com/Severson-Group/AMDC-Hardware/milestones?state=open).
For example, check out the issues resolved for the `REV E` hardware design [via the milestone](https://github.com/Severson-Group/AMDC-Hardware/milestone/5?closed=1).

## Change Log

A detailed hardware change log is provided in the repo with links to individual GitHub Issues containing discussion on each item.
Browse the [full change log here](https://github.com/Severson-Group/AMDC-Hardware/blob/develop/CHANGELOG.md).

```{toctree}
:hidden:

firmware-upgrades-per-hardware-target
rev-d/index
rev-e/index
```