# warp-orchestrator

Skills and scripts to run one agent session per task, each in its own Warp tab, from a
coordinator session. Based on `abrir-sesiones-warp` (gr) and the Warp part of `encarar` (jjs).

```
warp-orchestrator/        entry skill: checks Warp, routes, reads the registry
├── references/           read by the entry skill; not skills of their own, so only
│   ├── open.md           /warp-orchestrator shows in the slash menu
│   ├── umbrella.md
│   └── resume.md
├── agents/               warp-orchestrator.md, the coordinator agent
├── bin/                  warp-check, warp-tab, warp-name, warp-sessions, warp-opened, warp-alerts,
│                         warp-orchestrator
├── hooks/
│   ├── session-start     tells the agent when Warp is not available
│   └── agent-event       ✅ / 🔔 in the tab title and an optional sound
└── evals/cases.yml
```

## Install

```bash
~/.agents/skills/warp-orchestrator/install.sh
```

It links `bin/*` into `~/.local/bin`, the skills into `~/.agents/skills` and `~/.claude/skills`,
and registers the SessionStart, Stop and Notification hooks in `~/.claude/settings.json`.

## Requirements

Linux, Warp (stable or preview), `xdg-open`, `python3`, and the agent CLI the tab runs
(`claude`, `codex` or `gemini`).

## How a tab opens

`warp-tab` writes a launcher script with the agent command (it deletes itself when it runs) and a
Warp config that runs it:

- One tab, or `--same-window`: a tab config (TOML), opened with `warp://tab_config/<name>`.
- A group (`-g`) of 2+ tabs: a launch config with `tab_groups`, opened with `warp://launch/<name>`.
  Warp only creates tab groups from its UI or from a launch config, and a launch config link always
  opens a new window, so each group gets its own window.

- `--keys` (or `GROUP_MODE=keys`): a native group in the current window. `xdotool` presses the
  Warp shortcut of "Create tab group from active or selected tab(s)" (set it once in Settings >
  Keyboard shortcuts) and types the name. It is the only option that controls the screen. gr's
  `claude-tab` searches the command palette instead; a slow filter there can pick a file and type
  the group name into it.

Configs are deleted 15 seconds later.

## Coordinator agent

`agents/warp-orchestrator.md` is a Claude agent for the coordinator session, based on gr's
`orquestador`: it opens sessions with these skills, talks to them with `ListAgents` and
`SendMessage`, sums up where each one stands and keeps its pending items in
`~/.local/state/warp-orchestrator/state.md`. `install.sh` links it into `~/.claude/agents`.

```bash
warp-orchestrator          # new tab: claude --agent warp-orchestrator --name Orquestador, yellow
warp-orchestrator --here   # same, in this terminal (no color)
``` For Claude it
passes `--session-id`, so the registry knows the id of every new session.
