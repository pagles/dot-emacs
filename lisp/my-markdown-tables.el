;;; my-markdown-tables.el --- Display-only alignment of Markdown tables -*- lexical-binding: t; -*-

;;; Commentary:

;; Pads GFM pipe tables with overlays so columns line up by their *visible*
;; width (after `markdown-hide-markup' hides backticks, asterisks and so on),
;; and draws the borders with box characters.  The buffer text is never
;; changed, so files edited on disk by other tools stay untouched.
;;
;; Active only while markup is hidden; `C-c C-x C-m' shows the raw source.

;;; Code:

(require 'markdown-mode)

(defvar-local my/md-tables--timer nil)

(defun my/md-tables--visible-width (beg end)
  "Columns the text between BEG and END takes on screen."
  (let ((pos beg) (width 0))
    (while (< pos end)
      (let ((display (get-char-property pos 'display))
            (comp (find-composition pos nil nil t)))
        (cond
         ((invisible-p pos)
          (setq pos (min end (next-single-char-property-change pos 'invisible nil end))))
         ((stringp display)
          (setq width (+ width (string-width display))
                pos (min end (next-single-char-property-change pos 'display nil end))))
         ((and comp (= (car comp) pos))
          (setq width (+ width 1) pos (min end (cadr comp))))
         (t
          (setq width (+ width (char-width (char-after pos))) pos (1+ pos))))))
    width))

(defun my/md-tables--pipes (bol eol)
  "Positions of the cell-separating pipes on the line BOL..EOL.
Pipes inside code spans or escaped with a backslash don't count."
  (let ((pos bol) (in-code nil) (pipes nil))
    (while (< pos eol)
      (let ((c (char-after pos)))
        (cond ((and (eq c ?\\) (not in-code)) (setq pos (1+ pos)))
              ((eq c ?`) (setq in-code (not in-code)))
              ((and (eq c ?|) (not in-code)) (push pos pipes))))
      (setq pos (1+ pos)))
    (nreverse pipes)))

(defun my/md-tables--separator-p ()
  (looking-at-p "^[ \t]*|?[ \t]*:?-+:?[ \t]*\\(|[ \t]*:?-+:?[ \t]*\\)*|?[ \t]*$"))

(defun my/md-tables--row-p ()
  (and (looking-at-p "^[ \t]*|")
       (not (markdown-code-block-at-pos (point)))))

(defun my/md-tables--overlay (beg end &rest props)
  (let ((ov (make-overlay beg end nil t nil)))
    (overlay-put ov 'my-md-table t)
    (overlay-put ov 'evaporate nil)
    (while props
      (overlay-put ov (pop props) (pop props)))
    ov))

(defun my/md-tables--pad (pos text)
  "Show TEXT at POS (an empty position)."
  (my/md-tables--overlay pos pos 'before-string text))

(defun my/md-tables--cells (bol eol)
  "List of (BEG . END) for each cell on the row BOL..EOL, trimmed of spaces."
  (let* ((pipes (my/md-tables--pipes bol eol))
         (bounds (append pipes
                         ;; A row may omit its closing pipe.
                         (save-excursion
                           (goto-char eol)
                           (skip-chars-backward " \t" bol)
                           (unless (eq (char-before) ?|) (list (point))))))
         (cells nil))
    (while (cdr bounds)
      (push (cons (1+ (car bounds)) (cadr bounds)) cells)
      (setq bounds (cdr bounds)))
    (cons pipes (nreverse cells))))

(defun my/md-tables--render (rows)
  "Align one table.  ROWS is a list of (BOL EOL SEPARATOR-P)."
  (let* ((parsed (mapcar (lambda (r)
                           (pcase-let ((`(,bol ,eol ,sep) r))
                             (list bol eol sep (my/md-tables--cells bol eol))))
                         rows))
         (ncols (apply #'max (mapcar (lambda (p) (length (cdr (nth 3 p)))) parsed)))
         (widths (make-vector ncols 1)))
    ;; Column widths from the visible content of non-separator rows.
    (dolist (p parsed)
      (unless (nth 2 p)
        (let ((i 0))
          (dolist (cell (cdr (nth 3 p)))
            (save-excursion
              (goto-char (car cell)) (skip-chars-forward " \t" (cdr cell))
              (let ((tb (point)))
                (goto-char (cdr cell)) (skip-chars-backward " \t" tb)
                (aset widths i (max (aref widths i)
                                    (my/md-tables--visible-width tb (point))))))
            (setq i (1+ i))))))
    (let ((first t))
      (dolist (p parsed)
        (pcase-let ((`(,bol ,eol ,sep (,pipes . ,cells)) p))
          (if sep
              (let ((start (save-excursion (goto-char bol)
                                           (skip-chars-forward " \t" eol) (point))))
                (my/md-tables--overlay
                 start eol 'display
                 (concat "├"
                         (mapconcat (lambda (w) (make-string (+ w 2) ?─)) widths "┼")
                         "┤")
                 'face 'shadow))
            (dolist (pipe pipes)
              (my/md-tables--overlay pipe (1+ pipe) 'display "│" 'face 'shadow))
            (let ((i 0))
              (dolist (cell cells)
                (let* ((cb (car cell)) (ce (cdr cell))
                       (tb (save-excursion (goto-char cb) (skip-chars-forward " \t" ce) (point)))
                       (te (save-excursion (goto-char ce) (skip-chars-backward " \t" tb) (point)))
                       (w (aref widths i))
                       (pad (make-string (- (+ w 1) (my/md-tables--visible-width tb te)) ?\s)))
                  (if (> tb cb)
                      (my/md-tables--overlay cb tb 'display " ")
                    (my/md-tables--pad cb " "))
                  (if (> ce te)
                      (my/md-tables--overlay te ce 'display pad)
                    (my/md-tables--pad ce pad))
                  (when (and first (> te tb))
                    (my/md-tables--overlay tb te 'face 'bold)))
                (setq i (1+ i)))
              ;; Short rows: draw the missing cells, and the closing pipe.
              (let ((tail (concat (if (= (length pipes) (1+ (length cells))) "" "│")
                                  (mapconcat (lambda (j) (concat (make-string (+ (aref widths j) 2) ?\s) "│"))
                                             (number-sequence i (1- ncols)) ""))))
                (unless (string-empty-p tail)
                  (my/md-tables--pad
                   (save-excursion (goto-char eol) (skip-chars-backward " \t" bol) (point))
                   (propertize tail 'face 'shadow))))))
          (setq first nil))))))

(defun my/md-tables-refresh ()
  "Re-align every table in the buffer."
  (interactive)
  (save-excursion
    (save-restriction
      (widen)
      (remove-overlays (point-min) (point-max) 'my-md-table t)
      (when markdown-hide-markup
        (font-lock-ensure)
        (goto-char (point-min))
        (while (not (eobp))
          (if (not (my/md-tables--row-p))
              (forward-line 1)
            (let ((rows nil))
              (while (and (not (eobp)) (my/md-tables--row-p))
                (push (list (line-beginning-position) (line-end-position)
                            (my/md-tables--separator-p))
                      rows)
                (forward-line 1))
              (setq rows (nreverse rows))
              ;; A GFM table needs a header row followed by a separator row.
              (when (and (cdr rows) (nth 2 (cadr rows)) (not (nth 2 (car rows))))
                (my/md-tables--render rows)))))))))

(defun my/md-tables--schedule (&rest _)
  (when (timerp my/md-tables--timer) (cancel-timer my/md-tables--timer))
  (let ((buf (current-buffer)))
    (setq my/md-tables--timer
          (run-with-idle-timer
           0.3 nil
           (lambda ()
             (when (buffer-live-p buf)
               (with-current-buffer buf
                 (setq my/md-tables--timer nil)
                 (when (bound-and-true-p my/md-tables-mode) (my/md-tables-refresh)))))))))

(define-minor-mode my/md-tables-mode
  "Align Markdown tables on screen without changing the text."
  :lighter nil
  (if my/md-tables-mode
      (progn
        (add-hook 'after-change-functions #'my/md-tables--schedule nil t)
        (my/md-tables--schedule))
    (remove-hook 'after-change-functions #'my/md-tables--schedule t)
    (remove-overlays (point-min) (point-max) 'my-md-table t)))

;; Showing the raw markup (C-c C-x C-m) shows the raw tables too.
(advice-add 'markdown-toggle-markup-hiding :after
            (lambda (&rest _) (when my/md-tables-mode (my/md-tables-refresh))))

(provide 'my-markdown-tables)
;;; my-markdown-tables.el ends here
