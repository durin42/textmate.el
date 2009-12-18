;; textmate.el --- TextMate minor mode for Emacs

;; Copyright (C) 2008, 2009 Chris Wanstrath <chris@ozmm.org> and others

;; Licensed under the same terms as Emacs.

;; Keywords: textmate osx mac
;; Created: 22 Nov 2008
;; Author: Chris Wanstrath <chris@ozmm.org> and others

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; This minor mode exists to mimick TextMate's awesome
;; features.

;;    ⌘T - Go to File
;;  ⇧⌘T - Go to Symbol
;;    ⌘L - Go to Line
;;    ⌘/ - Comment Line (or Selection/Region)
;;    ⌘] - Shift Right
;;    ⌘[ - Shift Left
;;  ⌥⌘] - Align Assignments
;;  ⌥⌘[ - Indent Line
;;  ⌘RET - Insert Newline at Line's End
;;  ⌥⌘T - Reset File Cache (for Go to File, cache unused if using git/hg root,
;;                           but resets cached root location, useful if roots
;;                           are nested)

;; A "project" in textmate-mode is determined by the presence of
;; a .git directory, an .hg directory, a Rakefile, or a Makefile.

;; You can configure what makes a project root by appending a file
;; or directory name onto the `*textmate-project-roots*' list.

;; If no project root indicator is found in your current directory,
;; textmate-mode will traverse upwards until one (or none) is found.
;; The directory housing the project root indicator (e.g. a .git or .hg
;; directory) is presumed to be the project's root.

;; In other words, calling Go to File from
;; ~/Projects/fieldrunners/app/views/towers/show.html.erb will use
;; ~/Projects/fieldrunners/ as the root if ~/Projects/fieldrunners/.git
;; exists.

;; In the event that the project root was defined by either .git or .hg,
;; fast file-listing with no caching is provided by the version control
;; system.

;; Not bound to keys, but available are textmate-find-in-project and
;; textmate-find-in-project-type, which use grep, the file listing,
;; and grep-mode to provide excellent (and blindingly fast with git and
;; hg!) grep integration with emacs and your project.

;; Also available (and unbound) is textmate-compile, which is like
;; compile but prepends a cd to the project root to the command. It is
;; used to build the find-in-project commands, but has other possible
;; uses as well (eg, a test runner or some kind of compile command).

;;; Installation

;; $ cd ~/.emacs.d/vendor
;; $ git clone git://github.com/defunkt/textmate.el.git
;;
;; In your emacs config:
;;
;; (add-to-list 'load-path "~/.emacs.d/vendor/textmate.el")
;; (require 'textmate)
;; (textmate-mode)

;;; Depends on imenu
(require 'imenu)

;;; Needed for flet
(eval-when-compile
  (require 'cl))

;;; Minor mode

(defvar *textmate-gf-exclude*
  "/\\.|vendor|fixtures|tmp|log|build|\\.xcodeproj|\\.nib|\\.framework|\\.app|\\.pbproj|\\.pbxproj|\\.xcode|\\.xcodeproj|\\.bundle|\\.pyc"
  "Regexp of files to exclude from `textmate-goto-file'.")

(defvar *textmate-project-roots*
  '(".git" ".hg" "Rakefile" "Makefile" "README" "build.xml")
  "The presence of any file/directory in this list indicates a project root.")

(defvar textmate-use-file-cache t
  "Should `textmate-goto-file' keep a local cache of files?")

(defvar textmate-completing-library 'ido
  "The library `textmade-goto-symbol' and `textmate-goto-file' should use for
completing filenames and symbols (`ido' by default)")

(defvar *textmate-completing-function-alist* '((ido ido-completing-read)
                                               (icicles  icicle-completing-read)
                                               (none completing-read))
  "The function to call to read file names and symbols from the user")

(defvar *textmate-completing-minor-mode-alist*
  `((ido ,(lambda (a) (progn (ido-mode a) (setq ido-enable-flex-matching t))))
    (icicles ,(lambda (a) (icy-mode a)))
    (none ,(lambda (a) ())))
  "The list of functions to enable and disable completing minor modes")

(defvar *textmate-mode-map*
  (let ((map (make-sparse-keymap)))
    (cond ((featurep 'aquamacs)
           (define-key map [A-return] 'textmate-next-line)
           (define-key map (kbd "A-M-t") 'textmate-clear-cache)
           (define-key map (kbd "A-M-]") 'align)
           (define-key map (kbd "A-M-[") 'indent-according-to-mode)
           (define-key map (kbd "A-]")  'textmate-shift-right)
           (define-key map (kbd "A-[") 'textmate-shift-left)
           (define-key map (kbd "A-/") 'comment-or-uncomment-region-or-line)
           (define-key map (kbd "A-t") 'textmate-goto-file)
           (define-key map (kbd "A-T") 'textmate-goto-symbol))
          ((and (featurep 'mac-carbon) (eq window-system 'mac) mac-key-mode)
           (define-key map [(alt meta return)] 'textmate-next-line)
           (define-key map [(alt meta t)] 'textmate-clear-cache)
           (define-key map [(alt meta \])] 'align)
           (define-key map [(alt meta \[)] 'indent-according-to-mode)
           (define-key map [(alt \])]  'textmate-shift-right)
           (define-key map [(alt \[)] 'textmate-shift-left)
           (define-key map [(meta /)] 'comment-or-uncomment-region-or-line)
           (define-key map [(alt t)] 'textmate-goto-file)
           (define-key map [(alt shift t)] 'textmate-goto-symbol))
          ((featurep 'ns)  ;; Emacs.app
           (define-key map [(super meta return)] 'textmate-next-line)
           (define-key map [(super meta t)] 'textmate-clear-cache)
           (define-key map [(super meta \])] 'align)
           (define-key map [(super meta \[)] 'indent-according-to-mode)
           (define-key map [(super \])]  'textmate-shift-right)
           (define-key map [(super \[)] 'textmate-shift-left)
           (define-key map [(super /)] 'comment-or-uncomment-region-or-line)
           (define-key map [(super t)] 'textmate-goto-file)
           (define-key map [(super shift t)] 'textmate-goto-symbol))
          (t ;; Any other version
           (define-key map [(meta return)] 'textmate-next-line)
           (define-key map [(control c)(control t)] 'textmate-clear-cache)
           (define-key map [(control c)(control a)] 'align)
           (define-key map [(control tab)] 'textmate-shift-right)
           (define-key map [(control shift tab)] 'textmate-shift-left)
           (define-key map [(control c)(control k)] 'comment-or-uncomment-region-or-line)
           (define-key map [(meta t)] 'textmate-goto-file)
           (define-key map [(meta shift t)] 'textmate-goto-symbol)))
          map))

(defvar *textmate-project-root* nil
  "Used internally to cache the project root.")
(defvar *textmate-project-files* '()
  "Used internally to cache the files in a project.")

(defvar *textmate-vcs-exclude* nil
  "string to give to grep -V to exclude some VCS paths from being grepped."
  )

(defvar *textmate-find-in-project-default* nil)

(defvar *textmate-find-in-project-type-default* nil)

(defvar *textmate-compile-default* nil)

;;; Bindings

(defun textmate-ido-fix ()
  "Add up/down keybindings for ido."
  (define-key ido-completion-map [up] 'ido-prev-match)
  (define-key ido-completion-map [down] 'ido-next-match))

(defun textmate-completing-read (&rest args)
  "Uses `*textmate-completing-function-alist*' to call the appropriate completing
function."
  (let ((reading-fn
         (cadr (assoc textmate-completing-library
                      *textmate-completing-function-alist*))))
  (apply (symbol-function reading-fn) args)))

;;; allow-line-as-region-for-function adds an "-or-line" version of
;;; the given comment function which (un)comments the current line is
;;; the mark is not active.  This code comes from Aquamac's osxkeys.el
;;; and is licensed under the GPL

(defmacro allow-line-as-region-for-function (orig-function)
`(defun ,(intern (concat (symbol-name orig-function) "-or-line"))
   ()
   ,(format "Like `%s', but acts on the current line if mark is not active." orig-function)
   (interactive)
   (if mark-active
       (call-interactively (function ,orig-function))
     (save-excursion
       ;; define a region (temporarily) -- so any C-u prefixes etc. are preserved.
       (beginning-of-line)
       (set-mark (point))
       (end-of-line)
       (call-interactively (function ,orig-function))))))

(defun textmate-define-comment-line ()
  "Add or-line (un)comment function if not already defined"
  (unless (fboundp 'comment-or-uncomment-region-or-line)
    (allow-line-as-region-for-function comment-or-uncomment-region)))

;;; Commands

(defun textmate-next-line ()
  "Inserts an indented newline after the current line and moves the point to it."
  (interactive)
  (end-of-line)
  (newline-and-indent))

;; http://chopmo.blogspot.com/2008/09/quickly-jumping-to-symbols.html
(defun textmate-goto-symbol ()
  "Update the imenu index and then use ido to select a symbol to navigate to.
Symbols matching the text at point are put first in the completion list."
  (interactive)
  (imenu--make-index-alist)
  (let ((name-and-pos '())
        (symbol-names '()))
    (flet ((addsymbols (symbol-list)
                       (when (listp symbol-list)
                         (dolist (symbol symbol-list)
                           (let ((name nil) (position nil))
                             (cond
                              ((and (listp symbol) (imenu--subalist-p symbol))
                               (addsymbols symbol))

                              ((listp symbol)
                               (setq name (car symbol))
                               (setq position (cdr symbol)))

                              ((stringp symbol)
                               (setq name symbol)
                               (setq position (get-text-property 1 'org-imenu-marker symbol))))

                             (unless (or (null position) (null name))
                               (add-to-list 'symbol-names name)
                               (add-to-list 'name-and-pos (cons name position))))))))
      (addsymbols imenu--index-alist))
    ;; If there are matching symbols at point, put them at the beginning of `symbol-names'.
    (let ((symbol-at-point (thing-at-point 'symbol)))
      (when symbol-at-point
        (let* ((regexp (concat (regexp-quote symbol-at-point) "$"))
               (matching-symbols (delq nil (mapcar (lambda (symbol)
                                                     (if (string-match regexp symbol) symbol))
                                                   symbol-names))))
          (when matching-symbols
            (sort matching-symbols (lambda (a b) (> (length a) (length b))))
            (mapc (lambda (symbol) (setq symbol-names (cons symbol (delete symbol symbol-names))))
                  matching-symbols)))))
    (let* ((selected-symbol (ido-completing-read "Symbol? " symbol-names))
           (position (cdr (assoc selected-symbol name-and-pos))))
      (goto-char position))))

(defun textmate-goto-file ()
  "Uses your completing read to quickly jump to a file in a project."
  (interactive)
  (let ((root (textmate-project-root)))
    (when (null root)
      (error
       (concat
        "Can't find a suitable project root ("
        (string-join " " *textmate-project-roots* )
        ")")))
    (find-file
     (concat
      (expand-file-name root) "/"
      (textmate-completing-read
       "Find file: "
       (textmate-project-files root))))))

(defun textmate-find-in-project-type ()
  "Run grep over project files of a specific type and put the results
in a grep-mode buffer."
  (interactive)
  (let ((pat (read-string (concat "Suffix"
                                  (if *textmate-find-in-project-type-default*
                                      (format " [\"%s\"]" *textmate-find-in-project-type-default*)
                                    "")
                                  ": "
                                  ) nil nil *textmate-find-in-project-type-default*)))
    (setq *textmate-find-in-project-type-default* pat)
    (textmate-find-in-project (concat "*." pat))))

(defun textmate-start-compile-in-root (command &optional mode
                                                         name-function
                                                         highlight-regexp)
  "Idential to compilation-start, except it automatically changes to the
project root directory before starting the command."
  (let ((root (textmate-project-root)))
    (when (null root)
      (error "Not in a project area."))
    (let ((realcommand (concat "cd " root " ; " command)))
      (compilation-start realcommand mode name-function highlight-regexp))))

(defun textmate-compile ()
  "Run a command in compilation-mode rooted at the project root."
  (interactive)
  (let* ((default *textmate-compile-default*)
         (command (read-string
                   (concat "Command"
                           (if default (format " [\"%s\"]" default) "")
                           ": ") nil 'textmate-compile-history default)))
    (setq *textmate-compile-default* command)
    (textmate-start-compile-in-root command)))

(defun textmate-find-in-project (&optional pattern)
  "Run grep over project files with results in grep-mode.

Takes an optional argument (see also textmate-find-in-project-type)
of a file extension to limit the search. Useful for finding results in only a
specific type of file."
  (interactive)
    (let* ((default *textmate-find-in-project-default*)
           (re (read-string (concat "Search for "
                         (if (and default (> (length default) 0))
                             (format "[\"%s\"]" default)) ": ")
                 nil 'textmate-find-in-project-history default))
          (incpat (if pattern pattern "*"))
          (type (textmate-project-root-type (textmate-project-root)))
          (command
           (cond ((not (string= type "unknown"))
                   (concat (cond ((string= type "git") "git ls-files")
                                 ((string= type "hg") "hg manifest"))
                           (if *textmate-vcs-exclude*
                               (concat " | grep -v "
                                       (shell-quote-argument *textmate-vcs-exclude*))
                             "")
                           " | xargs egrep -nR "
                           (if pattern (concat " --include='" pattern "' ") "")
                           " -- "
                           (shell-quote-argument re)))
                  (t (concat "egrep -nR --exclude='"
                            *textmate-gf-exclude*
                            "' --include='"
                            incpat
                            "' -- "
                            (shell-quote-argument re)
                            " . | grep -vE '"
                            *textmate-gf-exclude*
                            "' | sed s:./::"
                            )))))
          (setq *textmate-find-in-project-default* re)
          (textmate-start-compile-in-root command 'grep-mode)))

(defun textmate-clear-cache ()
  "Clears the project root and project files cache. Use after adding files."
  (interactive)
  (setq *textmate-project-root* nil)
  (setq *textmate-project-files* nil)
  (message "textmate-mode cache cleared."))

(defun textmate-toggle-camel-case ()
  "Toggle current sexp between camelCase and snake_case, like TextMate C-_."
  (interactive)
  (if (thing-at-point 'word)
      (progn
        (unless (looking-at "\\<") (backward-sexp))
        (let ((case-fold-search nil)
              (start (point))
              (end (save-excursion (forward-sexp) (point))))
          (if (and (looking-at "[a-z0-9_]+") (= end (match-end 0))) ; snake-case
              (progn
                (goto-char start)
                (while (re-search-forward "_[a-z]" end t)
                  (goto-char (1- (point)))
                  (delete-char -1)
                  (upcase-region (point) (1+ (point)))
                  (setq end (1- end))))
            (downcase-region (point) (1+ (point)))
            (while (re-search-forward "[A-Z][a-z]" end t)
              (forward-char -2)
              (insert "_")
              (downcase-region (point) (1+ (point)))
              (forward-char 1)
              (setq end (1+ end)))
            (downcase-region start end)
            )))))

;;; Utilities

(defun textmate-project-root-type (root)
  (cond ((member ".git" (directory-files root)) "git")
        ((member ".hg" (directory-files root)) "hg")
        (t "unknown")
   ))

(defun textmate-project-files (root)
  "Finds all files in a given project using either hg, git, or find."
  (let ((type (textmate-project-root-type root)))
    (cond ((string= type "git") (split-string
                           (shell-command-to-string
                            (concat "cd " root " && git ls-files")) "\n" t))
          ((string= type "hg") (split-string
                          (shell-command-to-string
                           (concat "cd " root " && hg manifest")) "\n" t))
          ((string= type "unknown") (textmate-cached-project-files-find root))
  )))

(defun textmate-project-files-find (root)
  "Finds all files in a given project using find."
  (split-string
    (shell-command-to-string
     (concat
      "find "
      root
      " -type f  | grep -vE '"
      *textmate-gf-exclude*
      "' | sed 's:"
      *textmate-project-root*
      "/::'")) "\n" t))

(defun textmate-cached-project-files-find (&optional root)
  "Finds and caches all files in a given project using find."
  (cond
   ((null textmate-use-file-cache) (textmate-project-files root))
   ((equal (textmate-project-root) (car *textmate-project-files*))
    (cdr *textmate-project-files*))
   (t (cdr (setq *textmate-project-files*
                 `(,root . ,(textmate-project-files-find root)))))))

(defun textmate-project-root ()
  "Returns the current project root."
  (when (or
         (null *textmate-project-root*)
         (not (string-match *textmate-project-root* default-directory))
         (not (string-match *textmate-project-root* (getenv "HOME"))))
    (let ((root (textmate-find-project-root)))
      (if root
          (setq *textmate-project-root* (expand-file-name (concat root "/")))
        (setq *textmate-project-root* nil))))
  *textmate-project-root*)

(defun root-match(root names)
        (member (car names) (directory-files root)))

(defun root-matches(root names)
        (if (root-match root names)
                        (root-match root names)
                        (if (eq (length (cdr names)) 0)
                                        'nil
                                        (root-matches root (cdr names))
                                        )))

(defun textmate-find-project-root (&optional root)
  "Determines the current project root by recursively searching for an indicator."
  (when (null root) (setq root default-directory))
  (cond
   ((root-matches root *textmate-project-roots*)
                (expand-file-name root))
   ((equal (expand-file-name root) "/") nil)
   (t (textmate-find-project-root (concat (file-name-as-directory root) "..")))))

(defun textmate-shift-right (&optional arg)
  "Shift the line or region to the ARG places to the right.

A place is considered `tab-width' character columns."
  (interactive)
  (let ((deactivate-mark nil)
        (beg (or (and mark-active (region-beginning))
                 (line-beginning-position)))
        (end (or (and mark-active (region-end)) (line-end-position))))
    (indent-rigidly beg end (* (or arg 1) tab-width))))

(defun textmate-shift-left (&optional arg)
  "Shift the line or region to the ARG places to the left."
  (interactive)
  (textmate-shift-right (* -1 (or arg 1))))

;;;###autoload
(define-minor-mode textmate-mode "TextMate Emulation Minor Mode"
  :lighter " mate" :global t :keymap *textmate-mode-map*
  (add-hook 'ido-setup-hook 'textmate-ido-fix)
  (textmate-define-comment-line)
  ; activate preferred completion library
  (dolist (mode *textmate-completing-minor-mode-alist*)
    (if (eq (car mode) textmate-completing-library)
        (funcall (cadr mode) t)
      (when (fboundp
             (cadr (assoc (car mode) *textmate-completing-function-alist*)))
        (funcall (cadr mode) -1)))))

(provide 'textmate)
;;; textmate.el ends here
