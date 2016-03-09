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
(global-set-key "\C-x\C-m" 'execute-extended-command)
(global-set-key (kbd "\C-x\C-b") 'ibuffer)

(set-frame-font "Menlo-12")

(require 'ido)
(ido-mode t)

(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)

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
  (setq jedi:complete-on-dot t))

;; M-x jedi:install-server after running for the first time or after updates

(el-get-bundle color-theme)

(el-get-bundle color-theme-cobalt
  :url "https://github.com/nickewing/color-theme-cobalt.git")

(el-get-bundle highlight-indentation)

(el-get-bundle flymake-easy)

(el-get-bundle flymake-python-pyflakes)

(el-get-bundle virtualenvwrapper)

(el-get-bundle magit)

(el-get-bundle ag)

; cobalt color theme
(when (string-match "apple-darwin" system-configuration)
  (setq mac-allow-anti-aliasing t))

(require 'color-theme)
(color-theme-initialize)
(load-file "~/.emacs.d/el-get/color-theme-cobalt/color-theme-cobalt.el")

(if window-system
  (color-theme-cobalt)
)


; show indentation in python mode
(require 'highlight-indentation)
(add-hook 'python-mode-hook 'highlight-indentation-mode)


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


; magit
(global-set-key (kbd "C-x g") 'magit-status)


; ag
; this needs the silver searcher installed
; brew install the_silver_searcher
(require 'ag)
(setq ag-highlight-search t)
