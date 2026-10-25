# Daily build entry. Internal rules and compiler options stay in build/.
.DEFAULT_GOAL := all

SE = gnu
DefaultSetup = build/DefaultSetup
SOURCES = $(shell find src -type f -name '*.f90' | LC_ALL=C sort)

PROGRAM ?= silam
include $(DefaultSetup)

.PHONY: all full gnu gnu_debug gnumpi gnumpi_debug conf clean distr dot up tags ctags what

all:
	@echo Using RULES=simple SETUP=$(SE)
	$(MAKE) -C build RULES=simple SETUP=$(SE)
	rm -f bin/$(PROGRAM)
	ln -s $(PROGRAM).$(SE) bin/$(PROGRAM)

full:
	@echo Using -j 8 SETUP=$(SE)
	$(MAKE) -C build -j 8 SETUP=$(SE)
	rm -f bin/$(PROGRAM)
	ln -s $(PROGRAM).$(SE) bin/$(PROGRAM)

gnu gnu_debug gnumpi gnumpi_debug:
	printf 'SE=%s\n' $@ > $(DefaultSetup)
	@echo Switching make to SE=$@

$(DefaultSetup):
	printf 'SE=%s\n' $(SE) > $(DefaultSetup)
	@echo Switching make to SE=$(SE)

conf:
	$(MAKE) -C build config SETUP=$(SE)

clean distr dot up:
	$(MAKE) -C build $@ SETUP=$(SE)

tags: $(SOURCES)
	etags --ignore-case-regex='/ *interface *.*/' --ignore-case-regex='/ *integer,.*public.*/' --ignore-case-regex='/ *real,.*public.*/' \
--ignore-case-regex='/ *type [a-z_]*/' $(SOURCES)

ctags: $(SOURCES)
	ctags -R --fortran-kinds=+i src

what:
	cat $(DefaultSetup)
