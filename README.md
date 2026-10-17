<div align="center">

# lockin

### No more "I'll start in five minutes." Just lock in

**lockin** is a tiny **shell CLI** that drops you straight into a focused working
session. One command and you've got a **tmux workspace** spun up for your project,
your **editor** open in its own window, and your favorite **AI agent** riding shotgun.

![Bash Script](https://img.shields.io/badge/bash_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![tmux](https://img.shields.io/badge/tmux-%23000000.svg?style=for-the-badge&logo=tmux&logoColor=%231BB91F)

<code>lockin start mycoolapp</code>

</div>

## Background

**lockin** is a small set of shell scripts that start, stop, and manage my development environment for a given project.

### The problem

I work on multiple projects, each with a repo that needs the same handful of things running at once:

* A shell for git commands (commits, rebases, diffs).
* A second shell for running the server, tests, and ad-hoc commands.
* An editor (neovim) open in the project.
* Optionally, an AI coding harness (Claude Code, OpenCode, etc.) running against the code.

Doing this by hand every time is tedious and error-prone: opening several terminal windows, cd-ing each one into the repo, remembering to split the right pane the right way. The friction compounds across projects, and I kept re-deriving the same layout manually.

### The tool

**lockin** automates that setup. `lockin start <project>` creates three tmux sessions in one shot:

| Session | Purpose | Window |
| --- | --- | --- |
| `main-<project>` | Two panes: git (top), scratch/server (bottom) | Current terminal |
| `editor-<project>` | Neovim | Separate kitty window |
| `agent-<project>` | AI harness (optional) | Separate kitty window |

The main session attaches to the current terminal; the editor and agent sessions open in their own windows so the main terminal stays focused on git and scratch work. Re-running lockin start is idempotent; existing sessions are reused, not duplicated.

The counterpart, `lockin stop`, tears the sessions down (all of them, or one project's).

### Design decisions

A few choices shaped the implementation and are worth recording:

* **tmux as the backbone**. Sessions and panes are tmux's native abstraction, so **lockin** doesn't reimplement window management. This also means `tmux attach` works normally, sessions survive terminal restarts, and `tmux ls` gives a truthful view of what's running.

* **A project registry, not auto-discovery**. A file at `~/.config/lockin/projects.conf` maps project names to paths. Auto-scanning a `~/Projects` directory was considered and rejected: the layout is non-uniform (workspaces containing repos alongside non-repo directories like `photoshop/` and `planning/`), so scanning either misses repos or surfaces noise. Explicit registration is more honest.

* **Agents are a sub-resource**. AI harnesses live in their own registry (`agents.conf`) and are addressed as **lockin** agents register, not as a top-level verb because they're a property of the project environment, not a sibling concern.

* **One dispatcher, one script per verb**. **lockin** is a dispatcher; the real work lives in `lockin.d/*.sh`. This keeps each command independently testable and means a bug in one verb can't break another. No build step or runtime. The scripts are the app.

* **Validate before acting**. All argument and registry validation happens before any `tmux new-session` or `kitty` call, so a bad agent name or missing project fails cleanly without leaving half-created sessions behind.

## Features

* **One-word focus.** `lockin start <project>` boots a tmux session for your
  project and attaches you to it instantly.
* **Three panes.** Each session is split into the working
  shell, an editor window (nvim by default), and an optional AI agent window.
* **Project registry.** Register your projects once with `lockin register`,
  then start them by name instead of path.
* **Agent registry.** Register your AI agents once, then summon them alongside
  any project with `lockin start <project> <agent>`.
* **Safe teardown.** `lockin stop` lists every session it's about to kill and
  asks before pulling the plug.
* **Configurable.** Point the registries or terminal anywhere via environment
  variables. Ships with sane defaults so it just works.

## Project Structure

```
lockin/
├── lockin.sh                 # Dispatcher: parses commands and routes them
├── lockin.d/
│   ├── start.sh              # Spins up the tmux session(s) for a project
│   ├── stop.sh               # Kills lockin tmux sessions (with confirmation)
│   ├── list.sh               # Lists registered projects
│   ├── register.sh           # Registers a project path under a name
│   ├── agents-list.sh        # Lists registered agents
│   └── agents-register.sh    # Registers an agent name + launch command
├── LICENSE
└── README.md
```

## Installation

**Dependencies:** `bash`, `tmux`, and a terminal emulator (defaults to
`kitty`).

```bash
# Clone it anywhere you like
git clone https://github.com/ditramadia/lockin.git
cd lockin

# Symlink the dispatcher onto your PATH
ln -s "$(pwd)/lockin.sh" "$HOME/.local/bin/lockin"
```

Make sure `~/.local/bin` is on your `PATH` (add it to your shell profile if it
isn't), then:

```bash
lockin --help
```

## How it Works

### Registering projects

```bash
lockin register ~/code/my-cool-app mycoolapp
lockin list
```

Projects are stored one per line in
`~/.config/lockin/projects.conf` as `name<TAB>path`. Comments (`#`) and blank
lines are ignored.

### Registering agents

```bash
lockin agents register claude "claude --model claude-opus-5-5"
lockin agents list
```

Agents live in `~/.config/lockin/agents.conf` the same way. The command is what
gets typed into the agent's pane when you start a session.

### Locking in

```bash
lockin start mycoolapp claude
```

`start` resolves the project (and optional agent) from your registries, then
spins up three tmux sessions:

| Session        | Purpose                                        |
| -------------- | ---------------------------------------------- |
| `main-<proj>`  | Working shell — this is the one you attach to  |
| `editor-<proj>`| Your editor (nvim) in its own terminal window  |
| `agent-<proj>` | Your AI agent in its own terminal window       |

Sessions are only created if they don't already exist, so running `start` again
just re-attaches you and nothing gets duplicated. You can also run
`lockin start mycoolapp none` (or omit the agent entirely) to lock in solo.

### Clocking out

```bash
lockin stop            # kill every lockin session
lockin stop mycoolapp      # kill just mycoolapp's sessions
```

`stop` shows you exactly which sessions are about to die and asks for a `y`
before doing anything you'll regret.

### Configuration

| Variable                 | Default                            | Purpose                        |
| ------------------------ | ---------------------------------- | ------------------------------ |
| `LOCKIN_PROJECT_REGISTRY`| `~/.config/lockin/projects.conf`   | Project registry location      |
| `LOCKIN_AGENT_REGISTRY`  | `~/.config/lockin/agents.conf`     | Agent registry location        |
| `LOCKIN_TERMINAL`        | `kitty`                            | Terminal used for editor/agent windows |

## MIT License

MIT — See [LICENSE](LICENSE) for the full text.
