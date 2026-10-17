#!/usr/bin/env bash
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

usage() {
    local exit_code="${1:-1}"
    cat >&2 <<'EOF'
usage: lockin <command> [args...]

commands:
  start <project> [agent]   Start locking in for a project
  stop [project]            Stop locking in (all, or one project)
  list                      List registered projects
  register <path> [name]    Register a project

  agents list               List registered agents
  agents register <name> <command>
                            Register an AI agent
EOF
    exit "$exit_code"
}

[[ $# -ge 1 ]] || usage

cmd="$1"
shift

case "$cmd" in
start) exec "$SCRIPT_DIR/lockin.d/start.sh" "$@" ;;
stop) exec "$SCRIPT_DIR/lockin.d/stop.sh" "$@" ;;
list | ls) exec "$SCRIPT_DIR/lockin.d/list.sh" "$@" ;;
register) exec "$SCRIPT_DIR/lockin.d/register.sh" "$@" ;;
agents)
    [[ $# -ge 1 ]] || usage
    sub="$1"
    shift
    case "$sub" in
    register) exec "$SCRIPT_DIR/lockin.d/agents-register.sh" "$@" ;;
    list) exec "$SCRIPT_DIR/lockin.d/agents-list.sh" "$@" ;;
    *)
        echo "Unknown agents subcommand: $sub" >&2
        usage
        ;;
    esac
    ;;
-h | --help | help) usage 0 ;;
*)
    echo "Unknown command: $cmd" >&2
    usage
    ;;
esac
