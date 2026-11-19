;;; my-worktree-frames.el --- One frame per worktree, via beframe  -*- lexical-binding: t; -*-

;; Each `emacs' (emacsclient -t) frame belongs to the git checkout it was
;; started in.  beframe limits buffer switching to the frame's own buffers,
;; agents open files with `my/visit' so they land in the right frame, and
;; closing a frame kills the file buffers only it was using.

(require 'beframe)
(require 'seq)

(defun my/worktree-root (path)
  "Return the root of the git checkout containing PATH, or nil."
  (when-let* ((root (locate-dominating-file (expand-file-name path) ".git")))
    (file-name-as-directory (expand-file-name root))))

(defun my/worktree-buffers (root)
  "Return live buffers visiting files under ROOT."
  (seq-filter (lambda (buf)
                (when-let* ((file (buffer-file-name buf)))
                  (string-prefix-p root (expand-file-name file))))
              (buffer-list)))

(defun my/worktree-frame (root)
  "Return a live frame tied to ROOT, or nil."
  (seq-find (lambda (frame) (equal (frame-parameter frame 'my/worktree) root))
            (frame-list)))

(defun my/worktree-frame-setup (frame &optional _name)
  "Tie FRAME to the checkout its emacsclient was started in.
Used as `beframe-rename-function'.  Files from that checkout that are
already open join the frame's buffer list."
  (let* ((proc (frame-parameter frame 'client))
         (dir (or (and (processp proc) (process-get proc 'server-client-directory))
                  default-directory))
         (root (my/worktree-root dir)))
    (if (not root)
        (beframe-rename-frame frame)
      (set-frame-parameter frame 'my/worktree root)
      (beframe-rename-frame frame (file-name-nondirectory (directory-file-name root)))
      (modify-frame-parameters
       frame `((buffer-list . ,(seq-uniq (append (frame-parameter frame 'buffer-list)
                                                 (my/worktree-buffers root)))))))))

(defun my/visit (file)
  "Open FILE in the frame of its checkout and return that frame's name.
Meant for `emacsclient -e'.  With no frame for the checkout, the file is
loaded in the background; a frame opened there later picks it up."
  (let* ((file (expand-file-name file))
         (root (my/worktree-root file))
         (frame (and root (my/worktree-frame root)))
         (buf (find-file-noselect file)))
    (if (not frame)
        "no frame for this worktree; run emacs there to see it"
      (with-selected-frame frame
        (switch-to-buffer buf))
      (frame-parameter frame 'name))))

(defun my/worktree-frame-cleanup (frame)
  "Kill FRAME's unmodified file buffers that no other frame uses."
  (let ((others (remq frame (frame-list))))
    (dolist (buf (frame-parameter frame 'buffer-list))
      (when (and (buffer-live-p buf)
                 (buffer-file-name buf)
                 (not (buffer-modified-p buf))
                 (not (seq-some (lambda (other) (memq buf (frame-parameter other 'buffer-list)))
                                others)))
        (kill-buffer buf)))))

(add-hook 'delete-frame-functions #'my/worktree-frame-cleanup)

;; C-x b (consult-buffer) lists this frame's buffers instead of all of them.
(with-eval-after-load 'consult
  (defvar my/beframe-consult-source
    `( :name     "Frame buffers"
       :narrow   ?F
       :category buffer
       :face     consult-buffer
       :history  beframe-history
       :items    ,(lambda () (beframe-buffer-names nil :sort #'beframe-buffer-sort-visibility))
       :action   ,#'switch-to-buffer
       :state    ,#'consult--buffer-state))
  (consult-customize consult-source-buffer :hidden t :default nil)
  (add-to-list 'consult-buffer-sources 'my/beframe-consult-source))

(provide 'my-worktree-frames)
;;; my-worktree-frames.el ends here
