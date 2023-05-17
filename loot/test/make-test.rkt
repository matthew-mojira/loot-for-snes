#lang racket

(provide make-test)

(require "../compile.rkt"
         "../parse.rkt"
         "../65816.rkt")

;; REPLACE THIS WITH THE DIRECTORY OF YOUR ASSEMBLER!!!
(define asar "asar")

; This makes all the tests
(define (make-test code res)
  (let* ([name (symbol->string (gensym "test"))]
         [test (open-output-file (string-append name ".asm") #:exists 'replace)]
         [program (append print-library (replace-last code))])
    (display (comp->string (seq (compile (parse program))
                                (Pushpc)
                                (Org "$C10000") ; test data
                                (Data8 (Quote (~v res)))
                                (Data8 0) ; null terminate
                                (Data8 (Quote code))
                                (Pullpc)))
             test)
    (close-output-port test)
    (system (string-append asar
                           " --define CODE_FILE="
                           name
                           ".asm ../runtime.asm "
                           name
                           ".sfc"))
    (system (string-append "rm " name ".asm"))
    (void)))

(define/match (replace-last ls)
  [((list x)) `((print-value ,x))]
  [((cons x xs)) (cons x (replace-last xs))])

; This is the printing library supplied to all tests. The result of each test
; is then fed into the print-value function, and it is compared as strings to
; the expected result.
(define print-library
  '((define (print-value val)
      (cond
        [(integer? val) (print-int val)]
        [(boolean? val) (print-bool val)]
        [(char? val)
         (begin
           (print-string "#\\")
           (print-char val))]
        [(eof-object? val) (print-string "#<eof>")]
        [(eq? val (void)) (print-string "#<void>")]
        [(procedure? val) (print-string "#<procedure>")]
        [(string? val)
         (begin
           (print-char #\")
           (begin
             (print-string val)
             (print-char #\")))]
        [else
         (begin
           (print-char #\')
           (print-value-interior val))]))
    (define (print-value-interior val)
      (cond
        [(empty? val) (print-string "()")]
        [(box? val)
         (begin
           (print-string "#&")
           (print-value-interior (unbox val)))]
        [(cons? val)
         (begin
           (print-char #\()
           (begin
             (print-cons val)
             (print-char #\))))]
        [(vector? val) (print-vector val)]
        [else (print-value val)]))
    (define (print-string str)
      (print-str-ind str 0))
    (define (print-str-ind str ind)
      (if (= ind (string-length str))
          (void)
          (begin
            (print-char (string-ref str ind))
            (print-str-ind str (add1 ind)))))
    (define (print-vector vec)
      (if (zero? (vector-length vec))
          (print-string "#()")
          (begin
            (print-string "#(")
            (print-vec-ind vec 0))))
    (define (print-vec-ind vec ind)
      (begin
        (print-value-interior (vector-ref vec ind))
        (if (= ind (sub1 (vector-length vec)))
            (print-char #\))
            (begin
              (print-char #\space)
              (print-vec-ind vec (add1 ind))))))
    (define (print-cons pair)
      (begin
        (print-value-interior (car pair))
        (let ([sec (cdr pair)])
          (cond
            [(empty? sec) (void)]
            [(cons? sec)
             (begin
               (print-char #\space)
               (print-cons sec))]
            [else
             (begin
               (print-string " . ")
               (print-value-interior sec))]))))))
