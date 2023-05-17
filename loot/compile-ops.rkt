#lang racket
(provide (all-defined-out))
(require "ast.rkt"
         "65816.rkt"
         "assertions.rkt"
         "utilities.rkt")

(define (compile-op0 p)
  (match p
    ['void (Lda (Imm "!val_void"))]))

;; Op1 -> Asm
(define (compile-op1 p)
  (match p
    ['add1 (seq (assert-integer) (Inc (Acc "1<<!int_shift")))]
    ['sub1 (seq (assert-integer) (Dec (Acc "1<<!int_shift")))]
    ['zero?
     (seq (assert-integer)
          (Cmp (Imm 0)) ; think this is unnecessary
          (check-equal))]
    ['char?
     (seq (And (Imm "!char_type_mask"))
          (Cmp (Imm "!char_type_tag"))
          (check-equal))]
    ['char->integer
     (seq (assert-char) (Lsr (Acc "!char_shift")) (Asl (Acc "!int_shift")))]
    ['integer->char
     (seq (assert-ascii)
          (Lsr (Acc "!int_shift"))
          (Asl (Acc "!char_shift"))
          (Eor (Imm "!char_type_tag")))]
    ['eof-object? (seq (Cmp (Imm "!val_eof")) (check-equal))]
    ['box
     (seq (Ldy (Imm 2)) ; store value
          (Sta (ZpIndY "heap_pointer"))
          (Lda (Imm "!box_type_tag")) ; store type
          (Sta (ZpInd "heap_pointer"))
          (increment-heap 4)
          (tag-pointer))] ; size of box
    ['unbox (seq (assert-box) (deref-offset 2))]
    ['box? (check-pointer "box")]
    ['cons? (check-pointer "cons")]
    ['empty? (seq (Cmp (Imm "!val_empty")) (check-equal))]
    ['car (seq (assert-cons) (deref-offset 4))]
    ['cdr (seq (assert-cons) (deref-offset 2))]
    ['vector? (check-pointer "vector")]
    ['vector-length
     (seq (assert-vector)
          (deref-offset 2)
          (Asl (Acc "!int_shift")))] ;convert to int type
    ['string? (check-pointer "string")]
    ['string-length
     (seq (assert-string)
          (deref-offset 2)
          (Asl (Acc "!int_shift")))] ; convert to int type
    ['print-int
     (seq (assert-integer) (Jsl "print_int") (Lda (Imm "!val_void")))]
    ['print-char (seq (assert-char) (Jsl "print_char") (Lda (Imm "!val_void")))]
    ['print-bool (seq (assert-bool) (Jsl "print_bool") (Lda (Imm "!val_void")))]
    ['integer? (seq (Bit (Imm 1)) (check-equal))]
    ['boolean?
     (let ([yes (gensym ".bool_yes")] [done (gensym ".bool_done")])
       (seq (Cmp (Imm "!val_true"))
            (Beq yes)
            (Cmp (Imm "!val_false"))
            (Beq yes)
            (Lda (Imm "!val_false"))
            (Bra done)
            (Label yes)
            (Lda (Imm "!val_true"))
            (Label done)))]
    ['procedure? (check-pointer "proc")]))

;; Op2 -> Asm
(define (compile-op2 p)
  (match p
    ['+
     (seq (Clc) ; clear carry
          (Adc (Stk 1)))]
    ['-
     (seq (Sec) ; set carry (because subtraction is weird)
          (Sbc (Stk 1)))]
    ['<
     (let ([false (gensym ".lefalse")]
           [done (gensym ".ledone")]
           [skip (gensym ".cmp_bvc")])
       (seq (Sec) ; fixed version signed comparisons
            (Sbc (Stk 1))
            (Bvc skip)
            (Eor (Imm #x8000))
            (Label skip)
            (Bpl false)
            (Lda (Imm "!val_true"))
            (Bra done)
            (Label false)
            (Lda (Imm "!val_false"))
            (Label done)))]
    ['= (seq (Cmp (Stk 1)) (check-equal))]
    ['*
     (seq (Pha)
          (Lda (Stk 3))
          (Lsr (Acc 1)) ; convert stk to internal
          (Sta (Stk 3))
          (Pla) ; A <- A1 A0
          (Lsr (Acc 1)) ; convert arg to internal
          ; multiplying
          (Sep (Imm8 #x20)) ; ACCUMULATOR 8 BITS
          (Xba) ; A <- A0 A1
          (Sta (Abs "WRMPYA")) ; WRMPYA <- A1
          (Lda (Stk 1)) ; A <- A0 B0
          (Sta (Abs "WRMPYB")) ; WRMPYB <- B0
          ; initiate multiplication
          (Nop (Acc 4)) ; wait 8 cycles (must wait the whole time)
          (Lda (Abs "RDMPY")) ; A <- A0 (A1*B0)
          (Xba) ; A <- (A1*B0) A0
          (Sta (Abs "WRMPYA")) ; WRMPYA <- A0
          (Lda (Stk 2)) ; A <- (A1*B0) B1
          (Sta (Abs "WRMPYB")) ; WRMPYB <- B1
          ; initiate multiplication
          (Nop (Acc 2)) ; wait 4+3+2=9 cycles (perhaps it's okay to wait fewer)
          (Xba) ; A <- A0 (A1*B0)
          (Clc)
          (Adc (Abs "RDMPY")) ; A <- A0 (A1*B0+A0*B1)
          (Xba) ; A <- (A1*B0+A0*B1) A0
          (Lda (Stk 1)) ; A <- (A1*B0+A0*B1) B0
          (Sta (Abs "WRMPYB")) ; WRMPYB <- B0
          ; initiate multiplication (we do other things while waiting)
          (Rep (Imm8 #x20)) ; ACCUMULATOR 16 BITS
          (And (Imm #xFF00)) ; A <- (A1*B0+A0*B1) 0
          (Clc)
          (Adc (Abs "RDMPY"))
          (Asl (Acc 1)))] ; convert to type system
    ['cons
     (seq (Ldy (Imm 2)) ; store value (second, already in accumulator)
          (Sta (ZpIndY "heap_pointer"))
          (Iny (Acc 2))
          (Pla) ; pull from stack (first)
          (Sta (ZpIndY "heap_pointer"))
          (Lda (Imm "!cons_type_tag")) ; store type
          (Sta (ZpInd "heap_pointer"))
          (increment-heap 6)
          (tag-pointer))] ; size of cons
    ['eq?
     (seq (Cmp (Stk 1)) ; this is the same as = but compile-prim2 is diff
          (check-equal)
          (Ply))]
    ['make-vector
     (let ([loop (gensym ".make_vec_loop")])
       (seq (Tax) ; X <- default value
            (Pla) ; A <- length (size already in bytes)
            (assert-natural) ; no need to shift (Why?)
            (Tay) ; Y <- length
            (Txa) ; A <- default value
            (Tyx) ; X <- length
            (Iny (Acc 2)) ; offset for type/len stuff
            ; loop to copy stuff
            (Label loop)
            (Sta (ZpIndY "heap_pointer"))
            (Dey (Acc 2))
            (Bne loop) ; goto loop if not yet 0 (there is 3 bytes safe overrun)
            ; end loop
            (Txa) ; A <- length
            (Lsr (Acc 1)) ; length/2 bytes -> vals
            ; put type/length info
            (Ldy (Imm 2))
            (Sta (ZpIndY "heap_pointer"))
            (Lda (Imm "!vector_type_tag"))
            (Sta (ZpInd "heap_pointer"))
            (Lda (Zp "heap_pointer")) ; for the retval
            (Tay) ; Y <- heap pointer
            ; add offset to heap pointer
            (Txa) ; A <- length
            (Inc (Acc 4)) ; 2 + 2 for type and len
            (Clc)
            (Adc (Zp "heap_pointer"))
            (Sta (Zp "heap_pointer"))
            (Tya) ; A <- heap pointer
            ; tag pointer
            (tag-pointer)))]
    ['vector-ref
     (let ([ok (gensym ".vector_ref_cmp")])
       (seq (Tay) ; Y <- index
            (Pla) ; A <- vec ptr
            (assert-vector)
            ; put ptr in deref area and decode
            (Sec)
            (Ror (Acc 1))
            (Sta (Zp "deref_area"))
            ; compare index in bounds
            (Tya) ; A <- index
            (assert-natural)
            (Lsr (Acc "!int_shift")) ; convert to internal representation
            (Ldy (Imm 2))
            (Cmp (ZpIndY "deref_area"))
            (Bcc ok) ; index < len
            (Brk)
            ; load
            (Label ok)
            (Asl (Acc 1)) ; from index to byte offset
            (Inc (Acc 4)) ; compiled as 4 INCs (probably bad son)
            (Tay) ; Y <- offset for element
            (Lda (ZpIndY "deref_area"))))]
    ['make-string
     (let ([loop (gensym ".make_str_loop")] [even (gensym ".make_str_even")])
       (seq (Tax) ; X <- character to fill
            (Pla) ; A <- length
            (assert-natural)
            (Lsr (Acc "!int_shift")) ; convert to interal representation
            (Tay) ; Y <- length
            (Txa) ; A <- char
            (Tyx) ; X <- length
            (Iny (Acc 3)) ; offset for type/len stuff
            (assert-char)
            ; convert to raw 8-bit ascii
            (Lsr (Acc "!char_shift"))
            (Sep (Imm8 #x20)) ; ACCUMULATOR 8 BITS
            ; loop to copy stuff
            (Label loop)
            (Sta (ZpIndY "heap_pointer"))
            (Dey (Acc 1))
            (Bne loop) ; goto loop if not yet 0 (there is 3 bytes safe overrun)
            ; end loop
            (Rep (Imm8 #x20)) ; ACCUMULATOR 16 BITS
            (Txa) ; A <- length
            ; put type/length info
            (Ldy (Imm 2))
            (Sta (ZpIndY "heap_pointer"))
            (Lda (Imm "!string_type_tag"))
            (Sta (ZpInd "heap_pointer"))
            (Lda (Zp "heap_pointer")) ; for the retval
            (Tay) ; Y <- heap pointer
            ; add offset to heap pointer
            (Txa) ; A <- length
            (Bit (Imm #b1))
            (Beq even)
            (Inc (Acc 1)) ; 1 for even byte alignment
            (Label even)
            (Inc (Acc 4)) ; 2 + 2 for type and len
            (Clc)
            (Adc (Zp "heap_pointer"))
            (Sta (Zp "heap_pointer"))
            (Tya) ; A <- heap pointer
            ; tag pointer
            (tag-pointer)))]
    ['string-ref
     (let ([ok (gensym ".string_ref_cmp")])
       (seq (Tay) ; Y <- index
            (Pla) ; A <- str ptr
            (assert-string)
            ; put ptr in deref area and decode
            (Sec)
            (Ror (Acc 1))
            (Sta (Zp "deref_area"))
            ; compare index in bounds
            (Tya) ; A <- index
            (assert-natural)
            (Lsr (Acc "!int_shift")) ; convert to internal representation
            (Ldy (Imm 2))
            (Cmp (ZpIndY "deref_area"))
            (Bcc ok) ; index < len
            (Brk)
            ; load
            (Label ok)
            (Inc (Acc 4)) ; compiled as 4 INCs (probably bad son)
            (Tay) ; y <- offset for char
            (Lda (ZpIndY "deref_area"))
            (And (Imm #xFF)) ; get only lower byte
            (Asl (Acc "!char_shift"))
            (Ora (Imm "!char_type_tag"))))]))

(define (compile-op3 p)
  (match p
    ['vector-set!
     (let ([ok (gensym ".vector_set")])
       (seq (Ply) ; Y <- index
            (Tax) ; X <- arg to put
            (Pla) ; A <- vec ptr
            (assert-vector)
            ; put ptr in deref area and decode
            (Sec)
            (Ror (Acc 1))
            (Sta (Zp "deref_area"))
            ; compare index in bounds
            (Tya) ; A <- index
            (assert-natural)
            (Lsr (Acc "!int_shift")) ; convert to internal representation
            (Ldy (Imm 2))
            (Cmp (ZpIndY "deref_area"))
            (Bcc ok) ; index < len
            (Brk)
            ; load
            (Label ok)
            (Inc (Acc 2)) ; haha sneaky (really we want +4 but look below!)
            (Asl (Acc 1)) ; offset in bytes
            (Tay) ; Y <- offset
            (Txa) ; A <- item to put
            (Sta (ZpIndY "deref_area"))
            (Lda (Imm "!val_void"))))]))
