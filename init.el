;; emacs configuration

(push "/usr/local/bin" exec-path)
(push "/usr/local/share/python" exec-path)
(setenv "PATH" (concat (getenv "PATH") ":/usr/local/bin"))

(setq make-backup-files nil)
(setq auto-save-default nil)
(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)
(setq inhibit-startup-message t)

(fset 'yes-or-no-p 'y-or-n-p)

(delete-selection-mode t)
(scroll-bar-mode -1)
(tool-bar-mode -1)
(blink-cursor-mode t)
(show-paren-mode t)
(column-number-mode t)
(set-fringe-style -1)
(tooltip-mode -1)

(global-linum-mode 1)
(define-key global-map (kbd "RET") 'newline-and-indent)
(global-set-key (kbd "\C-x\C-b") 'ibuffer)

(set-frame-font "Menlo-12")

(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)

(when (string-match "apple-darwin" system-configuration)
  (setq mac-allow-anti-aliasing t))

(add-to-list 'load-path "~/.emacs.d/el-get/el-get")

(unless (require 'el-get nil 'noerror)
  (with-current-buffer
      (url-retrieve-synchronously
       "https://raw.githubusercontent.com/dimitri/el-get/master/el-get-install.el")
    (goto-char (point-max))
    (eval-print-last-sexp)))

(add-to-list 'el-get-recipe-path "~/.emacs.d/el-get-user/recipes")

(el-get-bundle jedi
  (add-hook 'python-mode-hook 'jedi:setup)
  (eval-when-compile (require 'jedi nil t))
  (setq jedi:complete-on-dot t)
  (define-key jedi-mode-map (kbd "C-.") 'jedi:complete))

;; M-x jedi:install-server after running for the first time or after updates

(el-get-bundle cobalt2-theme
  :url "https://github.com/chalmagean/cobalt2-emacs.git")

(el-get-bundle solarized-emacs)

(el-get-bundle highlight-indentation)

(el-get-bundle flymake-easy)

(el-get-bundle flymake-cursor)

(el-get-bundle flymake-python-pyflakes)

(el-get-bundle virtualenvwrapper)

(el-get-bundle magit)

(el-get-bundle ag)

(el-get-bundle projectile)

(el-get-bundle helm)

(el-get-bundle helm-projectile)

(el-get-bundle helm-ag)

(el-get-bundle yasnippet)

(el-get-bundle helm-c-yasnippet)

(el-get-bundle emacs-neotree
    :url "https://github.com/jaypei/emacs-neotree.git")


; theme
(add-to-list 'custom-theme-load-path "~/.emacs.d/el-get/cobalt2-theme")
(if window-system
    (load-theme 'solarized-light t))


; show indentation in python mode
(require 'highlight-indentation)
(add-hook 'python-mode-hook 'highlight-indentation-mode)


; show flymake errors in minibuf instead of popup
(require 'flymake-cursor)


; flymake with flake8
(require 'flymake-python-pyflakes)
(add-hook 'python-mode-hook 'flymake-python-pyflakes-load)
(setq flymake-python-pyflakes-executable "flake8")
(setq flymake-python-pyflakes-extra-arguments '("--ignore=W293"))


; virtualenvwrapper setup
(require 'virtualenvwrapper)
(venv-initialize-interactive-shells) ;; if you want interactive shell support
(venv-initialize-eshell) ;; if you want eshell support
(setq venv-location "~/.virtualenvs/")
(setq-default mode-line-format (cons '(:exec venv-current-name) mode-line-format))


; magit
(global-set-key (kbd "C-x g") 'magit-status)


; ag
; this needs the silver searcher installed
; brew install the_silver_searcher
(require 'ag)
(setq ag-highlight-search t)


; projectile
(projectile-global-mode)


; helm
(require 'helm-config)
(helm-mode 1)
(global-set-key "\C-x\C-m" 'helm-M-x)
(global-set-key (kbd "M-x") 'helm-M-x)
(global-set-key (kbd "C-x C-f") 'helm-find-files)


; helm-projectile
;; (setq helm-projectile-fuzzy-match nil)
(require 'helm-projectile)
(helm-projectile-on)


; neotree
(require 'neotree)
(setq projectile-switch-project-action 'neotree-projectile-action)
(global-set-key (kbd "C-x n") 'neotree-toggle)
(global-set-key (kbd "C-x C-n") 'neotree-toggle)
(setq neo-theme 'nerd)


; yasnippert
(require 'yasnippet)
(require 'helm-c-yasnippet)
(setq helm-yas-space-match-any-greedy t)
(global-set-key (kbd "C-c y") 'helm-yas-complete)
(yas-global-mode 1)


; custom settings
(custom-set-variables
 '(safe-local-variable-values (quote ((Encoding . utf-8)))))
