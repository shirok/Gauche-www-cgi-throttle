;;;
;;; www_cgi_throttle
;;;

(define-module www.cgi.throttle
  (use gauche.parameter)
  (use gauche.logger)
  (use gauche.experimental.app) ; unnecessary after Gauche-0.9.3
  (use text.html-lite)
  (use text.tree)
  (use www.cgi)
  (use util.list)
  (use util.match)
  (use srfi-1)
  (use srfi-13)
  ;; Requres Gauche-memcache (http://fixedpoint.jp/gauche-memcache/)
  (use memcache :prefix mc:)
  (export cgi-throttle
          cgi-throttle-log-drain
          cgi-throttle-return-503
          cgi-throttle-redirect)
  )
(select-module www.cgi.throttle)

;; We store list of timestamps for a key
;; "Gauche-www-cgi-throttle:SCRIPT_NAME:IP:METHOD".
;; Every time a request comes from an IP, we look up the entry,
;; push the current timestamp, and removes the timestamps that's
;; older than the "window" period.  After this process, if the
;; length of the timestamp list is longer than the threshold,
;; we take action---returns 503 or redirect.

;; The defaults - meaning, if 15 same request from the same ip occurs
;; in last 30 seconds, we limit.
(define-constant *default-window* 30)   ;seconds
(define-constant *default-count* 15)

;; Usage: wrap cgi-main procedure with cgi-throttle procedure
;;
;;  (define (main args)
;;    (cgi-throttle
;;     connection config
;;     (cut cgi-main (lambda (params) ...) ...)))
;;
;; Connection
;;   "memcache:HOST:PORT"
;;   In future we may provide other type of backend dbs.
;;
;; Configuration
;;  <config> : ((<request-method> . <options>) ...)
;;  <requerst-method> : <symbol>
;;  <options> : kv-list
;;              recognized keywords
;;               :window <duration>   ; in seconds
;;               :count <integer>
;;               :action <procedure>  ; a procedure takes ipaddr, request method
;;                                    ; and the list of timestamps.
;;                                    ; it should allow optional args for
;;                                    ; future extension.
;;                                    ; it must return a text tree or #f.
;;
;; Some predefined actions are provided.
;;   cgi-throttle-return-503  => returns 'service unavailable' status code
;;   (cgi-throttle-redirect url) => redirect to url
;;
;; NB: Alternative idea of API is to wrap the procedure passed to cgi-main.
;;   (cgi-main (cgi-throttle config (lambda (params) ...)) ...)
;; This allows cgi-throttle to dispatch based on the query parameters
;; as well.  The drawback is that it can't be used if the call of cgi-main
;; isn't exposed, such as in wiliki.

;; API
(define (cgi-throttle conn-spec config thunk)
  (guard (e [(<error> e) (report-memcache-error e)])
    (receive (host port) (parse-connection-spec conn-spec)
      (let1 conn (mc:memcache-connect host port)
        (unwind-protect
            (or (check config conn) (thunk))
          (mc:memcache-close conn))))))

;; API
(define cgi-throttle-log-drain (make-parameter #f))

;; API
(define cgi-throttle-return-503
  (^[ip method ts . rest]
    `(,(cgi-header :status 503)
      ,(html-doctype)
      ,(html:html (html:head (html:title "Service unavailable"))
                  (html:body (html:h1 "Service unavailable"))))))

;; API
(define (cgi-throttle-redirect url)
  (^[ip method ts . rest]
    `(,(cgi-header :status 302 :location url))))

;; There's a hazard accessing the same IP:METHOD in parallel; at worst,
;; we'll miss registering some accesses, causing to evaluate the traffic
;; less than actual.  However, for our purpose I think we can tolerate it.
(define (check config conn)
  (and-let* ([ip     (cgi-get-metavariable "REMOTE_ADDR")]
             [name   (cgi-get-metavariable "SCRIPT_NAME")]
             [method ($ string->symbol $ string-upcase
                        $ cgi-get-metavariable "REQUEST_METHOD")]
             [key    #`"Gauche-www-cgi-throttle:,|name|:,|ip|:,|method|"]
             [conf   (assq-ref config method #f)]
             [window (get-keyword :window conf *default-window*)])
    (match (mc:get conn key)
      [((_ . ts))
       (let* ([now    (sys-time)]
              [cutoff (- now window)]
              [count  (get-keyword :count conf *default-count*)]
              [ts (cons (sys-time) (take* (filter (pa$ <= cutoff) ts) count))])
         (mc:set conn key ts :exptime window)
         (and-let* ([ (> (length ts) count) ]
                    [content ((get-keyword :action conf cgi-throttle-return-503)
                              ip method ts)])
           (write-tree content)
           #t))]
      [_ (mc:set conn key `(,(sys-time)) :exptime window) #f])))

(define (report-memcache-error e)
  (log-format (cgi-throttle-log-drain) "~a: ~s"
              (class-name (class-of e))
              (~ e'message))
  (write-tree
   `(,(cgi-header)
     ,(html-doctype)
     ,(html:html (html:head (html:title "Error"))
                 (html:body (html:h1 "Internal server error"))))))

(define (parse-connection-spec conn-spec)
  (rxmatch-case conn-spec
    [#/^memcache:([^:]+):(\d+)$/ (_ host port) (values host (x->integer port))]
    [else (error "invalid connection spec" conn-spec)]))

            

                  

