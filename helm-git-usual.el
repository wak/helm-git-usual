;;; helm-git-usual.el --- list frequently used git files

;; Copyright (c) 2018 Hiroaki Wakabayashi

;; Package-Requires: ((helm "2.9.0"))

;;; Code

(defcustom helm-git-usual-repositories '(("env" . "~/")
                                         ("tips" . "~/work/tips"))
  "List of repositories."
  :group 'helm-git-usual)


(defvar helm-git-usual-candidates nil)
(defvar helm-git-usual-sources nil)

;;;###autoload
(defun helm-git-usual-clear ()
  (interactive)
  (setq helm-git-usual-candidates nil)
  (setq helm-git-usual-sources nil))

(defun helm-git-usual-init ()
  (setq helm-git-usual-candidates nil)
  (setq helm-git-usual-sources nil)
  (cl-loop for c in helm-git-usual-repositories
           do (let* ((source-name (car c))
                     (repo-path (cdr c)))
                (add-to-list 'helm-git-usual-candidates
                             (cons source-name (cons repo-path (helm-git-usual-ls-files repo-path))))
                (add-to-list 'helm-git-usual-sources
                             (helm-build-in-buffer-source source-name
                               :data (lambda () (helm-git-usual--source-init))
                               :action (lambda (cc) (helm-git-usual--source-action cc))
                               :display-to-real (lambda (d) (helm-git-usual--source-display-to-real d))))))
  (setq helm-git-usual-sources (reverse helm-git-usual-sources)))

(defun helm-git-usual--source-init ()
  (message (helm-attr 'name))
  (cl-loop for c in (cdr (cdr (assoc (helm-attr 'name) helm-git-usual-candidates)))
           collect (concat "[" (helm-attr 'name) "] " c)))

(defun helm-git-usual--source-action (candidate)
  (let ((filepath
         (concat
          (file-name-as-directory
           (car (cdr (assoc (helm-attr 'name) helm-git-usual-candidates))))
          candidate)))
    (find-file filepath)))

(defun helm-git-usual-ls-files (path)
  (if (file-directory-p (file-truename path))
      (split-string
       (with-output-to-string
         (with-current-buffer standard-output
           (cd (file-truename path))
           (apply #'process-file
                  "git"
                  nil (list t helm-ls-git-log-file) nil
                  '("ls-files" "--full-name" "--")))) "\n" t)
    '("repository not found.")))

(defun helm-git-usual--source-display-to-real (d)
  (substring d (+ 3 (length (helm-attr 'name)))))

;;;###autoload
(defun helm-git-usual ()
  (interactive)
  (if (null helm-git-usual-sources)
      (helm-git-usual-init))
  (helm :sources helm-git-usual-sources
        :buffer "*helm my repositories*"))

(provide 'helm-git-usual)
