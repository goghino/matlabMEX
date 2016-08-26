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
MATLAB_HOME = /Applications/MATLAB_R2014b.app

# Set the suffix for matlab mex files. The contents of the
# $(MATLAB_HOME)/extern/examples/mex directory might be able to help
# you in your choice.
MEXSUFFIX   = mexmaci64

# This is the command used to call the mex program. Usually, it is
# just "mex". But it also may be something like
# /user/local/R2006b/bin/mex if "mex" doesn't work.
MEX = $(MATLAB_HOME)/bin/mex
#MEX = "$(MATLAB_HOME)/sys/perl/win32/bin/perl" "`$(CYGPATH_W) "$(MATLAB_HOME)/bin/mex.pl"`"

#############################################################################
# Do not modify anything below unless you know what you're doing.
exec_prefix = ${prefix}
prefix      = /users/drosos/Ipopt-3.12.4/build
libdir      = ${exec_prefix}/lib

CXX         = mpicxx
CXXFLAGS    = -g -fPIC -fopenmp -m64   -DIPOPT_BUILD -DMATLAB_MEXFILE # -DMWINDEXISINT
LDFLAGS     = $(CXXFLAGS)   #-static-libgcc -static-libstdc++

# Include directories (we use the CYGPATH_W variables to allow compilation with Windows compilers)
#INCL = `PKG_CONFIG_PATH=/users/drosos/Ipopt-3.12.4/build/lib64/pkgconfig:/users/drosos/Ipopt-3.12.4/build/lib/pkgconfig:/users/drosos/Ipopt-3.12.4/build/share/pkgconfig:/usr/lib64/pkgconfig pkg-config --cflags ipopt`
#INCL = -I`$(CYGPATH_W) /users/drosos/Ipopt-3.12.4/build/include/coin` 

# Linker flags
#LIBS = `PKG_CONFIG_PATH=/users/drosos/Ipopt-3.12.4/build/lib64/pkgconfig:/users/drosos/Ipopt-3.12.4/build/lib/pkgconfig:/users/drosos/Ipopt-3.12.4/build/share/pkgconfig:/usr/lib64/pkgconfig pkg-config --libs ipopt | sed -e 's/-framework vecLib//g'`
##LIBS = -link -libpath:`$(CYGPATH_W) /users/drosos/Ipopt-3.12.4/build/lib` libipopt.lib -L/users/drosos/Libraries/linuxAMD64 -lpardiso500-GNU481-X86-64 -lgfortran -lm  -ldl
#LIBS = -L/users/drosos/Ipopt-3.12.4/build/lib -lipopt `echo -L/users/drosos/Libraries/linuxAMD64 -lpardiso500-GNU481-X86-64 -lgfortran -lm  -ldl | sed -e 's/-framework vecLib//g'`
LIBS_STATIC = $(LIBS)
#LIBS_STATIC = $$(echo " $(LIBS) " | sed -e "s| -lgfortran | `gfortran -print-file-name=libgfortran.a` |g" -e "s| -lquadmath | `gfortran -print-file-name=libquadmath.a` |g")
##LIBS_STATIC = $$(echo " $(LIBS) " | sed -e 's| -Wl,-Bdynamic,-lmwma57,-Bstatic | -lmwma57 |g')
# mex doesn't understand -Wl,-Bdynamic,-lmwma57,-Bstatic on Windows

# The following is necessary under cygwin, if native compilers are used
CYGPATH_W = echo

#MEXFLAGCXX = 
MEXFLAGCXX = -cxx
MEXFLAGS    = -v $(MEXFLAGCXX) -O CC="$(CXX)" CXX="$(CXX)" LD="$(CXX)"       \
              COPTIMFLAGS="$(CXXFLAGS)" CXXOPTIMFLAGS="$(CXXFLAGS)" \
              LDOPTIMFLAGS="$(LDFLAGS)" 

TARGET = demo.$(MEXSUFFIX)
OBJS   = demo.o

SRCDIR = /Users/Juraj/Documents/MATLAB/mex
VPATH = $(SRCDIR)

all: $(TARGET)

install: $(TARGET)
	if test -d $(libdir); then : ; else mkdir $(libdir); fi
	cp $(SRCDIR)/../ipopt.m $(SRCDIR)/../ipopt_auxdata.m $(TARGET) $(libdir)

uninstall:
	rm -f $(libdir)/ipopt.m $(libdir)/ipopt_auxdata.m $(libdir)/ipopt.$(MEXSUFFIX)

$(TARGET): $(OBJS)
	make mexopts
	$(MEX) $(MEXFLAGS) $(LIBS_STATIC) -output $@ $^

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCL) -I"$(MATLAB_HOME)/extern/include" \
        -o $@ -c $^

clean:
	rm -f $(OBJS) *.lo $(TARGET)

distclean: clean

GM_ADD_LIBS_STATIC = 
#GM_ADD_LIBS_STATIC = GM_ADD_LIBS="-static $$GM_ADD_LIBS";

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
