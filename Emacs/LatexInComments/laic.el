;;; laic --- Render LateX in comments -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Oscar Civit Flores
;; Author: Oscar Civit Flores
;; Keywords: LaTeX
;; Package-Version: ???????????
;; URL: https://github.com/??????????'
;; Version: 0.1
;; Package-Requires: ((emacs "27"))
;;
;;; Commentary:
;;
;; Provides functions to BLA BLA BLA
;;
;; Functionality:
;; - Calling the interactive function `laic-create-overlay-from-latex-forward' BLA BLA BLA
;; - Temporary files are stored in the customizable `org-sketch-output-dir'
;;   relative to current file path.
;;
;; Installation:
;; - Add (require 'laic) to your mode hook.
;; - Optionally add a local keybinding (suggested "C-c l") to call the provided
;;   functions `laic-create-overlay-from-latex-forward' and/or
;;   `laic-create-overlay-from-latex-inside'
;;
;;; License:
;;
;; This file is not a part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Code:

;;--------------------------------
;; Customization
;;--------------------------------

(defgroup laic nil
  "Render LaTeX blocks in comments."
  :group 'org) ;;TODO WHAT GROUP!!

(defcustom laic-output-dir "laic-tmp"
  "Default tmp output directory, relative to current file."
  :group 'laic
  :type 'directory)

(defcustom laic-command-convert "convert"
  "Command for ImageMagick convert."
  :group 'laic
  :type 'file)

(defcustom laic-command-dvipng "dvipng"
  "Command for dvipng."
  :group 'laic
  :type 'file)

;;--------------------------------
;; Internal implementation
;;--------------------------------

;; NOTE: comment-beginning returns nil if point not inside comment,
;; which seems to work, as opposed to (comment-only-p begin end),
;; which returns inconsistent results
(defun laic-is-point-in-comment-p()
  "Return non-nil if point is in comment, nil otherwise."
  (comment-normalize-vars)
  (not (eq (comment-beginning) nil)))

;; This would be the proper way, but requires finding physical screen size in
;; inches, on the XPS13 it's 170dpi... for now we just return 200dpi
;;  (/ (sqrt (+ (* (display-pixel-width) (display-pixel-width))
;;              (* (display-pixel-height) (display-pixel-height))))
;;     13.0)) ;TODO (physical-screen-diagonal-size-in-inches)))
(defun laic-get-dpi()
  "Return text DPI at point."
  200)

(defun laic-convert-color-to-dvipng-arg( color )
  "Convert Emacs COLOR string \"#RRGGBB\" to dvipng argument string."
  (let (rsub gsub bsub rnum gnum bnum)
       (setq rsub (substring color 1 3)) ;get RR
       (setq gsub (substring color 3 5)) ;get GG
       (setq bsub (substring color 5 7)) ;get BB
       (setq rnum (string-to-number rsub 16)) ;base 16
       (setq gnum (string-to-number gsub 16)) ;base 16
       (setq bnum (string-to-number bsub 16)) ;base 16
       ;; output "rgb r g b" with r,g,b \in [0..1]
       (format "rgb %f %f %f" (/ rnum 255.0) (/ gnum 255.0) (/ bnum 255.0))))

;;--------------------------------
;; OS-specific
;; NOTE: same as in org-sketch.el
;;--------------------------------
(defvar laic-OS-null-sink
  (cond ((eq system-type 'windows-nt)
         " > NUL 2> laic_errors.txt")
        (t ;;else 'gnu/linux, 'darwin, etc...
         " > /dev/null 2> laic_errors.txt")
        (t ""))
  "OS-specific commandline args to redirect output to null sink.")

(defun laic-OS-touch-file ( filename )
  "OS-specific touch FILENAME to create it or update its timestamp."
  (call-process "touch" nil nil nil filename))

(defun laic-OS-dir ( path )
  "OS-specific file-name-as-directory to convert PATH with \ to / if necessary."
  (cond ((eq system-type 'windows-nt)
         (subst-char-in-string ?/ ?\\ (file-name-as-directory path)))
        (t ;;else 'gnu/linux, 'darwin, etc...
         (file-name-as-directory path))))

;;--------------------------------
;; CONVERT
;;--------------------------------
(defun laic-convert ( args )
  "Run convert on ARGS argument string."
  (shell-command (concat laic-command-convert " " args laic-OS-null-sink)))

(defun laic-dvipng ( args )
  "Run dvipng on ARGS argument string."
  (shell-command (concat laic-command-dvipng " " args laic-OS-null-sink)))

(defun laic-create-image-from-latex ( code dpi bgcolor fgcolor )
  "Create an image from latex string with given dpi and bg/fg colors and return it."
  (interactive)

  ;; Ensure convert exists
  (unless (executable-find laic-command-convert)
    (error "Could not run ImageMagick convert as '%s', please install and/or customize laic-command-convert"
           laic-command-convert))

  ;; Create output dir if required
  (when (not (file-directory-p laic-output-dir))
    (make-directory laic-output-dir))

  ;; Try to create image
  (let (tmpfilename tmpfilename_tex tmpfilename_dvi tmpfilename_png prefix suffix fullcode img)

    ;; Create temporary filename using Unix epoch in seconds
    (setq tmpfilename (format "tmp-%d" (* 1000 (float-time))))
    (setq tmpfilename_tex (expand-file-name (concat (laic-OS-dir laic-output-dir) tmpfilename ".tex")))
    (setq tmpfilename_dvi (expand-file-name (concat (laic-OS-dir laic-output-dir) tmpfilename ".dvi")))
    (setq tmpfilename_png (expand-file-name (concat (laic-OS-dir laic-output-dir) tmpfilename ".png")))

    ;; Compose latex code into temporary file
    ;; TODO Add customizable list of packages
    (setq prefix "\\documentclass{article}\n\\pagestyle{empty}\n\\usepackage{amsmath,amsfonts,physics}\n\\begin{document}\n")
    (setq suffix "\\end{document}\n")
    (setq fullcode (concat prefix code "\n" suffix))
    (write-region fullcode nil tmpfilename_tex)

    ;; Run latex on tmp file with no output
    ;; TODO laic-latex command (also, instead of cd, could we force latex output to specific dir? -o maybe?)
    (shell-command (concat "cd " (laic-OS-dir laic-output-dir) "; latex " tmpfilename_tex laic-OS-null-sink))

    ;; Run dvipng
    ;;   -bg \"rgb 0.13 0.13 0.13\" using double quotes is required for Windows (Linux also supports single quotes '..')
    ;;   -bg Transparent works, but Emacs seems to ignore transparency
    ;; TODO:
    ;; - Retrieve DPI programmatically and pass as -D argument
    (laic-dvipng (concat " -D " (number-to-string dpi) ;DPI
                         " -bg \"" (laic-convert-color-to-dvipng-arg bgcolor) "\"" ;background color
                         " -fg \"" (laic-convert-color-to-dvipng-arg fgcolor) "\"" ;foreground color
                         " " tmpfilename_dvi ;input
                         " -o " tmpfilename_png)) ;output

    ;; Convert: Trim empty space
    (laic-convert (concat " -trim " tmpfilename_png " " tmpfilename_png))

    ;; Create image object, expand-file-name is requied
    (setq img (create-image tmpfilename_png))

    ;; Cleanup temporary files, but not .png required to insert/overlay later!
    (delete-file tmpfilename_tex)
    (delete-file tmpfilename_dvi)
    (delete-file (expand-file-name (concat (laic-OS-dir laic-output-dir) tmpfilename ".aux")))
    (delete-file (expand-file-name (concat (laic-OS-dir laic-output-dir) tmpfilename ".log")))

    ;; Return image
    img
    ))

;; TODO support \[\], \begin\end{equation,eqnarray,align} and starred versions
(defun laic-search-forward-latex-begin ()
  "Search forward latex block begin, return point."
  (search-forward "\\[" nil t))
(defun laic-search-forward-latex-end ()
  "Search forward latex block end, return point."
  (search-forward "\\]" nil t))
(defun laic-search-backward-latex-begin ()
  "Search backward latex block begin, return point."
  (search-backward "\\[" nil t))
(defun laic-search-backward-latex-end ()
  "Search backward latex block end, return point."
  (search-backward "\\]" nil t))

(defun laic-search-forward-latex-block ()
  "Find begin/end latex block forward."
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

;; TODO return overlay
(defun laic-create-overlay-from-latex-block ( begin end dpi bgcolor fgcolor )
  "Create latex overlay from buffer BEGIN..END region and return it."
  (interactive)
  (let (regioncode ov img)
    (setq regioncode (buffer-substring-no-properties begin end))
    (setq ov (make-overlay begin end))
    (setq img (laic-create-image-from-latex regioncode dpi bgcolor fgcolor))
    (overlay-put ov 'display img)))

;;--------------------------------
;; Region functionality
;;--------------------------------

(defun laic-gather-latex-blocks( begin end )
  "Gather all latex blocks inside BEGIN/END points, return as list of pairs."
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
  "Gather all latex blocks inside BEGIN/END points, return as list of pairs."
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

;; TODO Return listoverlays
(defun laic-create-overlays-from-blocks( listblocks )
  "Create overlays eack block in the LISTBLOCKS."
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

;;--------------------------------
;; Main interactive functionality
;;--------------------------------

;;;###autoload
(defun laic-create-overlay-from-latex-forward ()
  "Find next latex block, create overlay and place point at end."
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

;;;###autoload
;(defun laic-create-overlay-from-latex-inside ()
;  "If point is inside a latex block, create overlay and keep point unchanged."
;  (interactive)
;  (save-excursion
;    (let (pt beginpt endpt)
;      (setq pt (point)) ;get current point
;      (setq beginpt (laic-search-backward-latex-begin)) ;find prev begin
;      (when beginpt ;non-nil begin
;        (goto-char beginpt) ;move to begin
;        (setq endpt (laic-search-forward-latex-end)) ;find next end
;        (when (and endpt (< pt endpt)) ;non-nil end and after current
;          (laic-create-overlay-from-latex-block
;           beginpt endpt ;begin/end
;           (laic-get-dpi) ;dpi
;           (background-color-at-point) (foreground-color-at-point))))))) ;bg/fg colors

(defun laic-create-overlay-from-latex-inside ()
  "If point is inside a latex block, create overlay and keep point unchanged."
  (interactive)
  (let (pt beginpt endpt)
    (setq pt (point)) ;get current point
    (save-excursion
      (setq beginpt (laic-search-backward-latex-begin)) ;find prev begin
      (when beginpt ;non-nil begin
        (goto-char beginpt) ;move to begin
        (setq endpt (laic-search-forward-latex-end)))) ;find next end

    (when (and beginpt endpt (< pt endpt)) ;non-nil begin and end + end after current
      (laic-create-overlay-from-latex-block
       beginpt endpt ;begin/end
       (laic-get-dpi) ;dpi
       (background-color-at-point) (foreground-color-at-point)) ;bg/fg colors
      (goto-char endpt)))) ;move to end

;;;###autoload
(defun laic-create-overlay-from-latex-inside-or-forward ()
  "If point is inside a latex block create overlay its overlay, otherwise find next latex block."
  (interactive)
    (let (beginpt endpt)
      (save-excursion ;avoid changing point
        (setq beginpt (laic-search-backward-latex-begin))) ;find prev begin
      (when beginpt ;non-nil prev begin
        (save-excursion ;avoid changing point
          (setq endpt (laic-search-backward-latex-end)))) ;find prev end
      ;;if no begin, or prev end is before prev begin --> point is outside begin/end
      (cond ((or
              (eq beginpt nil)
              (and endpt (< beginpt endpt)))
             (laic-create-overlay-from-latex-forward))
            (t ;otherwise, point is inside begin/end
             (laic-create-overlay-from-latex-inside)))))

;; TODO Should only remove overlays added by laic, saved in a buffer-local variable laic--overlays?
;;;###autoload
(defun laic-remove-overlays ()
  "Remove all overlays."
  (interactive)
  (remove-overlays))

;;----------------------------------------------------------------
;; Buffer/Region interactive functionality
;;----------------------------------------------------------------

;;;###autoload
(defun laic-create-overlays-from-buffer()
  "Create image overlays for all blocks in the buffer."
  (interactive)
  (laic-create-overlays-from-blocks (laic-gather-latex-blocks (point-min) (point-max))))

;;;###autoload
(defun laic-create-overlays-from-buffer-comments()
  "Create image overlays for all blocks in the buffer comments."
  (interactive)
  (laic-create-overlays-from-blocks (laic-gather-latex-blocks-in-comments (point-min) (point-max))))

;;;###autoload
(defun laic-create-overlays-from-region()
  "Create image overlays for all blocks in the region."
  (interactive)
  (laic-create-overlays-from-blocks (laic-gather-latex-blocks (region-beginning) (region-end))))

;;;###autoload
(defun laic-create-overlays-from-region-comments()
  "Create image overlays for all blocks in active region comments."
  (interactive)
  (laic-create-overlays-from-blocks (laic-gather-latex-blocks-in-comments (region-beginning) (region-end))))

;;--------------------------------
;; Package setup
;;--------------------------------
(provide 'laic)
;;; laic.el ends here


;;--------------------------------
;; Keybindings
;;--------------------------------
;; (global-set-key (kbd "C-c l") 'laic-create-overlay-from-latex-forward)
;; (global-set-key (kbd "C-c i") 'laic-create-overlay-from-latex-inside)
;; (global-set-key (kbd "C-c r") 'laic-remove-overlays)
;;
;; (global-set-key (kbd "C-c L") 'laic-create-overlays-from-buffer)
;; (global-set-key (kbd "C-c R") 'laic-create-overlays-from-region)
;; (global-set-key (kbd "C-c C") 'laic-create-overlays-from-region-comments)
;; (global-set-key (kbd "C-c B") 'laic-create-overlays-from-buffer-comments)

;;----------------------------------------------------------------
;; Tests
;;
;; REQUIRES physics package (apt-get install texlive-science), see
;; https://ctan.org/pkg/physics and PDF manual linked there
;;----------------------------------------------------------------

;; \[ \bra{a} \ket{b} \]
;; \[ \dd[2]{x} \]
;; \[ \dv{f}{x} \qq{text} \pdv[2]{f}{x}{y} \qand \var{F} \]
;; \[ \div f \qand \curl f \qand \laplacian \]

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
