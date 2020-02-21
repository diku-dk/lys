LYS_BACKEND?=opencl
LYS_TTF?=0


PROG_FUT_DEPS:=$(shell ls *.fut; find lib -name \*.fut)

PKG_CFLAGS_PKGS=sdl2
ifeq ($(LYS_TTF),1)
PKG_CFLAGS_PKGS+= SDL2_ttf
endif

PKG_CFLAGS=$(shell pkg-config --cflags $(PKG_CFLAGS_PKGS))

BASE_LDFLAGS=-lm -lSDL2
ifeq ($(LYS_TTF),1)
BASE_LDFLAGS+= -lSDL2_ttf
endif

NOWARN_CFLAGS=-std=c11 -O

CFLAGS?=$(NOWARN_CFLAGS) $(PKG_CFLAGS) -Wall -Wextra -pedantic -DLYS_BACKEND_$(LYS_BACKEND)
ifeq ($(LYS_TTF),1)
CFLAGS+= -DLYS_TTF
endif

OS=$(shell uname -s)
ifeq ($(OS),Darwin)
OPENCL_LDFLAGS?=-framework OpenCL
else
OPENCL_LDFLAGS?=-lOpenCL
endif

ifeq ($(LYS_BACKEND),opencl)
LDFLAGS?=$(OPENCL_LDFLAGS) $(BASE_LDFLAGS)
else ifeq ($(LYS_BACKEND),cuda)
LDFLAGS?=$(BASE_LDFLAGS) -lcuda -lnvrtc
else ifeq ($(LYS_BACKEND),c)
LDFLAGS?=$(BASE_LDFLAGS)
else
$(error Unknown LYS_BACKEND: $(LYS_BACKEND).  Must be 'opencl', 'cuda', or 'c')
endif
