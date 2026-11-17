#!/usr/bin/env bash
set -euo pipefail
umask 077

backup_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
apt-mark showmanual | LC_ALL=C sort > "$backup_directory/apt-manual.txt"
dpkg-query -W -f='${binary:Package}\t${Version}\t${db:Status-Status}\n' \
    > "$backup_directory/apt-installed.tsv"
date -u '+%Y-%m-%dT%H:%M:%SZ' > "$backup_directory/captured-at.txt"
printf 'APT inventories exported to %s (ignored by Git).\n' "$backup_directory"
