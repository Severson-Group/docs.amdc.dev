# docs.amdc.dev

**AMDC Platform Documentation**

This repo stores all the raw source used to build the [docs.amdc.dev](https://docs.amdc.dev/) website.

## Getting Started

[Sphinx](https://www.sphinx-doc.org/en/master/) is used to build the docs.
If you want to do advanced things with the docs (i.e., add complicated features), you will need to read the Sphinx docs.
For most people, just read a few pages of the already-written docs to get a sense of how it works, then edit away.

Most of the pages are written in markdown (`*.md`).
A few pages are written in reStructuredText (`*.rst`).
These are just two different markup languages and can do the same things (by using `myst_parser` plug-in for markdown).
reStructuredText is technically more powerful out of the box, so if you want to learn cool things, try using it instead of markdown.

### Theme

The docs use the [furo](https://pradyunsg.me/furo/) theme.
For suggestions on cool features to use in the docs, check out furo's website.

## Automatic Build

The main docs are located in the `main` branch.
On push to `main`, the **Sphinx Build** GitHub Action is triggered which builds the docs and publishes them to the `gh-pages` branch.
The `gh-pages` branch serves the public website, docs.amdc.dev.

**Warning:** The build process is automatic and fast (< 60 seconds).
Make sure the changes being merged into `main` are ready to be published!
You will not have time to undo the merge before the changes are visible to all on the interwebs!

## Local Development

If you are making substantial changes, you should probably be editing and building the docs locally on your PC.
This will require you to have Python installed.

1. Install the required packages:

```
pip install -r requirements.txt
```

2. Build HTML files using Sphinx

```
make clean
make html
```

3. Browse local docs in your browser by opening: `build/html/index.html`

See [this discussion thread](https://github.com/Severson-Group/docs.amdc.dev/discussions/56) for more information on local development.
