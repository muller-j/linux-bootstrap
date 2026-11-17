#!/usr/bin/env bash
set -euo pipefail

download_verified_archive() {
    local download_url="$1"
    local expected_checksum="$2"
    local archive_path="$3"

    curl --fail --location --retry 3 --connect-timeout 15 --max-time 300 \
        "$download_url" --output "$archive_path"
    printf '%s  %s\n' "$expected_checksum" "$archive_path" | sha256sum --check
}

install_eza() (
    if command -v eza >/dev/null 2>&1; then
        eza --version
        return
    fi

    local temporary_directory
    temporary_directory="$(mktemp -d)"
    trap 'rm -rf -- "$temporary_directory"' EXIT
    download_verified_archive \
        https://github.com/eza-community/eza/releases/download/v0.23.5/eza_x86_64-unknown-linux-gnu.tar.gz \
        35c70c5c43c29108075e58b893234c67ef585f0b53a7eaf8e9e7d4eec9f339b4 \
        "$temporary_directory/eza.tar.gz"
    tar -xzf "$temporary_directory/eza.tar.gz" -C "$temporary_directory"
    install -m 755 "$temporary_directory/eza" "$HOME/.local/bin/eza"
    "$HOME/.local/bin/eza" --version
)

install_atuin() (
    if command -v atuin >/dev/null 2>&1; then
        atuin --version
        return
    fi

    local temporary_directory
    temporary_directory="$(mktemp -d)"
    trap 'rm -rf -- "$temporary_directory"' EXIT
    download_verified_archive \
        https://github.com/atuinsh/atuin/releases/download/v18.24.8/atuin-x86_64-unknown-linux-musl.tar.gz \
        f8dfc3f9d27cadc2e2c9d489394ef7c568291e2382a4d184865701bf1a4ac30a \
        "$temporary_directory/atuin.tar.gz"
    tar -xzf "$temporary_directory/atuin.tar.gz" -C "$temporary_directory"
    install -m 755 "$temporary_directory/atuin-x86_64-unknown-linux-musl/atuin" \
        "$HOME/.local/bin/atuin"
    "$HOME/.local/bin/atuin" --version
)

install_lazydocker() (
    if command -v lazydocker >/dev/null 2>&1; then
        lazydocker --version
        return
    fi

    local temporary_directory
    temporary_directory="$(mktemp -d)"
    trap 'rm -rf -- "$temporary_directory"' EXIT
    download_verified_archive \
        https://github.com/jesseduffield/lazydocker/releases/download/v0.25.2/lazydocker_0.25.2_Linux_x86_64.tar.gz \
        0d9dbfc26068b218e7ed84b104748cadc6e3cf733c0afd35465306fb39b9523c \
        "$temporary_directory/lazydocker.tar.gz"
    tar -xzf "$temporary_directory/lazydocker.tar.gz" -C "$temporary_directory"
    install -m 755 "$temporary_directory/lazydocker" "$HOME/.local/bin/lazydocker"
    "$HOME/.local/bin/lazydocker" --version
)

install_tmux_resurrect() (
    local plugin_directory="$HOME/.tmux/plugins/tmux-resurrect"
    if [[ -e "$plugin_directory" ]]; then
        if [[ ! -x "$plugin_directory/resurrect.tmux" ]]; then
            printf 'Incomplete tmux-resurrect installation: %s\n' "$plugin_directory" >&2
            return 1
        fi
        printf 'Keeping existing tmux-resurrect installation.\n'
        return
    fi

    local temporary_directory
    temporary_directory="$(mktemp -d)"
    trap 'rm -rf -- "$temporary_directory"' EXIT
    download_verified_archive \
        https://codeload.github.com/tmux-plugins/tmux-resurrect/tar.gz/cff343cf9e81983d3da0c8562b01616f12e8d548 \
        9f1dda18554291ee7f8a0f499e2af90bbadc2ebceb7a995bb13b76529fe0c5c9 \
        "$temporary_directory/tmux-resurrect.tar.gz"
    mkdir "$temporary_directory/plugin"
    tar -xzf "$temporary_directory/tmux-resurrect.tar.gz" \
        --strip-components=1 -C "$temporary_directory/plugin"
    if [[ ! -x "$temporary_directory/plugin/resurrect.tmux" ]]; then
        printf 'tmux-resurrect archive is missing its executable entry point.\n' >&2
        return 1
    fi
    mkdir -p "$HOME/.tmux/plugins"
    mv -- "$temporary_directory/plugin" "$plugin_directory"
)

install_shell_tools() {
    local oh_my_zsh_directory="${ZSH:-$HOME/.oh-my-zsh}"
    local custom_themes_directory="${ZSH_CUSTOM:-$oh_my_zsh_directory/custom}/themes"
    mkdir -p "$HOME/.local/bin"
    install_eza
    install_atuin
    install_lazydocker
    install_tmux_resurrect

    if [[ ! -e "$oh_my_zsh_directory" ]]; then
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$oh_my_zsh_directory"
    fi
    if [[ ! -r "$oh_my_zsh_directory/oh-my-zsh.sh" ]]; then
        printf 'Incomplete Oh My Zsh installation: %s\n' "$oh_my_zsh_directory" >&2
        return 1
    fi
    if [[ ! -e "$custom_themes_directory/powerlevel10k" ]]; then
        mkdir -p "$custom_themes_directory"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "$custom_themes_directory/powerlevel10k"
    fi
    if [[ ! -r "$custom_themes_directory/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
        printf 'Incomplete Powerlevel10k installation.\n' >&2
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
    install_shell_tools
fi
