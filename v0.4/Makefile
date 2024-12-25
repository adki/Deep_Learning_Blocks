DIRS	= $(subst /,, $(dir $(wildcard */Makefile)))

all:

clean cleanup clobber cleanupall:
	/bin/rm -rf lib include
	for D in $(DIRS); do\
		if [ -f $$D/Makefile ] ; then \
			echo "make -C $$D -s $@";\
			make -C $$D -s $@;\
		fi;\
	done

.PHONY: all clean cleanup clobber cleanupall
