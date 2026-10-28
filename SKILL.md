---
name: warp-orchestrator
description: Linux + Warp only. Makes the current agent session a coordinator that opens, tracks and resumes agent sessions (Claude Code, Codex or Gemini) in new Warp tabs, each named after the Odoo task it works on. Routes to warp-open (one session, one task, or a list), warp-umbrella (one session per open subtask of an Odoo umbrella task) and warp-resume (find and reopen an existing session). Use when the user says "abrí una sesión nueva", "nueva pestaña con Claude para X", "una sesión por subtarea de la 78564", "abrí sesiones para estos PRs", "retomá la sesión de la 77768", "qué sesiones abrí hoy", "coordiná estas tareas".
---

# Warp orchestrator

This session is the coordinator. Keep it short and clean: the work happens in the tabs it opens.
Each tab runs its own agent session, named `<task id> <short name>`.

## Before anything

Run `warp-check`. If it exits non-zero, stop and tell the user the reason it printed. Do not open
tabs another way. If `warp-check` is not found, tell the user to run
`~/.agents/skills/warp-orchestrator/install.sh`.

## Route

| The user asks for | Load |
|---|---|
| A new session, one task or ticket, or one session per item of a list | `warp-open` |
| One session per subtask of an umbrella task | `warp-umbrella` |
| Reopen a session that already exists | `warp-resume` |
| What was opened | `warp-opened` (below) |

## Tools

All are in `PATH`; `--help` prints the full usage.

```bash
warp-check                                   # exit 0 inside Warp on Linux
warp-name 78420 "Skill encarar: borrador"    # → 78420 Skill encarar
warp-name --group 78564 "Dev Tips en la era IA"  # → UM 78564 · Dev Tips en la era IA
warp-tab -d <dir> "<name>::<prompt>"         # one tab
warp-tab -d <dir> -g "<group>" "<n1>::<p1>" "<n2>::<p2>"   # several, grouped per GROUP_MODE
warp-tab --agent warp-orchestrator "Orquestador::"   # a session started with a Claude agent
warp-tab -d <dir> -r <session-id>            # resume; repeat -r to resume several
warp-orchestrator                            # start the coordinator here, named "Orquestador"
warp-tab -a codex ...                        # other runtime: claude (default), codex, gemini
warp-tab --dry-run ...                       # print the tab configs, open nothing
warp-sessions <number or words>              # find existing sessions
warp-opened [--days N] [--group TEXT] [--open]   # tabs opened by warp-tab, open or closed
```

## Rules for every tab

- **Name:** the task number and its Odoo name. Pass the full name: `warp-tab` shortens names that
  start with a task id. Name it by the task even when the session is about a PR. Without a task,
  say what it does (`Check Railway logs`). An empty session has no name.
- **Folder (`-d`):** the repo the request names; otherwise the coordinator's folder. For Claude, a
  folder without `hasTrustDialogAccepted: true` in `~/.claude.json` stops at the trust prompt: use
  the coordinator's folder and name the repo and its path in the prompt.
- **Runtime (`-a`):** `claude` unless the user asks for another.
- **Group (`-g`):** always with two or more tabs, so the user finds them together. Warp creates
  groups only from its UI or from a launch config, so there are three modes. `warp-tab` uses
  `GROUP_MODE` from `~/.config/warp-orchestrator/config` unless a flag says otherwise; do not pass
  a flag unless the user asks for a mode. The group is saved in the registry in all of them.
  - `keys`: a native group in the current window. `xdotool` presses the Warp shortcut of "Create
    tab group from active or selected tab(s)" and types the name in the rename box Warp opens.
    Before running it, tell the user not to type for about 10 seconds. It needs that shortcut set
    in Warp (Settings > Keyboard shortcuts); without it, or if Warp loses the focus, the tabs open
    without the group. Never search Warp's command palette instead: a slow filter can pick a file
    and the group name gets typed into it.
  - `window`: a native group in a new Warp window, from a launch config, with no screen control.
  - `inherit`: no native group; the tabs get the group's color, land after the active tab and join
    its Warp group, if it has one.
- **Group tabs that are already open:** no script can move or close a Warp tab. Ask the user to
  close them (the sessions stay on disk), check with `warp-opened` that their `live` column says
  `closed`, then reopen them all in one call, keeping their context:
  `warp-tab -g "<group>" -r <id1> -r <id2> "<n1>::" "<n2>::"`. Never reopen a session that is
  still `open`: two processes would write the same session.
- **Coordinator agent:** `agents/warp-orchestrator.md` is the coordinator's identity. Start it with
  `warp-orchestrator` (named `Orquestador`, or `ORCHESTRATOR_NAME` in the config), or in a new tab
  with `warp-tab --agent warp-orchestrator "Orquestador::"`. `--agent` works with any Claude agent.
- **Quota:** with more than 6 tabs that carry a prompt, show the list and ask first. With fewer,
  show one line per tab and open. Opening tabs needs no permission.
- **Report:** how many tabs opened, the group and its color. If `warp-tab` failed, quote its
  message as is.

## What was opened

`warp-opened` reads the registry `warp-tab` writes in
`~/.local/state/warp-orchestrator/sessions.jsonl`. Use it to answer "qué abrí hoy" or to find the
session id of a tab. For Claude sessions it also says whether the tab is still `open` (with the
agent's status: busy, idle, waiting) or `closed`, read from Claude's `~/.claude/sessions/*.json`,
and gives the tab's `warp://session/<uuid>` link: `xdg-open` it to bring that tab to the front.
To tell which tasks are done, check their `state` in Odoo
(`1_done` or `1_canceled`) and tell the user which tabs to close: there is no known way to close a
Warp tab from a script.

## Tab alerts

Hooks mark the tab title when a Claude session stops (`✅ <name>`) or needs the user
(`🔔 <name>`, on permission and idle prompts); Claude puts its own title back when it works again.
They sit next to Warp's own status icons from the `warp@claude-code-warp` plugin.

```bash
warp-alerts                  # show the config
warp-alerts sound on|off     # also play a sound (off by default)
warp-alerts test             # play both sounds
```

Sounds and their files live in `~/.config/warp-orchestrator/config`.

## Traps

- Tabs open in the Warp window that was focused last.
- Focus: each new tab takes the focus for about a second; then `warp-tab` goes back to the tab
  that ran it (Warp's `WARP_FOCUS_URL`). A key pressed in that second lands in the new tab. The
  Warp window comes to the front even if the user was in another app. Pass `--focus` only when
  the user wants to stay on the new tab.
- Screen control: only the `keys` group mode sends keys (`xdotool`). Everything else uses Warp's
  own files and `warp://` links.
- `warp-tab` writes a temporary tab config in Warp's `tab_configs` folder and opens it with a
  `warp://tab_config/<name>` link; it deletes the file 15 seconds later. The tab runs a launcher
  script from `~/.local/state/warp-orchestrator/launch/` that deletes itself and execs the agent.
  If a tab does not open, run again with `--dry-run` to see both files.
- Warp types the launcher command into the new tab. A key pressed in that second can land at its
  end; the launcher ignores it, so the agent still starts with the right arguments.
