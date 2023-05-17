#lang racket

(require "65816.rkt"
         "ast.rkt")

(provide (all-defined-out))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UTILITIES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (check-equal)
  (let ([true (gensym ".iftrue")] [endif (gensym ".endif")])
    (seq (Beq true)
         (Lda (Imm "!val_false"))
         (Bra endif)
         (Label true) ; true case
         (Lda (Imm "!val_true"))
         (Label endif))))

(define (check-pointer type)
  (let ([ok (gensym ".check_pointer")] [done (gensym ".check_pointer")])
    (seq (Tax)
         (And (Imm "!ptr_type_mask"))
         (Cmp (Imm "!ptr_type_tag"))
         (Beq ok)
         (Lda (Imm "!val_false"))
         (Bra done)
         (Label ok)
         (Txa)
         (deref)
         (Cmp (Imm (string-append "!" type "_type_tag")))
         (check-equal)
         (Label done))))

(define (tag-pointer)
  (seq (Asl (Acc 1)) (Ora (Imm "!ptr_type_tag"))))

; takes a value in type system (does not check if it's pointer)
; and dereferences
(define (deref)
  (seq (Sec) (Ror (Acc 1)) (Sta (Zp "deref_area")) (Lda (ZpInd "deref_area"))))

(define (deref-offset o)
  (seq (Sec)
       (Ror (Acc 1))
       (Ldy (Imm o))
       (Sta (Zp "deref_area"))
       (Lda (ZpIndY "deref_area"))))

; a constant, known offset to the heap pointer
; accumulator will contain the original value of heap pointer (before inc)
(define (increment-heap o)
  (seq (Lda (Zp "heap_pointer")) ; get actual heap pointer
       (Pha) ; preserve this now
       (Clc) ; don't add 1 to this addition, please!
       (Adc (Imm o)) ; arg
       (Sta (Zp "heap_pointer"))
       (Pla))) ; regrab and make pointer type

;; Symbol -> Label
;; Produce a symbol that is a valid asar label
(define (symbol->label s)
  (string-append "fn_"
                 (list->string (map (λ (c)
                                      (if (or (char<=? #\a c #\z)
                                              (char<=? #\A c #\Z)
                                              (char<=? #\0 c #\9)
                                              (memq c '(#\_)))
                                          c
                                          #\_))
                                    (string->list (symbol->string s))))
                 "_"
                 (number->string (eq-hash-code s) 16)))

(define (bank s)
  (string-append "<:" (~a s)))

; DO NOT USE THIS WITH A NEGATIVE ARGUMENT!!
(define (move-stack-words o)
  (if (< o 3)
      (for/list ([_ o])
        (Ply))
      (seq (Tax) ; rearrange the registers (can't save on the stack!)
           (Tsc) ; now playing with the stack pointer
           (Clc)
           (Adc (Imm (* 2 o))) ; this modifies the sp value
           (Tcs) ; put back stack pointer
           (Txa))))

; [Listof Id] CEnv Int -> Asm
; Copy the values of given free variables into the heap at given offset
; this one is actually recursive!
(define (free-vars-to-heap fvs c off)
  (match fvs
    ['() (seq)]
    [(cons x fvs)
     (seq (Lda (Stk (lookup x c)))
          (Ldy (Imm off))
          (Sta (ZpIndY "heap_pointer"))
          (free-vars-to-heap fvs c (+ off 2)))]))

;; Id CEnv -> Integer
(define (lookup x cenv)
  (match cenv
    ['() (error "undefined variable:" x)]
    [(cons y rest)
     (match (eq? x y)
       [#t 1] ; 1???
       [#f (+ 2 (lookup x rest))])]))

;; [Listof Defn] -> [Listof Id]
; The identifiers corresponding to all declared functions in the program.
(define (define-ids ds)
  (map (match-lambda
         [(Defn f xs e) f])
       ds))
