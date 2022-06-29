;; defcustoms
(setq rackscratch-path "/var/tmp/racket/") ; TODO: make platform-independent
(setq rackscratch-template-path "~/.racket-mode/scratch/templates/") ; TODO: make platform-independent
(setq rackscratch-session-name nil)
(setq rackscratch-major-mode 'racket-mode)
(setq rackscratch-file-extension ".rkt")
(setq rackscratch-default-template-name "racket.rkt")
(setq rackscratch-default-template
      (concat (file-name-as-directory rackscratch-template-path)
              rackscratch-default-template-name))

(defun rackscratch--unique-session-name ()
  "Unique name for a scratch buffer session."
  (let ((time (current-time)))
    (concat (format-time-string "%Y-%m-%d" time)
            "-"
            (sha1 (format "%s" time)))))

(defun rackscratch-write (index)
  "Write scratch buffer to disk with index INDEX."
  (let* ((session (or rackscratch-session-name
                      (rackscratch--unique-session-name)))
         (base-path (concat (file-name-as-directory rackscratch-path)
                            (file-name-as-directory session)))
         (index (or index 1)))
    (unless (file-directory-p base-path)
      (mkdir base-path t))
    (write-file
     (concat base-path
             (format "%d" index)
             rackscratch-file-extension))))

(defun rackscratch--ensure-templates-exist ()
  "Ensure that the templates directory exists and contains the default template."
  (unless (file-directory-p rackscratch-template-path)
    (mkdir rackscratch-template-path t)
    (let ((buf (generate-new-buffer "default-template")))
      (with-current-buffer buf
        (insert "#lang racket\n\n")
        (write-file (concat rackscratch-template-path
                            rackscratch-default-template-name)))
      (kill-buffer buf))))

(defun rackscratch-insert-template (template)
  "Insert TEMPLATE into the current buffer."
  (rackscratch--ensure-templates-exist)
  (insert-file-contents template))

(cl-defun rackscratch--new-scratch-buffer (buffer-name template &optional index)
  "Create a new empty buffer.

The buffer will be named BUFFER-NAME and will be created in the
currently active (at the time of command execution) major mode.
As a \"scratch\" buffer, its contents will be treated as
disposable, and it will not prompt to save if it is closed or
if Emacs is exited.

Modified from:
URL `https://ergoemacs.org/emacs/emacs_new_empty_buffer.html'
Version 2017-11-01"
  (interactive)
  (let ((buf (generate-new-buffer buffer-name))
        (major-mode-to-use rackscratch-major-mode))
    (with-current-buffer buf
      (funcall major-mode-to-use)
      (setq buffer-offer-save nil)
      (rackscratch-insert-template template)
      (goto-char (point-max))
      (rackscratch-write index)
      (rename-buffer buffer-name))
    buf))

(cl-defun rackscratch-get-or-create-scratch-buffer (&optional template)
  "Get the active scratch buffer or create a new one."
  (let* ((buffer-name "*scratch - Racket*")
         (buf (get-buffer buffer-name))
         (template (or template rackscratch-default-template)))
    (or buf (rackscratch--new-scratch-buffer buffer-name
                                             template))))

(defun rackscratch-switch-to-scratch-buffer ()
  "Switch to scratch buffer."
  (interactive)
  (let ((buf (rackscratch-get-or-create-scratch-buffer)))
    (switch-to-buffer buf)))

(defun rackscratch-switch-to-scratch-buffer-with-template (template)
  "Start a new scratch buffer using a specific template."
  (interactive (list (read-file-name "Which template? " rackscratch-template-path)))
  (let ((buf (rackscratch-get-or-create-scratch-buffer template)))
    (switch-to-buffer buf)))
