#################################################################
#
# Internal build control for SILAM. Use the project-root Makefile.
#
# author: J. Vira / FMI
#
#################################################################

# The executable

-include Makefile.branch
PROGRAM ?= $(BRANCH)

PYTHON ?= python3


# The setup variable: if defined, compiler options will be read from
# options.$(SETUP), and the executable will be named as $(PROGRAM).$(SETUP)
SETUP = 

SILAM_ROOT = ../
SHELL  := env TMPDIR=$(TMPDIR) $(SHELL)
TMPDIR ?= $(SILAM_ROOT)
# directory with makefiles
BUILDDIR = $(SILAM_ROOT)build/

ENDING = $(if $(SETUP),.$(SETUP))$(if $(SUFFIX), .$(SUFFIX))
OPTIONS = $(BUILDDIR)/options/$(ENDING)
include $(BUILDDIR)/$(join options, $(ENDING))
PROGRAM := $(PROGRAM)$(ENDING)

# source code.
SRCDIR = $(SILAM_ROOT)src/
# Wind initialization uses this reference self-test during normal model runs.
SOURCES = $(shell find $(SRCDIR) -type f -name '*.f90' | LC_ALL=C sort) \
          $(SILAM_ROOT)tests/numerics/test_fishpack_silam_impl.f90
# object and .mod files
OBJDIR = $(TMPDIR)/obj/$(SETUP)/
# directory for the executable
BINDIR = $(SILAM_ROOT)bin/

# directory for a distribution package
DISTRDIR=$(SILAM_ROOT)/distr

# Build rules: if this is set to simple, every module is assumed to depend
# on its own source only. Caveat emptor.
RULES = full

# The location of main program for the model
MODEL_MAIN = silam_main

# build targets
all : silam

export

# Only the actual fortran compilation shall be parallel - otherwise
# we'd be finding the dependencies simultaneously with compilation, etc.
.NOTPARALLEL : 

silam : expand last.revision config 
	mkdir -p $(OBJDIR) $(BINDIR)	
	$(MAKE) -f$(BUILDDIR)/makefile.model

silam_only : 
	mkdir -p $(OBJDIR) $(BINDIR)	
	$(MAKE) -f$(BUILDDIR)/makefile.model



clean:
	rm -f $(OBJDIR)*.o $(OBJDIR)*.mod $(OBJDIR)*.smod $(BINDIR)$(PROGRAM)

config:
	mkdir -p $(OBJDIR) $(BINDIR)	
	printf '%s\n' $(SOURCES) > $(OBJDIR)/sourcelist
	perl $(BUILDDIR)/config.pl $(OBJDIR)/sourcelist $(MODEL_MAIN) $(ARCH)
	rm $(OBJDIR)/sourcelist
	@echo Config OK.



tags: $(SOURCES)
	$(MAKE) -C $(SILAM_ROOT) tags

lib : expand config
	$(MAKE) -f $(BUILDDIR)/makefile.lib

dot : expand config
#	dot -Gratio=1.4 -Granksep=0.4 -Gnodesep=0.3 -Nfontsize=18 -Tsvg silam.dot > $(PROGRAM).svg
	dot -Granksep=0.4 -Gnodesep=0.3 -Nfontsize=18 -Tsvg $(MODEL_MAIN).dot > $(PROGRAM).svg
	@rsvg-convert -f pdf -o $(PROGRAM).pdf $(PROGRAM).svg || echo 'Sorry, failed to make pdf out of svg!'

# If no f90 file has changed since last running check_revision, no need to do anything.
# If something has been changed, check_revision will run and generate svndiff.mod.f90. 
# revision.mod.f90 is only generated if revision is changed.
last.revision : $(filter-out %svndiff.mod.f90, $(SOURCES))
# if the filter-out is removed, svndiff will be always regenerated because it's newer than last.revision

	$(PYTHON) $(BUILDDIR)/check_revision $(SRCDIR)


compact :
	rm -rf $(SILAM_ROOT)/obj/*
	cd $(SILAM_ROOT) && zip -r source.zip src tests && rm -rf src tests

expand :
	cd $(SILAM_ROOT) && { if [ -e source.zip ]; then unzip source.zip && rm source.zip; fi }

up : expand
	cd $(SRCDIR) && svn up

# Create a source package from the current sources and runtime resources.
# Preserve revision modules; the package has no version-control metadata.

DISTRO = $(DISTRDIR)/$(PROGRAM)
distr : config
	rm -rf  $(DISTRO)
	mkdir -p $(DISTRO)/src $(DISTRO)/tests $(DISTRO)/bin $(DISTRO)/build $(DISTRO)/obj $(DISTRO)/ini
	cp -vp makefile makefile.* config.pl library.objects Makefile.branch $(wildcard DefaultSetup) options.*[!~] $(DISTRO)/build
	touch $(DISTRO)/build/check_revision
	cd $(SILAM_ROOT) && find src tests -type f -name '*.f90' -exec cp --parents -vp -t $(abspath $(DISTRO)) {} +
	cp -vrp ../ini/*  $(DISTRO)/ini
	cp -vrp ../docs $(DISTRO)
	cp ../Makefile ../README.md ../LICENSE ../AGENTS.md ../.gitignore $(DISTRO)
	cd $(DISTRDIR) && tar cvjf $(PROGRAM).tar.bz2 $(PROGRAM)
