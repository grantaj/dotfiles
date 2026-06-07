;;; .emacs --- modern, tidy Emacs config -*- lexical-binding: t; -*-

;;; Commentary:
;; A cleaned-up single-file init.
;;
;; Main changes:
;; - Use `use-package' consistently.
;; - Refresh package archives automatically only when needed.
;; - Add eat as a terminal option alongside vterm.
;; - Move Custom settings into a separate file so this file stays tidy.
;; - Replace Ivy/Counsel stack with Vertico/Consult/Orderless/Marginalia/Embark.
;; - Add OpenAI Codex CLI integration via benthamite/codex when package-vc is available.

;;; Code:

;; ----------------------------------------------------------------------
;; Startup / UI basics

(setq inhibit-startup-message t
      initial-scratch-message nil
      ring-bell-function #'ignore
      use-short-answers t
      visible-bell nil
      make-backup-files nil
      auto-save-default t
      create-lockfiles nil)

(delete-selection-mode 1)
(global-auto-revert-mode 1)
(setq auto-revert-verbose nil)
(save-place-mode 1)
(savehist-mode 1)
(recentf-mode 1)
(electric-pair-mode 1)
(column-number-mode 1)

(setq recentf-max-saved-items 200
      history-length 200
      enable-recursive-minibuffers t
      custom-file (expand-file-name "custom.el" user-emacs-directory))

(when (file-exists-p custom-file)
  (load custom-file))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; Initial window size.
(setq initial-frame-alist
      '((width . 80)
        (height . 40)))

(setq default-frame-alist
      '((width . 80)
        (height . 40)))

(when (display-graphic-p)
  (set-face-attribute 'default nil
                      :family "Source Code Pro"
                      :height 120))

;; ----------------------------------------------------------------------
;; Packages

(require 'package)

(setq package-archives
      '(("gnu"          . "https://elpa.gnu.org/packages/")
        ("nongnu"       . "https://elpa.nongnu.org/nongnu/")
        ("melpa"        . "https://melpa.org/packages/")
        ("melpa-stable" . "https://stable.melpa.org/packages/")))

(setq package-native-compile t)
(package-initialize)

;; Refresh once on a clean machine, but do not refresh every startup.
(unless package-archive-contents
  (package-refresh-contents))

(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t
      use-package-always-defer t)

;; ----------------------------------------------------------------------
;; Theme / appearance

(use-package dracula-theme
  :demand t
  :config
  (load-theme 'dracula t))

(use-package nerd-icons
  :if (display-graphic-p))

;; ----------------------------------------------------------------------
;; Modern minibuffer completion

(use-package vertico
  :demand t
  :init
  (vertico-mode 1))

(use-package orderless
  :demand t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :demand t
  :init
  (marginalia-mode 1))

(use-package consult
  :bind (("C-c s"     . consult-line)
         ("C-x b"   . consult-buffer)
         ("M-y"     . consult-yank-pop)
         ("M-g g"   . consult-goto-line)
         ("M-g i"   . consult-imenu)
         ("M-g r"   . consult-ripgrep)))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         ("C-h B" . embark-bindings)))

(use-package embark-consult
  :after (embark consult))

(use-package which-key
  :demand t
  :config
  (which-key-mode 1))

;; ----------------------------------------------------------------------
;; Project / Git

(use-package projectile
  :demand t
  :bind-keymap ("C-c p" . projectile-command-map)
  :custom
  (projectile-completion-system 'default)
  :config
  (projectile-mode 1))

(use-package magit
  :bind ("C-x g" . magit-status))

(use-package diff-hl
  :hook ((after-init          . global-diff-hl-mode)
         (magit-pre-refresh   . diff-hl-magit-pre-refresh)
         (magit-post-refresh  . diff-hl-magit-post-refresh)))

;; ----------------------------------------------------------------------
;; Editing / programming

(use-package company
  :hook (after-init . global-company-mode)
  :custom
  (company-idle-delay 0.15)
  (company-minimum-prefix-length 2)
  (company-tooltip-align-annotations t))

(use-package flycheck
  :hook (after-init . global-flycheck-mode))

(use-package lsp-mode
  :hook ((c-mode c++-mode python-mode LaTeX-mode latex-mode tex-mode bibtex-mode) . lsp)
  :custom
  (lsp-keymap-prefix "C-c l")
  (lsp-enable-symbol-highlighting t)
  (lsp-headerline-breadcrumb-enable t)
  :init
  (setq lsp-use-plists t))

(use-package lsp-ui
  :after lsp-mode
  :commands lsp-ui-mode)

(use-package yasnippet
  :hook (lsp-mode . yas-minor-mode)
  :config (yas-reload-all))

(use-package yasnippet-snippets
  :after yasnippet)

(use-package python
  :ensure nil
  :custom
  (python-shell-interpreter "python3"))

(use-package python-black
  :after python
  :hook (python-mode . python-black-on-save-mode-enable-dwim))

;; Automatically activates the direnv environment for each project,
;; ensuring lsp-mode and shells use the correct Python venv.
(use-package envrc
  :hook (after-init . envrc-global-mode))

(use-package markdown-mode
  :mode "\\.md\\'")

;; ----------------------------------------------------------------------
;; Org / writing / LaTeX

(use-package org
  :ensure nil
  :hook ((org-mode . org-indent-mode)
         (org-mode . visual-line-mode))
  :config
  (require 'ox-md))

(use-package toc-org
  :hook (org-mode . toc-org-mode))

(use-package org-superstar
  :hook (org-mode . org-superstar-mode))

(use-package flyspell
  :ensure nil
  :hook ((LaTeX-mode . flyspell-mode)
         (org-mode   . flyspell-mode)))

(use-package auctex
  :defer t)

(use-package auctex-latexmk
  :after tex
  :config
  (auctex-latexmk-setup))

(use-package lsp-latex
  :after lsp-mode
  ;; Uncomment and adjust this if texlab is installed but not on PATH.
  ;; :custom
  ;; (lsp-latex-texlab-executable "/home/alex/.cargo/bin/texlab")
  )

;; Fast in-Emacs PDF viewer with SyncTeX forward/inverse search.
;; Run M-x pdf-tools-install once after first install.
(use-package pdf-tools
  :magic ("%PDF" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query)
  (setq TeX-view-program-selection '((output-pdf "PDF Tools"))
        TeX-view-program-list     '(("PDF Tools" TeX-pdf-tools-sync-view))
        TeX-source-correlate-mode        t
        TeX-source-correlate-start-server t))

;; ----------------------------------------------------------------------
;; Terminal support
;;
;; vterm provides a full-featured terminal with a native module; see the vterm
;; section below.  eat is pure Emacs Lisp and is the default terminal backend
;; used by the Codex integration.

(use-package eat
  :commands (eat eat-project))

;; ----------------------------------------------------------------------
;; OpenAI Codex CLI integration
;;
;; Prerequisites:
;;   1. Install the Codex CLI so `codex' is on PATH.
;;      For example: npm install -g @openai/codex
;;   2. Run `codex' once in a normal terminal and sign in.
;;   3. Restart Emacs, then use C-c x c to start Codex in the current project.
;;
;; The Emacs package is currently distributed directly from GitHub, so this
;; uses package-vc when available. package-vc is built into Emacs 29+.

(when (and (fboundp 'package-vc-install)
           (not (package-installed-p 'codex)))
  (package-vc-install
   '(codex :url "https://github.com/benthamite/codex"
           :branch "master")))

(use-package codex
  :if (locate-library "codex")
  :ensure nil
  :commands (codex codex-send-command codex-toggle codex-transient)
  :bind-keymap ("C-c x" . codex-command-map)
  :custom
  (codex-terminal-backend 'eat)
  :config
  (codex-mode 1))

(unless (fboundp 'package-vc-install)
  (display-warning
   'codex
   "Codex Emacs integration needs package-vc, which is built into Emacs 29+. Upgrade Emacs or install codex.el manually."))

;;; Python LSP
(use-package lsp-pyright
  :ensure t
  :after lsp-mode
  :hook ((python-mode . (lambda ()
                          (require 'lsp-pyright)
                          (lsp-deferred)))
         (python-ts-mode . (lambda ()
                             (require 'lsp-pyright)
                             (lsp-deferred)))))

;;; Codex IDE layout
;;
;; C-c i creates:
;;
;;   Treemacs | Codex eat
;;            | repo shell eat | source file
;;
;; In practice this is three columns, with the middle column split into
;; Codex above and a normal repo terminal below.

(use-package treemacs
  :ensure t
  :commands treemacs
  :bind (("C-c t" . treemacs))
  :bind ("C-c T" . treemacs-select-window)
  :custom
  (treemacs-width 32)
  (treemacs-is-never-other-window t)
  (treemacs-default-visit-action #'treemacs-visit-node-ace))

(use-package vterm
  :ensure t
  :commands vterm
  :config
  (setq vterm-shell (or (getenv "SHELL") "/bin/bash")))


(defun my/project-root-or-default ()
  "Return project root if available, otherwise current directory."
  (or (when-let ((project (project-current nil)))
        (project-root project))
      (vc-root-dir)
      default-directory))

(defun my/show-eat-buffer (name dir)
  "Display an eat terminal buffer NAME in the selected window, creating it if needed."
  (if (get-buffer name)
      (switch-to-buffer name)
    (let ((default-directory dir))
      (eat nil name))))

(defun my/codex-layout ()
  "Open layout: Treemacs | Codex over shell | file."
  (interactive)
  (let* ((file-buffer (current-buffer))
         (root (my/project-root-or-default)))

    ;; Start clean.
    (delete-other-windows)

    ;; Create the main area first: middle column plus right file column.
    ;; Treemacs is opened last so it can manage its own sidebar window.
    (let* ((middle-window (selected-window))
           (file-window (split-window-right)))

      ;; Split the middle column into Codex above and shell below.
      (select-window middle-window)
      (let ((shell-window (split-window-below)))

        ;; Top middle: Codex terminal.
        (select-window middle-window)
        (my/show-eat-buffer "*codex-term*" root)

        ;; Bottom middle: ordinary repo terminal.
        (select-window shell-window)
        (my/show-eat-buffer "*repo-term*" root)

        ;; Right: source file.
        (select-window file-window)
        (switch-to-buffer file-buffer)

        ;; Now let Treemacs create/manage its own left sidebar.
        (treemacs)

        ;; Focus Codex terminal.
        (select-window middle-window)))))

(global-set-key (kbd "C-c i") #'my/codex-layout)

;; Undo/redo window layout changes.
(use-package winner
  :ensure nil
  :demand t
  :bind (("C-c <left>"  . winner-undo)
         ("C-c <right>" . winner-redo))
  :config
  (winner-mode 1))

;; Jump to any visible window by label (falls back to other-window with 2 panes).
(use-package ace-window
  :bind ("M-o" . ace-window)
  :custom
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

;; Move between panes with Alt-arrow.
(global-set-key (kbd "M-<left>")  #'windmove-left)
(global-set-key (kbd "M-<right>") #'windmove-right)
(global-set-key (kbd "M-<up>")    #'windmove-up)
(global-set-key (kbd "M-<down>")  #'windmove-down)

(global-set-key (kbd "C-c e r") (lambda () (interactive) (load-file user-init-file)))

;; macOS GUI Emacs often does not inherit the shell PATH.
(when (eq system-type 'darwin)
  (dolist (path '("/opt/homebrew/bin"
                  "/usr/local/bin"
                  "/Library/TeX/texbin"))
    (when (file-directory-p path)
      (add-to-list 'exec-path path)
      (setenv "PATH" (concat path ":" (getenv "PATH"))))))

(provide 'init)
;;; .emacs ends here
