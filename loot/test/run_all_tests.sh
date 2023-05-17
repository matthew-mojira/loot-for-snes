## REPLACE THIS WITH THE DIRECTORY OF YOUR EMULATOR!!
mesen=Mesen

echo Removing previous tests

rm *.sfc

echo Creating new tests

racket test-cases.rkt

echo Testing started

# Runs 10 tests simultaneously, based on the last digit of the generated test
# number. (Not a great approach.)

(for file in ./test*0.sfc; do
  $mesen --testrunner $file test_script.lua
done) &
(for file in ./test*1.sfc; do
  $mesen --testrunner $file test_script.lua
done) &
(for file in ./test*2.sfc; do
  $mesen --testrunner $file test_script.lua
done) &
(for file in ./test*3.sfc; do
  $mesen --testrunner $file test_script.lua
done) &
(for file in ./test*4.sfc; do
  $mesen --testrunner $file test_script.lua
done) &
(for file in ./test*5.sfc; do
  $mesen --testrunner $file test_script.lua
done) &
(for file in ./test*6.sfc; do
  $mesen --testrunner $file test_script.lua
done) &
(for file in ./test*7.sfc; do
  $mesen --testrunner $file test_script.lua
done) &
(for file in ./test*8.sfc; do
  $mesen --testrunner $file test_script.lua
done) &
(for file in ./test*9.sfc; do
  $mesen --testrunner $file test_script.lua
done)

wait

echo Testing finished
