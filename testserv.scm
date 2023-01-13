#!/usr/bin/env gosh
;;
;; An http server to test testcgi.cgi.
;; Requires Gauche-makiki ( https://github.com/shirok/Gauche-makiki )
;;

(use file.util)
(use makiki)
(use makiki.cgi)

(define-http-handler "/"
  (cgi-script (build-path (sys-dirname (current-load-path))
                          "testcgi.cgi")
              :script-name "/testcgi.cgi"))

(define (main args)
  (start-http-server :port 6789
                     :access-log #t
                     :error-log #t))
