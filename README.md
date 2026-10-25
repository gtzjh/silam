# Silam public distribution 

This checkout is maintained for atmospheric pollen simulations. It keeps the
SILAM main model, shared transport and deposition code, and the existing
generated chemistry solvers.

KPP code generation, the chemistry box model, fire preprocessing, standalone
format converters, lagged-input tools, and old platform configurations have
been removed. GNU release, debug, and MPI configurations remain available.
The bundled photolysis lookup table and dedicated non-pollen examples are
omitted; CBM chemistry runs require an external compatible lookup table.
Pollen templates still require suitable meteorological, vegetation, and
phenological inputs for the selected case.

## Development

[AGENTS.md](AGENTS.md) defines agent execution and Git approval rules.
The [development guide](doc/dev/README.md) covers project structure, coding,
builds, and verification.

Production sources are grouped by function under `src/`. Test implementations
and the three standalone test programs use matching folders under `tests/`.
The [test guide](tests/README.md) describes their layout and build entry points.

The [runtime resource guide](ini/README.md) indexes shared databases, format
tables and historical configuration templates. Shared resources stay at the
root of `ini/`; example controls and their templates are grouped by purpose
under `ini/examples/` and may require external inputs or compatibility updates.

## BUILDING SILAM v6_1 in Ubuntu  20.04, 22.04, 24.04

Get the source code

`$ git clone https://github.com/fmidev/silam-model.git`

Install needed packages

`$ sudo apt install make python3 gfortran libeccodes-dev libnetcdf-dev libnetcdff-dev liblapack-dev libblas-dev libbz2-dev libproj-dev`

Compile the binary

`$ cd silam-model/`

`$ make -C src gnu`

`$ make -C src`

The latter command might require a second try. Finally, it should create a binary in bin/,
that can be launched as:

`$ ./bin/silam_v6_1pub.gnu`

Silam should run and complain about missing silam.ini.
Then the binary is ready to use! You can test it with a test case from
https://github.com/fmidev/silam-toypoint



## Troubleshooting

In Ubuntu one might get an error message like

`grib_api.mod not found`

There are several versions of gfortran available in 20.04. Some libraries
have headers in a location specific for "module version", where gfortran can't find them:

`/usr/lib/x86_64-linux-gnu/fortran/gfortran-mod-15/`

Others have them in gfortran-version-specific location

`/usr/lib/gcc/x86_64-linux-gnu/10/finclude/`

or 

`/usr/lib/gcc/x86_64-linux-gnu/19/finclude/`

A workaround would be to either explicitly call FORTRAN with `-I
/usr/lib/x86_64-linux-gnu/fortran/gfortran-mod-15` (by adding this option to
FFLAGS  in build/options.gnu).

or add symlinks to the needed .mod files to your gfortran include
directory (as root).

`# ln -s /usr/lib/x86_64-linux-gnu/fortran/gfortran-mod-15/grib_api.mod /usr/lib/gcc/x86_64-linux-gnu/10/finclude/`

or

`# ln -s /usr/lib/x86_64-linux-gnu/fortran/gfortran-mod-15/grib_api.mod /usr/lib/gcc/x86_64-linux-gnu/9/finclude/`

The exact command depends on your gcc version, which can be checked with 
`$ gfortran -v`

The issue has been reported at
https://bugs.launchpad.net/ubuntu/+source/gcc-defaults/+bug/1883855.
Please consider confirming the bug if it affects you.



  
