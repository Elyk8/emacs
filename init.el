;; -*- lexical-binding: t; -*-

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)

(setq straight-use-package-by-default t)
(setq use-package-verbose nil)
;; Load the helper package for commands like `straight-x-clean-unused-repos'
(require 'straight-x)

;; Thanks but no thanks
(setq inhibit-startup-screen t)
(use-package gcmh
  :diminish gcmh-mode
  :config
  (setq gcmh-idle-delay 5
        gcmh-high-cons-threshold (* 16 1024 1024))  ; 16mb
  (gcmh-mode 1))

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-percentage 0.1))) ;; Default value for `gc-cons-percentage'

(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Emacs ready in %s with %d garbage collections."
                     (format "%.2f seconds"
                             (float-time
                              (time-subtract after-init-time before-init-time)))
                     gcs-done)))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculated variables ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Set `elk/computer' to 'gpd or 'laptop.
(let ((sys (system-name)))
  (if (string= sys "gpdskynet")
      (setq elk/computer 'gpd)
    (setq elk/computer 'laptop)))

;;;;;;;;;;;;;;;;;;;;;;
;; Custom variables ;;
;;;;;;;;;;;;;;;;;;;;;;

(defcustom elk-doom-modeline-text-height nil "My preferred modeline text height.")
(defcustom elk-text-height nil "My preferred default text height.")
(defcustom elk-larger-text nil "Larger text height.")
(defcustom elk-default-line-spacing 0 "Baseline line spacing.")

(if (eq elk/computer 'gpd)
    (setq elk-text-height 120
          elk-larger-text 140)
  (setq elk-text-height 140
        elk-larger-text 160))

(if (eq elk/computer 'gpd)
    (setq elk-doom-modeline-text-height 120)
  (setq elk-doom-modeline-text-height 140))

(setq elk/init.org (expand-file-name "init.org" user-emacs-directory))
(setq org-directory (file-truename "~/Documents/org"))
(setq org-roam-directory org-directory)

(defun elk/split-window-vertically-and-switch ()
  (interactive)
  (split-window-vertically)
  (other-window 1))

(defun elk/split-window-horizontally-and-switch ()
  (interactive)
  (split-window-horizontally)
  (other-window 1))

;; from https://gist.github.com/3402786
(defun elk/toggle-maximize-buffer ()
  "Maximize buffer"
  (interactive)
  (if (and (= 1 (length (window-list)))
           (assoc ?_ register-alist))
      (jump-to-register ?_)
    (progn
      (window-configuration-to-register ?_)
      (delete-other-windows))))

;;;###autoload
(defun +evil-shift-left ()
  "vnoremap < <gv"
  (interactive)
  (call-interactively #'evil-shift-left)
  (evil-normal-state)
  (evil-visual-restore))

;;;###autoload
(defun +evil-shift-right ()
  "vnoremap > >gv"
  (interactive)
  (call-interactively #'evil-shift-right)
  (evil-normal-state)
  (evil-visual-restore))

;;;###autoload
(defun +evil-org-< ()
  "vnoremap < <gv"
  (interactive)
  (call-interactively #'evil-org-<)
  (evil-normal-state)
  (evil-visual-restore))

;;;###autoload
(defun +evil-org-> ()
  "vnoremap > >gv"
  (interactive)
  (call-interactively #'evil-org->)
  (evil-normal-state)
  (evil-visual-restore))

(defun elk/org-agenda-caller (letter)
  "Calls a specific org agenda view specified by the letter argument."
  (interactive)
  (org-agenda nil letter))

(defun elk/org-temp-export-html (&optional arg)
  "Quick, temporary HTML export of org file.
If region is active, export region. Otherwise, export entire file.
If run with universal argument C-u, insert org options to make export very plain."
  (interactive "P")
  (save-window-excursion
	(if (not (use-region-p)) ;; If there is no region active, mark the whole buffer
		(mark-whole-buffer))
	(let ((old-buffer (current-buffer)) (beg (region-beginning)) (end (region-end)))
	  (with-temp-buffer
		(when (equal '(4) arg)
		  (insert "#+options: toc:nil date:nil author:nil num:nil title:nil tags:nil \
              	  todo:nil html-link-use-abs-url:nil html-postamble:nil html-preamble:nil html-scripts:nil tex:nil \
                   html-style:nil html5-fancy:nil tex:nil")) ;; If desired, insert these options for a plain export
		(insert "\n \n")
		(insert-buffer-substring old-buffer beg end) ;; Insert desired text to export into temp buffer
		(org-html-export-as-html) ;; Export to HTML
		(write-file (concat (make-temp-file "jibemacsorg") ".html")) ;; Write HTML to temp file
		(elk/open-buffer-file-mac) ;; Use my custom function to open the file (Mac only)
		(kill-this-buffer)))))

(defun elk/org-schedule-tomorrow ()
  "Org Schedule for tomorrow (+1d)."
  (interactive)
  (org-schedule t "+1d"))

(defun elk/org-set-startup-visibility ()
  (interactive)
  (org-set-startup-visibility))

(defun elk/org-refile-this-file ()
  "Org refile to only headers in current file, 3 levels."
  (interactive)
  (let ((org-refile-targets '((nil . (:maxlevel . 3)))))
	(org-refile)))

(defun elk/refresh-org-agenda-from-afar ()
  "Refresh org agenda from anywhere."
  (interactive)
  (if (get-buffer "*Org Agenda*")
	  (save-window-excursion
		(switch-to-buffer "*Org Agenda*")
		(org-agenda-redo))))

;; Modified from https://stackoverflow.com/questions/25930097/emacs-org-mode-quickly-mark-todo-as-done?rq=1
(defun elk/org-done-keep-todo ()
  "Mark an org todo item as done while keeping its former keyword intact, and archive.
For example, * TODO This item    becomes    * DONE TODO This item. This way I can see what
the todo type was if I look back through my archive files."
  (interactive)
  (let ((state (org-get-todo-state)) (tag (org-get-tags)) (todo (org-entry-get (point) "TODO"))
        post-command-hook)
    (if (not (eq state nil))
        (progn (org-todo "DONE")
			   (org-set-tags tag)
			   (beginning-of-line)
			   (forward-word)
			   (insert (concat " " todo))
			   (org-archive-subtree-default))
	  (user-error "Not a TODO."))
    (run-hooks 'post-command-hook)))

(defun elk/org-archive-ql-search ()
  "Input or select a tag to search in my archive files."
  (interactive)
  (let* ((choices '("bv" "sp" "ch" "cl" "es" "Robotics ec" "Weekly ec"))
		 (tag (completing-read "Tag: " choices)))
	(org-ql-search
	  ;; Recursively get all .org_archive files from my archive directory
	  (directory-files-recursively
	   (expand-file-name "org-archive" org-directory) ".org_archive")
	  ;; Has the matching tags (can be a property or just a tag) and is a todo - done or not
	  `(and (or (property "ARCHIVE_ITAGS" ,tag) (tags ,tag)) (or (todo) (done))))))

