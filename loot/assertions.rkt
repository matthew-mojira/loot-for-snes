#lang racket

(require "65816.rkt"
         "utilities.rkt")

(provide assert-integer
         assert-bool
         assert-char
         assert-ascii
         assert-box
         assert-cons
         assert-string
         assert-vector
         assert-proc
         assert-natural)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ASSERTIONS
;; As an invariant, assertions are not allowed to clobber any registers.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (assert-integer)
  (let ([ok (gensym ".assert_int")])
    (seq (Bit (Imm "!int_type_mask"))
         (Beq ok)
         (Brk) ; err
         (Label ok))))

(define (assert-bool)
  (let ([ok (gensym ".assert_bool")])
    (seq (Cmp (Imm "!val_false"))
         (Beq ok)
         (Cmp (Imm "!val_true"))
         (Beq ok)
         (Brk)
         (Label ok))))

(define (assert-char)
  (let ([ok (gensym ".assert_char")])
    (seq (Pha)
         (And (Imm "!char_type_mask"))
         (Cmp (Imm "!char_type_tag"))
         (Beq ok)
         (Brk)
         (Label ok)
         (Pla))))

; CMP, CPX, and CPY clear the c flag if the register was less than the data,
; and set the c flag if the register was greater than or equal to the data.
(define (assert-ascii)
  (let ([ok (gensym ".assert_ascii")])
    (seq (assert-integer)
         (Cmp (Imm "128<<!int_shift-1")) ; magic num
         (Bcc ok)
         (Brk) ; err
         (Label ok))))

(define (assert-box)
  (assert-ptr "box"))

(define (assert-cons)
  (assert-ptr "cons"))

(define (assert-string)
  (assert-ptr "string"))

(define (assert-vector)
  (assert-ptr "vector"))

(define (assert-proc)
  (assert-ptr "proc"))

(define (assert-ptr type)
  (let ([fail (gensym ".assert_ptr")] [ok (gensym ".assert_ptr")])
    (seq (Pha)
         (And (Imm "!ptr_type_mask"))
         (Cmp (Imm "!ptr_type_tag"))
         (Bne fail) ; send to the brk instruction later (no need for 2)
         (Lda (Stk 1))
         (deref)
         (Cmp (Imm (string-append "!" type "_type_tag")))
         (Beq ok)
         (Label fail)
         (Brk)
         (Label ok)
         (Pla))))

(define (assert-natural)
  (let ([ok (gensym ".assert_nat")])
    (seq (assert-integer)
         (Bpl ok) ; exercise to the reader: why is this ok?
         (Brk)
         (Label ok))))
