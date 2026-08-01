# Makefile for Sphinx documentation
#

# You can set these variables from the command line, and also
# from the environment for the first two.
SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-multiversion
SOURCEDIR     = source
BUILDDIR      = build
UNAME = "Windows_NT"
ifeq ($(OS),Windows_NT)
UNAME_AVAIL = "false"
else
UNAME_AVAIL = "true"
endif

ifeq ($(UNAME_AVAIL), "true")
UNAME = $(shell uname -s)
endif

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) --help

.PHONY: help Makefile

# Catch-all target: route all unknown targets to Sphinx
# $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
ifeq ($(UNAME_AVAIL), "true")
ifeq ($(UNAME), Darwin)
	#We are on OSX
	mkdir -p tmptmp
	TMPDIR=$(CURDIR)/tmptmp $(SPHINXBUILD) "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(0)
	rm -r tmptmp
	cp ./index.html "$(BUILDDIR)/index.html"
else
	#We are on Linux
	@$(SPHINXBUILD) "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(0)
	cp ./index.html "$(BUILDDIR)/index.html"
endif
else
	#We are on Windows_NT
	@$(SPHINXBUILD) "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(0)
	copy .\index.html "$(BUILDDIR)\index.html"
endif


local:
	sphinx-build "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(0)

# We are no longer using make functionality of sphinx-build
# because sphinx-multiverison does not support it
# therefore we must define make clean ourselves.
clean:
ifeq ($(OS),Windows_NT)
	del /s "$(BUILDDIR)"
else
	rm -rf "$(BUILDDIR)/"* || true
endif
