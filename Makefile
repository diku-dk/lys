include lib/github.com/diku-dk/lys/common.mk

lib: futhark.pkg
	futhark pkg sync
