;;; early-init.el -*- lexical-binding: t; -*-

;; Skip garbage collection during startup, then settle on a sane threshold.
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 64 1024 1024))))

;; LSP servers send large responses.
(setq read-process-output-max (* 4 1024 1024))

(setq package-quickstart t
      native-comp-async-report-warnings-errors 'silent
      inhibit-startup-screen t
      frame-inhibit-implied-resize t)

;; Set in the frame parameters so the first frame (and emacsclient frames
;; from the daemon) are created with the right font, without a resize.
(push '(font . "Monaco-13") default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; GUI Emacs doesn't inherit the shell PATH. Set it directly (fast)
;; instead of spawning a shell with exec-path-from-shell (slow).
(dolist (dir '("~/.local/share/mise/shims" "~/.local/bin" "/opt/homebrew/bin"))
  (let ((d (expand-file-name dir)))
    (add-to-list 'exec-path d)
    (setenv "PATH" (concat d ":" (getenv "PATH")))))
