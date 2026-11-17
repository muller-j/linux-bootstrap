#!/usr/bin/env bash
set -euo pipefail

repository_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repository_directory/packages/tools.sh"

fnm_directory="$HOME/.local/share/fnm"
if [[ -x "$fnm_directory/fnm" ]]; then
    "$fnm_directory/fnm" --version
    exit 0
fi

temporary_directory="$(mktemp -d)"
trap 'rm -rf -- "$temporary_directory"' EXIT
download_verified_archive \
    https://github.com/Schniz/fnm/releases/download/v1.39.0/fnm-linux.zip \
    7807664f39d39fc518da1c35ba0181e4b3267603c4b1dedeb4b5fc6ae440a224 \
    "$temporary_directory/fnm.zip"
unzip -q "$temporary_directory/fnm.zip" -d "$temporary_directory/fnm"
mkdir -p "$fnm_directory"
install -m 755 "$temporary_directory/fnm/fnm" "$fnm_directory/fnm"
"$fnm_directory/fnm" --version
printf 'fnm installed. Select a Node version with: fnm install <version>\n'
