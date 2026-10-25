
#Default setup. Overriden by DefaultSetup file
SE=gnu
DefaultSetup=DefaultSetup

# Include if exists
-include ../build/Makefile.branch

PROGRAM=$(BRANCH)

include $(DefaultSetup)



#Fastest make by defult
all:   $(DefaultSetup)
	echo Using RULES=simple SETUP=$(SE)
#	cd ../build && $(MAKE) RULES=simple 
	cd ../build && $(MAKE) RULES=simple SETUP=$(SE)
	rm -f ../bin/$(PROGRAM)
	ln -s $(PROGRAM).$(SE) ../bin/$(PROGRAM)

gnumpi:
	echo "SE=gnumpi" > $(DefaultSetup)
	echo Switching make to `cat $(DefaultSetup)`

gnu_debug:
	echo "SE=gnu_debug" > $(DefaultSetup)
	echo Switching make to `cat $(DefaultSetup)`

gnumpi_debug:
	echo "SE=gnumpi_debug" > $(DefaultSetup)
	echo Switching make to `cat $(DefaultSetup)`

gnu:
	echo "SE=gnu" > $(DefaultSetup)
	echo Switching make to `cat $(DefaultSetup)`

$(DefaultSetup):
	echo "SE=$(SE)" > $(DefaultSetup)	
	echo Switching make to `cat $(DefaultSetup)`


conf:
	cd ../build && make config

full :
	echo Using -j 8 SETUP=$(SE)
#	cd ../build && $(MAKE) -j 8
	cd ../build && $(MAKE) -j 8 SETUP=$(SE)
	rm -f ../bin/$(PROGRAM)
	ln -s $(PROGRAM).$(SE) ../bin/$(PROGRAM)

tags : *.f90
	etags --ignore-case-regex='/ *interface *.*/' --ignore-case-regex='/ *integer,.*public.*/' --ignore-case-regex='/ *real,.*public.*/' \
--ignore-case-regex='/ *type [a-z_]*/' *.f90

ctags : *.f90
	ctags -R --fortran-kinds=+i

up : 
	cd ../build/ && $(MAKE) up

clean:
	cd ../build && $(MAKE) clean  SETUP=$(SE)

what:
	cat DefaultSetup

distr:
	cd ../build/ && $(MAKE) distr SETUP=$(SE)

dot:
	cd ../build/ && $(MAKE) dot  SETUP=$(SE)
