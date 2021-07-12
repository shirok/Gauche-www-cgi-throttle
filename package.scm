;;
;; Package Gauche-www-cgi-throttle
;;

(define-gauche-package "Gauche-www-cgi-throttle"
  ;;
  :version "0.2.1"

  ;; Description of the package.  The first line is used as a short
  ;; summary.
  :description "Sample package.scm\n\
                Write your package description here."

  ;; List of dependencies.
  :require (("Gauche" (>= "0.9.7_")))

  ;; List name and contact info of authors.
  ;; e.g. ("Eva Lu Ator <eval@example.com>"
  ;;       "Alyssa P. Hacker <lisper@example.com>")
  :authors ("Shiro Kawai <shiro@acm.org>")

  ;; List name and contact info of package maintainers, if they differ
  ;; from authors.
  ;; e.g. ("Cy D. Fect <c@example.com>")
  :maintainers ()

  ;; List licenses
  ;; e.g. ("BSD")
  :licenses ("BSD")

  ;; Homepage URL, if any.
  ; :homepage "http://example.com/@@package@@/"

  :providing-modules (www.cgi.throttle)

  ;; Repository URL, e.g. github
  :repository "https://github.com/shirok/Gauche-www-cgi-throttle.git"
  )
