SHELL=/bin/sh

TARGET  ?=test
CID     ?=0

SRC     =\
        main.c\
        arg_parser.c\
        trx_axi_api.c\
        mem_api.c\
        test_bench.c

all: pre $(TARGET)

run: $(TARGET)
	./$(TARGET) -c $(CID) -m 0:0x2000 -l 1 -v 3
#	./$(TARGET) -c $(CID) -m 0:0x2000 -l 7 -v 3

include ./Makefile.in
