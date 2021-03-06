TextMate Minor Mode
===================

    ;; This minor mode exists to mimick TextMate's awesome
    ;; features.

    ;;    ⌘T - Go to File
    ;;  ⇧⌘T - Go to Symbol
    ;;    ⌘L - Go to Line
    ;;    ⌘/ - Comment Line (or Selection/Region)
    ;;    ⌘] - Shift Right (currently indents region)
    ;;    ⌘[ - Shift Left  (not yet implemented)
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

    ;; In other words, calling Go to File from
    ;; ~/Projects/fieldrunners/app/views/towers/show.html.erb will use
    ;; ~/Projects/fieldrunners/ as the root if ~/Projects/fieldrunners/.git
    ;; exists.

Installation
============

    $ cd ~/.emacs.d/vendor
    $ git clone git://github.com/defunkt/textmate.el.git

In your emacs config:

    (add-to-list 'load-path "~/.emacs.d/vendor/textmate.el")
    (require 'textmate)
    (textmate-mode)

See the file for more configuration options.

Authors
======

    Adam Glasgall // adam@dropio.com
    Augie Fackler // durin42@gmail.com
    Carl Porth // badcarl@gmail.com
    Chris Wanstrath // chris@ozmm.org
    Federico Builes // federico.builes@gmail.com
    Nick Sieger // nick@nicksieger.com
