#lang racket

(provide compile-defines-values
         compile-defines
         compile-lambda-defines)

(require "65816.rkt"
         "ast.rkt"
         "free-vars.rkt"
         "lambdas.rkt"
         "utilities.rkt"
         "compile-exprs.rkt")

; Defns -> Asm
; Compile the closures for ds and push them on the stack
(define (compile-defines-values ds)
  (seq (alloc-defines ds 0)
       (init-defines ds (reverse (define-ids ds)) 4)
       (add-heap-defines ds 0)))

; Defns Int -> Asm
; Allocate closures for ds at given offset, but don't write environment yet
(define (alloc-defines ds off)
  (match ds
    ['() (seq)]
    [(cons (Defn f xs e) ds)
     (let ([fvs (free-vars (Lam f xs e))])
       (seq (Lda (Imm (symbol->label f)))
            (Ldy (Imm (+ 2 off)))
            (Sta (ZpIndY "heap_pointer"))
            (Lda (Imm "!proc_type_tag"))
            (Dey (Acc 2))
            (Sta (ZpIndY "heap_pointer"))
            (Lda (Zp "heap_pointer")) ; do not modify heap pointer yet
            (Clc)
            (Adc (Imm off))
            (tag-pointer)
            (Pha)
            (alloc-defines ds (+ off (* 2 (+ 2 (length fvs)))))))]))
; stuff                         ^     ^word  ^ ptr+tag

; Defns CEnv Int -> Asm
; Initialize the environment for each closure for ds at given offset
(define (init-defines ds c off)
  (match ds
    ['() (seq)]
    [(cons (Defn f xs e) ds)
     (let ([fvs (free-vars (Lam f xs e))])
       (seq (free-vars-to-heap fvs c off)
            (init-defines ds c (+ off (* 2 (+ 2 (length fvs)))))))]))

; Defns Int -> Asm
; Compute adjustment to heap pointer for allocation of all ds
(define (add-heap-defines ds n)
  (match ds
    ['()
     (seq (Lda (Zp "heap_pointer"))
          (Clc)
          (Adc (Imm (* n 2)))
          (Sta (Zp "heap_pointer")))]
    [(cons (Defn f xs e) ds)
     (add-heap-defines ds (+ 2 n (length (free-vars (Lam f xs e)))))]))

; [Listof Defn] -> Asm
(define (compile-defines ds)
  (foldr (match-lambda**
           [((Defn f xs e) ls)
            (seq (Comment (string-append (~a f) ": " (~a xs)))
                 (compile-lambda-define (Lam f xs e))
                 ls)])
         (seq)
         ds))

; [Listof Lam] -> Asm
(define (compile-lambda-defines ls)
  (foldr (lambda (lam ls) (seq (compile-lambda-define lam) ls)) (seq) ls))

; Lam -> Asm
(define/match (compile-lambda-define l)
  [((Lam f xs e))
   (let ([fvs (free-vars l)])
     (let ([env (append (reverse fvs) (reverse xs) (list #f))])
       (seq (Label (symbol->label f))
            (if (zero? (length fvs))
                '() ; empty closure optimization
                (seq (Lda (Stk (add1 (* 2 (length xs))))) ; get closure on stack
                     (Sec)
                     (Ror (Acc 1))
                     (Sta (Zp "deref_area")) ; move to get ready to deref
                     (copy-env-to-stack fvs 4)))
            (compile-e e env #t)
            (move-stack-words (length env)) ; pop env
            (Rts))))])

; [Listof Id] Int -> Asm
; Copy the closure environment at given offset to stack
(define (copy-env-to-stack fvs off)
  (let ([loop (gensym)])
    (seq (Ldy (Imm off)) ; initial offset
         (Label loop)
         (Lda (ZpIndY "deref_area"))
         (Pha)
         (Iny (Acc 2))
         (Cpy (Imm (* 2 (+ 2 (length fvs)))))
         (Bne loop))))
; no block move, an actual loop instead