(defmacro spacemacs|org-emphasize (fname char)
  "Make function for setting the emphasis in org mode"
  `(defun ,fname () (interactive)
          (org-emphasize ,char)))

(defun org-syntax-convert-keyword-case-to-lower ()
  "Convert all #+KEYWORDS to #+keywords."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((count 0)
          (case-fold-search nil))
      (while (re-search-forward "^[ \t]*#\\+[A-Z_]+" nil t)
        (unless (s-matches-p "RESULTS" (match-string 0))
          (replace-match (downcase (match-string 0)) t)
          (setq count (1+ count))))
      (message "Replaced %d occurances" count))))

;; From doom emacs
(defun +org--toggle-inline-images-in-subtree (&optional beg end refresh)
  "Refresh inline image previews in the current heading/tree."
  (let* ((beg (or beg
                  (if (org-before-first-heading-p)
                      (save-excursion (point-min))
                    (save-excursion (org-back-to-heading) (point)))))
         (end (or end
                  (if (org-before-first-heading-p)
                      (save-excursion (org-next-visible-heading 1) (point))
                    (save-excursion (org-end-of-subtree) (point)))))
         (overlays (cl-remove-if-not (lambda (ov) (overlay-get ov 'org-image-overlay))
                                     (ignore-errors (overlays-in beg end)))))
    (dolist (ov overlays nil)
      (delete-overlay ov)
      (setq org-inline-image-overlays (delete ov org-inline-image-overlays)))
    (when (or refresh (not overlays))
      (org-display-inline-images t t beg end)
      t)))

(defun +org-get-todo-keywords-for (&optional keyword)
  "Returns the list of todo keywords that KEYWORD belongs to."
  (when keyword
    (cl-loop for (type . keyword-spec)
             in (cl-remove-if-not #'listp org-todo-keywords)
             for keywords =
             (mapcar (lambda (x) (if (string-match "^\\([^(]+\\)(" x)
                                     (match-string 1 x)
                                   x))
                     keyword-spec)
             if (eq type 'sequence)
             if (member keyword keywords)
             return keywords)))

;;;###autoload
(defun +org/dwim-at-point (&optional arg)
  "Do-what-I-mean at point.

If on a:
- checkbox list item or todo heading: toggle it.
- citation: follow it
- headline: cycle ARCHIVE subtrees, toggle latex fragments and inline images in
  subtree; update statistics cookies/checkboxes and ToCs.
- clock: update its time.
- footnote reference: jump to the footnote's definition
- footnote definition: jump to the first reference of this footnote
- timestamp: open an agenda view for the time-stamp date/range at point.
- table-row or a TBLFM: recalculate the table's formulas
- table-cell: clear it and go into insert mode. If this is a formula cell,
  recaluclate it instead.
- babel-call: execute the source block
- statistics-cookie: update it.
- src block: execute it
- latex fragment: toggle it.
- link: follow it
- otherwise, refresh all inline images in current tree."
  (interactive "P")
  (if (button-at (point))
      (call-interactively #'push-button)
    (let* ((context (org-element-context))
           (type (org-element-type context)))
      ;; skip over unimportant contexts
      (while (and context (memq type '(verbatim code bold italic underline strike-through subscript superscript)))
        (setq context (org-element-property :parent context)
              type (org-element-type context)))
      (pcase type
        ((or `citation `citation-reference)
         (org-cite-follow context arg))

        (`headline
         (cond ((memq (bound-and-true-p org-goto-map)
                      (current-active-maps))
                (org-goto-ret))
               ((and (fboundp 'toc-org-insert-toc)
                     (member "TOC" (org-get-tags)))
                (toc-org-insert-toc)
                (message "Updating table of contents"))
               ((string= "ARCHIVE" (car-safe (org-get-tags)))
                (org-force-cycle-archived))
               ((or (org-element-property :todo-type context)
                    (org-element-property :scheduled context))
                (org-todo
                 (if (eq (org-element-property :todo-type context) 'done)
                     (or (car (+org-get-todo-keywords-for (org-element-property :todo-keyword context)))
                         'todo)
                   'done))))
         ;; Update any metadata or inline previews in this subtree
         (org-update-checkbox-count)
         (org-update-parent-todo-statistics)
         (when (and (fboundp 'toc-org-insert-toc)
                    (member "TOC" (org-get-tags)))
           (toc-org-insert-toc)
           (message "Updating table of contents"))
         (let* ((beg (if (org-before-first-heading-p)
                         (line-beginning-position)
                       (save-excursion (org-back-to-heading) (point))))
                (end (if (org-before-first-heading-p)
                         (line-end-position)
                       (save-excursion (org-end-of-subtree) (point))))
                (overlays (ignore-errors (overlays-in beg end)))
                (latex-overlays
                 (cl-find-if (lambda (o) (eq (overlay-get o 'org-overlay-type) 'org-latex-overlay))
                             overlays))
                (image-overlays
                 (cl-find-if (lambda (o) (overlay-get o 'org-image-overlay))
                             overlays)))
           (+org--toggle-inline-images-in-subtree beg end)
           (if (or image-overlays latex-overlays)
               (org-clear-latex-preview beg end)
             (org--latex-preview-region beg end))))

        (`clock (org-clock-update-time-maybe))

        (`footnote-reference
         (org-footnote-goto-definition (org-element-property :label context)))

        (`footnote-definition
         (org-footnote-goto-previous-reference (org-element-property :label context)))

        ((or `planning `timestamp)
         (org-follow-timestamp-link))

        ((or `table `table-row)
         (if (org-at-TBLFM-p)
             (org-table-calc-current-TBLFM)
           (ignore-errors
             (save-excursion
               (goto-char (org-element-property :contents-begin context))
               (org-call-with-arg 'org-table-recalculate (or arg t))))))

        (`table-cell
         (org-table-blank-field)
         (org-table-recalculate arg)
         (when (and (string-empty-p (string-trim (org-table-get-field)))
                    (bound-and-true-p evil-local-mode))
           (evil-change-state 'insert)))

        (`babel-call
         (org-babel-lob-execute-maybe))

        (`statistics-cookie
         (save-excursion (org-update-statistics-cookies arg)))

        ((or `src-block `inline-src-block)
         (org-babel-execute-src-block arg))

        ((or `latex-fragment `latex-environment)
         (org-latex-preview arg))

        (`link
         (let* ((lineage (org-element-lineage context '(link) t))
                (path (org-element-property :path lineage)))
           (if (or (equal (org-element-property :type lineage) "img")
                   (and path (image-type-from-file-name path)))
               (+org--toggle-inline-images-in-subtree
                (org-element-property :begin lineage)
                (org-element-property :end lineage))
             (org-open-at-point arg))))

        (`paragraph
         (+org--toggle-inline-images-in-subtree))

        ((guard (org-element-property :checkbox (org-element-lineage context '(item) t)))
         (let ((match (and (org-at-item-checkbox-p) (match-string 1))))
           (org-toggle-checkbox (if (equal match "[ ]") '(16)))))

        (_
         (if (or (org-in-regexp org-ts-regexp-both nil t)
                 (org-in-regexp org-tsr-regexp-both nil  t)
                 (org-in-regexp org-link-any-re nil t))
             (call-interactively #'org-open-at-point)
           (+org--toggle-inline-images-in-subtree
            (org-element-property :begin context)
            (org-element-property :end context))))))))

(defun elk/rg ()
  "Allows you to select a folder to ripgrep."
  (interactive)
  (let ((current-prefix-arg 4)) ;; emulate C-u
    (call-interactively 'consult-ripgrep)))

(defun elk/load-theme (theme)
  "Enhance `load-theme' by first disabling enabled themes."
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme theme t)
  (set-face-attribute 'font-lock-comment-face nil :slant 'italic)
  (set-face-attribute 'font-lock-keyword-face nil :slant 'italic)
  (set-face-attribute 'font-lock-function-name-face nil :slant 'italic)
  (set-face-attribute 'font-lock-variable-name-face nil :slant 'italic))

(defun spacemacs/deft ()
  "Helper to call deft and then fix things so that it is nice and works"
  (interactive)
  (deft)
  ;; Hungry delete wrecks deft's DEL override
  (when (fboundp 'hungry-delete-mode)
    (hungry-delete-mode -1))
  ;; When opening it you always want to filter right away
  (evil-insert-state nil))

(defun elk/switch-to-scratch-buffer ()
  (interactive)
  (switch-to-buffer "*scratch*"))

(defun elk/save-and-close-this-buffer (buffer)
  "Saves and closes given buffer."
  (if (get-buffer buffer)
	  (let ((b (get-buffer buffer)))
		(save-buffer b)
		(k
;; found at http://emacswiki.org/emacs/KillingBuffers
(defun elk/kill-other-buffers (&optional arg)
  "Kill all other buffers.
If the universal prefix argument is used then will the windows too."
  (interactive "P")
  (when (yes-or-no-p (format "Killing all buffers except \"%s\"? "
                             (buffer-name)))
    (mapc 'kill-buffer (delq (current-buffer) (buffer-list)))
    (when (equal '(4) arg) (delete-other-windows))
    (message "Buffers deleted!")))ill-buffer b))))

(defun elk/edit-init ()
  (interactive)
  (find-file-existing elk/init.org))

;; Simple clip
(defun elk/paste-in-minibuffer ()
  (local-set-key (kbd "M-v") 'simpleclip-paste))

(defun elk/copy-whole-buffer-to-clipboard ()
  "Copy entire buffer to clipboard"
  (interactive)
  (mark-whole-buffer)
  (simpleclip-copy (point-min) (point-max))
  (deactivate-mark))

;; Spacemacs
(defun spacemacs/new-empty-buffer ()
  "Create a new buffer called untitled(<n>)"
  (interactive)
  (let ((newbuf (generate-new-buffer-name "*scratch*")))
    (switch-to-buffer newbuf)))

;; Make writing and scrolling faster
(defun locally-defer-font-lock ()
  "Set jit-lock defer and stealth, when buffer is over a certain size."
  (when (> (buffer-size) 50000)
    (setq-local jit-lock-defer-time 0.05
                jit-lock-stealth-time 1)))

(use-package transpose-frame
  :commands transpose-frame)

(use-package windresize
  :defer t)

(use-package i3wm-config-mode
  :defer t)

(defun elk/emacs-i3-windmove (dir)
  (let ((other-window (windmove-find-other-window dir)))
    (if (or (null other-window) (window-minibuffer-p other-window))
        (error dir)
      (windmove-do-window-select dir))))

(defun elk/emacs-i3-direction-exists-p (dir)
  (cl-some (lambda (dir)
          (let ((win (windmove-find-other-window dir)))
            (and win (not (window-minibuffer-p win)))))
        (pcase dir
          ('width '(left right))
          ('height '(up down)))))

(defun elk/emacs-i3-move-window (dir)
  (let ((other-window (windmove-find-other-window dir))
        (other-direction (elk/emacs-i3-direction-exists-p
                          (pcase dir
                            ('up 'width)
                            ('down 'width)
                            ('left 'height)
                            ('right 'height)))))
    (cond
     ((and other-window (not (window-minibuffer-p other-window)))
      (window-swap-states (selected-window) other-window))
     (other-direction
      (evil-move-window dir))
     (t (error dir)))))

(defun elk/emacs-i3-resize-window (dir kind value)
  (if (or (one-window-p)
          (not (elk/emacs-i3-direction-exists-p dir)))
      (- (error (concat (symbol-name kind) (symbol-name dir))))
    (setq value (/ value 2))
    (pcase kind
      ('shrink
       (pcase dir
         ('width
          (evil-window-decrease-width value))
         ('height
          (evil-window-decrease-height value))))
      ('grow
       (pcase dir
         ('width
          (evil-window-increase-width value))
         ('height
          (evil-window-increase-height value)))))))

(defun elk/emacs-i3-integration (command)
  (pcase command
    ((rx bos "focus")
     (elk/emacs-i3-windmove
      (intern (elt (split-string command) 1))))
    ((rx bos "move")
     (elk/emacs-i3-move-window
      (intern (elt (split-string command) 1))))
    ((rx bos "resize")
     (elk/emacs-i3-resize-window
       (intern (elt (split-string command) 2))
       (intern (elt (split-string command) 1))
       (string-to-number (elt (split-string command) 3))))
    ("layout toggle split" (transpose-frame))
    ("split v" (evil-window-split))
    ("split h" (evil-window-vsplit))
    ("kill" (evil-quit))
    (- (error command))))

;; Use no-littering to automatically set common paths to unclutter our emacs directory
(use-package no-littering
  :config
  ;; Stores annoying auto save files in one directory
  (setq auto-save-file-name-transforms
	    `((".*" ,(no-littering-expand-var-file-name "auto-save/") t))))

;; Keep customization settings in a temporary file (thanks Ambrevar!)
(setq custom-file
      (if (boundp 'server-socket-dir)
          (expand-file-name "custom.el" server-socket-dir)
        (expand-file-name (format "emacs-custom-%s.el" (user-uid)) temporary-file-directory)))
(when (file-exists-p custom-file)
  (load custom-file))

;; A cool mode to revert window configurations.
(winner-mode 1)

;; Revert buffers when the underlying file has changed
(global-auto-revert-mode 1)

;; Automatically revert buffers for changed files
(setq global-auto-revert-non-file-buffers t)

;; INTERACTION -----

;; When emacs asks for "yes" or "no", let "y" or "n" suffice
(setq use-short-answers t)

;; When I want to kill emacs, I really want to kill emacs
(setq confirm-kill-emacs nil)

;; Major mode of new buffers
(setq initial-major-mode 'lisp-interaction-mode)

;; WINDOW ----------

;; Don't resize the frames in steps; it looks weird, especially in tiling window
;; managers, where it can leave unseemly gaps.
(setq frame-resize-pixelwise t)

;; But do not resize windows pixelwise, this can cause crashes in some cases
;; where we resize windows too quickly.
(setq window-resize-pixelwise nil)

;; When opening a file (like double click) on Mac, use an existing frame
(setq ns-pop-up-frames nil)

;; Disable warning when setting up local variables
(setq enable-local-variables :all)

;; BOOKMARKS -------

;; Everytime a bookmark is changed, automatically save it
(setq bookmark-save-flag 1)

;; LINES -----------
(setq-default truncate-lines t)

(setq-default tab-width 4)

(setq-default evil-shift-width tab-width)

(setq-default fill-column 80)

;; Use spaces instead of tabs for indentation
(setq-default indent-tabs-mode nil)

(use-package paren
  ;; highlight matching delimiters
  :config
  (setq show-paren-delay 0.1
        show-paren-highlight-openparen t
        show-paren-when-point-inside-paren t
        show-paren-when-point-in-periphery t)
  (show-paren-mode 1))


(setq sentence-end-double-space nil) ;; Sentences end with one space

(setq bookmark-fontify nil)

;; SCROLLING ---------
;; (setq mouse-wheel-scroll-amount '(1 ((shift) . 5) ((control) . nil)))
(setq scroll-conservatively 101)

(setq ;; If the frame contains multiple windows, scroll the one under the cursor
 ;; instead of the one that currently has keyboard focus.
 mouse-wheel-follow-mouse 't
 ;; Completely disable mouse wheel acceleration to avoid speeding away.
 mouse-wheel-progressive-speed nil
 ;; The most important setting of all! Make each scroll-event move 2 lines at
 ;; a time (instead of 5 at default). Simply hold down shift to move twice as
 ;; fast, or hold down control to move 3x as fast. Perfect for trackpads.
 mouse-wheel-scroll-amount '(2 ((shift) . 4) ((control) . 6)))

(setq visible-bell nil) ;; Make it ring (so no visible bell) (default)
(setq ring-bell-function 'ignore) ;; BUT ignore it, so we see and hear nothing

(setq line-move-visual t) ;; C-p, C-n, etc uses visual lines

;; Blank scratch buffer
(setq initial-scratch-message nil)

;; Uses system trash rather than deleting forever
(setq delete-by-moving-to-trash t
      trash-directory "~/.local/share/Trash/files/")

;; Try really hard to keep the cursor from getting stuck in the read-only prompt
;; portion of the minibuffer.
(setq minibuffer-prompt-properties '(read-only t intangible t cursor-intangible t face minibuffer-prompt))
(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

;; Explicitly define a width to reduce the cost of on-the-fly computation
(setq-default display-line-numbers-width 3)

;; When opening a symlink that links to a file in a git repo, edit the file in the
;; git repo so we can use the Emacs vc features (like Diff) in the future
(setq vc-follow-symlinks t)

;; Avoid showing ridiculous symlinks in the modeline
;;(setq find-file-visit-truename t)

;; BACKUPS/LOCKFILES --------
;; Don't generate backups or lockfiles.
(setq create-lockfiles nil
      make-backup-files nil
      ;; But in case the user does enable it, some sensible defaults:
      version-control t     ; number each backup file
      backup-by-copying t   ; instead of renaming current file (clobbers links)
      delete-old-versions t ; clean up after itself
      kept-old-versions 5
      kept-new-versions 5
      backup-directory-alist (list (cons "." (concat user-emacs-directory "backup/"))))

(use-package recentf
  :config
  (setq ;;recentf-auto-cleanup 'never
   ;; recentf-max-menu-items 0
   recentf-max-saved-items 200)
  ;; Show home folder path as a ~
  (setq recentf-filename-handlers
        (append '(abbreviate-file-name) recentf-filename-handlers))

  (add-to-list 'recentf-exclude no-littering-var-directory)
  (add-to-list 'recentf-exclude no-littering-etc-directory)
  (recentf-mode))

(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)

(setq blink-cursor-interval 0.6)
(blink-cursor-mode 0)

;; Show current key-sequence in minibuffer ala 'set showcmd' in vim. Any
;; (setq echo-keystrokes 0.8)

(setq save-interprogram-paste-before-kill t
      apropos-do-all t
      mouse-yank-at-point t)

;; Make executable prefix to env
(setq executable-prefix-env t)

;; How thin the window should be to stop splitting vertically (I think)
(setq split-width-threshold 80)

(use-package which-key
  :diminish which-key-mode
  :defer 0
  :custom
  (which-key-idle-delay 0.2)
  (which-key-prefix-prefix "+")
  (which-key-allow-imprecise-window-fit t) ; Comment this if experiencing crashes
  (which-key-sort-order 'which-key-key-order-alpha)
  (which-key-sort-uppercase-first nil)
  (which-key-add-column-padding 1)
  (which-key-max-display-columns nil)
  (which-key-min-display-lines 4)
  (which-key-side-window-slot -10)
  :config
  (put 'which-key-replacement-alist 'initial-value which-key-replacement-alist)
  ;; general improvements to which-key readability
  (which-key-setup-side-window-bottom)
  (which-key-mode)
  (set-face-attribute 'which-key-local-map-description-face nil
                      :weight 'bold))

(use-package evil
  :init
  ;; Make horizontal movement cross lines
  (setq-default evil-cross-lines t)
  (setq evil-want-fine-undo t
        evil-want-keybinding nil
        evil-want-Y-yank-to-eol t
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-mode-line-format nil
        evil-undo-system 'undo-fu)
  ;; It's infuriating that innocuous "beginning of line" or "end of line"
  ;; errors will abort macros, so suppress them:
  (setq evil-kbd-macro-suppress-motion-error t)
  ;; Dont replace text in the kill ring when visual pasting
  (setq evil-kill-on-visual-paste nil)
  ;; more vim-like behavior
  (setq evil-symbol-word-search t
        evil-vsplit-window-right t
        evil-split-window-below t
        ;; Only do highlighting in selected window so that Emacs has less work
        ;; to do highlighting them all.
        evil-ex-interactive-search-highlight 'selected-window)
  :config
  (evil-mode 1)
  (evil-select-search-module 'evil-search-module 'evil-search)

  ;; stop copying each visual state move to the clipboard:
  ;; https://github.com/emacs-evil/evil/issues/336
  ;; grokked from:
  ;; http://stackoverflow.com/questions/15873346/elisp-rename-macro
  (advice-add #'evil-visual-update-x-selection :override #'ignore)

  (evil-set-initial-state 'dashboard-mode 'motion)
  (evil-set-initial-state 'debugger-mode 'motion)
  (evil-set-initial-state 'pdf-view-mode 'motion)
  (evil-set-initial-state 'bufler-list-mode 'emacs)

  (define-key evil-motion-state-map (kbd "SPC") nil)
  (define-key evil-motion-state-map (kbd "RET") nil)
  (define-key evil-motion-state-map (kbd "TAB") nil)

  ;; ----- Keybindings
  ;; I tried using evil-define-key for these. Didn't work.
  ;; (define-key evil-motion-state-map "/" 'swiper)
  (define-key evil-window-map "\C-q" 'evil-delete-buffer) ;; Maps C-w C-q to evil-delete-buffer (The first C-w puts you into evil-window-map)
  (define-key evil-window-map "\C-w" 'kill-this-buffer)
  (define-key evil-motion-state-map "\C-b" 'evil-scroll-up) ;; Makes C-b how C-u is

  ;; ----- Setting cursor colors
  (setq evil-emacs-state-cursor    '("#649bce" box))
  (setq evil-normal-state-cursor   '("#ebcb8b" box))
  (setq evil-operator-state-cursor '("#ebcb8b" hollow))
  (setq evil-visual-state-cursor   '("#677691" box))
  (setq evil-insert-state-cursor   '("#eb998b" (bar . 2)))
  (setq evil-replace-state-cursor  '("#eb998b" hbar))
  (setq evil-motion-state-cursor   '("#ad8beb" box))

  ;; ;; Evil-like keybinds for custom-mode-map
  ;; (evil-define-key nil 'custom-mode-map
  ;;   ;; motion
  ;;   (kbd "C-j") 'widget-forward
  ;;   (kbd "C-k") 'widget-backward
  ;;   "q" 'Custom-buffer-done)

  (evil-define-key 'motion 'dired-mode-map "Q" 'kill-this-buffer)
  (evil-define-key 'motion 'help-mode-map "q" 'kill-this-buffer)
  (evil-define-key 'motion 'calendar-mode-map "q" 'kill-this-buffer))

(use-package evil-collection
  :after evil
  :config
  (setq evil-collection-setup-minibuffer t)
  (evil-collection-init)
  ;; A few of my own overrides/customizations
  (evil-collection-define-key 'normal 'dired-mode-map
    (kbd "RET") 'dired-find-alternate-file))

(use-package evil-lion
  :config
  (setq evil-lion-left-align-key (kbd "g a"))
  (setq evil-lion-right-align-key (kbd "g A"))
  (evil-lion-mode))

(use-package evil-nerd-commenter
  :commands (evilnc-comment-operator
             evilnc-inner-comment
             evilnc-outer-commenter)
  :bind ([remap comment-line] . evilnc-comment-or-uncomment-lines))

(use-package evil-numbers
  :after evil
  :config
  (global-set-key (kbd "C-c +") 'evil-numbers/inc-at-pt)
  (global-set-key (kbd "C-c -") 'evil-numbers/dec-at-pt))

(use-package evil-snipe
  :diminish evil-snipe-mode
  :diminish evil-snipe-local-mode
  :after evil
  :init
  (setq evil-snipe-smart-case t
        evil-snipe-scope 'line
        evil-snipe-repeat-scope 'visible
        evil-snipe-char-fold t)
  :config
  (evil-snipe-mode 1))

(use-package evil-surround
  :after evil
  :config
  (with-eval-after-load 'general
    (general-define-key
     :states 'visual
     "s" 'evil-surround-region))
  (global-evil-surround-mode 1))

;; Allows you to use the selection for * and #
(use-package evil-visualstar
  :commands (evil-visualstar/begin-search
             evil-visualstar/begin-search-forward
             evil-visualstar/begin-search-backward)
  :init
  (evil-define-key* 'visual 'global
    "*" #'evil-visualstar/begin-search-forward
    "#" #'evil-visualstar/begin-search-backward))

(use-package general
  :config
  (general-create-definer elk-leader-def
    :states '(normal insert visual motion emacs)
    :prefix "SPC"
    :global-prefix "M-SPC")
  
  (general-create-definer elk-localleader-def
    :states '(normal visual motion emacs)
    :prefix ",")

  (general-evil-setup t)
  (add-hook 'after-init-hook #'general-auto-unbind-keys))

(elk-leader-def
  ;; Top level functions
  "/" '(elk/rg :which-key "ripgrep")
  ";" '(spacemacs/deft :which-key "deft")
  ":" '(projectile-find-file :which-key "p-find file")
  "." '(find-file :which-key "find file")
  "," '(consult-recent-file :which-key "recent files")
  "TAB" '(switch-to-prev-buffer :which-key "previous buffer")
  "SPC" '(execute-extended-command :which-key "M-x")
  "q" '(save-buffers-kill-terminal :which-key "quit emacs")
  "r" '(jump-to-register :which-key "registers"))

(elk-leader-def
  :infix "a"
  ;; "Applications"
  "" '(:which-key "applications")
  "o" '(org-agenda :which-key "org-agenda")
  ;; "m" '(mu4e :which-key "mu4e")
  "C" '(calc :which-key "calc")
  "c" '(org-capture :which-key "org-capture")
  ;; "qq" '(org-ql-view :which-key "org-ql-view")
  ;; "qs" '(org-ql-search :which-key "org-ql-search")
  "t" '(vterm-toggle :which-key "toggle vterm popup")

  "b" '(:which-key "browse url")
  "bf" '(browse-url-firefox :which-key "firefox")
  "bc" '(browse-url-chrome :which-key "chrome")
  ;; "bx" '(xwidget-webkit-browse-url :which-key "xwidget")

  "d" '(dired :which-key "dired-jump")
  "D" '(dired-recent-open :wk "dired history")

  "m" '(magit-status :wk "magit"))

(elk-leader-def
  :infix "p"
  "" '(:which-key "project")
  "f" 'projectile-find-file
  "s" 'projectile-switch-project
  "r" 'consult-ripgrep
  "c" 'projectile-compile-project
  "d" 'projectile-dired)

(elk-leader-def
 :infix "b"
 ;; Buffers
 "" '(:which-key "buffer")
 "b" '(consult-buffer :which-key "switch buffers")
 "d" '(evil-delete-buffer :which-key "delete buffer")
 "s" '(elk/switch-to-scratch-buffer :which-key "scratch buffer")
 "m" '(elk/kill-other-buffers :which-key "kill other buffers")
 "i" '(clone-indirect-buffer  :which-key "indirect buffer")
 "r" '(revert-buffer :which-key "revert buffer")
 "[" '(previous-buffer :which-key "prev. buffer")
 "]" '(next-buffer :which-key "prev. buffer"))

(elk-leader-def
 :infix "c"
 :keymaps 'prog-mode-map
 ;; Code
 "" '(:which-key "code")
 "b" 'xref-pop-marker-stack
 "c" 'compile
 "C" 'recompile
 "d" 'xref-find-definitions
 "f" 'format-all-buffer
 "j" 'consult-eglot-symbols
 "r" 'eglot-rename
 "w" 'delete-trailing-whitespace
 )

(elk-leader-def
 :infix "e"
  ;; Elyk
  "" '(:which-key "elyk")
  "h" '(nil :which-key "hydras")
  "hf" '(elk-hydra-variable-fonts/body :which-key "mixed-pitch face")
  "hw" '(elk-hydra-window/body :which-key "window control")

  ;; Files
  "f" '(nil :which-key "open files")
  "fa" '((lambda () (interactive) (find-file "~/org/agenda.org")) :which-key "agenda.org")
  "fe" '((lambda () (interactive) (find-file "~/org/elfeed.org")) :which-key "elfeed.org")
  "ff" '((lambda () (interactive) (find-file "~/.config/fontconfig/fonts.conf")) :which-key "fonts.conf")
  "fi" '((lambda () (interactive) (find-file "~/.config/i3/i3.org")) :which-key "i3.org")
  "fp" '((lambda () (interactive) (find-file "~/.config/polybar/polybar.org")) :which-key "polybar.org")
  "fs" '((lambda () (interactive) (find-file "~/.config/sxhkd/sxhkdrc.org")) :which-key "sxhkdrc.org")
  "fx" '((lambda () (interactive) (find-file "~/.config/x11/x.org")) :which-key "x.org")
)

(elk-leader-def
  :infix "f"
  ;; Files
  "" '(:which-key "files")
  "b" '(consult-bookmark :which-key "bookmarks")
  "f" '(find-file :which-key "find file")
  "n" '(spacemacs/new-empty-buffer :which-key "new file")
  "r" '(recentf-open-files :which-key "recent files")
  "R" '(rename-file :which-key "rename file")
  "s" '(save-buffer :which-key "save buffer")
  "S" '(evil-write-all :which-key "save all buffers")
  "u" '(sudo-edit :which-key "sudo this file")
  "U" '(sudo-edit-find-file :which-key "sudo find file"))
;;"fo" '(reveal-in-osx-finder :which-key "reveal in finder")
;;"fO" '(jib/open-buffer-file-mac :which-key "open buffer file")

(use-package helpful
  :general
  ([remap describe-function] 'helpful-function
   [remap describe-symbol] 'helpful-symbol
   [remap describe-variable] 'helpful-variable
   [remap describe-command] 'helpful-command
   [remap describe-key] 'helpful-key)
  :config
  (defvar read-symbol-positions-list nil))

(elk-leader-def
 :infix "h"
  ;; Help/emacs
  "" '(:which-key "help/emacs")

  "d" '(helpful-at-point :which-key "des. at point")
  "v" '(helpful-variable :which-key "des. variable")
  "b" '(embark-bindings :which-key "des. bindings")
  "M" '(helpful-mode :which-key "des. mode")
  "f" '(helpful-callable :which-key "des. func")
  "F" '(describe-face :which-key "des. face")
  "i" '(elk/edit-init :which-key "edit dotfile")
  "k" '(helpful-key :which-key "des. key")
  "o" '(helpful-symbol :which-key "des. sym")

  "m" '(nil :which-key "switch mode")
  "me" '(emacs-lisp-mode :which-key "elisp mode")
  "mo" '(org-mode :which-key "org mode")
  "mt" '(text-mode :which-key "text mode"))

(elk-leader-def
 :infix "n"
  "" '(:which-key "notes")
  "b" '(elk/org-roam-capture-inbox :which-key "dump brain")
  "f" '(org-roam-node-find :which-key "find node")
  "i" '(org-roam-node-insert-immediate :which-key "insert node")
  "I" '(org-roam-node-insert:which-key "insert node cap.")
  "n" '(org-roam-capture :which-key "capture to node")
  "p" '(elk/org-download-paste-clipboard :which-key "paste attach")
  "r" '(org-roam-buffer-toggle :which-key "toggle roam buffer")
  "t" '(elk/org-roam-capture-task :which-key "task to prog.")
  "w" '(org-roam-ui-mode :which-key "web graph")

  "d" '(:which-key "dailies")
  "d-" '(org-roam-dailies-find-directory :which-key "find-dir")
  "dd" '(org-roam-dailies-goto-date :which-key "goto-date")
  "dy" '(org-roam-dailies-goto-yesterday :which-key "goto-yesterday")
  "dm" '(org-roam-dailies-goto-tomorrow :which-key "goto-tomorrow")
  "dn" '(org-roam-dailies-goto-today :which-key "goto-today")

  "dD" '(org-roam-dailies-capture-date :which-key "capture-date")
  "dY" '(org-roam-dailies-capture-yesterday :which-key "capture-yesterday")
  "dM" '(org-roam-dailies-capture-tomorrow :which-key "capture-tomorrow")
  "dt" '(org-roam-dailies-capture-today :which-key "capture-today")
)

(elk-leader-def
 :infix "x"
  ;; Help/emacs
  "" '(:which-key "text")
  "c" '(elk/copy-whole-buffer-to-clipboard :which-key "copy whole buffer to clipboard")
  "r" '(anzu-query-replace :which-key "find and replace")
  "s" '(yas-insert-snippet :which-key "insert yasnippet"))

(elk-leader-def
 :infix "t"
  ;; Toggles
  "" '(:which-key "toggles")
  "/" '(comment-line :which-key "comment")
  "T" '(toggle-truncate-lines :which-key "truncate lines")
  "a" '(mixed-pitch-mode :which-key "variable pitch mode")
  "c" '(visual-fill-column-mode :which-key "visual fill column mode")
  "I" '(toggle-input-method :which-key "toggle input method")
  "n" '(display-line-numbers-mode :which-key "display line numbers")
  "r" '(display-fill-column-indicator-mode :which-key "fill column indicator")
  "R" '(read-only-mode :which-key "read only mode")
  "t" '(load-theme :which-key "load theme")
  "v" '(visual-line-mode :which-key "visual line mode")
  "w" '(writeroom-mode :which-key "writeroom-mode"))

(elk-leader-def
 :infix "w"
  ;; Windows
  "" '(:which-key "window")
  "m" '(elk/toggle-maximize-buffer :which-key "maximize buffer")
  "n" '(make-frame :which-key "make frame")
  "d" '(evil-window-delete :which-key "delete window")
  "s" '(elk/split-window-vertically-and-switch :which-key "split below")
  "v" '(elk/split-window-horizontally-and-switch :which-key "split right")
  "r" '(elk-hydra-window/body :which-key "hydra window")
  "l" '(evil-window-right :which-key "evil-window-right")
  "h" '(evil-window-left :which-key "evil-window-left")
  "j" '(evil-window-down :which-key "evil-window-down")
  "k" '(evil-window-up :which-key "evil-window-up")
  "z" '(text-scale-adjust :which-key "text zoom"))

(elk-localleader-def
  :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
  "g" '(consult-imenu :which-key "imenu")
  "c" '(check-parens :which-key "check parens")
  "i" '(indent-region :which-key "indent-region")
  
  "e" '(nil :which-key "eval")
  "es" '(eval-last-sexp :which-key "eval-sexp")
  "er" '(eval-region :which-key "eval-region")
  "eb" '(eval-buffer :which-key "eval-buffer")
  )

(general-def
  :states 'normal
  :keymaps 'org-mode-map
  "t" 'org-todo
  [return] '+org/dwim-at-point
  "<return>" '+org/dwim-at-point
  )

(general-def
  :states '(normal insert emacs)
  :keymaps 'org-mode-map
  "M-[" 'org-metaleft
  "M-]" 'org-metaright
  "C-M-=" 'ap/org-count-words
  "s-r" 'org-refile
  )

;; Org-src - when editing an org source block
(elk-localleader-def
  :keymaps 'org-src-mode-map
  "b" '(nil :which-key "org src")
  "bc" 'org-edit-src-abort
  "bb" 'org-edit-src-exit
  )

(with-eval-after-load 'org
  (define-key org-src-mode-map (kbd "C-c C-c") #'org-edit-src-exit))

(elk-localleader-def
  :keymaps 'org-mode-map ;; Available in org mode, org agenda
  "." '(consult-org-heading :which-key "consult-org-heading")
  "A" '(org-archive-subtree-default :which-key "org-archive")
  "a" '(org-agenda :which-key "org agenda")
  "C" '(org-capture :which-key "org-capture")
  "s" '(org-schedule :which-key "schedule")
  "S" '(elk/org-schedule-tomorrow :which-key "schedule")
  "d" '(org-deadline :which-key "deadline")
  "g" '(org-goto :which-key "goto heading")
  "t" '(org-tag :which-key "set tags")
  "o" '(elk/org-download-paste-clipboard :which-key "paste attach")
  "p" '(org-set-property :which-key "set property")
  "r" '(elk/org-refile-this-file :which-key "refile in file")
  "e" '(org-export-dispatch :which-key "export org")
  "B" '(org-toggle-narrow-to-subtree :which-key "toggle narrow to subtree")
  "V" '(elk/org-set-startup-visibility :which-key "startup visibility")
  "H" '(org-html-convert-region-to-html :which-key "convert region to html")

  ;; org-babel
  "b" '(:which-key "babel")
  "bt" '(org-babel-tangle :which-key "org-babel-tangle")
  "bb" '(org-edit-special :which-key "org-edit-special")
  "bc" '(org-edit-src-abort :which-key "org-edit-src-abort")
  "bk" '(org-babel-remove-result-one-or-many :which-key "org-babel-remove-result-one-or-many")

  "x" '(:which-key "text")
  "xb" (spacemacs|org-emphasize elk/org-bold ?*)
  "xc" (spacemacs|org-emphasize elk/org-code ?~)
  "xi" (spacemacs|org-emphasize elk/org-italic ?/)
  "xs" (spacemacs|org-emphasize elk/org-strike-through ?+)
  "xu" (spacemacs|org-emphasize elk/org-underline ?_)
  "xv" (spacemacs|org-emphasize elk/org-verbose ?~) ;; I realized that ~~ is the same and better than == (Github won't do ==)

  ;; insert
  "i" '(:which-key "insert")

  "it" '(:which-key "tables")
  "itt" '(org-table-create :which-key "create table")
  "itl" '(org-table-insert-hline :which-key "table hline")

  "il" '(org-insert-link :which-key "link")

  ;; clocking
  "c" '(:which-key "clocking")
  "ci" '(org-clock-in :which-key "clock in")
  "co" '(org-clock-out :which-key "clock out")
  "cj" '(org-clock-goto :which-key "jump to clock")
  )

(general-define-key
 :keymaps 'org-agenda-mode-map
 :states 'motion
 ;; motion keybindings
 "j" 'org-agenda-next-line
 "k" 'org-agenda-previous-line
 "c" 'org-agenda-capture
 "gj" 'org-agenda-next-item
 "gk" 'org-agenda-previous-item
 "gH" 'evil-window-top
 "gM" 'evil-window-middle
 "gL" 'evil-window-bottom
 "C-j" 'org-agenda-next-item
 "C-k" 'org-agenda-previous-item
 "[[" 'org-agenda-earlier
 "]]" 'org-agenda-later

 ;; actions
 "t" 'org-agenda-todo
 "r" 'org-agenda-refile
 "d" 'org-agenda-deadline
 "s" 'org-agenda-schedule

 ;; goto
 "." 'org-agenda-goto-today

 ;; refresh
 "gr" 'org-agenda-redo
 "gR" 'org-agenda-redo-all

 ;; quit
 (kbd "<escape>") 'org-agenda-quit)

;; All-mode keymaps
(general-def
  :keymaps 'override
  
  ;; Emacs --------
  "M-x" 'execute-extended-command
  "??" 'evil-window-next ;; option-s
  "??" 'other-frame ;; option-shift-s
  ;;"C-S-B" 'switch-to-buffer
  "C-s" 'consult-line
  ;"C-S" 'consult-line-multi
  "???" 'consult-buffer ;; option-b
  "s-o" 'elk-hydra-window/body
  
  ;; Editing ------
  "M-v" 'simpleclip-paste
  "M-V" 'evil-paste-after ;; shift-paste uses the internal clipboard
  "M-c" 'simpleclip-copy
  "M-u" 'capitalize-dwim ;; Default is upcase-dwim
  "M-U" 'upcase-dwim ;; M-S-u (switch upcase and capitalize)
  "C-c u" 'elk/split-and-close-sentence
  
  ;; Zooming ------
  "C--" '(lambda () (interactive) (text-scale-decrease 1)) ;; Decrease font size
  "C-=" '(lambda () (interactive) (text-scale-increase 1)) ;; Increase font size
  
  ;; Utility ------
  "C-c c" 'org-capture
  "C-c a" 'org-agenda)

;; Non-insert mode keymaps
(general-def
  :states '(normal visual motion)
  "gc" 'comment-line
  "H" 'evil-first-non-blank
  "L" 'evil-org-end-of-line
  "k" 'evil-previous-visual-line ;; I prefer visual line navigation
  "j" 'evil-next-visual-line ; ""
  "|" '(lambda () (interactive) (org-agenda nil "n")) ;; Opens my n custom org-super-agenda view
  "C-|" '(lambda () (interactive) (org-agenda nil "m")) ;; Opens my m custom org-super-agenda view
  )

;; Only visual mode keymaps
(general-def
  :states '(visual)
  :keymaps 'override
  "<" '+evil-shift-left  ;; vnoremap < <gv
  ">" '+evil-shift-right ;; vnoremap > >gv
  )

;; Insert keymaps
;; Many of these are emulating standard Emacs bindings in Evil insert mode, such as C-a, or C-e.
(general-def
  :states '(insert)
  "C-SPC" 'completion-at-point
  "C-a" 'evil-beginning-of-visual-line
  "C-e" 'evil-end-of-visual-line
  "C-S-a" 'evil-beginning-of-line
  "C-S-e" 'evil-end-of-line
  "C-n" 'evil-next-visual-line
  "C-p" 'evil-previous-visual-line
  )

(use-package hydra
  :defer t)

;; This Hydra lets me swich between variable pitch fonts. It turns off mixed-pitch
;; WIP
(defhydra elk-hydra-variable-fonts (:pre (mixed-pitch-mode 0)
                                     :post (mixed-pitch-mode 1))
  ("t" (set-face-attribute 'variable-pitch nil :family "Times New Roman" :height 160) "Times New Roman")
  ("g" (set-face-attribute 'variable-pitch nil :family "EB Garamond" :height 160 :weight 'normal) "EB Garamond")
  ;; ("r" (set-face-attribute 'variable-pitch nil :font "Roboto" :weight 'medium :height 160) "Roboto")
  ("n" (set-face-attribute 'variable-pitch nil :slant 'normal :weight 'normal :height 160 :width 'normal :foundry "nil" :family "Nunito") "Nunito")
  )

;; All-in-one window managment. Makes use of some custom functions,
;; `ace-window' (for swapping), `windmove' (could probably be replaced
;; by evil?) and `windresize'.
;; inspired by https://github.com/jmercouris/configuration/blob/master/.emacs.d/hydra.el#L86
(defhydra elk-hydra-window (:hint nil)
   "
Movement      ^Split^            ^Switch^        ^Resize^
----------------------------------------------------------------
_h_  <        _s_ vertical       _b_uffer        _<left>_  <
_l_  >        _v_ horizontal     _f_ind file     _<down>_  ???
_k_  ???        _m_aximize         s_w_ap          _<up>_    ???
_j_  ???        _c_lose            _[_backward     _<right>_ >
_q_uit        _e_qualize         _]_forward      ^
^             ^                  _K_ill          ^
^             ^                  ^               ^
"
   ;; Movement
   ("h" windmove-left)
   ("j" windmove-down)
   ("k" windmove-up)
   ("l" windmove-right)

   ;; Split/manage
   ("s" elk/split-window-vertically-and-switch)
   ("v" elk/split-window-horizontally-and-switch)
   ("c" evil-window-delete)
   ("d" evil-window-delete)
   ("m" delete-other-windows)
   ("e" balance-windows)

   ;; Switch
   ("b" consult-buffer)
   ("f" find-file)
   ("P" projectile-find-file)
   ("w" ace-swap-window)
   ("[" previous-buffer)
   ("]" next-buffer)
   ("K" kill-this-buffer)

   ;; Resize
   ("<left>" windresize-left)
   ("<right>" windresize-right)
   ("<down>" windresize-down)
   ("<up>" windresize-up)

   ("q" nil))

;; If a popup does happen, don't resize windows to be equal-sized
(setq even-window-sizes nil)

(use-package corfu
  :general
  (:keymaps 'corfu-map
            :states 'insert
            "C-n" #'corfu-next
            "C-p" #'corfu-previous
            "<escape>" #'corfu-quit
            "<return>" #'corfu-insert
            "C-d" #'corfu-show-documentation
            "C-l" #'corfu-show-location)
  ;; Optional customizations
  :custom
  (corfu-auto nil)        ; Only use `corfu' when calling `completion-at-point' or
                                        ; `indent-for-tab-command'
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  (corfu-separator ?\s)          ;; Orderless field separator
  (corfu-min-width 80)
  (corfu-max-width corfu-min-width)       ; Always have the same width
  (corfu-count 14)
  (corfu-scroll-margin 4)

  ;; `nil' means to ignore `corfu-separator' behavior, that is, use the older
  ;; `corfu-quit-at-boundary' = nil behavior. Set this to separator if using
  ;; `corfu-auto' = `t' workflow (in that case, make sure you also set up
  ;; `corfu-separator' and a keybind for `corfu-insert-separator', which my
  ;; configuration already has pre-prepared). Necessary for manual corfu usage with
  ;; orderless, otherwise first component is ignored, unless `corfu-separator'
  ;; is inserted.
  (corfu-quit-at-boundary nil)
  (corfu-preselect-first t)        ; Preselect first candidate?

  (defun corfu-enable-always-in-minibuffer ()
    "Enable Corfu in the minibuffer if Vertico/Mct are not active."
    (unless (or (bound-and-true-p mct--active) ; Useful if I ever use MCT
                (bound-and-true-p vertico--input))
      (setq-local corfu-auto nil)       ; Ensure auto completion is disabled
      (corfu-mode 1)))
  (add-hook 'minibuffer-setup-hook #'corfu-enable-always-in-minibuffer 1)

  ;; Enable Corfu only for certain modes.
  ;; :hook ((prog-mode . corfu-mode)
  ;;        (shell-mode . corfu-mode)
  ;;        (eshell-mode . corfu-mode))
  :init
  (global-corfu-mode 1))

;; Add icons to corfu
(use-package kind-icon
  :after corfu
  :custom
  (kind-icon-use-icons t)
  (kind-icon-default-face 'corfu-default) ; Have background color be the same as `corfu' face background
  (kind-icon-blend-background nil)  ; Use midpoint color between foreground and background colors ("blended")?
  (kind-icon-blend-frac 0.08)

  ;; NOTE 2022-02-05: `kind-icon' depends `svg-lib' which creates a cache
  ;; directory that defaults to the `user-emacs-directory'. Here, I change that
  ;; directory to a location appropriate to `no-littering' conventions, a
  ;; package which moves directories of other packages to sane locations.
  (svg-lib-icons-dir (no-littering-expand-var-file-name "svg-lib/cache/")) ; Change cache dir

  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package corfu-doc
  :after corfu
  :hook (corfu-mode . corfu-doc-mode)
  :general (:keymaps 'corfu-map
                     ;; This is a manual toggle for the documentation popup.
                     [remap corfu-show-documentation] #'corfu-doc-toggle ; Remap the default doc command
                     ;; Scroll in the documentation window
                     "M-n" #'corfu-doc-scroll-up
                     "M-p" #'corfu-doc-scroll-down)
  :custom
  (corfu-doc-delay 0.5)
  (corfu-doc-max-width 70)
  (corfu-doc-max-height 20)

  ;; NOTE 2022-02-05: I've also set this in the `corfu' use-package to be
  ;; extra-safe that this is set when corfu-doc is loaded. I do not want
  ;; documentation shown in both the echo area and in the `corfu-doc' popup.
  (corfu-echo-documentation nil))

;; Add extensions
(use-package cape
  ;; Bind dedicated completion commands
  ;; Alternative prefix keys: C-c p, M-p, M-+, ...
  ;; :bind (("C-c p p" . completion-at-point) ;; capf
  ;;        ("C-c p t" . complete-tag)        ;; etags
  ;;        ("C-c p d" . cape-dabbrev)        ;; or dabbrev-completion
  ;;        ("C-c p h" . cape-history)
  ;;        ("C-c p f" . cape-file)
  ;;        ("C-c p k" . cape-keyword)
  ;;        ("C-c p s" . cape-symbol)
  ;;        ("C-c p a" . cape-abbrev)
  ;;        ("C-c p i" . cape-ispell)
  ;;        ("C-c p l" . cape-line)
  ;;        ("C-c p w" . cape-dict)
  ;;        ("C-c p \\" . cape-tex)
  ;;        ("C-c p _" . cape-tex)
  ;;        ("C-c p ^" . cape-tex)
  ;;        ("C-c p &" . cape-sgml)
  ;;        ("C-c p r" . cape-rfc1345))
  :init
  ;; Add `completion-at-point-functions', used by `completion-at-point'.
  (add-to-list 'completion-at-point-functions #'cape-file)
  ;;(add-to-list 'completion-at-point-functions #'cape-dabbrev)
  ;;(add-to-list 'completion-at-point-functions #'cape-history)
  (add-to-list 'completion-at-point-functions #'cape-keyword)
  (add-to-list 'completion-at-point-functions #'cape-tex)
  ;;(add-to-list 'completion-at-point-functions #'cape-sgml)
  ;;(add-to-list 'completion-at-point-functions #'cape-rfc1345)
  ;;(add-to-list 'completion-at-point-functions #'cape-abbrev)
  ;;(add-to-list 'completion-at-point-functions #'cape-ispell)
  ;;(add-to-list 'completion-at-point-functions #'cape-dict)
  (add-to-list 'completion-at-point-functions #'cape-symbol)
  ;;(add-to-list 'completion-at-point-functions #'cape-line)
  )

(defun elk/minibuffer-backward-kill (arg)
  "When minibuffer is completing a file name delete up to parent
folder, otherwise delete a word"
  (interactive "p")
  (if minibuffer-completing-file-name
      ;; Borrowed from https://github.com/raxod502/selectrum/issues/498#issuecomment-803283608
      (if (string-match-p "/." (minibuffer-contents))
          (zap-up-to-char (- arg) ?/)
        (delete-minibuffer-contents))
    (backward-kill-word arg)))

(use-package vertico
  ;; Special recipe to load extensions conveniently
  :general
  (:keymaps 'vertico-map
            "<tab>" #'vertico-insert  ; Insert selected candidate into text area
            "<escape>" #'abort-minibuffers ; Close minibuffer
            "<return>" #'exit-minibuffer
            "C-j" #'vertico-next
            "C-k" #'vertico-previous
            "C-f" #'vertico-exit
            ;; NOTE 2022-02-05: Cycle through candidate groups
            "C-M-n" #'vertico-next-group
            "C-M-p" #'vertico-previous-group)
  (:keymaps 'minibuffer-local-map
            "M-h" #'elk/minibuffer-backward-kill)
  :custom
  (vertico-resize nil)
  (vertico-count 13)
  (vertico-cycle t)
  (completion-in-region-function
   (lambda (&rest args)
     (apply (if vertico-mode
                #'consult-completion-in-region
              #'completion--in-region)
            args)))
  :init
  (vertico-mode)
  :config
  ;; Cleans up path when moving directories with shadowed paths syntax, e.g.
  ;; cleans ~/foo/bar/// to /, and ~/foo/bar/~/ to ~/.
  (add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy)
  ;;(add-hook 'minibuffer-setup-hook #'vertico-repeat-save)

  ;; These commands are problematic and automatically show the *Completions* buffer
  (advice-add #'tmm-add-prompt :after #'minibuffer-hide-completions)
  )

;; A few more useful configurations...
(use-package emacs
  :straight (:type built-in)
  :init
  ;; TAB cycle if there are only few candidates
  (setq completion-cycle-threshold 3)

  ;; Emacs 28: Hide commands in M-x which do not apply to the current mode.
  ;; Corfu commands are hidden, since they are not supposed to be used via M-x.
  ;; (setq read-extended-command-predicate
  ;;       #'command-completion-default-include-p)

  ;; Make TAB like all other editors
  (setq tab-always-indent 'nil)

  ;; Add prompt indicator to `completing-read-multiple'.
  ;; We display [CRM<separator>], e.g., [CRM,] if the separator is a comma.
  (defun crm-indicator (args)
    (cons (format "[CRM%s] %s"
                  (replace-regexp-in-string
                   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
                   crm-separator)
                  (car args))
          (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

  ;; Do not allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

  ;; Emacs 28: Hide commands in M-x which do not work in the current mode.
  ;; Vertico commands are hidden in normal buffers.
  (setq read-extended-command-predicate
        #'command-completion-default-include-p)

  ;; Enable recursive minibuffers
  (setq enable-recursive-minibuffers t)
 
  :custom
  (help-window-select t "Switch to help buffers automatically"))

;; Example configuration for Consult
(use-package consult
  :defer t
  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)
  :init
  (general-def
    [remap apropos]                       #'consult-apropos
    [remap bookmark-jump]                 #'consult-bookmark
    [remap evil-show-marks]               #'consult-mark
    ;;[remap evil-show-jumps]               #'+vertico/jump-list
    [remap evil-show-registers]           #'consult-register
    [remap goto-line]                     #'consult-goto-line
    [remap imenu]                         #'consult-imenu
    [remap locate]                        #'consult-locate
    [remap load-theme]                    #'consult-theme
    [remap man]                           #'consult-man
    [remap recentf-open-files]            #'consult-recent-file
    [remap switch-to-buffer]              #'consult-buffer
    [remap switch-to-buffer-other-window] #'consult-buffer-other-window
    [remap switch-to-buffer-other-frame]  #'consult-buffer-other-frame
    [remap yank-pop]                      #'consult-yank-pop)
  ;;[remap persp-switch-to-buffer]        #'+vertico/switch-workspace-buffer

  (advice-add #'multi-occur :override #'consult-multi-occur)

  (setq xref-show-xrefs-function       #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Optionally configure the register formatting. This improves the register
  ;; preview for `consult-register', `consult-register-load',
  ;; `consult-register-store' and the Emacs built-ins.
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)

  ;; Optionally tweak the register preview window.
  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config
  (setq consult-project-root-function #'projectile-root-local
        consult-narrow-key "<"
        consult-line-numbers-widen t
        consult-async-min-input 2
        consult-async-refresh-delay  0.15
        consult-async-input-throttle 0.2
        consult-async-input-debounce 0.1)

  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key (kbd "M-."))
  ;; (setq consult-preview-key (list (kbd "<S-down>") (kbd "<S-up>")))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize consult-theme
                     :preview-key '(:debounce 0.2 any)
                     consult-ripgrep consult-git-grep consult-grep
                     consult-bookmark consult-recent-file consult-xref
                     consult--source-bookmark consult--source-recent-file
                     consult--source-project-recent-file
                     :preview-key (kbd "C-SPC"))

  (defvar +vertico--consult-org-source
    (list :name     "Org Buffer"
          :category 'buffer
          :narrow   ?o
          :hidden   t
          :face     'consult-buffer
          :history  'buffer-name-history
          :state    #'consult--buffer-state
          :new
          (lambda (name)
            (with-current-buffer (get-buffer-create name)
              (insert "#+title: " name "\n\n")
              (org-mode)
              (consult--buffer-action (current-buffer))))
          :items
          (lambda ()
            (mapcar #'buffer-name
                    (if (featurep 'org)
                        (org-buffer-list)
                      (seq-filter
                       (lambda (x)
                         (eq (buffer-local-value 'major-mode x) 'org-mode))
                       (buffer-list)))))))
  (add-to-list 'consult-buffer-sources '+vertico--consult-org-source 'append))

(use-package consult-dir
  :bind (([remap list-directory] . consult-dir)
         :map vertico-map
         ("C-x C-d" . consult-dir)
         ("C-x C-j" . consult-dir-jump-file)))

(use-package consult-flycheck
  :after (consult flycheck))

(use-package consult-org-roam
  :after org-roam
  :hook (org-roam-mode . consult-org-roam-mode)
  :config
  (setq consult-org-roam-grep-func #'consult-ripgrep)
  ;; Eventually suppress previewing for certain functions
  (consult-customize
   consult-org-roam-forward-links
   :preview-key (kbd "M-."))
  :bind
  ("C-c n e" . consult-org-roam-file-find)
  ("C-c n b" . consult-org-roam-backlinks)
  ("C-c n r" . consult-org-roam-search))

(use-package embark
  :bind
  (("C-." . embark-act)         ;; pick some comfortable binding
   ("C-;" . embark-dwim)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'

  :init
  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  :config

  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; Consult users will also want the embark-consult package.
(use-package embark-consult
  :after (embark consult)
  :demand t ; only necessary if you have the hook below
  ;; if you want to have consult previews as you move around an
  ;; auto-updating embark collect buffer
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package wgrep
  :commands wgrep-change-to-wgrep-mode
  :config (setq wgrep-auto-save-buffer t))

(use-package orderless
  :config
  (setq completion-styles '(orderless flex)
        completion-category-defaults nil
        completion-category-overrides '((file (styles . (orderless flex)))))
  (set-face-attribute 'completions-first-difference nil :inherit nil))

(use-package savehist
  :config
  (setq savehist-save-minibuffer-history t
        savehist-autosave-interval nil     ; save on kill only
        savehist-additional-variables
        '(kill-ring                        ; persist clipboard
          register-alist                   ; persist macros
          mark-ring global-mark-ring       ; persist marks
          search-ring regexp-search-ring)) ; persist searches
  (savehist-mode))

(use-package marginalia
  :after vertico
  :custom
  (marginalia-annotators '(marginalia-annotaators-heavy marginalia-annotators-light nil))
  :init
  (marginalia-mode)
  :config
  (add-hook 'marginalia-mode-hook #'all-the-icons-completion-marginalia-setup))

(use-package projectile
  :commands (projectile-find-file
             projectile-project-root
             projectile-project-name
             projectile-project-p
             projectile-locate-dominating-file
             projectile-relevant-known-projects)
  :bind(("C-M-p" . projectile-find-file)
        ("C-c p" . projectile-command-map))
  :init
  (setq projectile-cache-file (concat no-littering-var-directory "projectile.cache")
        ;; Auto-discovery is slow to do by default. Better to update the list
        ;; when you need to (`projectile-discover-projects-in-search-path').
        projectile-auto-discover nil
        projectile-globally-ignored-files '(".DS_Store" "TAGS")
        projectile-globally-ignored-file-suffixes '(".elc" ".pyc" ".o")
        projectile-kill-buffers-filter 'kill-only-files
        projectile-ignored-projects '("~/")
        ;; The original `projectile-default-mode-line' can be expensive over
        ;; TRAMP, so we gimp it in remote buffers.
        projectile-mode-line-function
        (lambda ()
          (if (file-remote-p default-directory) ""
            (projectile-default-mode-line))))

  (global-set-key [remap evil-jump-to-tag] #'projectile-find-tag)
  (global-set-key [remap find-tag]         #'projectile-find-tag)

  :config
  (projectile-mode +1)
  (setq projectile-completion-system 'default)

  ;; In the interest of performance, we reduce the number of project root marker
  ;; files/directories projectile searches for when resolving the project root.
  (setq projectile-project-root-files-bottom-up
        (append '(".projectile"  ; projectile's root marker
                  ".git")        ; Git VCS root dir
                (when (executable-find "hg")
                  '(".hg"))      ; Mercurial VCS root dir
                (when (executable-find "bzr")
                  '(".bzr")))    ; Bazaar VCS root dir
        ;; This will be filled by other modules. We build this list manually so
        ;; projectile doesn't perform so many file checks every time it resolves
        ;; a project's root -- particularly when a file has no project.
        projectile-project-root-files '()
        projectile-project-root-files-top-down-recurring '("Makefile"))

  (push (abbreviate-file-name no-littering-etc-directory) projectile-globally-ignored-directories)
  (push (abbreviate-file-name no-littering-var-directory) projectile-globally-ignored-directories)

    ;; Per-project compilation buffers
  (setq compilation-buffer-name-function #'projectile-compilation-buffer-name
        compilation-save-buffers-predicate #'projectile-current-project-buffer-p)
  ;; Treat current directory in dired as a "file in a project" and track it
  (add-hook 'dired-before-readin-hook #'projectile-track-known-projects-find-file-hook)

  )

(use-package smartparens
  :diminish smartparens-mode
  :defer 1
  :config
  ;; Load default smartparens rules for various languages
  (require 'smartparens-config)
  (setq sp-max-prefix-length 25)
  (setq sp-max-pair-length 4)
  (setq sp-highlight-pair-overlay nil
        sp-highlight-wrap-overlay nil
        sp-highlight-wrap-tag-overlay nil)

  (with-eval-after-load 'evil
    (setq sp-show-pair-from-inside t)
    (setq sp-cancel-autoskip-on-backward-movement nil)
    (setq sp-pair-overlay-keymap (make-sparse-keymap)))

  (let ((unless-list '(sp-point-before-word-p
                       sp-point-after-word-p
                       sp-point-before-same-p)))
    (sp-pair "'"  nil :unless unless-list)
    (sp-pair "\"" nil :unless unless-list))

  ;; In lisps ( should open a new form if before another parenthesis
  (sp-local-pair sp-lisp-modes "(" ")" :unless '(:rem sp-point-before-same-p))

  ;; Don't do square-bracket space-expansion where it doesn't make sense to
  (sp-local-pair '(emacs-lisp-mode org-mode markdown-mode gfm-mode)
                 "[" nil :post-handlers '(:rem ("| " "SPC")))

  (dolist (brace '("(" "{" "["))
    (sp-pair brace nil
             :post-handlers '(("||\n[i]" "RET") ("| " "SPC"))
             ;; Don't autopair opening braces if before a word character or
             ;; other opening brace. The rationale: it interferes with manual
             ;; balancing of braces, and is odd form to have s-exps with no
             ;; whitespace in between, e.g. ()()(). Insert whitespace if
             ;; genuinely want to start a new form in the middle of a word.
             :unless '(sp-point-before-word-p sp-point-before-same-p)))
  (smartparens-global-mode t))

(use-package flyspell
  :defer t
  :init
  (setq flyspell-issue-welcome-flag nil)
  :config
  (add-to-list 'ispell-skip-region-alist '("~" "~"))
  (add-to-list 'ispell-skip-region-alist '("=" "="))
  (add-to-list 'ispell-skip-region-alist '("^#\\+BEGIN_SRC" . "^#\\+END_SRC"))
  (add-to-list 'ispell-skip-region-alist '("^#\\+BEGIN_EXPORT" . "^#\\+END_EXPORT"))
  (add-to-list 'ispell-skip-region-alist '("^#\\+BEGIN_EXPORT" . "^#\\+END_EXPORT"))
  (add-to-list 'ispell-skip-region-alist '(":\\(PROPERTIES\\|LOGBOOK\\):" . ":END:"))

  (dolist (mode '(org-mode-hook
                  mu4e-compose-mode-hook))
    (add-hook mode (lambda () (flyspell-mode 1))))
  :general ;; Switches correct word from middle click to right click
  (:keymaps 'flyspell-mouse-map
            "<mouse-3>" #'flyspell-correct-word
            "<mouse-2>" nil)
  (:keymaps 'evil-motion-state-map
            "zz" #'ispell-word)
  )

(use-package flyspell-correct
  :after flyspell
  :bind (:map flyspell-mode-map ("C-;" . flyspell-correct-wrapper)))

(use-package flyspell-correct-popup
  :after flyspell-correct)

(use-package evil-anzu
  :after evil
  :config
  (global-anzu-mode 1))

(use-package simpleclip
  :config
  (simpleclip-mode 1))
;; Allows pasting in minibuffer with M-v
(add-hook 'minibuffer-setup-hook 'elk/paste-in-minibuffer)

(use-package undo-fu)

(use-package undo-fu-session
  :config
  (setq undo-fu-session-incompatible-files '("/COMMIT_EDITMSG\\'" "/git-rebase-todo\\'")))

(global-undo-fu-session-mode)

(use-package dired
  :straight (:type built-in)
  :hook (dired-mode . dired-async-mode)
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :init
  (setq dired-dwim-target t  ; suggest a target for moving/copying intelligently
        dired-hide-details-hide-symlink-targets nil
        ;; don't prompt to revert, just do it
        dired-auto-revert-buffer #'dired-buffer-stale-p
        ;; Always copy/delete recursively
        dired-recursive-copies  'always
        dired-recursive-deletes 'top
        ;; Ask whether destination dirs should get created when copying/removing files.
        dired-create-destination-dirs 'ask)
  :config
  (setq dired-listing-switches "-agho --group-directories-first"
        dired-omit-files "^\\.[^.].*"
        dired-omit-verbose nil
        dired-hide-details-hide-symlink-targets nil
        delete-by-moving-to-trash t)

  (evil-collection-define-key 'normal 'dired-mode-map
    "h" 'dired-single-up-directory
    "H" 'dired-omit-mode
    "l" 'dired-single-buffer))

(use-package dired-single
 :after dired)

(use-package dired-recent
  :after dired
  :commands dired-recent-open
  :config
  (dired-recent-mode)
  (general-define-key
   :keymaps 'dired-recent-mode-map
   "C-x C-d" nil))

(use-package all-the-icons-dired
  :hook (dired-mode . all-the-icons-dired-mode)
  :config
  (setq all-the-icons-dired-monochrome nil))

(use-package dired-open
  :after dired
  :config
  ;; Doesn't work as expected!
  ;;(add-to-list 'dired-open-functions #'dired-open-xdg t)
 (setq dired-open-extensions '(("gif" . "open")
                              ("jpg" . "open")
                              ("png" . "open")
                              ("mkv" . "open")
                              ("mp4" . "open"))))

(use-package dired-hide-dotfiles
  :after dired
  :hook (dired-mode . dired-hide-dotfiles-mode)
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "H" 'dired-hide-dotfiles-mode))

(use-package diredfl
  :after dired
  :config
  (diredfl-global-mode 1))

(use-package dired-sidebar
  :after dired
  :commands (dired-sidebar-toggle-sidebar)
  :init
  (general-define-key
   :keymaps '(normal override global)
   "C-n" 'dired-sidebar-toggle-sidebar)
  :config
  (defun elk/dired-sidebar-setup ()
    (toggle-truncate-lines 1)
    (display-line-numbers-mode -1)
    (setq-local dired-subtree-use-backgrounds nil))

  (general-define-key
   :keymaps 'dired-sidebar-mode-map
   :states '(normal emacs)
   "l" 'dired-sidebar-find-file
   "h" 'dired-sidebar-up-directory
   "=" 'dired-narrow)
  (add-hook 'dired-sidebar-mode-hook #'elk/dired-sidebar-setup))

(use-package super-save
  :diminish super-save-mode
  :defer 2
  :config
  (setq super-save-auto-save-when-idle t)
  (setq super-save-idle-duration 10) ;; after 5 seconds of not typing autosave
  (setq super-save-triggers ;; Functions after which buffers are saved (switching window, for example)
        '(evil-window-next evil-window-prev balance-windows other-window))
  (super-save-mode +1))

;; After super-save autosaves, wait __ seconds and then clear the buffer. I don't like
;; the save message just sitting in the echo area.
(defun elk-clear-echo-area-timer ()
  (run-at-time "2 sec" nil (lambda () (message " "))))

(advice-add 'super-save-command :after 'elk-clear-echo-area-timer)

(use-package saveplace
  :init (setq save-place-limit 100)
  :config (save-place-mode))

(use-package tempel
  ;; Require trigger prefix before template name when completing.
  ;; :custom
  ;; (tempel-trigger-prefix "<")
  :bind (("M-+" . tempel-complete) ;; Alternative tempel-expand
         ("M-*" . tempel-insert))
  :init
  ;; Setup completion at point
  (defun tempel-setup-capf ()
    ;; Add the Tempel Capf to `completion-at-point-functions'.
    ;; `tempel-expand' only triggers on exact matches. Alternatively use
    ;; `tempel-complete' if you want to see all matches, but then you
    ;; should also configure `tempel-trigger-prefix', such that Tempel
    ;; does not trigger too often when you don't expect it. NOTE: We add
    ;; `tempel-expand' *before* the main programming mode Capf, such
    ;; that it will be tried first.
    (setq-local completion-at-point-functions
                (cons #'tempel-expand
                      completion-at-point-functions)))
  
  (add-hook 'prog-mode-hook 'tempel-setup-capf)
  (add-hook 'text-mode-hook 'tempel-setup-capf)
  ;; Optionally make the Tempel templates available to Abbrev,
  ;; either locally or globally. `expand-abbrev' is bound to C-x '.
  ;; (add-hook 'prog-mode-hook #'tempel-abbrev-mode)
  ;; (global-tempel-abbrev-mode)
)

(setq text-scale-mode-step 1.1) ;; How much to adjust text scale by when using `text-scale-mode'

(setq-default line-spacing elk-default-line-spacing)

(set-face-attribute 'default nil
                    :family "Fira Code"
                    :weight 'regular
                    :height elk-text-height)

;; Float height value (1.0) makes fixed-pitch take height 1.0 * height of default
;; This means it will scale along with default when the text is zoomed
(set-face-attribute 'fixed-pitch nil
                    :family "Fira Code"
                    :weight 'regular
                    :height elk-text-height)

;; Height of 160 seems to match perfectly with 12-point on Google Docs
(set-face-attribute 'variable-pitch nil
                    :family "Iosevka Aile"
                    :weight 'book
                    :height elk-larger-text)

(use-package mixed-pitch
  :defer t
  :config
  (setq mixed-pitch-set-height nil)
  (dolist (face '(org-date org-priority org-tag org-special-keyword)) ;; Some extra faces I like to be fixed-pitch
    (add-to-list 'mixed-pitch-fixed-pitch-faces face)))

(defun elk/replace-unicode-font-mapping (block-name old-font new-font)
  (let* ((block-idx (cl-position-if
                     (lambda (i) (string-equal (car i) block-name))
                     unicode-fonts-block-font-mapping))
         (block-fonts (cadr (nth block-idx unicode-fonts-block-font-mapping)))
         (updated-block (cl-substitute new-font old-font block-fonts :test 'string-equal)))
    (setf (cdr (nth block-idx unicode-fonts-block-font-mapping))
          `(,updated-block))))

(use-package unicode-fonts
  :disabled t
  :custom
  (unicode-fonts-skip-font-groups '(low-quality-glyphs))
  :config
  ;; Fix the font mappings to use the right emoji font
  (mapcar
   (lambda (block-name)
     (elk/replace-unicode-font-mapping block-name "Apple Color Emoji" "Noto Color Emoji"))
   '("Dingbats"
     "Emoticons"
     "Miscellaneous Symbols and Pictographs"
     "Transport and Map Symbols"))
  (unicode-fonts-setup))

;; Disables showing system load in modeline, useless anyway
(setq display-time-default-load-average nil)

(line-number-mode)
(column-number-mode)
(display-time-mode -1)
(size-indication-mode -1)

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :config
  (setq doom-modeline-buffer-file-name-style 'auto ;; Just show file name (no path)
        doom-modeline-project-detection 'project
        doom-modeline-enable-word-count t
        doom-modeline-buffer-encoding nil
        doom-modeline-icon t ;; Enable/disable all icons
        doom-modeline-modal-icon t ;; Icon for Evil mode
        doom-modeline-major-mode-icon t
        doom-modeline-major-mode-color-icon t
        doom-modeline-bar-width 3))

(setq doom-modeline-height 1)

(use-package hide-mode-line
  :defer t
  :hook (completion-list-mode-hook . hide-mode-line-mode))

(defun split-horizontally-for-temp-buffers ()
  "Split the window horizontally for temp buffers."
  (when (and (one-window-p t)
             (not (active-minibuffer-window)))
    (split-window-horizontally)))
(add-hook 'temp-buffer-setup-hook 'split-horizontally-for-temp-buffers)

(use-package all-the-icons)

(use-package all-the-icons-completion
  :after (marginalia all-the-icons)
  :hook (marginalia-mode . all-the-icons-completion-marginalia-setup)
  :init
  (all-the-icons-completion-mode))

(use-package doom-themes
  :config
  (doom-themes-visual-bell-config)
  (doom-themes-org-config)
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  :custom-face
  (org-ellipsis ((t (:height 0.8 :inherit 'shadow))))
  ;; Keep the modeline proper every time I use these themes.
  (mode-line ((t (:height ,elk-doom-modeline-text-height))))
  (mode-line-inactive ((t (:height ,elk-doom-modeline-text-height))))
  (org-scheduled-previously ((t (:background "red")))))

;; Load the theme here
(elk/load-theme 'doom-dark+)

(setq-default fringes-outside-margins nil)
(setq-default indicate-buffer-boundaries nil) ;; Otherwise shows a corner icon on the edge
(setq-default indicate-empty-lines nil) ;; Otherwise there are weird fringes on blank lines

(set-face-attribute 'fringe nil :background nil)
(set-face-attribute 'header-line nil :background nil :inherit 'default)

;; Enable line numbers for some modes
(dolist (mode '(text-mode-hook
                prog-mode-hook
                conf-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 1)))
  (add-hook mode (lambda () (hl-line-mode 1))))

;; Override some modes which derive from the above
(dolist (mode '(org-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;; This makes emacs transparent
(set-frame-parameter (selected-frame) 'alpha '(95 . 95))
(add-to-list 'default-frame-alist '(alpha . (95 . 95)))

;; Make fill-paragraph (M-q) 100 characters long
(setq-default fill-column 100)

(use-package visual-fill-column
  :defer t
  :commands visual-fill-column-mode
  :init
  (setq visual-fill-column-width 100
        visual-fill-column-center-text t))

(use-package writeroom-mode
  :defer t
  :config
  (setq writeroom-maximize-window nil
        writeroom-header-line "" ;; Makes sure we have a header line, that's blank
        writeroom-mode-line t
        writeroom-global-effects nil) ;; No need to have Writeroom do any of that silly stuff
  (setq writeroom-width 70)
  ;; (add-hook 'writeroom-mode-hook (lambda () (setq-local line-spacing 10)))
  )

(use-package evil-goggles
  :custom-face
  (evil-goggles-default-face ((t (:inherit 'highlight)))) ;; default is to inherit 'region
  ;; run `M-x list-faces-display` in a fresh emacs to get a list of faces on your emacs
  :init
  (setq evil-goggles-duration 0.1
        evil-goggles-pulse nil ; too slow
        ;; evil-goggles provides a good indicator of what has been affected.
        ;; delete/change is obvious, so I'd rather disable it for these.
        evil-goggles-enable-delete nil
        evil-goggles-enable-change nil)
  :config
  (evil-goggles-mode))

(use-package org-super-agenda
    :after org
    :config
    (setq org-super-agenda-header-map nil) ;; takes over 'j'
    (setq org-super-agenda-header-prefix " ??????") ;; There are some unicode "THIN SPACE"s after the ???
    (org-super-agenda-mode))

(use-package org-superstar
  :disabled t
  :hook (org-mode . org-superstar-mode)
  :config
  (setq org-superstar-headline-bullets-list '("???" "???" "???" "???" "???" "???" "???" "???")
        org-superstar-leading-bullet ?\s
        org-superstar-leading-fallback ?\s
        org-superstar-item-bullet-alist '((?+ . ????) (?- . ????)) ; changes +/- symbols in item lists
        org-superstar-prettify-item-bullets t
        org-hide-leading-stars nil)
  (setq org-superstar-special-todo-items t  ;; Makes TODO header bullets into boxes
        org-superstar-todo-bullet-alist '(("TODO" . 9744)
                                          ("INPROG-TODO" . 9744)
                                          ("HW" . 9744)
                                          ("STUDY" . 9744)
                                          ("SOMEDAY" . 9744)
                                          ("READ" . 9744)
                                          ("PROJ" . 9744)
                                          ("CONTACT" . 9744)
                                          ("DONE" . 9745)))
  )

;; Removes gap when you add a new heading
;;(setq org-blank-before-new-entry '((heading . nil) (plain-list-item . nil)))

(use-package org-modern
  :custom
  (org-modern-hide-stars nil) ; adds extra indentation
  :hook
  (org-mode . org-modern-mode)
  (org-agenda-finalize . org-modern-agenda))

(use-package org-modern-indent
  :straight (:host github :repo "jdtsmith/org-modern-indent")
  :hook
  (org-mode . org-modern-indent-mode))

(use-package evil-org
  :hook (org-mode . evil-org-mode)
  :diminish evil-org-mode
  :config
  (add-hook 'evil-org-mode-hook
            (lambda () (evil-org-set-key-theme)))
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

(use-package org-gcal
    :defer t
    :config
    (setq org-gcal-down-days '20) ;; Only fetch events 20 days into the future
    (setq org-gcal-up-days '10) ;; Only fetch events 10 days into the past
    (setq org-gcal-recurring-events-mode 'top-level)
    (setq org-gcal-remove-api-cancelled-events t) ;; No prompt when deleting removed events

    ;; NOTE - org-gcal ids and calendar configuation is set in 'private.el' for sake of security/privacy.
    )

(use-package org-appear
    :commands (org-appear-mode)
    :hook (org-mode . org-appear-mode)
    :init
    (setq org-hide-emphasis-markers t) ;; A default setting that needs to be t for org-appear
    (setq org-appear-autoemphasis t)  ;; Enable org-appear on emphasis (bold, italics, etc)
    (setq org-appear-autolinks nil) ;; Enable on links
    (setq org-appear-autosubmarkers t)) ;; Enable on subscript and superscript

(use-package toc-org
  :commands toc-org-enable
  :hook (org-mode . toc-org-enable)
  :config
  (setq toc-org-hrefify-default "gh"))

(use-package org-auto-tangle
  :commands org-auto-tangle-mode
  :hook (org-mode . org-auto-tangle-mode))

(use-package ox-reveal
  :after org)

(defun elk/org-download-paste-clipboard (&optional use-default-filename)
  (interactive "P")
  (require 'org-download)
  (let ((file
         (if (not use-default-filename)
             (read-string (format "Filename [%s]: "
                                  org-download-screenshot-basename)
                          nil nil org-download-screenshot-basename)
           nil)))
    (org-download-clipboard file)))

(use-package org-download
  :after org
  :config
  (setq org-download-method 'directory)
  (setq org-download-image-dir "images")
  (setq org-download-heading-lvl nil)
  (setq org-download-timestamp "%Y%m%d-%H%M%S_")
  (setq org-image-actual-width 300))

(setq org-modules '(org-habit))
(eval-after-load 'org
    '(org-load-modules-maybe t))

(require 'org-tempo)
(add-to-list 'org-structure-template-alist '("sh" . "src sh"))
(add-to-list 'org-structure-template-alist '("n" . "notes"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("li" . "src lisp"))
(add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
(add-to-list 'org-structure-template-alist '("ts" . "src typescript"))
(add-to-list 'org-structure-template-alist '("py" . "src python"))
(add-to-list 'org-structure-template-alist '("go" . "src go"))
(add-to-list 'org-structure-template-alist '("yaml" . "src yaml"))
(add-to-list 'org-structure-template-alist '("json" . "src json"))

;; Org-agenda specific bindings
(with-eval-after-load 'evil
  (evil-define-key 'motion org-agenda-mode-map
    (kbd "f") 'org-agenda-later
    (kbd "b") 'org-agenda-earlier))

(general-def 'org-mode-map
  ;; Emacs bindings
  "C-c t" 'elk/org-done-keep-todo)

(general-def 'visual org-mode-map
  [remap +evil-shift-left] '+evil-org-< ; vnoremap < <gv
  [remap +evil-shift-right] '+evil-org-> ; vnoremap > >gv
  )

(defun elk/org-font-setup ()
  (custom-theme-set-faces
   'user
   ;; '(org-level-4 ((t (:inherit t :height 1.1))))
   ;; '(org-level-3 ((t (:inherit t :height 1.25))))
   ;; '(org-level-2 ((t (:inherit t :height 1.5))))
   ;; '(org-level-1 ((t (:inherit t :height 1.75))))
   '(org-block ((t (:foreground nil))))
   '(org-tag ((t (:inherit org-tag :italic t))))
   '(org-ellipsis ((t (:inherit shadow :height 0.8))))
   '(org-link ((t (:foreground "royal blue" :underline t)))))

  ;; (mixed-pitch-mode 1)
  )

(defun elk/prettify-symbols-setup ()
  ;; checkboxes
  (push '("[ ]" .  "???") prettify-symbols-alist)
  ;; (push '("[X]" . "???" ) prettify-symbols-alist)
  (push '("[X]" . "???" ) prettify-symbols-alist)
  (push '("[-]" . "???" ) prettify-symbols-alist)
  
  ;; org-babel
  (push '("#+BEGIN_SRC" . ????) prettify-symbols-alist)
  (push '("#+END_SRC" . ????) prettify-symbols-alist)
  (push '("#+begin_src" . ????) prettify-symbols-alist)
  (push '("#+end_src" . ????) prettify-symbols-alist)
  
  ;; (push '("#+BEGIN_SRC python" . ???) prettify-symbols-alist) ;; This is the Python symbol. Comes up weird for some reason
  (push '("#+RESULTS:" . ???? ) prettify-symbols-alist)
  
  ;; drawers
  (push '(":PROPERTIES:" . ????) prettify-symbols-alist)
  
  ;; tags
  (push '(":Misc:" . "???" ) prettify-symbols-alist)
  (push '(":ec:" . "???" ) prettify-symbols-alist)
  (push '(":Weekly:ec:" . "???" ) prettify-symbols-alist)
  (push '(":Robo:ec:" . "???" ) prettify-symbols-alist)
  
  (push '(":bv:" . ???? ) prettify-symbols-alist)
  (push '(":sp:" . ???? ) prettify-symbols-alist)
  (push '(":cl:" . "??" ) prettify-symbols-alist)
  (push '(":ch:" . ????) prettify-symbols-alist)
  (push '(":es:" . "???" ) prettify-symbols-alist)
  (prettify-symbols-mode 1))

(defun +org-realign-table-maybe-h ()
  "Auto-align table under cursor."
  (when (and (org-at-table-p) org-table-may-need-update)
    (let ((pt (point))
          (inhibit-message t))
      (if org-table-may-need-update (org-table-align))
      (goto-char pt))))

(defun +org-realign-table-maybe-a (&rest _)
  "Auto-align table under cursor and re-calculate formulas."
  (when (eq major-mode 'org-mode)
    (+org-realign-table-maybe-h)))

;; From DOOM Emacs
(defun +org-enable-auto-reformat-tables-h ()
  "Realign tables & update formulas when exiting insert mode (`evil-mode').
Meant for `org-mode-hook'."
  (when (featurep 'evil)
    (add-hook 'evil-insert-state-exit-hook #'+org-realign-table-maybe-h nil t)
    (add-hook 'evil-replace-state-exit-hook #'+org-realign-table-maybe-h nil t)
    (advice-add #'evil-replace :after #'+org-realign-table-maybe-a)))

(defun elk/org-setup ()
  (org-indent-mode) ;; Keeps org items like text under headings, lists, nicely indented
  (visual-line-mode 1) ;; Nice line wrapping
  (visual-fill-column-mode 1) ;; Make the document centered with 100 words.

  (centered-cursor-mode)

  ;; (setq header-line-format "") ;; Empty header line, basically adds a blank line on top
  (setq-local line-spacing (+ elk-default-line-spacing 1)))

(use-package org
  :hook (org-mode . +org-enable-auto-reformat-tables-h)
  :hook (org-mode . elk/org-setup)
  :hook (org-mode . elk/prettify-symbols-setup)
  :hook (org-mode . elk/org-font-setup)
  :hook (org-mode . locally-defer-font-lock)
  :hook (org-capture-mode . evil-insert-state) ;; Start org-capture in Insert state by default
  :diminish org-indent-mode
  :diminish visual-line-mode
  :config

(setq org-ellipsis "?????? ") ;; ???
(setq org-src-fontify-natively t) ;; Syntax highlighting in org src blocks
(setq org-highlight-latex-and-related '(native)) ;; Highlight inline LaTeX
(setq org-startup-folded 'showall)
(setq org-image-actual-width nil)

(setq org-cycle-separator-lines 1)
(setq org-catch-invisible-edits 'smart)
(setq org-return-follows-link t)

(setq org-edit-src-content-indentation 0
      org-src-tab-acts-natively t
      org-src-ask-before-returning-to-edit-buffer nil
      org-src-preserve-indentation t)

;; M-Ret can split lines on items and tables but not headlines and not on anything else (unconfigured)
(setq org-M-RET-may-split-line '((headline) (item . t) (table . t) (default)))
(setq org-loop-over-headlines-in-active-region nil)

;; Opens links to other org file in same frame (rather than splitting)
(setq org-link-frame-setup '((file . find-file)))

(setq org-log-done t)
(setq org-log-into-drawer t)

;; Automatically change bullet type when indenting
;; Ex: indenting a + makes the bullet a *.
(setq org-list-demote-modify-bullet
      '(("+" . "*") ("*" . "-") ("-" . "+")))

;; Automatically save and close the org files I most frequently archive to.
;; I see no need to keep them open and crowding my buffer list.
;; Uses my own function elk/save-and-close-this-buffer.
;; (dolist (file '("homework-archive.org_archive" "todo-archive.org_archive"))
;;   (advice-add 'org-archive-subtree-default :after
;;               (lambda () (elk/save-and-close-this-buffer file))))

(setq counsel-org-tags '("qp" "ec" "st")) ;; Quick-picks, extracurricular, short-term

(setq org-tag-faces '(
                      ("bv" . "dark slate blue")
                      ("sp" . "purple3")
                      ("ch" . "PaleTurquoise3")
                      ("cl" . "chartreuse4")
                      ("es" . "brown3")
                      ("Weekly" . "SteelBlue1")
                      ("Robo" . "IndianRed2")
                      ("Misc" . "tan1")
                      ("qp" . "RosyBrown1") ;; Quick-picks
                      ("ec" . "PaleGreen3") ;; Extracurricular
                      ("st" . "DimGrey") ;; Near-future (aka short term) todo
                      ))

;; (setq org-tags-column -64)
(setq org-tags-column 1)

(setq org-todo-keywords '((type
                           "TODO(t)" "INPROG-TODO(i)" "HW(h)" "STUDY" "SOMEDAY"
                           "READ(r)" "PROJ(p)" "CONTACT(c)"
                           "|" "DONE(d)" "CANCELLED(C)")))

(setq org-todo-keyword-faces '(("TODO" nil :foreground "orange1" :inherit fixed-pitch :weight medium)
                               ("HW" nil :foreground "coral1" :inherit fixed-pitch :weight medium)
                               ("STUDY" nil :foreground "plum3" :inherit fixed-pitch :weight medium)
                               ("SOMEDAY" nil :foreground "steel blue" :inherit fixed-pitch)
                               ("CONTACT" nil :foreground "LightSalmon2" :inherit fixed-pitch :weight medium)
                               ("READ" nil :foreground "MediumPurple3" :inherit fixed-pitch :weight medium)
                               ("PROJ" nil :foreground "aquamarine3" :inherit fixed-pitch :weight medium)

                               ("INPROG-TODO" nil :foreground "orange1" :inherit fixed-pitch :weight medium)

                               ("DONE" nil :foreground "LawnGreen" :inherit fixed-pitch :weight medium)
                               ("CANCELLED" nil :foreground "dark red" :inherit fixed-pitch :weight medium)))

(setq org-lowest-priority ?F)  ;; Gives us priorities A through F
(setq org-default-priority ?E) ;; If an item has no priority, it is considered [#D].

(setq org-priority-faces
      '((65 nil :inherit fixed-pitch :foreground "red2" :weight medium)
        (66 . "Gold1")
        (67 . "Goldenrod2")
        (68 . "PaleTurquoise3")
        (69 . "DarkSlateGray4")
        (70 . "PaleTurquoise4")))

;; Org-Babel
(org-babel-do-load-languages
 'org-babel-load-languages
 '(
   (python . t)
   (shell . t)
   (gnuplot . t)
   (emacs-lisp . t)
   ))

;; Asynchronous src block execution
(use-package ob-async
  :config
  (setq ob-async-no-async-languages-alist '("python" "hy" "jupyter-python" "jupyter-octave" "restclient")))

(use-package gnuplot)

;; Don't prompt before running code in org
(setq org-confirm-babel-evaluate nil)
(setq python-shell-completion-native-enable nil)

;; How to open buffer when calling `org-edit-special'.
(setq org-src-window-setup 'current-window)

(setq org-habit-preceding-days 6)
(setq org-habit-following-days 6)
(setq org-habit-show-habits-only-for-today nil)
(setq org-habit-today-glyph ????) ;;???
(setq org-habit-completed-glyph ????)
(setq org-habit-graph-column 40)

;; Uses custom time stamps
(setq org-time-stamp-custom-formats '("<%A, %B %d, %Y" . "<%m/%d/%y %a %I:%M %p>"))

(setq org-agenda-restore-windows-after-quit t)

;; Only show upcoming deadlines for tomorrow or the day after tomorrow. By default it shows
;; 14 days into the future, which seems excessive.
(setq org-deadline-warning-days 2)
;; If something is done, don't show it's deadline
(setq org-agenda-skip-deadline-if-done t)
;; If something is done, don't show when it's scheduled for
(setq org-agenda-skip-scheduled-if-done t)
;; If something is scheduled, don't tell me it is due soon
(setq org-agenda-skip-deadline-prewarning-if-scheduled t)

(setq org-agenda-timegrid-use-ampm 1)

;; (setq org-agenda-time-grid '((daily today require-timed)
;;                              (800 900 1000 1100 1200 1300 1400 1500 1600 1700)
;;                              "        "
;; 							 "----------------"))

(setq org-agenda-time-grid nil) ;; I've decided to disable the time grid. 2021-09-22.

(setq org-agenda-block-separator 8213) ;; Unicode: ???
(setq org-agenda-current-time-string "<----------------- Now")
(setq org-agenda-scheduled-leaders '("" ""))
;; note: maybe some day I want to use org-agenda-deadline-leaders

(setq org-agenda-prefix-format '((agenda . " %i %-1:i%?-2t% s")
                                 (todo . "   ")
                                 (tags . " %i %-12:c")
                                 (search . " %i %-12:c")))

;; https://stackoverflow.com/questions/58820073/s-in-org-agenda-prefix-format-doesnt-display-dates-in-the-todo-view
;; something to look into

(setq org-agenda-custom-commands nil)

(setq elk-org-super-agenda-school-groups
                              '(
                                (:name "Overdue"
                                       :discard (:tag "habit") ;; No habits in this todo view
                                       :face (:background "red")
                                       :scheduled past
                                       :deadline past
                                       :order 2)
                                (:name "Important"
                                       :and (:todo "TODO" :priority "A") ;; Homework doesn't count here
                                       :todo "CONTACT"
                                       :order 3)
                                (:name "Short-term Todo"
                                       :tag "st"
                                       :order 4)
                                (:name "Personal"
                                       :category "personal"
                                       :order 40)
                                (:name "Someday"
                                       :todo "SOMEDAY"
                                       :order 30)
                                (:name "Homework"
                                       :todo ("HW" "READ")
                                       :order 5)
                                (:name "Studying"
                                       :todo "STUDY"
                                       :order 7)
                                (:name "Quick Picks"
                                       :tag "qp"
                                       :order 11)
                                (:name "Projects"
                                       :todo "PROJ"
                                       :order 12)
                                (:name "Weekly"
                                       :tag "weekly"
                                       :order 15)
                                (:name "Extracurricular"
                                       :discard (:todo "SOMEDAY")
                                       :tag "ec"
                                       :order 13)
                                (:name "Todo"
                                       :discard (:category "personal")
                                       :todo ("TODO" "INPROG-TODO")
                                       :order 20)))

(add-to-list 'org-agenda-custom-commands
             '("n" "Super zaen view"
               ((agenda "" ((org-agenda-span 'day) (org-agenda-overriding-header "Today's Agenda:")
                            (org-super-agenda-groups '(
                                                       (:name "Schedule"
                                                              :time-grid t
                                                              :order 1)
                                                       (:name "Tasks"
                                                              ;; :discard (:not (:scheduled today))
                                                              ;; :discard (:deadline today)
                                                              :scheduled t
                                                              :order 2)
                                                       (:name "Unscheduled Tasks"
                                                              :deadline t
                                                              :order 3)
                                                       ))))

                (alltodo "" ((org-agenda-overriding-header "All Tasks:")
                             (org-super-agenda-groups elk-org-super-agenda-school-groups
                                                      ))))
               ))

(add-to-list 'org-agenda-custom-commands
             '("m" "Agendaless Super zaen view"
               ((alltodo "" ((org-agenda-overriding-header "Agendaless Todo View")
                             (org-super-agenda-groups (push '(:name "Today's Tasks" ;; elk-org-super-agenda-school-groups, with this added on
                                                                    :scheduled today
                                                                    :deadline today) elk-org-super-agenda-school-groups)
                                                      )))))
             )
;; Org-super-agenda-mode itself is activated in the use-package block

;; By default an org-capture/refile will save a bookmark. This
;; disables that and keeps my bookmark list how I want it.
(setq org-bookmark-names-plist nil)

(setq org-refile-targets (quote (("~/Dropbox/org/work.org" :maxlevel . 2))))
(setq org-outline-path-complete-in-steps nil) ; Refile in a single go
(setq org-refile-use-outline-path t)          ; Show full paths for refilin0

(setq org-capture-templates
      '(
        ("n" "CPB Note" entry (file+headline "~/Dropbox/org/cpb.org" "Refile")
         "** Note: %? @ %U" :empty-lines 0)

        ("w" "Work Todo Entries")
            ("we" "No Time" entry (file "~/Dropbox/org/work.org")
             "** %^{Type|TODO|HW|READ|PROJ} %^{Todo title} %?" :prepend t :empty-lines-before 0)

            ("ws" "Scheduled" entry (file "~/Dropbox/org/work.org")
             "** %^{Type|TODO|HW|READ|PROJ} %^{Todo title}\nSCHEDULED: %^t%?" :prepend t :empty-lines-before 0)

            ("wd" "Deadline" entry (file "~/Dropbox/org/work.org")
             "** %^{Type|TODO|HW|READ|PROJ} %^{Todo title}\nDEADLINE: %^t%?" :prepend t :empty-lines-before 0)

            ("ww" "Scheduled & deadline" entry (file "~/Dropbox/org/work.org")
             "** %^{Type|TODO|HW|READ|PROJ} %^{Todo title}\nSCHEDULED: %^t DEADLINE: %^t %?" :prepend t :empty-lines-before 0)
        ))

(setq org-export-backends '(ascii beamer html latex md odt))

;; I want docx document for MS Word compatibility
(setq org-odt-preferred-output-format "docx")


(setq org-export-with-broken-links t)
(setq org-export-with-smart-quotes t)
(setq org-export-allow-bind-keywords t)

;; From https://stackoverflow.com/questions/23297422/org-mode-timestamp-format-when-exported
(defun org-export-filter-timestamp-remove-brackets (timestamp backend info)
  "removes relevant brackets from a timestamp"
  (cond
   ((org-export-derived-backend-p backend 'latex)
    (replace-regexp-in-string "[<>]\\|[][]" "" timestamp))
   ((org-export-derived-backend-p backend 'html)
    (replace-regexp-in-string "&[lg]t;\\|[][]" "" timestamp))))


;; HTML-specific
(setq org-html-validation-link nil) ;; No validation button on HTML exports

;; LaTeX Specific
(eval-after-load 'ox '(add-to-list
                       'org-export-filter-timestamp-functions
                       'org-export-filter-timestamp-remove-brackets))

(use-package ox-hugo
  :defer 2
  :after ox
  :config
  (setq org-hugo-base-dir "~/Dropbox/Projects/cpb"))

(setq org-latex-listings t) ;; Uses listings package for code exports
(setq org-latex-compiler "lualatex") ;; LuaLaTex rather than pdflatex

;; not sure what this is, look into it
;; '(org-latex-active-timestamp-format "\\texttt{%s}")
;; '(org-latex-inactive-timestamp-format "\\texttt{%s}")

;; LaTeX Classes
(with-eval-after-load 'ox-latex
  (add-to-list 'org-latex-classes
               '("org-plain-latex" ;; I use this in base class in all of my org exports.
                 "\\documentclass{extarticle}
           [NO-DEFAULT-PACKAGES]
           [PACKAGES]
           [EXTRA]"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
  )

(setq org-clock-mode-line-total 'current) ;; Show only timer from current clock session in modeline
(setq-default org-attach-id-dir (expand-file-name ".attach/" org-directory))

) ;; This parenthesis ends the org use-package.

(use-package org-roam
  :hook (org-load . org-roam-mode)
  :init
  (setq org-roam-db-gc-threshold most-positive-fixnum)
  (setq org-roam-v2-ack t)
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         :map org-mode-map
         ("C-M-i"    . completion-at-point))
  :config
  (setq org-roam-completion-everywhere t)
  (setq org-roam-list-files-commands '(fd fdfind rg find))

(defun org-roam-node-insert-immediate (arg &rest args)
  (interactive "P")
  (let ((args (cons arg args))
        (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                  '(:immediate-finish t)))))
    (apply #'org-roam-node-insert args)))

(defun elk/org-roam-capture-inbox ()
  (interactive)
  (org-roam-capture- :node (org-roam-node-create)
                     :templates '(("i" "inbox" plain "* %?"
                                  :if-new (file+head "braindump/inbox.org" "#+title: Inbox\n")))))

(defun elk/org-roam-filter-by-tag (tag-name)
  (lambda (node)
    (member tag-name (org-roam-node-tags node))))

(defun elk/org-roam-list-notes-by-tag (tag-name)
  (mapcar #'org-roam-node-file
          (seq-filter
           (elk/org-roam-filter-by-tag tag-name)
           (org-roam-node-list))))

(defun elk/org-roam-refresh-agenda-list ()
  (interactive)
  (setq org-agenda-files (elk/org-roam-list-notes-by-tag "Project")))

(cl-defmethod org-roam-node-type ((node org-roam-node))
  "Return the TYPE of NODE."
  (condition-case nil
      (file-name-nondirectory
       (directory-file-name
        (file-name-directory
         (file-relative-name (org-roam-node-file node) org-roam-directory))))
    (error "")))

(setq org-roam-node-display-template
      (concat (propertize "${type:10}" 'face 'org-tag) "${title:*} " (propertize "${tags:10}" 'face 'font-lock-comment-face)))

(setq org-roam-capture-templates
      '(("b" "brain" plain "\n%?"
         :if-new (file+head "brain/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date: %U\n")
         :immediate-finish t
         :unnarrowed t)
        ("r" "reference" plain "\n%?"
         :if-new (file+head "reference/${citekey}.org" "#+title: ${title}\n#+date: %U\n")
         :immediate-finish t
         :unnarrowed t)
        ("a" "article" plain "\n%?"
         :if-new (file+head "article/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date: %U\n#+filetags: Seedling\n")
         :immediate-finish t
         :unnarrowed t)
        ("s" "school" plain "\n%?"
         :if-new (file+head "school/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+date: %U\n")
         :immediate-finish t
         :unnarrowed t)
        ("p" "project" plain "\n* Goals\n\n%?\n\n* Tasks\n\n** TODO Add initial tasks\n\n* Dates\n\n"
         :if-new (file+head "project/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+category: ${title}\n#+date: %U\n#+filetags: Project\n\n")
         :immediate-finish t
         :unnarrowed t)
        ("t" "tag" plain "%?"
         :if-new (file+head "tag/${slug}.org" "#+title: ${title}\n\n")
         :immediate-finish t
         :unnarrowed t)
        ))

(setq org-roam-dailies-capture-templates
      '(("d" "default" entry "* %?"
         :if-new (file+head "journal/%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d> Journal\n\n")
         :unnarrowed t)))

(defun elk/org-roam-project-finalize-hook ()
  "Adds the captured project file to `org-agenda-files' if the
capture was not aborted."
  ;; Remove the hook since it was added temporarily
  (remove-hook 'org-capture-after-finalize-hook #'elk/org-roam-project-finalize-hook)

  ;; Add project file to the agenda list if the capture was confirmed
  (unless org-note-abort
    (with-current-buffer (org-capture-get :buffer)
      (add-to-list 'org-agenda-files (buffer-file-name)))))

(defun elk/org-roam-capture-task ()
  (interactive)
  ;; Add the project file to the agenda after capture is finished
  (add-hook 'org-capture-after-finalize-hook #'elk/org-roam-project-finalize-hook)

  ;; Capture the new task, creating the project file if necessary
  (org-roam-capture- :node (org-roam-node-read
                            nil
                            (elk/org-roam-filter-by-tag "Project"))
                     :templates '(("p" "project" plain "** TODO %?"
                                   :if-new (file+head "project/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+category: ${title}\n#+date: %U\n#+filetags: Project\n\n"("Tasks"))
                                   ))))

(defun elk/org-roam-filter-by-tag (tag-name)
  (lambda (node)
    (member tag-name (org-roam-node-tags node))))

(defun elk/org-roam-list-notes-by-tag (tag-name)
  (mapcar #'org-roam-node-file
          (seq-filter
           (elk/org-roam-filter-by-tag tag-name)
           (org-roam-node-list))))

(defun elk/org-roam-refresh-agenda-list ()
  (interactive)
  (setq org-agenda-files (elk/org-roam-list-notes-by-tag "projects")))

(org-roam-db-autosync-mode)
(elk/org-roam-refresh-agenda-list) ;; Build the agenda list the first time for the session
) ;; End of org-roam block

(use-package websocket
  :after org-roam)

(use-package org-roam-ui
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t))

(use-package citar
  :config
  (setq org-cite-insert-processor 'citar
        org-cite-follow-processor 'citar
        org-cite-activate-processor 'citar)

  (setq citar-bibliography (directory-files-recursively "~/Documents/bib/" "\\.bib$"))

  ;; `org-cite'
  (setq org-cite-global-bibliography citar-bibliography
        ;; Setup export processor; default csl/citeproc-el, with biblatex for latex
        ;; org-cite-export-processors '((latex biblatex) (t csl))
        org-support-shift-select t))

(use-package org-roam-bibtex
  :after org-roam
  :hook (org-roam-mode . org-roam-bibtex-mode))

(use-package org-noter
  :after (:any org pdf-view)
  :config
  (setq org-noter-notes-search-path (list org-directory)
        org-noter-auto-save-last-location t
        org-noter-separate-notes-from-heading t))

(use-package popwin
  :defer 0
  :config
  (popwin-mode 1))

(use-package dumb-jump
  :defer t
  :hook (xref-backend-functions . dumb-jump-xref-activate)
  :config
  (setq xref-show-definitions-function #'xref-show-definitions-completing-read))

(use-package kbd-mode
  :straight (:host github :repo "kmonad/kbd-mode")
  :mode ("\\.kbd\\'" . kbd-mode))

(use-package unfill :defer t)
(use-package burly :defer t)
(use-package ace-window :defer t)
(use-package org-real :defer t)
(use-package centered-cursor-mode :diminish centered-cursor-mode)
(use-package restart-emacs :defer t)
(use-package diminish)

(use-package bufler
  :general
  (:keymaps 'bufler-list-mode-map "Q" 'kill-this-buffer))

(use-package deft
  :commands (deft deft-find-file)
  :config
  (setq deft-directory org-directory
        deft-strip-summary-regexp ":PROPERTIES:\n\\(.+\n\\)+:END:\n"
        deft-use-filename-as-title t
        deft-recursive t
        deft-extensions '("md" "org")))

(defun elfeed-v-mpv (url)
  "Watch a video from URL in MPV"
  (async-shell-command (format "mpv --really-quiet \"%s\"" url)))

(defun elfeed-view-mpv (&optional use-generic-p)
  "Youtube-feed link"
  (interactive "P")
  (let ((entries (elfeed-search-selected)))
    (cl-loop for entry in entries
             do (elfeed-untag entry 'unread)
             when (elfeed-entry-link entry)
             do (elfeed-v-mpv it))
    (mapc #'elfeed-search-update-entry entries)
    (unless (use-region-p) (forward-line))))

(defun elfeed-eww-open (&optional use-generic-p)
  "open with eww"
  (interactive "P")
  (let ((entries (elfeed-search-selected)))
    (cl-loop for entry in entries
             do (elfeed-untag entry 'unread)
             when (elfeed-entry-link entry)
             do (eww-browse-url it))
    (mapc #'elfeed-search-update-entry entries)
    (unless (use-region-p) (forward-line))))

(defun elfeed-firefox-open (&optional use-generic-p)
  "open with firefox"
  (interactive "P")
  (let ((entries (elfeed-search-selected)))
    (cl-loop for entry in entries
             do (elfeed-untag entry 'unread)
             when (elfeed-entry-link entry)
             do (browse-url-firefox it))
    (mapc #'elfeed-search-update-entry entries)
    (unless (use-region-p) (forward-line))))

(defun elfeed-chromium-open (&optional use-generic-p)
  "open with firefox"
  (interactive "P")
  (let ((entries (elfeed-search-selected)))
    (cl-loop for entry in entries
             do (elfeed-untag entry 'unread)
             when (elfeed-entry-link entry)
             do (browse-url-chromium it))
    (mapc #'elfeed-search-update-entry entries)
    (unless (use-region-p) (forward-line))))

(defun elfeed-w3m-open (&optional use-generic-p)
  "open with w3m"
  (interactive "P")
  (let ((entries (elfeed-search-selected)))
    (cl-loop for entry in entries
             do (elfeed-untag entry 'unread)
             when (elfeed-entry-link entry)
             do (ffap-w3m-other-window it))
    (mapc #'elfeed-search-update-entry entries)
    (unless (use-region-p) (forward-line))))


(defun +rss/open (entry)
  "Display the currently selected item in a buffer."
  (interactive (list (elfeed-search-selected :ignore-region)))
  (when (elfeed-entry-p entry)
    (elfeed-untag entry 'unread)
    (elfeed-search-update-entry entry)
    (elfeed-show-entry entry)))

(defun +rss/next ()
  "Show the next item in the elfeed-search buffer."
  (interactive)
  (funcall elfeed-show-entry-delete)
  (with-current-buffer (elfeed-search-buffer)
    (forward-line)
    (call-interactively '+rss/open)))

(defun +rss/previous ()
  "Show the previous item in the elfeed-search buffer."
  (interactive)
  (funcall elfeed-show-entry-delete)
  (with-current-buffer (elfeed-search-buffer)
    (forward-line -1)
    (call-interactively '+rss/open)))

(defun +rss/delete-pane ()
  "Delete the *elfeed-entry* split pane."
  (interactive)
  (let* ((buf (get-buffer "*elfeed-entry*"))
         (window (get-buffer-window buf)))
    (delete-window window)
    (when (buffer-live-p buf)
      (kill-buffer buf))))

(setq rmh-elfeed-org-files '("~/Documents/org/elfeed.org"))

(use-package elfeed
  :commands elfeed
  :hook (elfeed-search-mode-hook . elfeed-update)
  :general
  (:states 'motion
           :keymaps 'elfeed-search-mode-map
           "r" #'elfeed-search-update--force
           (kbd "RET") #'elfeed-search-show-entry
           (kbd "M-RET") #'elfeed-search-browse-url

           "gr" #'elfeed-search-update--force
           "gR" #'elfeed-search-fetch

           "v" nil
           "v" #'elfeed-view-mpv
           "t" #'elfeed-w3m-open
           "w" #'elfeed-eww-open
           "f" nil
           "f" #'elfeed-firefox-open
           "c" nil
           "c" #'elfeed-chromium-open)
  (:states 'motion
    :keymaps 'elfeed-show-mode-map
    "q" #'elfeed-kill-buffer
    [remap next-buffer]     #'+rss/next
    [remap previous-buffer] #'+rss/previous)
  :init
  (setq elfeed-db-directory (concat user-emacs-directory "elfeed/db/")
        elfeed-enclosure-default-dir (concat user-emacs-directory "elfeed/enclosures/"))
  :config
  ;; Buffers are read only and, so we need only motion state
  (add-to-list 'evil-motion-state-modes 'elfeed-search-mode)
  (add-to-list 'evil-motion-state-modes 'elfeed-show-mode)
  (setq elfeed-show-entry-switch 'display-buffer
        elfeed-show-entry-switch #'pop-to-buffer
        elfeed-show-entry-delete #'+rss/delete-pane))

(use-package elfeed-goodies
  :after elfeed
  :config
  (elfeed-goodies/setup))

(use-package elfeed-org
  :after elfeed
  :config
  (elfeed-org))

(use-package elfeed-summary
  :commands elfeed-summary
  :config
  (setq elfeed-summary-filter-by-title t))

(use-package auctex
  :defer t
  :init
  (setq TeX-engine 'luatex ;; Use luaTeX
        latex-run-command "luatex")

  (setq TeX-parse-self t ; parse on load
        TeX-auto-save t  ; parse on save
        ;; Use directories in a hidden away folder for AUCTeX files.
        TeX-auto-local (concat user-emacs-directory "auctex/auto/")
        TeX-style-local (concat user-emacs-directory "auctex/style/")

        TeX-source-correlate-mode t
        TeX-source-correlate-method 'synctex

        TeX-show-compilation nil

        ;; Don't start the Emacs server when correlating sources.
        TeX-source-correlate-start-server nil

        ;; Automatically insert braces after sub/superscript in `LaTeX-math-mode'.
        TeX-electric-sub-and-superscript t
        ;; Just save, don't ask before each compilation.
        TeX-save-query nil)

  ;; To use pdfview with auctex:
  (setq TeX-view-program-selection '((output-pdf "PDF Tools"))
        TeX-view-program-list '(("PDF Tools" TeX-pdf-tools-sync-view))
        TeX-source-correlate-start-server t)
  :general
  (elk-localleader-def
   :keymaps 'LaTeX-mode-map
   "a" '(TeX-command-run-all :which-key "TeX run all")
   "c" '(TeX-command-master :which-key "TeX-command-master")
   "e" '(LaTeX-environment :which-key "Insert environment")
   "s" '(LaTeX-section :which-key "Insert section")
   "m" '(TeX-insert-macro :which-key "Insert macro")
   ))

(add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer) ;; Standard way

(use-package magit
  :commands (magit magit-status)
  :init
  (setq magit-auto-revert-mode nil)  ; we do this ourselves further down
  ;; Must be set early to prevent ~/.emacs.d/transient from being created
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  :config
  (setq transient-default-level 5
        magit-diff-refine-hunk t ; show granular diffs in selected hunk
        ;; Don't autosave repo buffers. This is too magical, and saving can
        ;; trigger a bunch of unwanted side-effects, like save hooks and
        ;; formatters. Trust the user to know what they're doing.
        magit-save-repository-buffers nil
        ;; Don't display parent/related refs in commit buffers; they are rarely
        ;; helpful and only add to runtime costs.
        magit-revision-insert-related-refs nil)
  (add-hook 'magit-process-mode-hook #'goto-address-mode))

(use-package magit-todos
  :after magit)

(use-package mw-thesaurus
  :defer t
  :config
  ;; Binds q to quit in mw-thesaurus
  (add-hook 'mw-thesaurus-mode-hook (lambda () (define-key evil-normal-state-local-map (kbd "q") 'mw-thesaurus--quit))))

(use-package pdf-tools
  :magic ("%PDF" . pdf-view-mode)
  :config
  (pdf-loader-install :no-query)
  (setq pdf-view-midnight-colors '("#ffffff" . "#121212" )) ;; I use midnight mode as dark mode, dark mode doesn't seem to work
  :general
  (:states 'motion :keymaps 'pdf-view-mode-map
           "j" 'pdf-view-next-line-or-next-page
           "k" 'pdf-view-previous-line-or-previous-page

           "C-j" 'pdf-view-next-line-or-next-page
           "C-k" 'pdf-view-previous-line-or-previous-page

           ;; Arrows for movement as well
           (kbd "<down>") 'pdf-view-next-line-or-next-page
           (kbd "<up>") 'pdf-view-previous-line-or-previous-page

           (kbd "<left>") 'image-backward-hscroll
           (kbd "<right>") 'image-forward-hscroll

           "H" 'pdf-view-fit-height-to-window
           "0" 'pdf-view-fit-height-to-window
           "W" 'pdf-view-fit-width-to-window
           "=" 'pdf-view-enlarge
           "-" 'pdf-view-shrink

           "q" 'quit-window
           "Q" 'kill-this-buffer
           "g" 'revert-buffer
           ))

(use-package popper
  :general
  (:states '(normal visual emacs)
           :prefix "SPC"
           "`" 'popper-toggle-latest
           "~" 'popper-cycle)
  :custom
  (popper-window-height 20)
  (popper-mode-line nil)
  (popper-reference-buffers '("\\*Messages\\*"
                              "Output\\*$"
                              "\\*Warnings\\*"
                              "\\*eldoc\\*"
                              "\\*Async Shell Command\\*"
                              help-mode
                              helpful-mode
                              eldoc-mode
                              compilation-mode))
  :init
  (popper-mode +1))

(use-package eglot
  :hook ((c-mode . eglot-ensure)
         (sh-mode . eglot-ensure)
         (latex-mode . eglot-ensure))
  :custom-face
  ;; Make highlight symbols stand out better
  (eglot-highlight-symbol-face ((t (:inherit bold :underline t))))
  :commands (eglot eglot-ensure)
  :config
  ;; Replace default servers
  (add-to-list 'eglot-server-programs '(lua-mode . "lua-language-server"))
  (add-to-list 'eglot-server-programs '((c++-mode c-mode) "ccls"))

  (setq eglot-sync-connect 1
        eglot-connect-timeout 10
        eglot-autoshutdown t
        eglot-send-changes-idle-time 0.5
        ;; NOTE We disable eglot-auto-display-help-buffer because :select t in
        ;;      its popup rule causes eglot to steal focus too often.
        eglot-auto-display-help-buffer nil)
  (setq eglot-stay-out-of '(flymake)))

(use-package consult-eglot
  :after (eglot consult vertico)
  :general
  (:keymaps 'eglot-mode-map [remap xref-find-apropos] #'consult-eglot-symbols))

(use-package flycheck
  :config
  (global-flycheck-mode))

(use-package format-all
  :commands format-all-buffer format-all-mode)

(use-package rainbow-mode
  :defer t)

(use-package hl-todo
  :hook (prog-mode . hl-todo-mode)
  :config
  (setq hl-todo-keyword-faces
      '(("TODO"   . "#FF0000")
        ("FIXME"  . "#FF4500")
        ("DEBUG"  . "#A020F0")
        ("WIP"   . "#1E90FF"))))

(use-package rainbow-delimiters
  :commands rainbow-delimiters-mode
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package platformio-mode
  :config
  ;; Enable ccls for all c++ files, and platformio-mode only
  ;; when needed (platformio.ini present in project root).
  (add-hook 'c++-mode-hook (lambda ()
                             (lsp-deferred)
                             (platformio-conditionally-enable))))

(use-package lua-mode
  :hook (lua-mode . eglot-ensure)
  :mode ("\\.lua\\'" . lua-mode)
  :config
  (setq lua-indent-level 2))

;; A better python mode (supposedly)
(use-package python-mode
  :mode ("\\.py\\'" . python-mode)
  :interpreter ("python" . python-mode)
  :hook (python-mode . eglot-ensure)
  :init
   ;; Stop the spam!
  (setq python-indent-guess-indent-offset-verbose nil)
  :config
  (setq python-indent-guess-indent-offset-verbose nil))

;; Using my virtual environments
(use-package pyvenv
  :defer t
  :init
  (setenv "WORKON_HOME" "~/.pyenv/versions")) ;; Where the virtual envs are stored on my computer

;; Automatically set the virtual environment when entering a directory
(use-package auto-virtualenv
  :defer 2
  :config
  (add-hook 'python-mode-hook 'auto-virtualenv-set-virtualenv))

;; Python development helper
;; (use-package elpy
;;   :defer t
;;   :init
;;   (setq elpy-rpc-virtualenv-path 'current)
;;   (advice-add 'python-mode :before 'elpy-enable))

(use-package web-mode
  :mode ("\\.html\\'" . web-mode) ;; Open .html files in web-mode
  :config
  (setq web-mode-enable-current-element-highlight t
        web-mode-enable-current-column-highlight t)

  :general
  (elk-localleader-def
  :keymaps 'web-mode-map
  "i" '(web-mode-buffer-indent :which-key "web mode indent")
  "c" '(web-mode-fold-or-unfold :which-key "web mode toggle fold")
  ))

(use-package yaml-mode
  :mode "Procfile\\'"
  :init
  (add-hook 'yaml-mode-local-vars-hook #'lsp 'append))

(use-package sudo-edit
  :defer t
  :commands sudo-edit sudo-edit-find-file)

(use-package vterm
  :commands vterm-mode vterm vterm-other-window
  :hook (vterm-mode . hide-mode-line-mode)
  :config
  ;; Once vterm is dead, the vterm buffer is useless. Why keep it around? We can
  ;; spawn another if want one.
  (setq vterm-kill-buffer-on-exit t)

  ;; 5000 lines of scrollback, instead of 1000
  (setq vterm-max-scrollback 5000)

  (add-hook 'vterm-mode-hook confirm-kill-processes nil)
  (add-hook 'vterm-mode-hook hscroll-margin 0))

(use-package vterm-toggle
  :config
  (setq vterm-toggle-fullscreen-p nil)
  (add-to-list 'display-buffer-alist
               '((lambda (buffer-or-name _)
                   (let ((buffer (get-buffer buffer-or-name)))
                     (with-current-buffer buffer
                       (or (equal major-mode 'vterm-mode)
                           (string-prefix-p vterm-buffer-name (buffer-name buffer))))))
                 (display-buffer-reuse-window display-buffer-at-bottom)
                 ;;(display-buffer-reuse-window display-buffer-in-direction)
                 ;;display-buffer-in-direction/direction/dedicated is added in emacs27
                 ;;(direction . bottom)
                 (dedicated . t) ;dedicated is supported in emacs27
                 (reusable-frames . visible)
                 (window-height . 0.3))))

;; Make gc pauses faster by decreasing the threshold.
(setq gc-cons-threshold (* 2 1000 1000))
