# lys - 2D graphics and interaction for Futhark

Lys is a library and wrapper for pain-free graphics programming with
[Futhark](https://futhark-lang.org).  It works by using `Makefile`
rules to automatically generate a wrapper program in C that uses
[SDL2](https://www.libsdl.org/) to display graphics and handle user
events, whose behaviour is controlled by calling a Futhark program
with specially defined entry points.

## Usage

Download the package like any other Futhark package:

```
$ futhark pkg add github.com/diku-dk/lys
$ futhark pkg sync
```

Then create a `Makefile` with the following contents:

```make
include lib/github.com/diku-dk/lys/common.mk
```

Finally create a Futhark program `lys.fut` that defines at least a
module named `lys` of module type `lys` ([example](lys.fut)).  Run
`make` and a binary called `lys` will be compiled.

## Requirements

Lys is written in C, and requires a working C compiler and the SDL2
library with associated header files.  On Debian-like systems
(including Ubuntu), this can be installed with

```
# sudo apt install libsdl2-dev
```
