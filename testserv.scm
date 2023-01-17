#!/usr/bin/env gosh
;;
;; An http server to test testcgi.cgi.
;; Requires Gauche-makiki ( https://github.com/shirok/Gauche-makiki )
;;

(use file.util)
(use makiki)
(use makiki.cgi)
(use rfc.uuid)

;; We give a unique name as a script name, so that each run of the test
;; wont interfere with other runs.
(define-http-handler "/"
  (cgi-script (build-path (sys-dirname (current-load-path))
                          "testcgi.cgi")
              :script-name #"/~(uuid->string (uuid4))"))

(define (main args)
  (start-http-server :port 0
                     :access-log #t
                     :error-log #t))
