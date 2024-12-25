DIRS	= $(subst /,, $(dir $(wildcard */Makefile)))

all:

clean cleanup clobber cleanupall distclean:
	for D in $(DIRS); do\
		if [ -f $$D/Makefile ] ; then \
			(cd $$D; make -s $@);\
		fi;\
	done

.PHONY: all clean cleanup clobber cleanupall distclean
