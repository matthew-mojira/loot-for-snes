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
