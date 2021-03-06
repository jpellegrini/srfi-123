;;; generic-ref-set --- Generic accessor and modifier operators.

;; Copyright © 2015  Taylan Ulrich Bayırlı/Kammer <taylanbayirli@gmail.com>

;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

(define-library (tests srfi-123)
  (export run-tests)
  (import (except (scheme base) define-record-type set!)
          (r6rs hashtables)
          (srfi 64)
          (srfi 123))
  (cond-expand
   ((library (srfi 99))
    (import (srfi 99)))
   ((library (rnrs records inspection))
    (import (rnrs records syntactic))
    (import (rnrs records procedural)))
    (import (rnrs records inspection))
   ((library (r6rs records inspection))
    (import (r6rs records syntactic))
    (import (r6rs records procedural)))
    (import (r6rs records inspection))
   (else))
  (cond-expand
   ((library (srfi 4))
    (import (srfi 4)))
   (else
    (begin
      ;; Stub to silence compilers.
      (define s16vector #f))))
  (cond-expand
   ((library (srfi 111))
    (import (srfi 111)))
   (else
    (begin
      ;; Stub to silence compilers.
      (define box #f))))
  (begin

    (define-record-type <foo> (make-foo a b) foo?
      (a foo-a set-foo-a!)
      (b foo-b))

    ;; The SRFI-99 sample implementation contains a bug where immutable fields
    ;; are nevertheless mutable through the procedural API.  Test whether we are
    ;; on that implementation.
    (cond-expand
     ((library (srfi 99))
      (define using-broken-srfi99
        (guard (err (else #f))
          (rtd-mutator <foo> 'b))))
     (else
      (define using-broken-srfi99 #f)))

    (define (run-tests)
      (let ((runner (test-runner-create)))
        (parameterize ((test-runner-current runner))
          (test-begin "SRFI-123")

          (test-begin "ref")
          (test-assert "bytevector" (= 1 (ref (bytevector 0 1 2) 1)))
          (test-assert "hashtable" (let ((table (make-eqv-hashtable)))
                                     (hashtable-set! table 'foo 0)
                                     (= 0 (ref table 'foo))))
          (test-assert "hashtable default" (let ((table (make-eqv-hashtable)))
                                             (= 1 (ref table 0 1))))
          (test-assert "pair" (= 1 (ref (cons 0 1) 'cdr)))
          (test-assert "list" (= 1 (ref (list 0 1 2) 1)))
          (test-assert "string" (char=? #\b (ref "abc" 1)))
          (test-assert "vector" (= 1 (ref (vector 0 1 2) 1)))
          (test-assert "record" (= 1 (ref (make-foo 0 1) 'b)))
          (cond-expand
           ((library (srfi 4)) (values))
           (else               (test-skip 1)))
          (test-assert "srfi-4" (= 1 (ref (s16vector 0 1 2) 1)))
          (cond-expand
           ((library (srfi 111)) (values))
           (else                 (test-skip 1)))
          (test-assert "srfi-111" (= 1 (ref (box 1) '*)))
          (test-end "ref")

          (test-assert "ref*" (= 1 (ref* '(_ #(_ (0 . 1) _) _) 1 1 'cdr)))

          (test-begin "ref setter")
          (test-assert "bytevector" (let ((bv (bytevector 0 1 2)))
                                      (set! (ref bv 1) 3)
                                      (= 3 (ref bv 1))))
          (test-assert "hashtable" (let ((ht (make-eqv-hashtable)))
                                     (set! (ref ht 'foo) 0)
                                     (= 0 (ref ht 'foo))))
          (test-assert "pair" (let ((p (cons 0 1)))
                                (set! (ref p 'cdr) 2)
                                (= 2 (ref p 'cdr))))
          (test-assert "list" (let ((l (list 0 1 2)))
                                (set! (ref l 1) 3)
                                (= 3 (ref l 1))))
          (test-assert "string" (let ((s (string #\a #\b #\c)))
                                  (set! (ref s 1) #\d)
                                  (char=? #\d (ref s 1))))
          (test-assert "vector" (let ((v (vector 0 1 2)))
                                  (set! (ref v 1) 3)
                                  (= 3 (ref v 1))))
          (test-assert "record" (let ((r (make-foo 0 1)))
                                  (set! (ref r 'a) 2)
                                  (= 2 (ref r 'a))))
          (when using-broken-srfi99
            (test-expect-fail 1))
          (test-assert "bad record assignment"
            (not (guard (err (else #f)) (set! (ref (make-foo 0 1) 'b) 2) #t)))
          (cond-expand
           ((library (srfi 4)) (values))
           (else               (test-skip 1)))
          (test-assert "srfi-4" (let ((s16v (s16vector 0 1 2)))
                                  (set! (ref s16v 1) 3)
                                  (= 3 (ref s16v 1))))
          (cond-expand
           ((library (srfi 111)) (values))
           (else                 (test-skip 1)))
          (test-assert "srfi-111" (let ((b (box 0)))
                                    (set! (ref b '*) 1)
                                    (= 1 (ref b '*))))
          (test-end "ref setter")

          (test-assert "ref* setter"
            (let ((obj (list '_ (vector '_ (cons 0 1) '_) '_)))
              (set! (ref* obj 1 1 'cdr) 2)
              (= 2 (ref* obj 1 1 'cdr))))

          (test-end "SRFI-123")
          (and (= 0 (test-runner-xpass-count runner))
               (= 0 (test-runner-fail-count runner))))))

    ))
