# Loot for SNES

This is a compiler for the Loot language from CMSC 430 targeted for the SNES
(though there are some feature differences).

## Compiling a program

To compile a program, you will need Racket (duh) and the assembler
[asar](https://github.com/RPGHacker/asar).

I have made a Makefile that should let you compile a program. Suppose you have
a racket file called `42.rkt`. Then you can create the ROM using
`make 42.sfc`. The output file will be `42.sfc`. You may have to modify the
first line of the Makefile so that it points to wherever your `asar` executable
is.

## Running a program

To run `42.sfc` you can open it in any Super Nintendo emulator (a recommended
emulator is [Mesen2](https://github.com/SourMesen/Mesen2)--Mac users will need
to build it from source). If you don't want to open it directly I made a Lua
script for Mesen that will run the program and relay the output to standard
out. You can run it with:

```
Mesen --testrunner 42.sfc out_relay.lua
```

## Sample program

A sample program that includes the printing library can be found under
`print.rkt`.

## Running tests

Testing is done using Lua scripts with Mesen. But you have to again have
to do some setup:
1. Set the directory to the assembler in `make-test.rkt`
2. Set the directory to Mesen in `run_all_tests.sh`

All of the test cases can be found in `test-cases.rkt`. I have included all the
tests from the lecture code, and many of my own. To actually do the testing, I
made a shell script `run_all_tests.sh`, which will compile all the tests in
`test-cases.rkt` (each as a separate ROM), then run all of them in the
emulator. It will print out success or failure for all the tests.
