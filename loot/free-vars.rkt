#lang racket
(require "ast.rkt")
(provide free-vars)

;; I changed fv to free-vars for no reason (I just felt like it)

;; Expr -> [Listof Id]
;; List all of the free variables in e
(define (free-vars e)
  (remove-duplicates (free-vars* e)))

(define (free-vars* e)
  (match e
    [(Var x) (list x)]
    [(Prim1 p e) (free-vars* e)]
    [(Prim2 p e1 e2) (append (free-vars* e1) (free-vars* e2))]
    [(Prim3 p e1 e2 e3)
     (append (free-vars* e1) (free-vars* e2) (free-vars* e3))]
    [(If e1 e2 e3) (append (free-vars* e1) (free-vars* e2) (free-vars* e3))]
    [(Begin e1 e2) (append (free-vars* e1) (free-vars* e2))]
    [(Let x e1 e2) (append (free-vars* e1) (remq* (list x) (free-vars* e2)))]
    [(App e1 es) (append (free-vars* e1) (append-map free-vars* es))]
    [(Lam f xs e) (remq* xs (free-vars* e))]
    [(Cond cs e) (append (free-vars* e) (append-map free-vars* cs))]
    [(Clause p b) (append (free-vars* p) (free-vars* b))]
    [_ '()]))
