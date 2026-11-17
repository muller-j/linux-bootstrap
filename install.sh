#!/usr/bin/env bash
set -euo pipefail
umask 077

repository_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
links_only=false
case "${1:-}" in
    "") ;;
    --links-only) links_only=true ;;
    --help)
        printf 'Usage: bash install.sh [--links-only]\n'
        printf 'Install configured tools and link dotfiles; --links-only skips package/tool installation.\n'
        exit 0
        ;;
    *)
        printf 'Unknown option: %s\n' "$1" >&2
        exit 1
        ;;
esac
if (( $# > 1 )); then
    printf 'Only one option is accepted.\n' >&2
    exit 1
fi
if [[ "$EUID" -eq 0 ]]; then
    printf 'Run as your regular user, not with sudo. APT requests sudo when needed.\n' >&2
    exit 1
fi
if [[ "$(readlink -f -- "$HOME/linux-bootstrap")" != "$repository_directory" ]]; then
    printf 'Clone this repository at %s/linux-bootstrap before installing.\n' "$HOME" >&2
    exit 1
fi

export PATH="$HOME/.local/bin:$PATH"
if [[ -L "$repository_directory/proxy.env" ]]; then
    printf 'proxy.env must be a regular private file, not a symlink.\n' >&2
    exit 1
fi
if [[ -r "$repository_directory/proxy.env" ]]; then
    chmod 600 "$repository_directory/proxy.env"
    source "$repository_directory/proxy.env"
fi

install_apt_packages() {
    local package_name
    local package_status
    local missing_packages=()
    while IFS= read -r package_name || [[ -n "$package_name" ]]; do
        [[ -z "$package_name" || "$package_name" == \#* ]] && continue
        if package_status="$(dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null)" \
            && [[ "$package_status" == 'install ok installed' ]]; then
            continue
        fi
        missing_packages+=("$package_name")
    done < "$repository_directory/packages/apt.txt"

    if (( ${#missing_packages[@]} )); then
        sudo apt-get update
        sudo apt-get install -y -- "${missing_packages[@]}"
    fi
    if ! command -v eza >/dev/null 2>&1 && apt-cache show eza >/dev/null 2>&1; then
        sudo apt-get install -y eza
    fi
}

if [[ "$links_only" == false ]]; then
    if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
        printf 'This V1 supports Ubuntu/Debian Linux x86_64 only.\n' >&2
        exit 1
    fi
    install_apt_packages
    bash "$repository_directory/packages/tools.sh"
    bash "$repository_directory/scripts/install-node.sh"
    bash "$repository_directory/scripts/install-sdkman.sh"
fi

backup_directory=""
link_configuration() {
    local source_path="$1"
    local destination_path="$2"
    local relative_destination="${destination_path#"$HOME/"}"
    if [[ ! -e "$source_path" ]]; then
        printf 'Missing configuration source: %s\n' "$source_path" >&2
        return 1
    fi
    if [[ -L "$destination_path" && "$(readlink -- "$destination_path")" == "$source_path" ]]; then
        return
    fi
    if [[ -e "$destination_path" || -L "$destination_path" ]]; then
        if [[ -z "$backup_directory" ]]; then
            mkdir -p "$HOME/.local/state/linux-bootstrap/backups"
            backup_directory="$(mktemp -d "$HOME/.local/state/linux-bootstrap/backups/install.XXXXXX")"
        fi
        mkdir -p "$(dirname -- "$backup_directory/$relative_destination")"
        mv -- "$destination_path" "$backup_directory/$relative_destination"
    fi
    mkdir -p "$(dirname -- "$destination_path")"
    ln -s -- "$source_path" "$destination_path"
}

for dotfile_name in .bashrc .zshrc .profile; do
    link_configuration "$repository_directory/shell/$dotfile_name" "$HOME/$dotfile_name"
done
link_configuration "$repository_directory/config/powerlevel10k/.p10k.zsh" "$HOME/.p10k.zsh"
link_configuration "$repository_directory/config/eza/theme.yml" "$HOME/.config/eza/theme.yml"
link_configuration "$repository_directory/config/atuin/config.toml" "$HOME/.config/atuin/config.toml"
link_configuration "$repository_directory/config/tmux/.tmux.conf" "$HOME/.tmux.conf"

if [[ ! -e "$repository_directory/proxy.env" ]]; then
    printf 'Proxy not configured. Copy proxy.env.example to proxy.env if required.\n'
else
    chmod 600 "$repository_directory/proxy.env"
fi
if [[ -n "$backup_directory" ]]; then
    printf 'Previous configurations preserved in %s\n' "$backup_directory"
fi
printf 'Configuration linked. Run exec zsh in your terminal to reload.\n'
