#!/bin/bash
# Bamboo Build script
# Stage 0 : load modules

# Set up environment for compilation
. /usr/share/Modules/init/sh
module use /work/imas/etc/modulefiles
module use /work/imas/etc/modules/all
module purge

# FOSS environment based upon GCC v6.4.0

module load CMake/3.12.1-GCCcore-6.4.0

module load PostgreSQL/10.3-foss-2018a-Python-2.7.14
module load Boost/1.66.0-foss-2018a
module load Blitz++/0.10-GCCcore-6.4.0
module load netCDF/4.6.0-foss-2018a
module load HDF5/1.10.1-foss-2018a
module load MDSplus-Java/7.49.1-GCCcore-6.4.0-Java-1.8.0_162

module use "$HOME"/uda/modulefiles
module load uda/2.2.6
