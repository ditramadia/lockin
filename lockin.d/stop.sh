#!/usr/bin/env bash
set -euo pipefail

command -v tmux >/dev/null 2>&1 || { echo "tmux is required but not installed." >&2; exit 1; }

PREFIXES=(main editor agent)

usage() {
    echo "usage: lockin stop [project]" >&2
    echo "  (No arg: kill all lockin sessions)" >&2
    exit 1
}

# --- Validate args

[[ $# -le 1 ]] || usage

filter="${1:-}"

# --- Collect matching session names

mapfile -t sessions < <(
    tmux ls -F '#{session_name}' 2>/dev/null |
        awk -v p="$filter" -v prefixes="${PREFIXES[*]}"'
        BEGIN { n = split(prefixes, pre, " ") }
        {
            name = $0
            for (i = 1; i <= n; i++) {
                pfx = pre[i] "-"
                if (index(name, pfx) == 1) {
                    if (p == "" || substr(name, length(pfx) + 1) == p) {
                        print name
                        next
                    }
                }
            }
        }
    '
)

# --- Validate if the project is actually running

if [[ ${#sessions[@]} -eq 0 ]]; then
    if [[ -n "$filter" ]]; then
        echo "No lockin sessions found for project: $filter"
    else
        echo "No lockin sessions running."
    fi
    exit 0
fi

# --- Warn before the kill

echo "The following tmux sessions will be terminated:"
for s in "${sessions[@]}"; do
    echo "  - $s"
done

if ! read -p "Are you sure? (y/N) " -n 1 -r; then
    echo
    echo "Aborted."
    exit 1
fi
echo
[[ $REPLY =~ ^[Yy]$ ]] || {
    echo "Aborted."
    exit 1
}

# --- Kill the sessions

for s in "${sessions[@]}"; do
    tmux kill-session -t "$s" 2>/dev/null || true
    echo "  [✓] Killed session: $s"
done

exit 0
