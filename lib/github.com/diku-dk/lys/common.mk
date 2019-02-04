PROGNAME?=lys

all: $(PROGNAME)

OS=$(shell uname -s)
ifeq ($(OS),Darwin)
LDFLAGS?=-framework OpenCL -lm -lsdl2
else
LDFLAGS?=-lOpenCL -lm -lsdl2
endif

$(PROGNAME): $(PROGNAME).o lib/github.com/diku-dk/lys/liblys.c lib/github.com/diku-dk/lys/liblys.h
	gcc lib/github.com/diku-dk/lys/liblys.c -I. -DPROGHEADER='"$(PROGNAME).h"' $(PROGNAME).o -o lys $(LDFLAGS)

%.c: %.fut
	futhark opencl --library $<

run: lys
	./lys

clean:
	rm -f $(PROGNAME) $(PROGNAME).c $(PROGNAME).h *.o
