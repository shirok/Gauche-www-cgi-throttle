;;;
;;; Test www.cgi.throttle
;;;

(use gauche.test)
(use gauche.process)
(add-load-path "." :relative)

(test-start "www.cgi.throttle")
(use www.cgi.throttle)
(test-module 'www.cgi.throttle)

(when (library-exists? 'makiki)
  (load "./test-with-server"))

(test-end)
