#lang racket
(provide parse)
(require "ast.rkt")

;; [Listof S-Expr] -> Prog
(define (parse s)
  (match s
    [(cons (and (cons 'define _) d) s)
     (match (parse s)
       [(Prog ds e) (Prog (cons (parse-define d) ds) e)])]
    [(cons e '()) (Prog '() (parse-e e))]
    [_ (error "program parse error")]))

;; S-Expr -> Defn
(define (parse-define s)
  (match s
    [(list 'define (list-rest (? symbol? f) xs) e)
     (if (andmap symbol? xs)
         (Defn f xs (parse-e e))
         (error "parse definition error"))]
    [_ (error "Parse defn error" s)]))

;; S-Expr -> Expr
(define (parse-e s)
  (match s
    ['eof (Eof)]
    [(? exact-integer?) (Int s)]
    [(? boolean?) (Bool s)]
    [(? char?) (Char s)]
    [(list (? op0? o)) (Prim0 o)]
    [(list (? op1? o) e) (Prim1 o (parse-e e))]
    [(list 'begin e1 e2) (Begin (parse-e e1) (parse-e e2))]
    [(list 'if e1 e2 e3) (If (parse-e e1) (parse-e e2) (parse-e e3))]
    [(list 'let (list (list (? symbol? x) e1)) e2)
     (Let x (parse-e e1) (parse-e e2))]
    [(? symbol? s) (Var s)]
    [(list (? op2? o) e1 e2) (Prim2 o (parse-e e1) (parse-e e2))]
    [(list 'quote (list)) (Empty)]
    [(list (? op3? o) e1 e2 e3)
     (Prim3 o (parse-e e1) (parse-e e2) (parse-e e3))]
    [(? string?) (Str s)]
    [(list (or 'lambda 'λ) xs e)
     (if (and (list? xs) (andmap symbol? xs))
         (Lam (gensym 'lambda) xs (parse-e e))
         (error "parse lambda error"))]
    [(cons 'cond cs) (parse-cond cs)]
    [(cons e es) (App (parse-e e) (map parse-e es))]
    [_ (error "Parse error")]))

;; Any -> Boolean
(define (op0? x)
  (memq x '(void error)))
(define (op1? x)
  (memq x
        '(add1 sub1
               zero?
               char?
               integer->char
               char->integer
               eof-object?
               box
               unbox
               empty?
               cons?
               box?
               car
               cdr
               vector?
               vector-length
               string?
               string-length
               print-int
               print-char
               print-bool
               integer?
               boolean?
               procedure?)))
(define (op2? x)
  (memq x '(+ - < = cons eq? make-vector vector-ref make-string string-ref)))
(define (op3? x)
  (memq x '(vector-set!)))

;; S-Expr -> Cond
(define (parse-cond cs)
  (match cs
    [(list (list 'else e)) (Cond '() (parse-e e))]
    [(cons (list p e) css)
     (match (parse-cond css)
       [(Cond cs el) (Cond (cons (Clause (parse-e p) (parse-e e)) cs) el)])]
    [_ (error "parse error")]))
