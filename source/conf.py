# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
# import os
# import sys
# sys.path.insert(0, os.path.abspath('.'))
import datetime


# -- Project information -----------------------------------------------------

project = 'AMDC Platform'
copyright = '2018-' + str(datetime.date.today().year) + ', Electric Machinery and Levitation Laboratory'
author = 'Electric Machinery and Levitation Laboratory'


# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'myst_parser',
    'sphinx_design',
    'sphinx_last_updated_by_git',
    'sphinx_copybutton',
    'sphinx_sitemap',
    'matplotlib.sphinxext.plot_directive'
]

myst_enable_extensions = [
    'dollarmath',
    'amsmath',
]

# https://myst-parser.readthedocs.io/en/latest/syntax/optional.html#auto-generated-header-anchors
myst_heading_anchors = 3

git_last_updated_timezone = 'US/Central'

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = []

# -- Options for HTML output -------------------------------------------------

html_theme = 'furo'

html_title = "AMDC Platform"

html_favicon = '_static/favicon.png'

html_show_sphinx = True

html_theme_options = {
    'navigation_with_keys': True,
    "source_repository": "https://github.com/Severson-Group/docs.amdc.dev/",
    "source_branch": "main",
    "source_directory": "source/",    
}

html_baseurl = 'https://docs.amdc.dev/'
sitemap_filename = 'sitemap.xml'

html_extra_path = ['robots.txt']

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']

# These paths are either relative to html_static_path
# or fully qualified paths (eg. https://...)
html_css_files = [
    'css/custom.css',
]


# Matplotlib options
plot_html_show_source_link = False
plot_html_show_formats = False
plot_formats = ['svg']
plot_rcparams = {'font.size' : 12}