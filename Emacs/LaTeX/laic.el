; laic = latex-in-comments
;; TODO convert into proper package?
;; - Eval whole buffer with M-x eval-buffer

(defun laic-is-point-in-comment-p()
  ;; Return true if point is in comment, nil otherwise
  ;; NOTE: comment-beginning returns nil if point not inside comment,
  ;; which seems to work, as opposed to (comment-only-p begin end),
  ;; which returns inconsistent results
  (comment-normalize-vars)
  (not (eq (comment-beginning) nil)))

(defun laic-get-dpi()
  ;; Return text DPI at point
  200)
  ;; This is the proper way, but requires finding physical screen size
  ;; in inches, on the XPS13 it's 170dpi
;;  (/ (sqrt (+ (* (display-pixel-width) (display-pixel-width))
;;              (* (display-pixel-height) (display-pixel-height))))
;;     13.0)) ;TODO (physical-screen-diagonal-size-in-inches)))

(defun laic-convert-color-to-dvipng-arg( color )
  ;; Convert emacs color string "#RRGGBB" to dvipng argument string
  ;; "rgb r g b" with r,g,b \in [0..1]
  (let (rsub gsub bsub rnum gnum bnum)
       (setq rsub (substring color 1 3)) ;get RR
       (setq gsub (substring color 3 5)) ;get GG
       (setq bsub (substring color 5 7)) ;get BB
       ;;(format "%s %s %s" rsub gsub bsub)
       (setq rnum (string-to-number rsub 16)) ;base 16
       (setq gnum (string-to-number gsub 16)) ;base 16
       (setq bnum (string-to-number bsub 16)) ;base 16
       ;;(format "%d %d %d" rnum gnum bnum)
       (format "rgb %f %f %f" (/ rnum 255.0) (/ gnum 255.0) (/ bnum 255.0))))
;;TEST
;;(laic-convert-color-to-dvipng-arg "#112233")

;;----------------------------------------------
(defun laic-create-image-from-latex ( code dpi bgcolor fgcolor )
  ;; Create an image from latex string with given dpi and bg/fg colors and return it
  (interactive)
  (let (tmpfilename tmpfilename_tex tmpfilename_dvi tmpfilename_png prefix suffix fullcode img)
    ;; Create temporary filename using Uniz epoch in seconds
    (setq tmpfilename (format "tmp-%d" (* 1000 (float-time))))
    (setq tmpfilename_tex (expand-file-name (concat tmpfilename ".tex")))
    (setq tmpfilename_dvi (expand-file-name (concat tmpfilename ".dvi")))
    (setq tmpfilename_png (expand-file-name (concat tmpfilename ".png")))
    ;; Compose latex code into temporary file
    ;;(setq prefix "\\documentclass{article}\n\\pagestyle{empty}\n\\usepackage{amsmath,amsfonts}\n\\begin{document}\n")
    (setq prefix "\\documentclass{article}\n\\pagestyle{empty}\n\\usepackage{amsmath,amsfonts,physics}\n\\begin{document}\n")
    (setq suffix "\\end{document}\n")
    (setq fullcode (concat prefix code "\n" suffix))
    (write-region fullcode nil tmpfilename_tex)
    ;; Run latex on tmp file
    ;;   > /dev/null to avoid output buffer (> NUL in Windows)
    (shell-command (concat "latex " tmpfilename_tex " > /dev/null"))
    ;; Run dvipng
    ;;   -bg \"rgb 0.13 0.13 0.13\" using double quotes is required for Windows (Linux also supports single quotes '..'
    ;;   -bg Transparent works, but Emacs seems to ignore transparency
    ;;   > /dev/null to avoid output buffer in Linux (> NUL in Windows)
    ;; TODO:
    ;; - Retrieve DPI programmatically and pass as -D argument
    (shell-command (concat "dvipng"
                           " -D " (number-to-string dpi) ;DPI
                           " -bg \"" (laic-convert-color-to-dvipng-arg bgcolor) "\"" ;background color
                           " -fg \"" (laic-convert-color-to-dvipng-arg fgcolor) "\"" ;foreground color
                           " " tmpfilename_dvi ;input
                           " -o " tmpfilename_png ;output
                           " > /dev/null"))
    ;; Trim image
    ;;   > /dev/null to avoid output buffer
    (shell-command (concat "convert -trim "
                           tmpfilename_png ;input
                           " " tmpfilename_png ;output
                           " > /dev/null"))
    ;; Create image object, expand-file-name is requied
    (setq img (create-image (expand-file-name (concat tmpfilename ".png"))))
    ;; Cleanup temporary files
    ;;   TODO this would delete .png required to insert/overlay later! (shell-command (concat "rm " tmpfilename ".*"))
    (shell-command (concat "rm " tmpfilename ".tex " tmpfilename ".dvi " tmpfilename ".aux " tmpfilename ".log "))
    ;; Return image
    img
    ))

