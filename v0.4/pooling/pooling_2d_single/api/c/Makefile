SHELL=/bin/bash

DIR_OBJ   := ./obj
DUMMY     := $(shell [ -d $(DIR_OBJ) ] || mkdir $(DIR_OBJ) )

LIB       := dlb

DIR_SRC   := .
C_SRCS    := pooling_2d_one_core.c
CPP_SRCS  := $(DIR_SRC)/pooling_2d_one.cpp
C_HDRS    := $(DIR_SRC)/pooling_2d_one_core.h\
             $(DIR_SRC)/pooling_2d_one.h
CPP_HDRS  := $(DIR_SRC)/pooling_2d_one.hpp
OBJS      := $(addprefix $(DIR_OBJ)/,$(patsubst %.c,%.o,$(notdir $(C_SRCS))))
OBJS      += $(addprefix $(DIR_OBJ)/,$(patsubst %.cpp,%.o,$(notdir $(CPP_SRCS))))

DEFINES   := -DCOSIM_BFM
CFLAGS    := -O3 -x c -c -fPIC -I$(DIR_SRC) -I$(COSIM_HOME)/include $(DEFINES)
CPPFLAGS  := -O3 -c -fPIC -I$(DIR_SRC) $(DEFINES)

vpath %.h    $(DIR_SRC)
vpath %.c    $(DIR_SRC)
vpath %.hpp  $(DIR_SRC)
vpath %.cpp  $(DIR_SRC)

$(DIR_OBJ)/%.o: %.c %.h
	g++ $(CFLAGS) -o $@ $<

$(DIR_OBJ)/%.o: %.cpp %.hpp
	g++ $(CPPFLAGS) -o $@ $<

all: $(OBJS) lib$(LIB).so lib$(LIB).a

install:

lib$(LIB).so lib$(LIB).a: $(OBJS)
	g++ -shared -Wl,-soname,lib$(LIB) -o lib$(LIB).so $^
	ar rcs lib$(LIB).a $^

.PHONY: all clean cleanup clobber cleanupall disclean

clean:
	/bin/rm   -f  *.o
	/bin/rm   -rf $(DIR_OBJ)
	/bin/rm   -f lib$(LIB).so lib$(LIB).a
	/bin/rm   -f dlr.h dlr.hpp

cleanup clobber: clean

cleanupall distclean: cleanup
