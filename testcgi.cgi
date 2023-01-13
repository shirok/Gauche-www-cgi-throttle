#!/usr/bin/env gosh
;;
;; This is a test script to check if throttling is working.
;;

(use www.cgi)
(use www.cgi.throttle)
(use text.html-lite)

(define *port* 11211) ;change this to the port memcached is listening.

(define (action ip method timestamps)
  `(,(cgi-header)
    ,(html-doctype)
    ,(html:html (html:head (html:title "Throttling"))
                (html:body (html:h1 "Throttling")
                           (html:p "Access timestamps from " ip)
                           (html:ul (map (^t (html:li (x->string t)))
                                         timestamps))))))

(define (main args)
  (cgi-throttle
   #"memcache:localhost:~*port*"
   `((GET :window 30 :count 3 :action ,action))
   (cut cgi-main (^[params] `(,(cgi-header)
                              ,(html-doctype)
                              ,(html:html (html:head (html:title "Hello"))
                                          (html:body (html:h1 "Hello"))))))))

;; Local variables:
;; mode: scheme
;; end:
