#lang racket

(require "65816.rkt"
         "free-vars.rkt"
         "compile-ops.rkt"
         "ast.rkt"
         "utilities.rkt"
         "assertions.rkt")

(provide compile-e)

;; Expr -> Asm
(define (compile-e e cenv t?)
  (match e
    [(Int i) (compile-int i)]
    [(Char c) (compile-char c)]
    [(Bool b) (compile-bool b)]
    [(Eof) (compile-eof)]
    [(Empty) (compile-empty)]
    [(Prim0 p) (compile-prim0 p cenv)]
    [(Prim1 p e) (compile-prim1 p e cenv)]
    [(If e1 e2 e3) (compile-if-long e1 e2 e3 cenv t?)]
    [(Begin e1 e2) (compile-begin e1 e2 cenv t?)]
    [(Let x e1 e2) (compile-let x e1 e2 cenv t?)]
    [(Var x) (compile-variable x cenv)]
    [(Prim2 p e1 e2) (compile-prim2 p e1 e2 cenv)]
    [(Prim3 p e1 e2 e3) (compile-prim3 p e1 e2 e3 cenv)]
    [(Str s) (compile-string s)]
    [(App e es) (compile-app e es cenv t?)]
    [(Lam f xs e) (compile-lam f xs e cenv)]
    [(Cond cs el) (compile-cond cs el cenv t?)]))

;; Integer -> Asm
(define (compile-int i)
  (Lda (Imm (string-append (~a i) "<<!int_shift"))))
