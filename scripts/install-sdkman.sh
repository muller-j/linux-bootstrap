#!/usr/bin/env bash
set -euo pipefail

export SDKMAN_DIR="$HOME/.sdkman"
if [[ -r "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    printf 'Keeping existing SDKMAN installation: %s\n' "$SDKMAN_DIR"
    exit 0
fi
if [[ -e "$SDKMAN_DIR" ]]; then
    printf 'Incomplete SDKMAN directory; inspect it before retrying: %s\n' "$SDKMAN_DIR" >&2
    exit 1
fi

temporary_directory="$(mktemp -d)"
trap 'rm -rf -- "$temporary_directory"' EXIT
curl --fail --location --retry 3 --connect-timeout 15 --max-time 300 \
    https://get.sdkman.io --output "$temporary_directory/install-sdkman.sh"
bash -n "$temporary_directory/install-sdkman.sh"
bash "$temporary_directory/install-sdkman.sh"
if [[ ! -r "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    printf 'SDKMAN installer did not create its initialization script.\n' >&2
    exit 1
fi
