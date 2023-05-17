## REPLACE THIS WITH THE DIRECTORY OF YOUR ASSEMBLER!!!
ASSEMBLER = asar

libs = \
  runtime.asm \
  registers.asm \
  types.asm

racket = \
	65816.rkt \
	assertions.rkt \
	ast.rkt \
	compile-exprs.rkt \
	compile-fun.rkt \
	compile-ops.rkt \
	compile-stdin.rkt \
	compile.rkt \
	free-vars.rkt \
	lambdas.rkt \
	parse.rkt \
	read-all.rkt \
	utilities.rkt

%.sfc: %.asm $(libs)
	$(ASSEMBLER) --symbols=wla --define CODE_FILE=$< runtime.asm $@

%.asm: %.rkt $(racket)
	cat $< | racket -t compile-stdin.rkt -m > $@

clean:
	rm *.sfc *.sym
