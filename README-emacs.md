# Emacs setup

A modern single-file Emacs configuration for Python, C, and LaTeX development.

**Stack overview:**

| Concern | Package(s) |
|---|---|
| Completion UI | Vertico · Orderless · Marginalia |
| Navigation | Consult · Embark |
| LSP | lsp-mode · lsp-ui · yasnippet |
| Diagnostics | Flycheck |
| Git | Magit · diff-hl |
| Projects | Projectile |
| Completion backend | Company |
| Python | lsp-mode → Pyright · python-black · envrc |
| C/C++ | lsp-mode → clangd |
| LaTeX | AUCTeX · auctex-latexmk · lsp-latex → texlab · pdf-tools |
| Prose | flyspell · org-superstar |
| Windows | ace-window · winner · windmove · treemacs |
| Terminals | vterm · eat (used by Codex) |
| AI coding | OpenAI Codex CLI via codex.el |
| Theme | Dracula |

---

## 1. Install

Copy the config to your home directory:

```sh
cp .emacs ~/.emacs
```

> If you use `~/.emacs.d/init.el` instead, copy it there. Do not keep both
> `~/.emacs` and `~/.emacs.d/init.el` — Emacs uses `~/.emacs` if it exists.

---

## 2. First run

```sh
emacs
```

On a clean machine Emacs will automatically:

1. Refresh package archive metadata (once only).
2. Install `use-package` if missing.
3. Install all declared packages on first use.

The first startup takes a minute or two. Native compilation runs in the
background on subsequent startups until all packages are compiled.

---

## 3. System packages

### Ubuntu/Debian

Install a baseline:

```sh
sudo apt update
sudo apt install -y \
  git curl wget ripgrep fd-find \
  clangd \
  shellcheck \
  python3 python3-pip python3-venv \
  direnv \
  aspell aspell-en \
  npm \
  texlive-latex-recommended texlive-latex-extra \
  texlive-fonts-recommended texlive-bibtex-extra latexmk \
  cmake libtool libtool-bin libvterm-dev
```

### macOS

Install Homebrew first if it is not already installed:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

On Apple Silicon, make sure Homebrew is on your shell path before continuing:

```sh
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Install Emacs and the command-line tools used by this config:

```sh
brew update
brew install --cask emacs
brew install \
  git curl wget ripgrep fd \
  llvm \
  shellcheck \
  python \
  direnv \
  aspell \
  node \
  mactex-no-gui \
  latexmk \
  cmake libtool libvterm
