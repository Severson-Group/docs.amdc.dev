# Makefile for Sphinx documentation
#

# You can set these variables from the command line, and also
# from the environment for the first two.
SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-multiversion
SOURCEDIR     = source
BUILDDIR      = build

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) --help

.PHONY: help Makefile

# Catch-all target: route all unknown targets to Sphinx
# $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(0)

local:
	sphinx-build "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(0)

# We are no longer using make functionality of sphinx-build
# because sphinx-multiverison does not support it
# therefore we must define make clean ourselves.
clean:
ifeq ($(OS),Windows_NT)
	del /s "$(BUILDDIR)"
else
	rm -r "$(BUILDDIR)/"*
endif
