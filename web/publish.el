;;----------------------------------------------------------------
;; ORG-PUBLISH standalone script
;;
;; Based on: https://systemcrafters.net/publishing-websites-with-org-mode/building-the-site/
;;----------------------------------------------------------------

;; Set the package installation directory so that packages aren't stored in the
;; ~/.emacs.d/elpa path.
(require 'package)
(setq package-user-dir (expand-file-name "./.packages"))
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

;; Initialize the package system
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Install dependencies
;; Nicer code formatting
(package-install 'htmlize)
(package-install 'ample-zen-theme)
(load-theme 'ample-zen t)

;;---- PUBLISH
(require 'ox-publish)

;; Customize the HTML output
(setq org-html-validation-link nil             ;remove ugly link
      org-html-head-include-scripts nil        ;Use our own scripts???
      org-html-head-include-default-style nil) ;Use our own styles???

;; Use Local CSS with custom overrides, copied from https://simplecss.org/
;;   "<link rel=\"stylesheet\" href=\"https://cdn.simplecss.org/simple.min.css\" />"
(setq org-html-head (concat "<link rel=\"stylesheet\" href=\"../css/simple.min.css\" />"
                            "<link rel=\"stylesheet\" href=\"../css/custom.css\" />"))

;;---- website sources
(setq org-publish-project-alist
      '(("posts"
         :recursive t
         :base-directory "posts/"
         :base-extension "org"
         :publishing-directory "public/"
         :publishing-function org-html-publish-to-html
         ;; SiteMap
         :auto-sitemap t
         :sitemap-title "Site Map TEST"
         :sitemap-sort-files anti-chronologically
         ;; Header (TODO class-es should be defined in CSS!!! ex ".notice" is defined, but no others
         ; :html-preamble "<div class=\"header\"> PREAMBLE </div>"
         ;; Footer
         ; :html-postamble "<div class=\"footer\"> <div class=\"bg\"> <div class=\"notice\"> POSTAMBLE </div> </div> </div>"
         ;; Info
         :author "OCF"
         :email "invalid@example.com"
         ;; Style
         :with-author nil
         :with-creator t ;show Emacs+Org version
         :with-date nil ;toggle page gen date
         :with-toc t
         :with-todo-keywords t
         :section-numbers nil
         :time-stamp-file nil)
        ("img"
         :recursive t
         :base-directory "img/"
         :base-extension "png\\|jpg\\|gif"
         :publishing-directory "public/img"
         :publishing-function org-publish-attachment)
        ("css"
          :recursive t
          :base-directory "css/"
          :base-extension "css"
          :publishing-directory "public/css"
          :publishing-function org-publish-attachment)
        ("all" :components ("posts" "img" "css"))))

;; Run from Makefile and consider avoiding explicit call to org-publish-all with
;;EITHER emacs --batch --load publish.el --funcall org-publish-all
;;OR emacs -Q --script publish.el
(org-publish-all t)
(message "ORG-PUBLISH COMPLETED")
