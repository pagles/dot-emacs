;;; init.el -*- lexical-binding: t; -*-

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(setq use-package-always-defer t)

;;;; Basics
(setq custom-file (locate-user-emacs-file "custom.el")
      make-backup-files nil
      create-lockfiles nil
      auto-save-default nil
      ring-bell-function #'ignore
      use-short-answers t)
(load custom-file 'noerror)
(setq-default indent-tabs-mode nil)

(savehist-mode 1)
(recentf-mode 1)
(which-key-mode 1)
(column-number-mode 1)

;; Agents edit files on disk; keep buffers in sync without prompts.
(global-auto-revert-mode 1)
(setq auto-revert-avoid-polling t
      auto-revert-verbose nil
      global-auto-revert-non-file-buffers t)

;;;; Look
(setq-default fill-column 120)                      ; same as ruff's line-length
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)

;; GitHub Light colours applied to the built-in modus-operandi theme.
(setq modus-operandi-palette-overrides
      '((bg-main "#ffffff") (fg-main "#1f2328") (fg-dim "#59636e")
        (keyword "#cf222e") (preprocessor "#cf222e")
        (builtin "#0550ae") (constant "#0550ae")
        (string "#0a3069") (docstring "#0a3069")
        (fnname "#8250df") (type "#953800") (variable fg-main)
        (comment "#59636e")
        (bg-region "#ddf4ff") (fg-region unspecified)
        (bg-hl-line "#f6f8fa") (fringe "#ffffff")
        (fg-line-number-inactive "#8c959f") (bg-line-number-inactive "#ffffff")
        (fg-line-number-active "#1f2328") (bg-line-number-active "#f6f8fa")
        (bg-mode-line-active "#f6f8fa") (fg-mode-line-active "#1f2328")
        (border-mode-line-active "#d0d7de")))
(load-theme 'modus-operandi t)
;; Thin line: no background (fills the whole cell in a terminal).
(setq-default display-fill-column-indicator-character ?│)
(set-face-attribute 'fill-column-indicator nil
                    :foreground "#d0d7de" :background 'unspecified)

;; Mouse clicks and scrolling in terminal frames.
(xterm-mouse-mode 1)

;; Terminal frames share the macOS clipboard via pbcopy/pbpaste, so kills
;; (M-w, C-w, mouse selections) reach Cmd-V elsewhere and C-y pastes from it.
;; GUI frames keep the built-in clipboard handling.
(defun my/clipboard-cut (text)
  (if (display-graphic-p)
      (gui-select-text text)
    (let ((process-environment (cons "LANG=en_US.UTF-8" process-environment))
          (process-connection-type nil)
          (coding-system-for-write 'utf-8))
      (let ((proc (start-process "pbcopy" nil "pbcopy")))
        (process-send-string proc text)
        (process-send-eof proc)))))

(defun my/clipboard-paste ()
  (if (display-graphic-p)
      (gui-selection-value)
    (let* ((process-environment (cons "LANG=en_US.UTF-8" process-environment))
           (coding-system-for-read 'utf-8)
           (text (shell-command-to-string "pbpaste")))
      (unless (or (string-empty-p text) (equal text (car kill-ring)))
        text))))

(setq interprogram-cut-function #'my/clipboard-cut
      interprogram-paste-function #'my/clipboard-paste
      mouse-drag-copy-region t)          ; selecting with the mouse copies, like iTerm

;;;; Minibuffer completion
(use-package vertico :ensure t :init (vertico-mode))
(use-package marginalia :ensure t :init (marginalia-mode))
(use-package orderless :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package consult :ensure t
  :bind (("C-x b" . consult-buffer)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ("M-g g" . consult-goto-line)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line))
  :init
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref))

;;;; In-buffer completion
(use-package corfu :ensure t
  :init (global-corfu-mode)
  :custom (corfu-auto t))

;;;; Tree-sitter (python-ts-mode etc.), prompts once per grammar
(use-package treesit-auto :ensure t :demand t
  :custom (treesit-auto-install 'prompt)
  :config
  ;; Markdown goes to markdown-mode (gfm-mode) instead; see below.
  (setq treesit-auto-langs (remq 'markdown treesit-auto-langs))
  (global-treesit-auto-mode))

;;;; Markdown (plan files, READMEs)
(use-package markdown-mode :ensure t
  :mode ("\\.md\\'" . gfm-mode)
  :hook (markdown-mode . visual-line-mode)   ; soft-wrap long lines
  :custom
  (markdown-fontify-code-blocks-natively t)  ; code blocks in their language's colours
  (markdown-header-scaling t)                ; bigger headings (GUI only)
  (markdown-hide-markup t)                   ; read like rendered text; toggle C-c C-x C-m
  (markdown-list-indent-width 2))

;; Highlighting for ```mermaid blocks (and .mmd files).
(use-package mermaid-mode :ensure t
  :mode "\\.mmd\\'")

;;;; Drawer: file tree (left), shows whichever project the current file is in
(use-package dired-subtree :ensure t)    ; in-place folder expansion; dired-sidebar needs it
(use-package dired-sidebar :ensure t
  :bind ("C-c t" . dired-sidebar-toggle-sidebar)
  :custom
  ;; No idle timers: with one daemon serving several windows (one per worktree)
  ;; they keep re-reading trees and hang Emacs. The tree opens on the current
  ;; project when toggled, and global-auto-revert-mode refreshes it on changes.
  (dired-sidebar-should-follow-file nil)
  (dired-sidebar-refresh-on-special-commands nil)
  (dired-sidebar-delay-auto-revert-updates nil)
  (dired-sidebar-theme 'ascii)           ; plain markers, safe in the terminal
  (dired-sidebar-width 35))

;;;; Drawer: current file's structure (right)
(use-package imenu-list :ensure t
  :bind ("C-c s" . imenu-list-smart-toggle)
  :custom
  (imenu-list-position 'right)
  (imenu-list-size 40)
  (imenu-list-focus-after-activation nil) ; keep the cursor in the file
  (imenu-list-auto-resize nil))

;;;; Projects / worktrees
(defun my/remember-worktrees ()
  "Register every git checkout under ~/Workbench as a project."
  (interactive)
  (project-remember-projects-under (expand-file-name "~/Workbench")))

;;;; LSP: ty
(defun my/eglot-ty (&optional _interactive project)
  "Run the ty from the project's .venv, falling back to ty on PATH."
  (let* ((proj (or project (project-current)))
         (root (if proj (project-root proj) default-directory))
         (local (expand-file-name ".venv/bin/ty" root)))
    (list (if (file-executable-p local) local "ty") "server")))

(use-package eglot
  :hook ((python-mode python-ts-mode) . eglot-ensure)
  :bind (:map eglot-mode-map
         ("C-c r" . eglot-rename)
         ("C-c a" . eglot-code-actions)
         ("C-c h" . eldoc-doc-buffer))
  :custom
  (eglot-autoshutdown t)                 ; stop ty when a worktree's last buffer closes
  (eglot-extend-to-xref t)               ; keep site-packages files on the same server
  (eglot-events-buffer-config '(:size 0 :format full)) ; no logging overhead
  :config
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) . my/eglot-ty)))
