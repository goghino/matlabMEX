# Copyright (C) 2007, 2009 Peter Carbonetto. All Rights Reserved.
# This code is published under the Eclipse Public License.
#
# Author: Peter Carbonetto
#         Dept. of Computer Science
#         University of British Columbia
#         May 19, 2007

# INSTRUCTIONS: Please modify the following few variables. See the
# Ipopt documentation (Ipopt/doc/documentation.pdf) for more details.

# This variable corresponds to the base directory of your MATLAB
# installation. This is the directory so that in its 'bin/'
# subdirectory you see all the matlab executables (such as 'matlab',
# 'mex', etc.)

HOST=$(shell hostname)
ifeq ($(HOST),archimedes)
mpi_base = /home/kardos/openmpi
MATLAB_HOME = /opt/MATLAB/R2014b
else ifeq ($(HOST),pilatus01)
mpi_base = $(OPENMPI_DIR)
MATLAB_HOME = /apps/pilatus/matlab/r2016a
LIB_SLURM = -L/apps/pilatus/slurm/default/lib/ -lslurm
#PRELOAD = LD_PRELOAD="/usr/lib64/libslurm.so"
PRELOAD = LD_PRELOAD="/apps/pilatus/slurm/default/lib/libslurm.so /usr/lib64/libstdc++.so.6"
else
mpi_base = $(OPENMPI_DIR)
MATLAB_HOME = /apps/matlab/R2016a
LIB_SLURM = -lslurm
PRELOAD = LD_PRELOAD="/usr/lib64/libslurm.so"
#PRELOAD = LD_PRELOAD="/usr/lib64/libslurm.so /apps/gcc/gcc-6.1.0/lib64/libstdc++.so.6"
#also modify matlab's .rc script $vim ~/.matlab7rc.sh and
#set up LDPATH_PREFIX='/apps/gcc/gcc-6.1.0/lib64/'
HOSTFILES= -hostfile my_hosts
endif

# Set the suffix for matlab mex files. The contents of the
# $(MATLAB_HOME)/extern/examples/mex directory might be able to help
# you in your choice.
MEXSUFFIX   = mexmaci64

# This is the command used to call the mex program. Usually, it is
# just "mex". But it also may be something like
# /user/local/R2006b/bin/mex if "mex" doesn't work.
MEX = $(MATLAB_HOME)/bin/mex

#############################################################################
# Do not modify anything below unless you know what you're doing.
prefix      = $(CURDIR) #??? 
exec_prefix = ${prefix} #???
libdir      = ${exec_prefix}/lib #???  

mpi_library = $(mpi_base)/lib


CXX         = g++
CXXFLAGS    = -O2 -fPIC -fopenmp -m64 -DIPOPT_BUILD -DMATLAB_MEXFILE # -DMWINDEXISINT
CXXFLAGS   += -I$(mpi_base)/include -pthread
LFLAGS      = -L$(mpi_library)

CYGPATH_W = echo

MEXFLAGCXX = -cxx
MEXFLAGS    = -v $(MEXFLAGCXX) -O CC="$(CXX)" CXX="$(CXX)" LD="$(CXX)"       \
              COPTIMFLAGS="$(CXXFLAGS)" CXXOPTIMFLAGS="$(CXXFLAGS)" \
              LDOPTIMFLAGS="$(LFLAGS)" 

TARGET = demo.$(MEXSUFFIX)
OBJS   = demo.o

SRCDIR = ${prefix} 
VPATH = $(SRCDIR)

all: $(TARGET) worker

$(TARGET): $(OBJS)
	make mexopts
	$(MEX) -L${mpi_library} -g $(MEXFLAGS) -output $@ $^ -lmpi $(LIB_SLURM)

worker: worker.cpp
	$(CXX) $(CXXFLAGS) $(LFLAGS) -O3 -Wall -W  -I. -o worker worker.cpp -lmpi


%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCL) -I"$(MATLAB_HOME)/extern/include" \
        -o $@ -c $^

clean:
	rm -f $(OBJS) *.lo $(TARGET) worker
	
print_pwd:
	echo $(CURDIR)
	echo $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

hostname:
	echo $(shell hostname)

run:
	LD_LIBRARY_PATH=$$LD_LIBRARY_PATH:$(mpi_library) \
	$(PRELOAD) \
	mpirun ${HOSTFILES} -np 1 matlab -nojvm -nodisplay -nosplash -r "matlabDemo; exit"

distclean: clean

