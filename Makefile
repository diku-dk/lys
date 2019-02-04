all: lys

OS=$(shell uname -s)
ifeq ($(OS),Darwin)
LDFLAGS?=-framework OpenCL -lm -lsdl2
else
LDFLAGS?=-lOpenCL -lm -lsdl2
endif

lys: lys.c test.o lib/github.com/diku-dk/lys/lys.h
	gcc lys.c -o lys test.c $(LDFLAGS)

%.c: %.fut
	futhark opencl --library $<

run: lys
	./lys

clean:
	rm -f lys test.c test.h *.o
