#lang racket
(provide compile)

(require "ast.rkt"
         "65816.rkt"
         "utilities.rkt"
         "lambdas.rkt"
         "compile-exprs.rkt"
         "compile-fun.rkt")

;; Prog -> Asm
(define (compile p)
  (match p
    [(Prog ds e)
     ; note it's seq not prog
     (seq (Label "entry")
          (compile-defines-values ds)
          (compile-e e (reverse (define-ids ds)) #f) ; the actual program
          (move-stack-words (length ds)) ; pop fn defs
          (Rtl)
          (compile-defines ds)
          (compile-lambda-defines (lambdas p)))])) ; new definitions