```

Notes:

- `brew install --cask emacs` installs the GUI application. You can also use a
  different Emacs build, such as `emacs-plus`, if you already prefer one.
- Homebrew's `llvm` package provides `clangd`. If Emacs cannot find `clangd`,
  add Homebrew's LLVM binary directory to your PATH/`exec-path` (see section 4).
- `mactex-no-gui` is large. If you do not use LaTeX from Emacs, you can skip it.
- On Intel Macs, Homebrew usually lives under `/usr/local` instead of
  `/opt/homebrew`; adjust paths accordingly.

Key items:

| Package | Purpose |
|---|---|
| `ripgrep` | `consult-ripgrep` (`M-g r`) |
| `clangd` | C/C++ language server |
| `direnv` | Per-project env activation via `envrc` |
| `aspell aspell-en` / `aspell` | Spell checking via `flyspell` |
| `latexmk` | AUCTeX build backend |
| `libvterm-dev` / `libvterm` + build tools | Needed to compile the vterm native module |

### Font: Source Code Pro

The config uses Source Code Pro at size 14.3. Install it.

Ubuntu/Debian:

```sh
sudo apt install fonts-sourcecodepro
```

macOS with Homebrew:

```sh
brew install --cask font-source-code-pro
```

Or download from [Google Fonts](https://fonts.google.com/specimen/Source+Code+Pro)
and install the `.ttf` files manually. On Linux, placing them under
`~/.local/share/fonts/` and running `fc-cache -fv` is enough; on macOS, open the
font files in Font Book and click **Install**.

---

## 4. User-local PATH

Many tools install into user-local directories. Add these to your shell startup
file. On Ubuntu/Debian this is usually `~/.bashrc`; on macOS this is usually
`~/.zshrc`.

```sh
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.cargo/bin:$PATH"
```

On Apple Silicon macOS, also add Homebrew if it is not already present:

```sh
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
```

On Intel macOS, use `/usr/local` instead:

```sh
export PATH="/usr/local/opt/llvm/bin:$PATH"
```

Configure npm to use a home-directory prefix (avoids `sudo`):

```sh
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
```

Reload the appropriate shell file, for example:

```sh
source ~/.bashrc   # Ubuntu/Debian
source ~/.zshrc    # macOS
```

Verify Emacs can find tools with `M-:` in Emacs:

```elisp
(executable-find "pyright-langserver")
(executable-find "clangd")
(executable-find "texlab")
```

If the shell finds a command but Emacs cannot, it is a PATH/`exec-path` mismatch.
Add the missing directory in `.emacs`:

```elisp
(add-to-list 'exec-path (expand-file-name "~/.local/bin"))
(setenv "PATH" (concat (expand-file-name "~/.local/bin") ":" (getenv "PATH")))
```

For Apple Silicon macOS, the equivalent Homebrew paths are often useful:

```elisp
(add-to-list 'exec-path "/opt/homebrew/bin")
(add-to-list 'exec-path "/opt/homebrew/opt/llvm/bin")
(setenv "PATH" (concat "/opt/homebrew/bin:/opt/homebrew/opt/llvm/bin:" (getenv "PATH")))
```

---

## 5. Python: Pyright

Install the Python language server:

```sh
npm install -g pyright
```

Verify:

```sh
which pyright-langserver
pyright --version
```

### Virtual environments with direnv

`envrc-mode` reads a `.envrc` file at the project root and activates the correct
Python environment for every buffer in that project, including the LSP server.

Create a `.envrc` in your project:

```sh
# for a venv in .venv/
echo 'source .venv/bin/activate' > .envrc
direnv allow
```

Or use a direnv layout:

```sh
echo 'layout python3' > .envrc
direnv allow
```

After this, opening any file in the project automatically switches Emacs
(and the LSP server) to the correct Python.

---

## 6. C/C++: clangd

`clangd` is installed by the system package above. Verify:

```sh
which clangd
clangd --version
```

For accurate diagnostics in non-trivial projects, provide a
`compile_commands.json` file at the project root (CMake generates one with
`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`; `bear` can generate one for Makefile
projects).

---

## 7. LaTeX: texlab

`lsp-latex` uses the `texlab` language server for completion, diagnostics, and
formatting in LaTeX buffers.

### Install texlab (prebuilt binary)

Ubuntu/Debian x86_64:

```sh
mkdir -p ~/.local/bin
cd /tmp
wget https://github.com/latex-lsp/texlab/releases/latest/download/texlab-x86_64-linux.tar.gz
tar -xzf texlab-x86_64-linux.tar.gz
mv texlab ~/.local/bin/
chmod +x ~/.local/bin/texlab
texlab --version
```

macOS Apple Silicon:

```sh
mkdir -p ~/.local/bin
cd /tmp
curl -L -o texlab-aarch64-macos.tar.gz \
  https://github.com/latex-lsp/texlab/releases/latest/download/texlab-aarch64-macos.tar.gz
tar -xzf texlab-aarch64-macos.tar.gz
mv texlab ~/.local/bin/
chmod +x ~/.local/bin/texlab
texlab --version
```

macOS Intel users should use the `texlab-x86_64-macos.tar.gz` release instead.

### Install texlab via Cargo

```sh
cargo install --git https://github.com/latex-lsp/texlab.git --locked
```

For `cargo`, prefer `rustup` over the Ubuntu `rustc` package:

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

### pdf-tools first-time setup

`pdf-tools` needs a native module compiled once. Inside Emacs:

```
M-x pdf-tools-install
```

After this, `.pdf` files open in `pdf-view-mode`. SyncTeX forward search
(`C-c C-v` in a LaTeX buffer) jumps to the correct position in the PDF, and
clicking in the PDF jumps back to the source line.

---

## 8. vterm first-time setup

`vterm` requires a native module. The first time the package is loaded Emacs
will prompt to compile it. Accept the prompt. Subsequent startups use the
pre-compiled module.

Required system packages are installed in section 3: `cmake` and `libvterm-dev`
on Ubuntu/Debian, or `cmake` and `libvterm` on macOS.

`eat` is available as a fallback terminal (no compilation required) and is the
default backend for the Codex integration.

---

## 9. Codex CLI

The Codex Emacs package is only a wrapper. The CLI must work in a normal
terminal first.

Install:

```sh
npm install -g @openai/codex
```

Sign in (run once interactively, then exit):

```sh
codex
```

Verify:

```sh
which codex
codex --version
```

Open the Codex IDE layout from Emacs with `C-c i` (see key reference below).

---

## 10. Key reference

### Navigation & search

| Key | Command |
|---|---|
| `C-x b` | `consult-buffer` — switch buffer |
| `C-x C-b` | `list-buffers` — full buffer list |
| `C-c s` | `consult-line` — search in file |
| `M-g g` | `consult-goto-line` |
| `M-g i` | `consult-imenu` — jump to symbol |
| `M-g r` | `consult-ripgrep` — search project |
| `M-y` | `consult-yank-pop` — browse kill ring |
| `C-.` | `embark-act` — context actions on thing at point |
| `C-;` | `embark-dwim` |
| `C-h B` | `embark-bindings` — browse all active bindings |

### Windows & layout

| Key | Command |
|---|---|
| `C-c i` | `my/codex-layout` — Treemacs + Codex + shell + file |
| `C-c t` | Toggle Treemacs sidebar |
| `M-o` | `ace-window` — jump to any pane by label |
| `M-<arrow>` | `windmove` — move to adjacent pane directionally |
| `C-c <left>` | `winner-undo` — restore previous layout |
| `C-c <right>` | `winner-redo` |

### LSP (`C-c l` prefix, active in code buffers)

| Key | Command |
|---|---|
| `C-c l g g` | Go to definition |
| `C-c l g r` | Find references |
| `C-c l r r` | Rename symbol |
| `C-c l a a` | Code action |
| `C-c l = =` | Format buffer |

### Git

| Key | Command |
|---|---|
| `C-x g` | `magit-status` |

### Project (Projectile `C-c p` prefix)

| Key | Command |
|---|---|
| `C-c p f` | Find file in project |
| `C-c p p` | Switch project |
| `C-c p s r` | Ripgrep in project |
| `C-c p k` | Kill all project buffers |

### Codex

| Key | Command |
|---|---|
| `C-c x` | Codex command map |

### LaTeX (AUCTeX, active in `.tex` buffers)

| Key | Command |
|---|---|
| `C-c C-c` | Compile |
| `C-c C-v` | View / SyncTeX forward search |
| `C-c C-e` | Insert environment |
| `C-c C-s` | Insert section |

---

## 11. Troubleshooting

### Debug init errors

```sh
emacs --debug-init
```

### Start with no config

```sh
emacs -Q
```

Confirms whether a problem is in your init file or in Emacs itself.

### Native compilation warnings

Warnings like the following are harmless:

```
Warning (comp): embark.el:... variable '_' not left unused
Warning (comp): lsp-ui-sideline.el:... Unused lexical argument
```

They come from third-party packages being compiled and do not indicate a broken
setup.

### Missing language server

```sh
which pyright-langserver
which clangd
which texlab
```

```elisp
M-: (executable-find "pyright-langserver")
M-: (executable-find "clangd")
M-: (executable-find "texlab")
```

### PATH mismatch between shell and Emacs

If the shell finds a command but Emacs cannot, see section 4.

### envrc not activating

Run `direnv allow` in the project directory. Check `M-x envrc-allow` from
within Emacs. The mode line shows the active environment name when envrc is
working.

### Recover from a broken config

```sh
mv ~/.emacs ~/.emacs.broken
# restore from backup or dotfiles repo
```
