# Silam public distribution 

This is a full-featured source code of the Silam model
with striped revision history

## BUILDING SILAM v5.9 in Ubuntu 18.04, 20.04, 22.04

Get the source code

```bash
git clone https://github.com/fmidev/silam-model.git
```

Install needed packages

```bash
sudo apt install make python gfortran libeccodes-dev libnetcdf-dev libnetcdff-dev liblapack-dev libblas-dev libbz2-dev libproj-dev
```

Compile the binary

```bash
cd silam-model/source/
make gnu
make
```

The latter command should create a binary in ../bin

```
../bin/silam_v5_7pub.gnu
```

Silam should run and complain about missing silam.ini.
Then the binary is ready to use! You can test it with a test case from
https://github.com/fmidev/silam-toypoint

In Ubuntu 20.04 one might get an error message like

```
grib_api.mod not found
```

There are several versions of gfortran available in 20.04. Some libraries
have headers in a location specific for "module version", where gfortran can't find them:

```
/usr/lib/x86_64-linux-gnu/fortran/gfortran-mod-15/
```

others have them in gfortran-version-specific locarion

```
/usr/lib/gcc/x86_64-linux-gnu/10/finclude/
```

or 

```
/usr/lib/gcc/x86_64-linux-gnu/19/finclude/
```

A workaround would be to either explicitly call fortran with `-I
/usr/lib/x86_64-linux-gnu/fortran/gfortran-mod-15` (by adding this option to
FFLAGS in build/options.gnu).

or add symlinks to the needed .mod files to your gfortran include
directory (as root).

```bash
ln -s /usr/lib/x86_64-linux-gnu/fortran/gfortran-mod-15/grib_api.mod /usr/lib/gcc/x86_64-linux-gnu/10/finclude/
```

or

```bash
ln -s /usr/lib/x86_64-linux-gnu/fortran/gfortran-mod-15/grib_api.mod /usr/lib/gcc/x86_64-linux-gnu/9/finclude/
```

or wherever your fortran can find them...
The issue has been reported at
https://bugs.launchpad.net/ubuntu/+source/gcc-defaults/+bug/1883855 .
Please consider confirming the bug if it affects you.
