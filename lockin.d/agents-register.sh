#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${LOCKIN_AGENT_REGISTRY:-$HOME/.config/lockin/agents.conf}"
mkdir -p "$(dirname "$REGISTRY")"
touch "$REGISTRY"

usage() {
    echo "usage: lockin agents register <name> <command>" >&2
    exit 1
}

[[ $# -eq 2 ]] || usage

NAME="$1"
COMMAND="$2"

if [[ "$COMMAND" == *$'\t'* || "$COMMAND" == *$'\n'* ]]; then
    echo "Command must not contain tabs or newlines." >&2
    exit 1
fi

if [[ -z "$NAME" || "$NAME" == *[[:space:]]* || "$NAME" == *[/.:]* ]]; then
    echo "Name must be non-empty and free of whitespace, '/', '.', or ':': '$NAME'" >&2
    exit 1
fi

if awk -F'\t' -v n="$NAME" '!/^[[:space:]]*(#|$)/ && $1==n { found=1 } END { exit !found }' "$REGISTRY"; then
    echo "Agent '$NAME' is already registered:" >&2
    awk -F'\t' -v n="$NAME" '$1==n { printf "  %s -> %s\n", $1, $2 }' "$REGISTRY" >&2
    exit 1
fi

printf '%s\t%s\n' "$NAME" "$COMMAND" >>"$REGISTRY"
echo "Registered agent: @$NAME -> $COMMAND"

exit 0
