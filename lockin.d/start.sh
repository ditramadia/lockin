#!/usr/bin/env bash
set -euo pipefail

command -v tmux >/dev/null 2>&1 || {
    echo "tmux is required but not installed." >&2
    exit 1
}

TERMINAL="${LOCKIN_TERMINAL:-kitty}"

launch_terminal() {
    local session="$1"

    if ! command -v "$TERMINAL" >/dev/null 2>&1; then
        echo "Warning: terminal '$TERMINAL' not found; '$session' left detached." >&2
        return 0
    fi

    case "$TERMINAL" in
    kitty) kitty --detach tmux attach -t "$session" ;;
    gnome-terminal) gnome-terminal -- tmux attach -t "$session" & ;;
    wezterm) wezterm start -- tmux attach -t "$session" & ;;
    *) "$TERMINAL" -e tmux attach -t "$session" & ;;
    esac
}

# --- Validate project registry

PROJECT_REGISTRY="${LOCKIN_PROJECT_REGISTRY:-$HOME/.config/lockin/projects.conf}"

if [[ ! -f "$PROJECT_REGISTRY" ]]; then
    echo "No registry at $PROJECT_REGISTRY" >&2
    exit 1
fi

usage() {
    echo "usage: lockin start <project> [agent]" >&2
    echo "  (to see registered projects, use: lockin list)"
    exit 1
}

# --- Valdiate command

[[ $# -ge 1 && $# -le 2 ]] || usage

PROJECT_NAME="$1"

# --- Resolve Project

# Look up the line whose first field is exactly $PROJECT_NAME.
# exit on first match
LINE="$(awk -F'\t' -v n="$PROJECT_NAME" '!/^[[:space:]]*(#|$)/ && $1==n { print; exit }' "$PROJECT_REGISTRY")"

if [[ -z "$LINE" ]]; then
    echo "Unknown project: $PROJECT_NAME" >&2
    echo "  (to see registered projects, use: lockin list)"
    exit 1
fi

PROJECT_DIR="$(cut -f2 <<<"$LINE")"
PROJECT_DIR="${PROJECT_DIR/#\~/$HOME}"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "Path no longer exists: $PROJECT_DIR" >&2
    exit 1
fi

# --- Resolve agent (optional)

AGENT=""
AGENT_COMMAND=""

if [[ $# -gt 1 ]]; then
    AGENT="$2"

    if [[ "$AGENT" == "none" ]]; then
        AGENT="" # explicit "no agent"; treated same as omitting
    else
        AGENT_REGISTRY="${LOCKIN_AGENT_REGISTRY:-$HOME/.config/lockin/agents.conf}"

        if [[ ! -f "$AGENT_REGISTRY" ]]; then
            echo "No agent registry at $AGENT_REGISTRY" >&2
            exit 1
        fi

        AGENT_LINE="$(awk -F'\t' -v n="$AGENT" '!/^[[:space:]]*(#|$)/ && $1==n { print; exit }' "$AGENT_REGISTRY")"

        if [[ -z "$AGENT_LINE" ]]; then
            echo "Unknown agent: $AGENT" >&2
            exit 1
        fi

        AGENT_COMMAND="$(cut -f2 <<<"$AGENT_LINE")"
    fi
fi

echo "name: $PROJECT_NAME"
echo "dir:  $PROJECT_DIR"
echo "agent: ${AGENT:-<none>}"

# --- Create session: main

SESSION_MAIN="main-$PROJECT_NAME"

if ! tmux has-session -t "$SESSION_MAIN" 2>/dev/null; then
    tmux new-session -d -s "$SESSION_MAIN" -c "$PROJECT_DIR"
    tmux split-window -v -t "$SESSION_MAIN:0" -c "$PROJECT_DIR"
    tmux select-pane -t "$SESSION_MAIN:0.0"
fi

# --- Create session: editor (in a separate kitty window)

SESSION_EDITOR="editor-$PROJECT_NAME"

if ! tmux has-session -t "$SESSION_EDITOR" 2>/dev/null; then
    tmux new-session -d -s "$SESSION_EDITOR" -c "$PROJECT_DIR"
    tmux send-keys -t "$SESSION_EDITOR:0.0" "nvim" C-m

    launch_terminal "$SESSION_EDITOR"
fi

# -- Create session: agent (in a separate kitty window)

if [[ -n "$AGENT" ]]; then
    SESSION_AGENT="agent-$PROJECT_NAME"

    if ! tmux has-session -t "$SESSION_AGENT" 2>/dev/null; then
        tmux new-session -d -s "$SESSION_AGENT" -c "$PROJECT_DIR"
        tmux send-keys -t "$SESSION_AGENT:0.0" "$AGENT_COMMAND" C-m

        launch_terminal "$SESSION_AGENT"
    fi
fi

exec tmux attach -t "$SESSION_MAIN"
