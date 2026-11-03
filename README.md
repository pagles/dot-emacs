# dot-emacs

Emacs 31 configuration for macOS, built for Python work across many git worktrees.

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

Run `M-x my/remember-worktrees` to register every checkout under `~/Workbench` as a project, and `M-x project-forget-zombie-projects` to drop deleted ones.
