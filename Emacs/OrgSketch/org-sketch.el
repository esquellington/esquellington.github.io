;;; org-sketch --- Draw instant sketches and insert them as org-mode links -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2020 Oscar Civit Flores
;; Author: Oscar Civit Flores
;; Keywords: org
;; Package-Version: ???????????
;; URL: https://github.com/??????????'
;; Version: 0.1
;; Package-Requires: ((emacs "27"))
;;
;;; Commentary:
;;
;; Provides org-mode functions to insert sketches on at the point by
;; invoking an external drawing tool modally.
;;
;; Functionality:
;; - Calling the interactive function `org-sketch-insert' prompts for
;;   a sketch name and opens a drawing tool with a blank sketch
;;   template.When the tool is closed the sketch is converted to .PNG
;;   and inserted an org link at the point.
;; - Sketches are stored in the customizable `org-sketch-output-dir'
;;   relative to current org file path.
;; - The drawing tool can be customized with `org-sketch-tool'
;; - The sketch resolution can be customized with
;;   `org-sketch-default-output-width' and `org-sketch-default-output-height'
;;
;; Installation:
;; - Add (require 'org-sketch) to your org-mode-hook.
;; - Optionally add a local keybinding (suggested "C-c s") to call
;;   the provided function `org-sketch-insert' to insert a sketch
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
;; Dependencies
;;--------------------------------
(eval-when-compile (require 'subr-x)) ;for string-empty-p

;;--------------------------------
;; Customization
;;--------------------------------

(defgroup org-sketch nil
  "Draw sketches and insert them as org mode links."
  :group 'org)

(defcustom org-sketch-output-dir "sketches"
  "Default sketch output directory, relative to .org file."
  :group 'org-sketch
  :type 'directory)

(defcustom org-sketch-default-output-width 400
  "Default sketch width."
  :group 'org-sketch
  :type 'integer)

(defcustom org-sketch-default-output-height 300
  "Default sketch height."
  :group 'org-sketch
  :type 'integer)

;; TODO Some tools are OS-specific, try to add them conditionally
;; depending on system-type, or even build the choice list differently
;; per-OS and/or tool availability in the system
(defcustom org-sketch-tool nil
  "Default sketch tool."
  :group 'org-sketch
  :type '(choice (const :tag "Best Available" nil)
                 (const :tag "gimp" gimp)
                 (const :tag "gnome-paint" gnome-paint)
                 (const :tag "inkscape" inkscape)
                 (const :tag "mspaint" mspaint)
                 (const :tag "xournal++" xournalpp)))

(defcustom org-sketch-convert-command "convert"
  "Default command for ImageMagick convert."
  :group 'org-sketch
  :type 'file)

;;--------------------------------
;; Basic helpers
;;--------------------------------
(defun org-sketch-output-width ()
  "Compute sketch width, func so that it can be context-sensitive at point."
  org-sketch-default-output-width)

(defun org-sketch-output-height ()
  "Compute sketch height, func so that can be context-sensitive at point."
  org-sketch-default-output-height)

;;--------------------------------
;; OS-specific
;;--------------------------------
(defvar org-sketch-OS-null-sink
  (cond ((eq system-type 'windows-nt)
         " > NUL ")
        (t ;;else 'gnu/linux, 'darwin, etc...
         " > /dev/null ")
        (t ""))
  "OS-specific commandline args to redirect output to null sink.")

(defun org-sketch-OS-touch-file ( filename )
  "OS-specific touch FILENAME to create it or update its timestamp."
  (shell-command (concat "touch " filename " " org-sketch-OS-null-sink)))

(defun org-sketch-OS-dir ( path )
  "OS-specific file-name-as-directory to convert PATH with \ to / if necessary."
  (cond ((eq system-type 'windows-nt)
         (subst-char-in-string ?/ ?\\ (file-name-as-directory path)))
        (t ;;else 'gnu/linux, 'darwin, etc...
         (file-name-as-directory path))))

;;--------------------------------
;; CONVERT
;;--------------------------------
(defun org-sketch-convert ( args )
  "Run convert on ARGS argument string."
  (shell-command (concat org-sketch-convert-command " " args org-sketch-OS-null-sink)))

;;--------------------------------
;; TOOL: gimp
;;--------------------------------
(defvar org-sketch-tool-command--GIMP "gimp --no-splash" "GIMP command.")
(defvar org-sketch-tool-extension--GIMP ".xcf" "GIMP native file extension.")
(defun org-sketch-tool-template-file--GIMP ()
  "Return tool-specific template file."
  ;; Check empty template, create blank .XCF if none
  (let (template_file)
    (setq template_file_png (concat (org-sketch-OS-dir org-sketch-output-dir) "org-sketch-template--GIMP.png"))
    (setq template_file (concat (org-sketch-OS-dir org-sketch-output-dir) "org-sketch-template--GIMP.xcf"))
    (when (not (file-exists-p template_file))
      ;; Create blank .PNG and convert to .XCF (ImageMagick cannot create .XCF directly)
      (org-sketch-convert (concat "-size 900x450 xc:white " template_file_png))
      (org-sketch-convert (concat template_file_png " " template_file)))
    template_file))
(defun org-sketch-tool-edit--GIMP ( file )
  "Edit FILE with GIMP."
  (shell-command (concat org-sketch-tool-command--GIMP " " file org-sketch-OS-null-sink)))
(defun org-sketch-tool-export-png--GIMP ( input output )
  "Export/Convert native INPUT to OUTPUT .PNG image."
  ;; ImageMagick supports converting to/from .XCF
  (org-sketch-convert (concat input " " output)))

;;--------------------------------
;; TOOL: gnome-paint
;;--------------------------------
(defvar org-sketch-tool-command--GP "gnome-paint" "Gnome-paint command.")
(defvar org-sketch-tool-extension--GP ".png" "Gnome-paint native file extension.")
(defun org-sketch-tool-template-file--GP ()
  "Return tool-specific template file."
  ;; Check empty template, create blank .PNG if none
  (let (template_file)
    (setq template_file (concat (org-sketch-OS-dir org-sketch-output-dir) "org-sketch-template--GP.png"))
    (when (not (file-exists-p template_file))
      (org-sketch-convert (concat "-size 900x450 xc:white " template_file)))
    template_file))
(defun org-sketch-tool-edit--GP ( file )
  "Edit FILE with gnome-paint."
  (shell-command (concat org-sketch-tool-command--GP " " file org-sketch-OS-null-sink)))
(defun org-sketch-tool-export-png--GP ( input output )
  "Export/Convert native INPUT to OUTPUT .PNG image."
  (org-sketch-convert (concat input " " output)))

;;--------------------------------
;; TOOL: inkscape
;;--------------------------------
(defvar org-sketch-tool-command--INK "inkscape" "Inkscape command." )
(defvar org-sketch-tool-extension--INK ".svg" "Inkscape native file extension.")
(defun org-sketch-tool-template-file--INK ()
  "Return tool-specific template file."
  ;; Check empty template, create if not available
  ;; NOTE: Inkscape blank .svg is long and ugly, but there seems to be
  ;; no way to generate it automatically using inkscape commandline
  (let (template_file)
    (setq template_file (concat (org-sketch-OS-dir org-sketch-output-dir) "org-sketch-template--INK.svg"))
    (when (not (file-exists-p template_file))
      (shell-command (concat "echo '"
                             "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
                              <!-- Created with Inkscape (http://www.inkscape.org/) -->
                              <svg
                                 xmlns:dc=\"http://purl.org/dc/elements/1.1/\"
                                 xmlns:cc=\"http://creativecommons.org/ns#\"
                                 xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"
                                 xmlns:svg=\"http://www.w3.org/2000/svg\"
                                 xmlns=\"http://www.w3.org/2000/svg\"
                                 xmlns:sodipodi=\"http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd\"
                                 xmlns:inkscape=\"http://www.inkscape.org/namespaces/inkscape\"
                                 width=\"210mm\"
                                 height=\"297mm\"
                                 viewBox=\"0 0 744.09448819 1052.3622047\"
                                 id=\"svg2\"
                                 version=\"1.1\"
                                 inkscape:version=\"0.91 r13725\"
                                 sodipodi:docname=\"org-sketch-template--INK.svg\">
                                 <defs
                                    id=\"defs4\" />
                                 <sodipodi:namedview
                                    id=\"base\"
                                    pagecolor=\"#ffffff\"
                                    bordercolor=\"#666666\"
                                    borderopacity=\"1.0\"
                                    inkscape:pageopacity=\"1\"
                                    inkscape:pageshadow=\"2\"
                                    inkscape:zoom=\"0.35\"
                                    inkscape:cx=\"375\"
                                    inkscape:cy=\"528.57143\"
                                    inkscape:document-units=\"px\"
                                    inkscape:current-layer=\"layer1\"
                                    showgrid=\"false\"
                                    inkscape:window-width=\"1920\"
                                    inkscape:window-height=\"1056\"
                                    inkscape:window-x=\"0\"
                                    inkscape:window-y=\"24\"
                                    inkscape:window-maximized=\"1\" />
                                 <metadata
                                    id=\"metadata7\">
                                    <rdf:RDF>
                                     <cc:Work
                                        rdf:about=\"\">
                                       <dc:format>image/svg+xml</dc:format>
                                       <dc:type
                                          rdf:resource=\"http://purl.org/dc/dcmitype/StillImage\" />
                                       <dc:title></dc:title>
                                     </cc:Work>
                                    </rdf:RDF>
                                 </metadata>
                                 <g
                                    inkscape:label=\"Capa 1\"
                                    inkscape:groupmode=\"layer\"
                                    id=\"layer1\" />
                              </svg>"
                             "' > "
                             template_file ))
      )
    ;; Return
    template_file))
(defun org-sketch-tool-edit--INK ( file )
  "Edit FILE with Inkscape."
  (shell-command (concat org-sketch-tool-command--INK " " file org-sketch-OS-null-sink)))
(defun org-sketch-tool-export-png--INK ( input output )
  "Export/Convert native INPUT to OUTPUT .PNG image."
  ;; inkscape -e exports to .PNG
  (shell-command (concat (org-sketch-tool-command--INK) " " input " -e " output org-sketch-OS-null-sink)))

;;--------------------------------
;; TOOL: mspaint
;;--------------------------------
(defvar org-sketch-tool-command--MSP "mspaint.exe" "MS-Paint command.")
(defvar org-sketch-tool-extension--MSP ".png" "MS-Paint native file extension.")
(defun org-sketch-tool-template-file--MSP ()
  "Return tool-specific template file."
  ;; Check empty template, create blank .PNG if none
  (let (template_file)
    (setq template_file (concat (org-sketch-OS-dir org-sketch-output-dir) "org-sketch-template--MSP.png"))
    (when (not (file-exists-p template_file))
      (org-sketch-convert (concat "-size 900x450 xc:white " template_file)))
    template_file))
(defun org-sketch-tool-edit--MSP ( file )
  "Edit FILE with MS Paint."
  (shell-command (concat org-sketch-tool-command--MSP " " file org-sketch-OS-null-sink)))
(defun org-sketch-tool-export-png--MSP ( input output )
  "Export/Convert native INPUT to OUTPUT .PNG image."
  (org-sketch-convert (concat input " " output)))

;;--------------------------------
;; TOOL: xournalpp
;;--------------------------------
(defvar org-sketch-tool-command--XPP "~/Escriptori/esquellington/ext/bin/xournalpp-1.0.19-x86_64.AppImage" "Xournal++ command.")
(defvar org-sketch-tool-extension--XPP ".xopp" "Xournal++ native file extension.")
(defun org-sketch-tool-template-file--XPP ()
  "Return tool-specific template file."
  ;; Check empty template, create if not available
  (let (template_file)
    (setq template_file (concat (org-sketch-OS-dir org-sketch-output-dir) "org-sketch-template--XPP.xopp"))
    (when (not (file-exists-p template_file))
      ;; The .xopp files are XML compressed with gzip, so I
      ;; uncompressed an empty canvas .xopp and pasted the XML here
      ;; TODO could parametrize template sizes and colors, but better
      ;; keep it simple and have a unique base template and
      ;; resize/modify individual outputs instead
      (shell-command (concat "echo '"
                             "<?xml version=\"1.0\" standalone=\"no\"?>"
                             "<xournal creator=\"Xournal++ 1.0.19\" fileversion=\"4\">"
                             "<title>Xournal++ document - see https://github.com/xournalpp/xournalpp</title>"
                             "<preview/>"
                             "<page width=\"900.0\" height=\"450.0\">" ;;16/9
                             "<background type=\"solid\" color=\"#ffffffff\" style=\"plain\"/>"
                             "<layer/>"
                             "</page>"
                             "</xournal>"
                             "' | gzip > "
                             template_file ))
      )
    ;; Return
    template_file))
(defun org-sketch-tool-edit--XPP ( file )
  "Edit FILE with Xournal++."
  (shell-command (concat org-sketch-tool-command--XPP " " file org-sketch-OS-null-sink)))
(defun org-sketch-tool-export-png--XPP ( input output )
  "Export/Convert native INPUT to OUTPUT .PNG image."
  ;; xournalpp -i exports to .PNG
  (shell-command (concat (org-sketch-tool-command--XPP) " " input " -i " output org-sketch-OS-null-sink)))

;;--------------------------------
;; Interactive functions
;;--------------------------------
;;;###autoload
(defun org-sketch-insert ( skname &optional width height )
  "Insert sketch SKNAME at point, with optional WIDTH/HEIGHT in pixels."
  (interactive "sSketch Name:") ;"sXXXX" prompts user for string param SKNAME

  ;; Default params if empty/nil
  (when (string-empty-p skname) (setq skname "UNNAMED_SKETCH")) ;TODO find unique name
  (when (eq width nil) (setq width (org-sketch-output-width)))
  (when (eq height nil) (setq height (org-sketch-output-height)))

  ;; Select tool
  ;; TODO Try to do this only once on startup or similar
  (cond ((eq org-sketch-tool 'gimp)
         (setq org-sketch-tool-ext 'org-sketch-tool-extension--GIMP)
         (fset 'org-sketch-tool-template-file 'org-sketch-tool-template-file--GIMP)
         (fset 'org-sketch-tool-edit 'org-sketch-tool-edit--GIMP)
         (fset 'org-sketch-tool-export-png 'org-sketch-tool-export-png--GIMP)
         ;;(message "GIMP")
         )
        ((eq org-sketch-tool 'gnome-paint)
         (setq org-sketch-tool-ext 'org-sketch-tool-extension--GP)
         (fset 'org-sketch-tool-template-file 'org-sketch-tool-template-file--GP)
         (fset 'org-sketch-tool-edit 'org-sketch-tool-edit--GP)
         (fset 'org-sketch-tool-export-png 'org-sketch-tool-export-png--GP)
         ;;(message "GNOME-PAINT")
         )
        ((eq org-sketch-tool 'inkscape)
         (setq org-sketch-tool-ext 'org-sketch-tool-extension--INK)
         (fset 'org-sketch-tool-template-file 'org-sketch-tool-template-file--INK)
         (fset 'org-sketch-tool-edit 'org-sketch-tool-edit--INK)
         (fset 'org-sketch-tool-export-png 'org-sketch-tool-export-png--INK)
         ;;(message "INKSCAPE")
         )
        ((eq org-sketch-tool 'mspaint)
         (setq org-sketch-tool-ext 'org-sketch-tool-extension--MSP)
         (fset 'org-sketch-tool-template-file 'org-sketch-tool-template-file--MSP)
         (fset 'org-sketch-tool-edit 'org-sketch-tool-edit--MSP)
         (fset 'org-sketch-tool-export-png 'org-sketch-tool-export-png--MSP)
         ;;(message "MSPAINT")
         )
        ((eq org-sketch-tool 'xournalpp)
         (setq org-sketch-tool-ext org-sketch-tool-extension--XPP)
         (fset 'org-sketch-tool-template-file 'org-sketch-tool-template-file--XPP)
         (fset 'org-sketch-tool-edit 'org-sketch-tool-edit--XPP)
         (fset 'org-sketch-tool-export-png 'org-sketch-tool-export-png--XPP)
         ;;(message "XOURNAL++")
         )
        (t ;;default covers nil (best available) case too, by now
         (setq org-sketch-tool-ext 'org-sketch-tool-extension--GP)
         (fset 'org-sketch-tool-template-file 'org-sketch-tool-template-file--GP)
         (fset 'org-sketch-tool-edit 'org-sketch-tool-edit--GP)
         (fset 'org-sketch-tool-export-png 'org-sketch-tool-export-png--GP)
         ;;(message "DEFAULT"))
         ))

  (let (skname_tmp_ext skname_png skname_timestamp)

    ;; Create output dir if required
    (when (not (file-directory-p org-sketch-output-dir))
      (make-directory org-sketch-output-dir))

    ;; org-sketch-OS-dir is OS-independent and adds either / or \ as required
    (setq skname_png (concat (org-sketch-OS-dir org-sketch-output-dir) skname ".png"))

    ;; Avoid overwriting silently
    (when (or (not (file-exists-p skname_png))
              (yes-or-no-p "Sketch exists! Overwrite? "))

      ;; Create sketch tool empty file from template
      (setq skname_tmp_ext (concat (org-sketch-OS-dir org-sketch-output-dir) skname "_tmp" org-sketch-tool-ext))
      (setq skname_timestamp (concat (org-sketch-OS-dir org-sketch-output-dir) skname ".timestamp"))
      (copy-file (org-sketch-tool-template-file) skname_tmp_ext)

      ;; Create empty timestamp file afterwards, to detect if skname_tmp_ext is overwritten by tool
      (org-sketch-OS-touch-file skname_timestamp)

      ;; Open sketch tool on empty file and wait for close/exit
      (org-sketch-tool-edit skname_tmp_ext)

      ;; Check if tool-specific temp file was saved (thus newer than
      ;; timestamp) and continue processing if so
      (when (file-newer-than-file-p skname_tmp_ext skname_timestamp)

        ;; Export to .PNG
        (org-sketch-tool-export-png skname_tmp_ext skname_png)

        ;; Convert: Trim empty space and resize
        (org-sketch-convert (concat " -trim"
                                    " -resize " (format "%dx%d" width height)
                                    " " skname_png   ;input
                                    " " skname_png)) ;output

        ;; Insert org link
        ;; NOTE: We insert a plain bracket link [[file:skname_png]]
        ;; without description, insteaad of a described link
        ;; [[file:skname_png][description]] so that it can be
        ;; displayed with default org-toggle-inline-images params (C-c
        ;; C-v C-x). To display image links with description a non-nil
        ;; prefix argument must be passed (C-u C-c C-v C-x)
        (org-insert-link nil (concat "file:" skname_png) nil)
        )

      ;; Delete temp
      (delete-file skname_tmp_ext)
      (delete-file skname_timestamp)
      )
    )
  )

;;--------------------------------
;; Package setup
;;--------------------------------
(provide 'org-sketch)
;;; org-sketch.el ends here
