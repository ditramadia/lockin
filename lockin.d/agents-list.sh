#!/usr/bin/env bash
set -euo pipefail

REGISTRY="${LOCKIN_AGENT_REGISTRY:-$HOME/.config/lockin/agents.conf}"

if [[ ! -f "$REGISTRY" ]]; then
    echo "No registry at $REGISTRY" >&2
    exit 1
fi

usage() {
    echo "usage: lockin agents list" >&2
    exit 1
}

# --- Validate args

[[ $# -lt 1 ]] || usage

# --- List registered agents

echo "Registered agents:"
awk -F'\t' '!/^[[:space:]]*(#|$)/ { printf "  %s\n", $1 }' "$REGISTRY"

exit 0