;; \[ \text{curl} \vec f = \nabla \times \vec f\]

;; TEST Insert image at point
(insert-image (laic-create-image-from-latex
               "$$\\alpha=\\theta$$"
               (laic-get-dpi) ;dpi
               (background-color-at-point)
               (foreground-color-at-point)))

;; TODO find first match in {$, $$, \[, \begin{REGEXP!}}
(defun laic-search-forward-latex-begin ()
  ;; Search forward latex block begin, return point
  (search-forward "\\[" nil t))
(defun laic-search-forward-latex-end ()
  ;; Search forward latex block end, return point
  (search-forward "\\]" nil t))
(defun laic-search-backward-latex-begin ()
  ;; Search backward latex block begin, return point
  (search-backward "\\[" nil t))
(defun laic-search-backward-latex-end ()
  ;; Search backward latex block end, return point
  (search-backward "\\]" nil t))

(defun laic-search-forward-latex-block ()
  ;; Find begin/end latex block forward
  (save-excursion
    (let (begin end)
      (setq begin (laic-search-forward-latex-begin))
      (setq end (laic-search-forward-latex-end))
      (cond ((or (eq begin nil) (eq end nil))
             (message "NOT FOUND")
             nil) ;returns nil
            (t
             ;;(message "FOUND")
             (list (- begin 2) end) ;returns (begin . end) points
             )))))

(defun laic-create-overlay-from-latex-block ( begin end dpi bgcolor fgcolor )
  ;; Create latex overlay from buffer begin..end region and return it
  (interactive)
  (let (regioncode ov img)
    (setq regioncode (buffer-substring-no-properties begin end))
    (setq ov (make-overlay begin end))
    (setq img (laic-create-image-from-latex regioncode dpi bgcolor fgcolor))
    (overlay-put ov 'display img)))

(defun laic-create-overlay-from-latex-forward ()
  ;; Find next latex block, create overlay and place point at end
  (interactive)
  (let (be)
    (setq be (laic-search-forward-latex-block))
    (cond ((eq be nil)
           (message "LaTeX block not found"))
          (t
           (goto-char (nth 0 be)) ;move to begin
           (laic-create-overlay-from-latex-block
            (nth 0 be) (nth 1 be) ;begin/end
            (laic-get-dpi) ;dpi
            (background-color-at-point) (foreground-color-at-point)) ;bg/fg colors
           (goto-char (nth 1 be)))))) ;move to end

(defun laic-create-overlay-from-latex-inside ()
  ;; If we're inside a latex block create overlay and place point at end
  (interactive)
  (save-excursion
    (let (pt beginpt endpt)
      (setq pt (point)) ;;get current point
      (setq beginpt (laic-search-backward-latex-begin)) ;;find prev begin
      (when beginpt ;;non-nil begin
        (goto-char beginpt) ;;move to begin
        (setq endpt (laic-search-forward-latex-end)) ;;find next end
        (when (and endpt (< pt endpt)) ;;non-nil end and after current
          (laic-create-overlay-from-latex-block
           beginpt endpt ;begin/end
           (laic-get-dpi) ;dpi
           (foreground-color-at-point) (background-color-at-point)) ;bg/fg colors TODO INVERTED to tell from -forward version
          )))))

;; TODO Should only remove overlays added by laic, saved in a buffer-local laic-overlays?
(defun laic-remove-overlays ()
  ;;Remove all overlays
  (interactive)
  (remove-overlays))

(message "Configuring keybindings")
(global-set-key (kbd "C-c r") 'laic-remove-overlays)
(global-set-key (kbd "C-c l") 'laic-create-overlay-from-latex-inside)
(global-set-key (kbd "C-c p") 'laic-create-overlay-from-latex-forward)

;;----------------------------------------------------------------
;; Tests
;;----------------------------------------------------------------

;;---- Simple blocks
;; IMPORTANT: Comment prefix does not matter here

;; Del operator
;; \[ \nabla = ( \frac{\partial}{\partial x}, \frac{\partial}{\partial y}, \frac{\partial}{\partial z} ) \]
;; Gradient
;; \[ \nabla f = ( \frac{\partial f}{\partial x}, \frac{\partial f}{\partial y}, \frac{\partial f}{\partial z} ) \]
;; Laplacian (Del squared)
;; \[ \Delta f = \nabla^2 f = \nabla \cdot \nabla f\]
;; Divergence
;; \[ \text{div} \vec f = \nabla \cdot \vec f \]
;; Curl
;; \[ \text{curl} \vec f = \nabla \times \vec f\]

;;---- Equation environments
;; IMPORTANT: Comment prefix
;; \begin{equation}
;; e^{i\pi} = -1
;; \end{equation}

;; List tests
;;(setq ll ())
;;(setq aa '(1 2))
;;(setq bb (list 3 4))
;;(setq cc (list 4 5))
;;(push aa ll)
;;(push bb ll)
;;(push cc ll)
;;(reverse ll)

(defun laic-gather-latex-blocks( begin end )
  ;; Gather all latex blocks inside begin/end points, return as list of pairs
  (save-excursion
    (let (lb be)
      (setq lb ()) ;empty
      (goto-char begin) ;goto of range
      (setq be (laic-search-forward-latex-block)) ;1st block
      (while (and be (<= (nth 1 be) end)) ;non-empty and be.end < end
        (push be lb) ;save block
        (goto-char (nth 1 be)) ;skip block
        (setq be (laic-search-forward-latex-block))) ;next block
      (reverse lb))))

(defun laic-gather-latex-blocks-in-comments( begin end )
  ;; Gather all latex blocks inside begin/end points, return as list of pairs
  (save-excursion
    (let (lb be)
      (setq lb ()) ;empty
      (goto-char begin) ;goto of range
      (setq be (laic-search-forward-latex-block)) ;1st block
      (while (and be (<= (nth 1 be) end)) ;non-empty and be.end < end
        (let ((b (nth 0 be))
              (e (nth 1 be)))
          ;;DEBUG (message "be = %d %d = %s" b e (buffer-substring-no-properties b e))
          (goto-char b) ;move to block begin
          ;;(when (comment-only-p b e) ;block is inside comment
          (when (laic-is-point-in-comment-p) ;block in comment
            ;;DEBUG (message "COMMENT in %d %d" b e)
            (push be lb)) ;save block
          (goto-char e) ;skip to block end
          (setq be (laic-search-forward-latex-block)))) ;next block
      (reverse lb))))

;(defun laic-test()
;  (interactive)
;  (laic-gather-latex-blocks-in-comments (region-beginning) (region-end)))
;(global-set-key (kbd "C-c o") 'laic-test)

;; (laic-gather-latex-blocks (point) (point-max))
;; \[ \text{curl} \vec f = \nabla \times \vec f\]
;; (laic-gather-latex-blocks (region-beginning) (region-end))

;; (point)fdfd(point)
;; \[ \vec f \]
;;fddf

(defun laic-create-overlays-from-blocks( listblocks )
  ;; Create overlays eack block in the list
  ;; TODO Return listoverlays
  (interactive)
  (save-excursion
    (let (lb be)
      (setq lb listblocks)
      (while lb
        (setq be (pop lb))
        (goto-char (nth 0 be)) ;move to begin
        (laic-create-overlay-from-latex-block
         (nth 0 be) (nth 1 be) ;begin/end
         (laic-get-dpi) ;dpi
         (background-color-at-point) (foreground-color-at-point)))))) ;bg/fg colors

;;----------------------------------------------
;; Top-level functions
;;----------------------------------------------
(defun laic-create-overlays-from-buffer()
  ;; Create image overlays for all blocks in the buffer
  (interactive)
  (laic-create-overlays-from-blocks (laic-gather-latex-blocks (point-min) (point-max))))

(defun laic-create-overlays-from-buffer-comments()
  ;; Create image overlays for all blocks in the buffer comments
  (interactive)
  (laic-create-overlays-from-blocks (laic-gather-latex-blocks-in-comments (point-min) (point-max))))

(defun laic-create-overlays-from-region()
  ;; Create image overlays for all blocks in the region
  (interactive)
  (laic-create-overlays-from-blocks (laic-gather-latex-blocks (region-beginning) (region-end))))

(defun laic-create-overlays-from-region-comments()
  ;; Create image overlays for all blocks in active region comments
  (interactive)
  (laic-create-overlays-from-blocks (laic-gather-latex-blocks-in-comments (region-beginning) (region-end))))

;; \[ \text{curl} \vec f = \nabla \times \vec f\]

(global-set-key (kbd "C-c L") 'laic-create-overlays-from-buffer)
(global-set-key (kbd "C-c R") 'laic-create-overlays-from-region)
(global-set-key (kbd "C-c C") 'laic-create-overlays-from-region-comments)
(global-set-key (kbd "C-c B") 'laic-create-overlays-from-buffer-comments)

;; \[ \text{curl} \vec f = \nabla \times \vec f\] fdfdfd

;; REQUIRES physics package (apt-get install texlive-science), see https://ctan.org/pkg/physics and PDF manual linked there
;; \[ \bra{a} \ket{b} \]
;; \[ \dd[2]{x} \]
;; \[ \dv{f}{x} \qq{text} \pdv[2]{f}{x}{y} \qand \var{F} \]
;; \[ \div f \qand \curl f \qand \laplacian \]
