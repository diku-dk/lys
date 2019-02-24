# 2D graphics and interaction for Futhark [![Build Status](https://travis-ci.org/diku-dk/lys.svg?branch=master)](https://travis-ci.org/diku-dk/lys)

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

If you don't want your binary to be called `lys`, set the `Makefile`
variable `PROGNAME` to whatever you wish.  For example, if you use

```make
PROGNAME=spetakel
include lib/github.com/diku-dk/lys/common.mk
```

then Lys will look for a Futhark program `spetakel.fut` and generate a
binary named `spetakel`.  The file `spetakel.fut` should still define
a module called `lys`, however.

## Requirements

Lys is written in C, and requires a working C compiler and the SDL2
and SDL2-ttf libraries with associated header files.  On Debian-like
systems (including Ubuntu), this can be installed with

```
# apt install libsdl2-dev libsdl2-ttf-dev
```

On RHEL/Fedora:

```
# yum install SDL2-devel SDL2_ttf-devel
```

On macOS with [Homebrew](https://brew.sh), run

```
$ brew install sdl2 sdl2_gfx sdl2_image sdl2_ttf
```

## Common keybindings

These keybindings are common for all lys programs and cannot be
overridden:

  + ESC: Exit the program.
  + F1: Toggle showing text.

## Common command-line options

Run `./lys --help` to see the available options.

## Using the CUDA backend

By default, the build rules defined in
`lib/github.com/diku-dk/lys/common.mk` use Futhark's OpenCL backend.
You can change it to use Futhark's CUDA backend by setting
`LYS_BACKEND=cuda`, either in the Makefile or as an environment
variable.
