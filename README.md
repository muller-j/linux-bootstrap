# Linux bootstrap

Personal Ubuntu 22.04 / WSL2 x86_64 setup. Shell configuration and application settings are versioned here; home dotfiles are symlinks. Prefer APT when packages are available.

## Layout

```text
linux-bootstrap/
├── README.md
├── install.sh
├── packages/
│   ├── apt.txt
│   └── tools.sh
├── shell/
│   ├── .bashrc
│   ├── .zshrc
│   ├── .profile
│   ├── aliases.sh
│   ├── functions.sh
│   └── exports.sh
├── config/
│   ├── atuin/config.toml
│   ├── eza/theme.yml
│   ├── powerlevel10k/.p10k.zsh
│   ├── tmux/.tmux.conf
│   ├── git/
│   └── ssh/
├── scripts/
│   ├── install-node.sh
│   └── install-sdkman.sh
├── backup/
│   └── export-packages.sh
├── proxy.env.example
└── proxy.env                 # local only, ignored by Git
```

`config/git` and `config/ssh` are reserved for future non-secret configuration. No existing Git configuration, Git credentials, SSH configuration, or SSH keys are copied or replaced.

This V1 automates only the shell tools configured here. Docker, Python, Ansible, and unrelated existing tools are left untouched; no Docker/Python installation scripts are included.

## Installation

### New WSL distribution

Install Git, then clone into the expected location:

```sh
sudo apt update
sudo apt install -y git
git clone REPLACE_WITH_REPOSITORY_URL "$HOME/linux-bootstrap"
cd "$HOME/linux-bootstrap"
```

If a proxy is required, create and edit the private local file before installation:

```sh
cp -n proxy.env.example proxy.env
chmod 600 proxy.env
${EDITOR:-nano} proxy.env
```

Run the installer as your regular user, **not** with `sudo`:

```sh
bash "$HOME/linux-bootstrap/install.sh"
```

The installer:

1. Sources the optional local proxy configuration without displaying its values.
2. Installs missing packages from `packages/apt.txt` using APT; sudo may request your password. Existing packages are not forcibly upgraded.
3. Prefers APT for eza if provided by the configured repositories. Otherwise installs the official eza release. Installs the official Atuin and lazydocker releases, tmux-resurrect, Oh My Zsh, Powerlevel10k, fnm, and SDKMAN only when missing.
4. Links shell dotfiles and application configuration into the home directory.
5. Moves conflicting files and symlinks into a private directory under `~/.local/state/linux-bootstrap/backups/install.*`, outside this Git repository.

Release archives for eza, Atuin, lazydocker, tmux-resurrect, and fnm have pinned versions or commits and SHA-256 checksums in the scripts. SDKMAN uses its official HTTPS installer. Existing tool installations, Node versions, Java versions, and Maven versions are retained; reruns do not reinstall or update them.

`scripts/install-node.sh` installs the **fnm manager**, not an arbitrary new Node runtime. On a new machine, choose your runtime/tool versions after installation:

```sh
exec zsh
fnm install <node-version>
fnm default <node-version>
sdk install java <java-version-identifier>
sdk install maven <maven-version>
```

The configured Node options `--use-env-proxy --use-system-ca` require a compatible Node release. Select the same Node version as your existing setup if restoring it.

Open an Ubuntu terminal running Zsh, or use `exec zsh`. The installer does not change your login shell, run `p10k configure`, create a Git commit, import shell history, or register an Atuin account.

### Relink or migrate an existing installation

If tools are already installed, relink configuration without APT or downloads:

```sh
bash "$HOME/linux-bootstrap/install.sh" --links-only
exec zsh
```

Both installer modes can be rerun. Already-correct symlinks are unchanged. Existing conflicting configurations are backed up, never silently overwritten. Keep the repository at `~/linux-bootstrap`, as the shell startup files source that location.

The home links are:

| Home path | Repository source |
|---|---|
| `~/.bashrc` | `shell/.bashrc` |
| `~/.zshrc` | `shell/.zshrc` |
| `~/.profile` | `shell/.profile` |
| `~/.p10k.zsh` | `config/powerlevel10k/.p10k.zsh` |
| `~/.config/eza/theme.yml` | `config/eza/theme.yml` |
| `~/.config/atuin/config.toml` | `config/atuin/config.toml` |
| `~/.tmux.conf` | `config/tmux/.tmux.conf` |

