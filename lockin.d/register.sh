#!/usr/bin/env bash
set -euo pipefail

# --- Get or create project registry

REGISTRY="${LOCKIN_PROJECT_REGISTRY:-$HOME/.config/lockin/projects.conf}"
mkdir -p "$(dirname "$REGISTRY")"
touch "$REGISTRY"

usage() {
    echo "usage: lockin register <path> [name]" >&2
    exit 1
}

[[ $# -ge 1 && $# -le 2 ]] || usage

# --- Validate project directory

if ! DIR="$(realpath -e "$1" 2>/dev/null)"; then
    echo "No such path: $1" >&2
    exit 1
fi

if [[ ! -d "$DIR" ]]; then
    echo "Not a directory: $DIR" >&2
    exit 1
fi

# --- Validate project name

NAME="${2:-$(basename "$DIR")}"

# Reject names that would collide with the session-name scheme.
if [[ -z "$NAME" || "$NAME" == *[[:space:]]* || "$NAME" == *[/.:]* ]]; then
    echo "Name must be non-empty and free of whitespace, '/', '.', or ':': '$NAME'" >&2
    exit 1
fi

if awk -F'\t' -v n="$NAME" '!/^[[:space:]]*(#|$)/ && $1==n { found=1 } END { exit !found }' "$REGISTRY"; then
    echo "Name '$NAME' is already registered:" >&2
    awk -F'\t' -v n="$NAME" '$1==n { printf "  %s -> %s\n", $1, $2 }' "$REGISTRY" >&2
    exit 1
fi

# Same path under a different name is probably a mistake; warn but allow.
if awk -F'\t' -v p="$DIR" '!/^[[:space:]]*(#|$)/ && $2==p { found=1 } END { exit !found }' "$REGISTRY"; then
    echo "Warning: path is already registered under a different name." >&2
fi

printf '%s\t%s\n' "$NAME" "$DIR" >>"$REGISTRY"
echo "Registered: $NAME -> $DIR"

exit 0
