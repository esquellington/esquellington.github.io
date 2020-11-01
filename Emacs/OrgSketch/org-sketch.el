;;; org-sketch --- WIP WIP WIP
;;
;;
;;; Commentary:
;;
;;  All shell-command issued with "> /dev/null" to avoid output buffer
;;  (> NUL in Windows)
;;
;;
;;; Code:

;;--------------------------------
;;---- TOOL = gnome-paint
(defun org-sketch-tool-command ()
  "Return tool-specific command."
  "gnome-paint "
)
(defun org-sketch-tool-ext ()
  "Return tool-specific file extension."
  ".png"
)
(defun org-sketch-tool-template-file ()
  "Return tool-specific template file."
   ;; Check empty template, create if not available
  (when (not (file-exists-p "template_genearted.xopp"))
    ;; Create blank .PNG
    (shell-command (concat "convert -size 900x450 xc:white org-sketch-template.png > /dev/null")))
  "org-sketch-template.png"
)
(defun org-sketch-tool-export-png ( input output )
  "Export/Convert native INPUT to OUTPUT image."
  (shell-command (concat "convert " input " " output " > /dev/null"))
)

;;--------------------------------
;;---- TOOL = xournalpp
;;TODO SOME OF THESE SHOULD BE defvar and customizable I guess
;; (defun org-sketch-tool-command ()
;;   "Return tool-specific command."
;;   "./xournalpp-1.0.19-x86_64.AppImage "
;; )
;; (defun org-sketch-tool-ext ()
;;   "Return tool-specific file extension."
;;   ".xopp"
;; )
;; (defun org-sketch-tool-template-file ()
;;   "Return tool-specific template file."
;;   ;; Check empty template, create if not available
;;   (when (not (file-exists-p "template_genearted.xopp"))
;;     ;; Empty .xopp is XML compressed with gzip
;;     ;; TODO could parametrize template sizes and colors, but better
;;     ;; keep it simple and have a unique base template and
;;     ;; resize/modify individual outputs instead
;;     (shell-command (concat "echo '"
;;                            "<?xml version=\"1.0\" standalone=\"no\"?>"
;;                            "<xournal creator=\"Xournal++ 1.0.19\" fileversion=\"4\">"
;;                            "<title>Xournal++ document - see https://github.com/xournalpp/xournalpp</title>"
;;                            "<preview/>"
;;                            "<page width=\"900.0\" height=\"450.0\">" ;;16/9
;;                            "<background type=\"solid\" color=\"#ffffffff\" style=\"plain\"/>"
;;                            "<layer/>"
;;                            "</page>"
;;                            "</xournal>"
;;                            "' | gzip > org-sketch-template.xopp" ))
;;       )
;;   ;; Return
;;   "org-sketch-template.xopp"
;;   )

;; (defun org-sketch-tool-export-png ( input output )
;;   "Export/Convert native INPUT to OUTPUT image."
;;   (shell-command (concat (org-sketch-tool-command) " " input " -i " output " > /dev/null"))
;;)

;;--------------------------------
;; Interactive functions
(defun org-sketch-insert ( skname &optional width height )
  "Insert sketch SKNAME at point, with optional WIDTH/HEIGHT in pixels."
  (interactive "sSketch Name:") ;"sXXXX" prompts user for string param SKNAME

  ;; Default params if empty/nil
  (when (string-empty-p skname) (setq skname "UNNAMED_SKETCH"))
  (when (eq width nil) (setq width 600))
  (when (eq height nil) (setq height 400))

  (let (skname_tmp_ext skname_png skname_timestamp)

    (setq skname_png (concat skname ".png"))

    ;; Avoid overwriting silently
    (when (or (not (file-exists-p skname_png))
              (yes-or-no-p "Sketch exists! Overwrite? "))

      ;; Create sketch tool empty file from template
      (setq skname_tmp_ext (concat skname "_tmp" (org-sketch-tool-ext)))
      (setq skname_timestamp (concat skname ".timestamp"))
      (shell-command (concat "cp " (org-sketch-tool-template-file) " " skname_tmp_ext " > /dev/null"))

      ;; Create timestamp file afterwards, to detect if skname_tmp_ext is overwritten by tool
      (shell-command (concat "touch " skname_timestamp " > /dev/null"))

      ;; Open sketch tool on empty file and wait for close/exit
      (shell-command (concat (org-sketch-tool-command) skname_tmp_ext " > /dev/null"))

      ;; Check if tool file was saved, continue processing if it was, delete and exit if not
      (when (file-newer-than-file-p skname_tmp_ext skname_timestamp)

        ;; Export to .PNG
        (org-sketch-tool-export-png skname_tmp_ext skname_png)

        ;; Trim empty space and resize
        (shell-command (concat "convert -trim"
                               " -resize " (format "%dx%d" width height)
                               " " skname_png ;input
                               " " skname_png ;output
                               " > /dev/null"))

        ;; Insert org link
        ;; NOTE: We insert a plain bracket link [[file:skname_png]]
        ;; without description, insteaad of a described link
        ;; [[file:skname_png][description]] so that it can to be
        ;; displayed with default org-toggle-inline-images params (C-c
        ;; C-v C-x). To display image links with description a
        ;; non-nil prefix argument must be passed (C-u C-c C-v C-x)
        (org-insert-link nil (concat "file:" skname_png) nil)
        (message (concat "inserted sketch " skname) )
        )

      ;; Delete temp
      (shell-command (concat "rm " skname_tmp_ext " " skname_timestamp " > /dev/null"))
      )
    )
  )

(provide 'org-sketch)
;;; org-sketch.el ends here
