#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${LOCKIN_PROJECT_REGISTRY:-$HOME/.config/lockin/projects.conf}"

if [[ ! -f "$REGISTRY" ]]; then
    echo "No registry at $REGISTRY" >&2
    exit 1
fi

usage() {
    echo "usage: lockin list" >&2
    exit 1
}

# --- Validate args

[[ $# -lt 1 ]] || usage

# --- List registered projects

echo "Registered projects:"
awk -F'\t' '!/^[[:space:]]*(#|$)/ { printf "  %s\n", $1 }' "$REGISTRY"

exit 0
