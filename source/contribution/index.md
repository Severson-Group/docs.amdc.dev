# Versioning

We use Sphinx-Multiversion to allow users to view historic revisions of our documentation. This page exists to explain how the documentation all ends up under the correct labels.

## Sphinx Multiversion Overview

Sphinx has been configured to search for tags starting with `v#.` and add them to the version switcher at the bottom of the page. The version switcher has also been configured to put the branch named `main` at the very top, labled as `latest`.
During the build process sphinx will go to the commits that the various tags are pointing to, build them, and put the results in seperate folders. Each folder is accessable online as a part of the url when visiting the docs. For example, `docs.amdc.dev/v1.0/index.html` points to the `v1.0` folder, while `docs.amdc.dev/v2.0/index.html` points to the `v2.0` folder.

## Organization Paradigm for docs.amdc.dev

Each folder/tag is a snapshot of the docs at one point in time, representing the most up to date documentation for the firmware revision it is tagged as. 
Please note that the latest firmware release does not have its own tag! Instead, it is assumed that `main` contains the most up to date documentation for the current firmware revision.
When releasing a new firmware version, the latest commit on `main` should be tagged as the firmware revision it was written for. (AKA, the version prior to the one currently being released) This will give it an entry in the version selector. Now, any documentation for the new firmware release can now be merged in without removing access to previous documentation. The main branch remains the most up to date documentation, and now targets the new firmware version that was just released.