(define (compile-char c)
  (case c
    [(#\') (Lda (Imm "(($27<<!char_shift)|!char_type_tag)"))]
    [(#\newline) (Lda (Imm "(($10<<!char_shift)|!char_type_tag)"))]
    [else
     (Lda
      (Imm (string-append "(('" (~a c) "'<<!char_shift)|!char_type_tag)")))]))
(define (compile-bool b)
  (if b (Lda (Imm "!val_true")) (Lda (Imm "!val_false"))))
(define (compile-eof)
  (Lda (Imm "!val_eof")))
(define (compile-empty)
  (Lda (Imm "!val_empty")))

;; String -> Asm
(define (compile-string s)
  (let ([len (string-length s)]
        [str (gensym ".string")]
        [done (gensym ".string_done")]
        [even (gensym ".string_even")])
    (seq (Lda (Zp "heap_pointer"))
         (Pha)
         (if (zero? len)
             '()
             (seq (Ldx (Imm str)) ; x <- source lower 16 (in ROM)
                  (Clc)
                  (Adc (Imm 4))
                  (Tay) ; y <- dest lower 16 (on the heap)
                  (Lda (Imm (sub1 len))) ; -1 for block move
                  (Phb) ; push data bank register
                  (Mvn (Mov #x7E (bank str))) ; heap bank hardcoded
                  (Plb) ; pull data bank register
                  (Brl done) ; skip past data (don't execute the string!)
                  (Label str) ; string data
                  (Data8 (Quote s)) ; DATA
                  (Label done)))
         ; configure metadata on heap
         (Lda (Imm "!string_type_tag"))
         (Sta (ZpInd "heap_pointer"))
         (Ldy (Imm 2))
         (Lda (Imm len)) ; can optimize with above loading of length
         (Sta (ZpIndY "heap_pointer"))
         (Bit (Imm #b1))
         (Beq even)
         (Inc (Acc 1)) ; 1 for even byte alignment
         (Label even)
         (Inc (Acc 4)) ; 2 + 2 for type and len
         (Clc)
         (Adc (Zp "heap_pointer"))
         (Sta (Zp "heap_pointer"))
         ; get the actual pointer
         (Pla)
         (tag-pointer))))

(define (compile-prim0 p cenv)
  (compile-op0 p))

;; Expr Expr Expr -> Asm
;; New version uses long branching to prevent issues about branch out of
;; bounds. However, it's less efficient so we should think about a method to
;; only use this version if necessary. (Right now, it's always being used.)
;
; Ok, it's not really that much less efficient
(define (compile-if-long e1 e2 e3 cenv t?)
  (let ([true (gensym ".iftrue")]
        [false (gensym ".iffalse")]
        [endif (gensym ".endif")])
    (seq (compile-e e1 cenv #f)
         (Cmp (Imm "!val_false"))
         (Bne true)
         (Brl false)
         (Label true)
         (compile-e e2 cenv t?) ; true case
         (Brl endif)
         (Label false) ; false case
         (compile-e e3 cenv t?)
         (Label endif))))

; Technically unused
(define (compile-if e1 e2 e3 cenv t?)
  (let ([false (gensym ".iftrue")] [endif (gensym ".endif")])
    (seq (compile-e e1 cenv #f)
         (Cmp (Imm "!val_false"))
         (Beq false)
         (compile-e e2 cenv t?) ; true case
         (Bra endif)
         (Label false) ; false case
         (compile-e e3 cenv t?)
         (Label endif))))

;; Op1 Expr -> Asm
(define (compile-prim1 p e cenv)
  (seq (compile-e e cenv #f) (compile-op1 p)))

(define (compile-begin e1 e2 cenv t?)
  (seq (compile-e e1 cenv #f) (compile-e e2 cenv t?)))

(define (compile-let x e1 e2 cenv t?)
  (seq (compile-e e1 cenv #f)
       (Pha)
       (compile-e e2 (cons x cenv) t?) ; add to env
       (Ply)))

;; Id CEnv -> Asm
(define (compile-variable x cenv)
  (let ([i (lookup x cenv)]) (seq (Lda (Stk i)))))

;; Op2 Expr Expr CEnv -> Asm
(define (compile-prim2 p e1 e2 cenv)
  (case p
    [(+ - < = *) ; special integer instructions
     (seq (compile-e e2 cenv #f) ; HUGE! expressions evaluated right-to-left
          (assert-integer) ; big note, we're doing this here, as long as
          (Pha) ; our prim2 constructs all expect integers
          (compile-e e1 (cons #f cenv) #f)
          (assert-integer) ; assert arg2 integer
          (compile-op2 p)
          (Ply))]
    [else
     (seq (compile-e e1 cenv #f) ; expressions evaluated left-to-right
          (Pha)
          (compile-e e2 (cons #f cenv) #f)
          (compile-op2 p))])) ;careful, stack not pulled!

;; Op3 Expr Expr Expr CEnv -> Asm
(define (compile-prim3 p e1 e2 e3 cenv)
  (seq (compile-e e1 cenv #f)
       (Pha)
       (compile-e e2 (cons #f cenv) #f)
       (Pha)
       (compile-e e3 (cons #f (cons #f cenv)) #f)
       (compile-op3 p)))

; [Listof Expr] CEnv -> Asm
(define (compile-es es c)
  (match es
    ['() '()]
    [(cons e es)
     (seq (compile-e e c #f)
          (Pha) ; retval in A
          (compile-es es (cons #f c)))])) ; fold?

;; Id [Listof Expr] CEnv -> Asm
;; The return address is placed above the arguments, so callee pops
;; arguments and return address is next frame
(define (compile-app e es c t?)
  (if t?
      (seq (compile-es (cons e es) c)
           (move-args (add1 (length es)) (length c))
           (Lda (Stk (add1 (* 2 (length es)))))
           (assert-proc)
           (deref-offset 2) ; code label
           (Sta (Zp #x00)) ; zero page alert
           (Jmp "($0000)")) ; indirect jump
      (let ([r (gensym ".fn_ret")])
        (seq (Pea (Label (string-append (~a r) "-1"))) ; pushes 16-bit address
             ; remember to complain about the -1 part later
             (compile-es (cons e es) (cons #f c))
             (Lda (Stk (add1 (* 2 (length es)))))
             (assert-proc)
             (deref-offset 2) ; code label
             (Sta (Zp #x00)) ; zero page alert
             (Jmp "($0000)") ; indirect jump
             (Label r)))))

;; Integer Integer -> Asm
(define (move-args i off) ; not recursive!
  (cond
    [(zero? off) (seq)]
    [(zero? i) (seq)]
    [else ; don't need to save A?
     (seq (Tsc)
          (Clc)
          (Adc (Imm (* 2 i)))
          (Tax) ; X <- S + (2 * i)
          (Adc (Imm (* 2 off)))
          (Tay) ; Y <- S + (2 * i) + (2 * off)
          (Lda (Imm (sub1 (* 2 i)))) ; A <- (i * 2) - 1
          (Mvp (Mov 0 0)) ; no need to preserve B
          (Tya)
          (Tcs))])) ; S <- S + (2 * off)

; Id [Listof Id] Expr CEnv -> Asm
(define (compile-lam f xs e c)
  (let ([fvs (free-vars (Lam f xs e))])
    (seq (Lda (Imm (symbol->label f)))
         (Ldy (Imm 2))
         (Sta (ZpIndY "heap_pointer"))
         (free-vars-to-heap fvs c 4)
         (Lda (Imm "!proc_type_tag"))
         (Sta (ZpInd "heap_pointer"))
         (Lda (Zp "heap_pointer"))
         (Tax)
         (Clc)
         (Adc (Imm (* 2 (+ 2 (length fvs)))))
         (Sta (Zp "heap_pointer"))
         (Txa)
         (tag-pointer))))

(define (compile-cond cs el ev t?)
  (let ([done (gensym ".cond_done")])
    (seq (flatten (map (match-lambda
                         [(Clause p e) (compile-cond-clause p e done ev t?)])
                       cs))
         (compile-e el ev t?)
         (Label done))))

(define (compile-cond-clause p e done ev t?)
  (let ([next (gensym ".cond_next")] [true (gensym ".cond_true")])
    (seq (compile-e p ev #f)
         (Cmp (Imm "!val_false"))
         (Bne true)
         (Brl next)
         (Label true)
         (compile-e e ev t?)
         (Brl done)
         (Label next))))
