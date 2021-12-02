# docs.amdc.dev

**AMDC Platform Documentation**

This repo stores all the raw source used to build the [docs.amdc.dev](https://docs.amdc.dev/) website.

## Automatic Build

The main docs are located in the `main` branch.
On push to `main`, the **Sphinx Build** GitHub Action is triggered which builds the docs and publishes them to the `gh-pages` branch.
The `gh-pages` branch serves the public website, docs.amdc.dev.

**Warning:** The build process is automatic and fast (< 60 seconds).
Make sure the changes being merged into `main` are ready to be published!
You will not have time to undo the merge before the changes are visible to all on the interwebs!
