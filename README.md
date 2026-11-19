# dot-emacs

Emacs 31 configuration for macOS, built for Python and Rust work across many git worktrees.

## Install

```sh
brew tap d12frosted/emacs-plus
brew install emacs-plus@31
git clone git@github.com:pagles/dot-emacs.git ~/.config/emacs
```

Packages install from MELPA on first launch. Tree-sitter grammars install on first use of each language (answer yes to the prompt).

Terminal use with a shared background server, in `~/.zshrc`:

```sh
alias emacs='emacsclient -t -a ""'
export EDITOR='emacsclient -t -a ""'
```

In iTerm, set both Option keys to `Esc+` (Settings, Profiles, Keys) so they act as Meta.

## Clipboard

Terminal Emacs shares the macOS clipboard (through `pbcopy`/`pbpaste`), and the GUI does so natively.

| Keys | Action |
| --- | --- |
| Mouse drag | select and copy, like iTerm |
| `M-w` / `C-w` | copy / cut |
| `C-y` or Cmd-V | paste |

Cmd-C doesn't reach terminal Emacs, because iTerm keeps it. To get a raw iTerm selection, hold Option while dragging.

## Python

Code navigation uses [ty](https://github.com/astral-sh/ty) through eglot. Each project uses its own `.venv/bin/ty`, falling back to `ty` on PATH (`uv tool install ty`).

| Key | Action |
| --- | --- |
| `M-.` / `M-?` / `M-,` | definition / references / back |
| `C-M-.` | workspace symbol search |
| `M-g i` | symbols in file |
| `M-s r` | ripgrep in project |
| `C-x p f` / `C-x p p` | find file / switch project |
| `C-c r` / `C-c a` / `C-c h` | rename / code actions / docs |
| `C-c t` | file tree drawer (left), follows the current project and file; click to open |
| `C-c s` | structure of current file (right) |

## Rust

`.rs` files open in `rust-ts-mode` with [rust-analyzer](https://rust-analyzer.github.io) through eglot (`rustup component add rust-analyzer`). The keys above work the same way; the fill column indicator sits at 100, rustfmt's default width.

## Projects

Run `M-x my/remember-worktrees` to register every checkout under `~/Workbench` as a project, and `M-x project-forget-zombie-projects` to drop deleted ones.

## Worktree frames

Each `emacs` frame belongs to the git checkout you started it in and is named after it. [beframe](https://protesilaos.com/emacs/beframe) keeps buffer lists per frame, so `C-x b` only offers that frame's buffers. Files already open from the checkout join a new frame, and closing a frame kills the unmodified file buffers no other frame uses.

Agents send files with `emacsclient -e '(my/visit "/abs/path")'`, which opens them in their checkout's frame. Without one, the file loads in the background and shows up when you start `emacs` in that checkout.

## Markdown

`.md` files open in `gfm-mode` (GitHub-flavoured Markdown) with soft wrapping, markup hidden, and code blocks highlighted in their own language. Tables are aligned on screen with box borders, without touching the file; showing the markup shows the raw tables.

| Key | Action |
| --- | --- |
| `TAB` / `S-TAB` | fold heading / cycle whole document |
| `M-g i` | jump to a heading |
| `C-c C-n` / `C-c C-p` | next / previous heading |
| `C-c C-x C-m` | show or hide markup |
| `C-c C-o` | open link at point |
| `C-c C-d` | toggle checkbox |
| `M-↑` / `M-↓` | move list item or section |
