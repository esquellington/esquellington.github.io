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
  ".jpg"
)
(defun org-sketch-tool-template-file ()
  "Return tool-specific template file."
  ;;TODO CREATE IF not found
  "template.jpg"
)
(defun org-sketch-tool-export-png ( input output )
  "Export/Convert native INPUT to OUTPUT image."
  (shell-command (concat "convert " input " " output " > /dev/null"))
)

;;--------------------------------
;;---- TOOL = xournalpp
(defun org-sketch-tool-command ()
  "Return tool-specific command."
  "./xournalpp-1.0.19-x86_64.AppImage "
)
(defun org-sketch-tool-ext ()
  "Return tool-specific file extension."
  ".xopp"
)
(defun org-sketch-tool-template-file ()
  "Return tool-specific template file."
  ;;TODO CREATE IF not found
  "template.xopp"
)
(defun org-sketch-tool-export-png ( input output )
  "Export/Convert native INPUT to OUTPUT image."
  (shell-command (concat (org-sketch-tool-command) " " input " -i " output " > /dev/null"))
)

;;--------------------------------
;; Interactive functions
(defun org-sketch-insert ( skname )
  "Insert sketch SKNAME at point."
  (interactive "sSketch Name: ") ;"sXXXX" prompts user for string param SKNAME
  (let (skname_ext skname_png skname_timestamp)
    (setq skname_png (concat skname ".png"))
    ;; Avoid overwriting silently
    (when (or (not (file-exists-p skname_png))
              (yes-or-no-p "Sketch exists! Overwrite? "))

      ;; Create sketch tool empty file from template
      (setq skname_ext (concat skname (org-sketch-tool-ext)))
      (setq skname_timestamp (concat skname ".timestamp"))
      (shell-command (concat "cp " (org-sketch-tool-template-file) " " skname_ext " > /dev/null"))

      ;; Create timestamp file afterwards, to detect if skname_ext is overwritten by tool
      (shell-command (concat "touch " skname_timestamp " > /dev/null"))

      ;; Open sketch tool on empty file and wait for close/exit
      (shell-command (concat (org-sketch-tool-command) skname_ext " > /dev/null"))

      ;; Check if tool file was saved, continue processing if it was, delete and exit if not
      (when (file-newer-than-file-p skname_ext skname_timestamp)
        ;; Export to .PNG
        (org-sketch-tool-export-png skname_ext skname_png)

        ;; Trim empty space
        (shell-command (concat "convert -trim " skname_png " " skname_png " > /dev/null"))

        ;; Insert org link
        ;; NOTE: We insert a plain bracket link [[file:skname_png]] insteaad
        ;; of a described link [[file:skname_png][description]] one so that
        ;; it can to be displayed with default org-toggle-inline-images
        ;; params. To display image links with description, a non-nil prefix
        ;; argument must be passed
        (org-insert-link nil (concat "file:" skname_png) nil)
        (message (concat "inserted sketch " skname) )
        )

      ;; Delete temp
      (shell-command (concat "rm " skname_ext " " skname_timestamp " > /dev/null"))
      )
    )
  )

;; TODO command, should be org-only or similar, define in init.el
(global-set-key (kbd "C-c s") 'org-sketch-insert)

(provide 'org-sketch)
;;; org-sketch.el ends here