`functions.sh` is the shared Bash/Zsh extension point for future functions. `exports.sh` contains shared environment variables, PATH setup, and local proxy loading. `aliases.sh` contains shared aliases, including any explicit Windows shortcuts you add.

## Shell tools

### eza and bat

[eza](https://github.com/eza-community/eza) replaces directory listings with icons and the versioned [TokyoNight theme](https://github.com/eza-community/eza-themes/blob/main/themes/tokyonight.yml). Ubuntu 22.04's default repositories do not include it, so `packages/tools.sh` provides the official v0.23.5 binary in `~/.local/bin`.

[bat](https://github.com/sharkdp/bat) is installed through APT. Ubuntu names its executable `batcat`. The shared aliases are:

```sh
alias ls='eza --icons=always'
alias ll='eza -lah --icons=always'
alias tree='eza --tree --icons=always --group-directories-first'
alias cat='batcat'
```

Use `command cat` for the original command. bat uses plain output without paging when redirected or piped. `LS_COLORS` and `EZA_COLORS` are unset so eza can use its theme.

`tree` displays files and subdirectories recursively with eza icons and the TokyoNight theme, without installing another utility. Use `tree -L 2` to limit depth, `tree -a` to include hidden entries, or `tree --git-ignore` to skip Git-ignored entries. Unlike the standalone tree command, this alias accepts eza options.

Reload shared aliases with:

```sh
source "$HOME/linux-bootstrap/shell/aliases.sh"
```

### fzf, zoxide, and Atuin

[fzf](https://github.com/junegunn/fzf) and [zoxide](https://github.com/ajeetdsouza/zoxide) are installed through APT. [Atuin](https://github.com/atuinsh/atuin) v18.24.8 is installed from its official release because the configured Ubuntu 22.04 repositories do not provide it.

Zsh initialization order is **fzf → zoxide → Atuin → autosuggestions → syntax highlighting**:

| Action | Behavior |
|---|---|
| **Ctrl+R** | Search history with Atuin, not fzf |
| **Ctrl+T** | Insert paths selected with fzf |
| **Alt+C** | Select a directory with fzf |
| `cat **` then **Tab** | Fuzzy path completion |
| `cd project` or `z project` | Jump using zoxide |
| `zi project` | Select a known directory interactively |
| `builtin cd /path` | Bypass zoxide |

The `cd='z'` alias is Zsh-only and is defined after zoxide initialization to avoid recursion with Ubuntu's older zoxide package. Atuin's Up Arrow and AI bindings are disabled.

Atuin uses `config/atuin/config.toml`: automatic synchronization and update checks are off; the built-in secrets filter is on, but does not detect every secret. Do not type credentials directly into commands. Existing history is not automatically imported; use `atuin import auto` only if you want to import it.

Atuin data/credentials (`~/.atuin/data` for the installed release; see `atuin info`) and zoxide's database (`~/.local/share/zoxide`) remain outside this repository.

### tmux

[tmux](https://github.com/tmux/tmux) is installed through APT and included in `packages/apt.txt`:

```sh
sudo apt install tmux
tmux new -s main
```

The shared alias `tm` runs `tmux new -s main`. If the session already exists, reattach with `tmux attach -t main`.

The tmux prefix is **Ctrl+Q**. Press **Ctrl+Q**, then **D** to detach, **H** to split left/right, **V** to split top/bottom, or **C** to create a window. Navigate between panes directly with **Alt+Arrow**, without the prefix. Reattach with `tmux attach -t main`, or list sessions with `tmux ls`.

If the terminal intercepts Ctrl+Q for software flow control, run `stty -ixon` in the terminal before starting tmux.

The versioned `config/tmux/.tmux.conf` loads [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect), installed under `~/.tmux/plugins/tmux-resurrect` without requiring a plugin manager. tmux does not start automatically when opening a shell.

Press **Ctrl+Q**, then **Ctrl+S** to save sessions, windows, pane layouts, and working directories. Press **Ctrl+Q**, then **Ctrl+R** to restore. Saves remain local under `~/.tmux/resurrect`, outside this repository. No automatic save/restore is enabled. Pane text capture is disabled; saved metadata can still contain command arguments, so treat snapshots as private. Restoring is not a process-memory snapshot; only supported programs are restarted.

If tmux was already running when configuration changed, run `tmux source-file ~/.tmux.conf` inside it.

### fd and direnv

Both tools are installed using APT:

```sh
sudo apt install fd-find direnv
```

Ubuntu names [fd](https://github.com/sharkdp/fd)'s binary `fdfind`. The shared alias `fd='fdfind'` makes `fd README` search filenames and `fd -e java` find Java files. Hidden and Git-ignored entries are skipped by default; `fd -H` includes hidden entries.

[direnv](https://direnv.net) is hooked into Bash and Zsh. Put project-specific environment variables in a project's `.envrc`, review the file, then run `direnv allow`. Never automatically authorize untrusted `.envrc` files: they execute shell code. Use `direnv deny` to revoke authorization, and keep secret-bearing `.envrc` files out of Git.

### lazydocker

[lazydocker](https://github.com/jesseduffield/lazydocker) provides a terminal UI for Docker containers, logs, images, and volumes. It is not available in the configured APT repositories; `packages/tools.sh` installs the official v0.25.2 Linux x86_64 release into `~/.local/bin`.

Run `lazydocker` to open it. It requires the Docker CLI and access to a running Docker daemon; this installation does not install Docker, change socket permissions, or add your user to a privileged group.

### Suggestions and highlighting

[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) and [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) are installed through APT. **Right Arrow** accepts a suggestion at the end of the command line.

Zsh sources the packaged scripts directly. Do not also add them to the Oh My Zsh plugin list. Syntax highlighting must remain last, after plugins and widget bindings.

### Powerlevel10k and fonts

The existing colors, two-line layout, Nerd Font v3 mode, Git indicators, and enabled segment icons are preserved. The OS icon is customized to **🦖**. Git status only appears inside a Git repository; execution duration appears after three seconds.

Edit `config/powerlevel10k/.p10k.zsh`, then reload:

```sh
source ~/.p10k.zsh
```

Avoid `p10k configure` unless you want to regenerate that file.

For WSL, install a Nerd Font **on Windows**, then select it in Windows Terminal's active Ubuntu profile under **Settings → Ubuntu → Appearance → Font face**. Check profile overrides, not only Defaults. The working Windows family is `CaskaydiaCove NFM`; `MesloLGS NF` is another option recommended by Powerlevel10k. Restart Windows Terminal after installing fonts. The Linux installer does not modify Windows fonts or terminal settings.

### WSL typing performance

Before loading plugins, Zsh removes Windows drive entries (`/mnt/c/...`, `/mnt/d/...`) from its PATH to avoid slow command lookups during syntax highlighting. Linux paths, fnm, and SDKMAN remain available. Bash and system-wide WSL settings are unchanged.

Call Windows tools by full path or add explicit aliases in `shell/aliases.sh`, for example:

```sh
alias explorer='/mnt/c/Windows/explorer.exe'
alias clip='/mnt/c/Windows/System32/clip.exe'
```

## Package inventory and backups

Export installed APT packages without sudo:

```sh
bash "$HOME/linux-bootstrap/backup/export-packages.sh"
```

This creates ignored local inventories in `backup/`: `apt-manual.txt`, `apt-installed.tsv`, and `captured-at.txt`. It does not change `packages/apt.txt`, capture secrets, or automatically reinstall every package on the machine. Keep `packages/apt.txt` as the curated bootstrap list.

Installer conflict backups are separate, under `~/.local/state/linux-bootstrap/backups`. Restore selected files manually after inspecting them; they are not automatically deleted.

## Secrets

`proxy.env` stays at the repository root, ignored by Git with permissions `600`. `proxy.env.example` is the safe versioned template. Both shells load the optional local proxy through `shell/exports.sh`; the installer also sources it for downloads. URL-encode special characters in proxy credentials.

Never commit `proxy.env`, shell history databases, private SSH keys, Git credentials, or copied personal configuration containing secrets. No Git/SSH secrets are collected by the installer.
