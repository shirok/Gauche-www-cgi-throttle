;;;
;;; Run dummy server to test the cgi throttling
;;;
;;; This file is loaded into test.scm when Makiki is available
;;;

(use makiki.subserver)
(use rfc.http)
(use sxml.ssax)
(use sxml.sxpath)

(test-section "test with server")

(define (get-title host path)
  (receive [status hdrs body] (http-get host path)
    (unless (equal? status "200")
      (error #"HTTP error ~status" body))
    ((car-sxpath '(// title *text*))
     (call-with-input-string body (cut ssax:xml->sxml <> '())))))


($ call-with-httpd "./testserv.scm"
   (^[port]
     (define host #"localhost:~port")
     (test* "Pass-through" '("Hello" "Hello" "Hello")
            (list (get-title host "/")
                  (get-title host "/")
                  (get-title host "/")))
     (test* "Cache hit" '("Throttling")
            (list (get-title host "/")))
     ))
