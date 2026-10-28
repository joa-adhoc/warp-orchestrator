# warp-orchestrator

Skills and scripts to run one agent session per task, each in its own Warp tab, from a
coordinator session. Based on `abrir-sesiones-warp` (gr) and the Warp part of `encarar` (jjs).

```
warp-orchestrator/        entry skill: checks Warp, routes, reads the registry
├── skills/
│   ├── warp-open/        one session, one task, or a list
│   ├── warp-umbrella/    one session per open subtask of an umbrella
│   └── warp-resume/      find and reopen a session
├── bin/                  warp-check, warp-tab, warp-name, warp-sessions, warp-opened, warp-alerts
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

`warp-tab` writes a Warp tab config (TOML) with the title, color and folder, and a launcher script
with the agent command. It opens the config with `warp://tab_config/<name>` and deletes it 15
seconds later; the launcher deletes itself when it runs. For Claude it
passes `--session-id`, so the registry knows the id of every new session.
