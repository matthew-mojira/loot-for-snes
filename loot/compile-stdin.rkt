#lang racket
(provide main)
(require "parse.rkt"
         "compile.rkt"
         "65816.rkt"
         "read-all.rkt")

;; -> Void
;; Compile contents of stdin,
;; emit asm code on stdout
(define (main)
  (read-line) ; ignore #lang racket line
  ;  (print (parse (read-all)))
  (printer (compile (parse (read-all)))))