# make mexopts applies a set of fixes to mexopts.sh on Mac,
# or mexopts.bat on Windows (if that file was generated
# by Gnumex to use gcc via Cygwin or MinGW)
mexopts:
	case `uname` in \
	  Darwin*) \
	    if ! test -e mexopts.sh; then \
	      sed -e 's/-arch $$ARCHS//g' \
	        $(MATLAB_HOME)/bin/mexopts.sh > mexopts.sh; \
	      SDKROOT=`grep -m1 'SDKROOT=' mexopts.sh | sed -e 's/SDKROOT=//g'`; \
	      if ! test -d $$SDKROOT; then \
	        sed -e 's/-arch $$ARCHS//g' \
	          -e 's/-isysroot $$SDKROOT//g' \
	          -e 's/-Wl,-syslibroot,$$SDKROOT//g' \
	          $(MATLAB_HOME)/bin/mexopts.sh > mexopts.sh; \
	      fi; \
	    fi \
	    ;; \
	  MINGW*) \
	    if ! test -e mexopts.bat; then \
	      echo Warning: no mexopts.bat found. You will probably need to run Gnumex to generate this file. Call \"make gnumex\" then try again.; \
	    else \
	      libdirwin=$$(cd $(libdir); cmd /c 'for %i in (.) do @echo %~fi' | sed 's|\\|/|g'); \
	      mingwlibdirwin=$$(cd /mingw/lib; cmd /c 'for %i in (.) do @echo %~fi' | sed 's|\\|/|g'); \
	      GM_ADD_LIBS=$$(echo "-llibmx -llibmex -llibmat $(LIBS) " | \
	        sed -e "s| -L$(libdir) | -L$$libdirwin |g" \
	        -e "s| -L/mingw/lib | -L$$mingwlibdirwin |g"); \
	      $(GM_ADD_LIBS_STATIC) \
	      cp mexopts.bat mexopts.bat.orig; \
	      sed -e 's|COMPILER=gcc|COMPILER=g++|' -e 's|GM_MEXLANG=c$$|GM_MEXLANG=cxx|' \
	        -e "s|GM_ADD_LIBS=-llibmx -llibmex -llibmat$$|GM_ADD_LIBS=$$GM_ADD_LIBS|" \
	        mexopts.bat.orig > mexopts.bat; \
	    fi \
	    ;; \
	  CYGWIN*) \
	    if ! test -e mexopts.bat; then \
	      echo Warning: no mexopts.bat found. You will probably need to run Gnumex to generate this file. Call \"make gnumex\" then try again.; \
	    else \
	      libdirwin=`cygpath -m $(libdir)`; \
	      cyglibdirwin=`cygpath -m /usr/lib`; \
	      GM_ADD_LIBS=$$(echo "-llibmx -llibmex -llibmat $(LIBS) " | \
	        sed -e "s| -L$(libdir) | -L$$libdirwin |g" \
	        -e "s| -L/usr/lib/| -L$$cyglibdirwin/|g"); \
	      $(GM_ADD_LIBS_STATIC) \
	      cp mexopts.bat mexopts.bat.orig; \
	      sed -e 's|COMPILER=gcc|COMPILER=g++|' -e 's|GM_MEXLANG=c$$|GM_MEXLANG=cxx|' \
	        -e "s|GM_ADD_LIBS=-llibmx -llibmex -llibmat$$|GM_ADD_LIBS=$$GM_ADD_LIBS|" \
	        mexopts.bat.orig > mexopts.bat; \
	    fi \
	    ;; \
	esac

# make gnumex opens a Matlab session and calls the Gnumex tool to
# generate mexopts.bat set up for using gcc via Cygwin or MinGW
gnumex:
	if ! test -d "$(SRCDIR)/../gnumex"; then \
	  echo "Warning: no gnumex folder found. Run \"cd `dirname $(SRCDIR)`; ./get.Gnumex\" first."; \
	else \
	  GM_COMMANDS="oldpwd=pwd; cd $(SRCDIR)/../gnumex; gnumex('startup'); \
	    gnumexopts=gnumex('defaults'); gnumexopts.precompath=[pwd '\libdef']; \
	    gnumexopts.optfile=[oldpwd '\mexopts.bat'];"; \
	  case `uname` in \
	    MINGW*) \
	      echo Use gnumex in Matlab to create mexopts.bat file, then close this new instance of Matlab.; \
	      "$(MATLAB_HOME)/bin/matlab" -wait -r "$$GM_COMMANDS \
	        gnumexopts.mingwpath=fileparts(gnumexopts.gfortpath); gnumex('struct2fig',gnumexopts)" \
	      ;; \
	    CYGWIN*) \
	      echo Use gnumex in Matlab to create mexopts.bat file, then close this new instance of Matlab.; \
	      "$(MATLAB_HOME)/bin/matlab" -wait -r "$$GM_COMMANDS gnumexopts.environ=3; gnumex('struct2fig',gnumexopts)" \
	      ;; \
	  esac \
	fi
