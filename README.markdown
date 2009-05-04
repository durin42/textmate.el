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
    
    ;; A "project" in textmate-mode is determined by the presence of
    ;; a .git directory. If no .git directory is found in your current
    ;; directory, textmate-mode will traverse upwards until one (or none)
    ;; is found. The directory housing the .git directory is presumed
    ;; to be the project's root.
    
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

Configuration
=============

To ignore additional files in a "project", use textmate-also-ignore in your emacs config.  For example if you had a directory named "gems" and a directory named "bin" that you wanted to ignore, you would add the following to your emacs config:

    (textmate-also-ignore "bin|gems")
