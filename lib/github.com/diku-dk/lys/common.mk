PROGNAME?=lys

all: $(PROGNAME)

OS=$(shell uname -s)
ifeq ($(OS),Darwin)
LDFLAGS?=-framework OpenCL -lm -lSDL2
else
LDFLAGS?=-lOpenCL -lm -lSDL2
endif

$(PROGNAME): $(PROGNAME).o lib/github.com/diku-dk/lys/liblys.c
	gcc lib/github.com/diku-dk/lys/liblys.c -I. -DPROGHEADER='"$(PROGNAME).h"' $(PROGNAME).o -o lys $(LDFLAGS)

lib: futhark.pkg
	futhark pkg sync

%.c: %.fut lib
	futhark opencl --library $<

run: lys
	./lys

clean:
	rm -f $(PROGNAME) $(PROGNAME).c $(PROGNAME).h *.o
