(defvar w3m-haddock-entry-regex "^\\(\\(data\\|type\\) \\|[a-z].* :: \\)"
  "Regex to match entry headings.")

(defun w3m-haddock-page-p ()
  "Haddock general page?"
  (save-excursion
    (goto-char (point-max))
    (forward-line -2)
    (looking-at "[ ]*Produced by Haddock")))

(defun w3m-haddock-source-p ()
  "Haddock source page?"
  (save-excursion
    (goto-char (point-min))
    (looking-at "Location: https?://hackage.haskell.org/package/.*/docs/src/")))

(defun w3m-haddock-p ()
  "Any haddock page?"
  (or (w3m-haddock-page-p)
      (w3m-haddock-source-p)))

(defun w3m-haddock-find-tag ()
  "Find a tag by jumping to the \"All\" index and doing a
  search-forward."
  (interactive)
  (when (w3m-haddock-p)
    (let ((ident (haskell-ident-at-point)))
      (when ident
        (w3m-browse-url
         (replace-regexp-in-string "docs/.*" "docs/doc-index-All.html" w3m-current-url))
        (search-forward ident)))))

(defun w3m-haddock-display (url)
  "To be ran by w3m's display hook. This takes a normal w3m
  buffer containing hadddock documentation and reformats it to be
  more usable and look like a dedicated documentation page."
  (when (w3m-haddock-page-p)
    (save-excursion
      (goto-char (point-min))
      (let ((inhibit-read-only t))
        (delete-region (point)
                       (line-end-position))
        (w3m-haddock-next-heading)
        ;; Start formatting entries
        (while (looking-at w3m-haddock-entry-regex)
          (when (w3m-haddock-valid-heading)
            (w3m-haddock-format-heading))
          (w3m-haddock-next-heading))))
    (rename-buffer (concat "*haddock: " (w3m-buffer-title (current-buffer)) "*")))
  (when (w3m-haddock-source-p)
    (font-lock-mode -1)
    (let ((n (line-number-at-pos)))
      (save-excursion
        (goto-char (point-min))
        (forward-line 1)
        (let ((text (buffer-substring (point)
                                      (point-max)))
              (inhibit-read-only t))
          (delete-region (point)
                         (point-max))
          (insert
           (haskell-fontify-as-mode text
                                    'haskell-mode))))
      (goto-line n))))

(defun w3m-haddock-damp-out-version ()
  "Damp out the Haddock version number."
  (goto-char (point-max))
  (search-backward-regexp "^[ ]+Produced by")
  (goto-char (line-beginning-position))
  (put-text-property (line-beginning-position)
                     (point-max)
                     'face
                     '(:foreground "#666"))
  (indent-rigidly (line-beginning-position)
                  (point-max)
                  -4))

(defun w3m-haddock-format-heading ()
  "Format a haddock entry."
  (let ((o (make-overlay (line-beginning-position)
                         (1- (save-excursion (w3m-haddock-header-end))))))
    (overlay-put o 'face '(:background "#333333")))
  (let ((end (save-excursion
               (w3m-haddock-next-heading)
               (when (w3m-haddock-valid-heading)
                 (point)))))
    (when end
      (save-excursion
        (w3m-haddock-header-end)
        (indent-rigidly (point)
                        end
                        4)))))

(defun w3m-haddock-next-heading ()
  "Go to the next heading, or end of the buffer."
  (forward-line 1)
  (or (search-forward-regexp w3m-haddock-entry-regex nil t 1)
      (goto-char (point-max)))
  (goto-char (line-beginning-position)))

(defun w3m-haddock-valid-heading ()
  "Is this a valid heading?"
  (not (get-text-property (point) 'face)))

(defun w3m-haddock-header-end ()
  "Go to the end of the header."
  (search-forward-regexp "\n[ \n]"))

(provide 'w3m-haddock)
