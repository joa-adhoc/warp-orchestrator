---
name: warp-orchestrator
description: Linux + Warp only. Makes the current agent session a coordinator that opens, tracks and resumes agent sessions (Claude Code, Codex or Gemini) in new Warp tabs, each named after the Odoo task it works on. Covers one session, one task, a list, one session per open subtask of an Odoo umbrella task, and resuming existing sessions, grouped in Warp tab groups. Use when the user says "abrí una sesión nueva", "nueva pestaña con Claude para X", "una sesión por subtarea de la 78564", "abrí sesiones para estos PRs", "retomá la sesión de la 77768", "qué sesiones abrí hoy", "coordiná estas tareas".
---

# Warp orchestrator

This session is the coordinator. Keep it short and clean: the work happens in the tabs it opens.
Each tab runs its own agent session, named `<task id> <short name>`.

## Before anything

If this session is not the coordinator agent (you were not started with `--agent
warp-orchestrator`), say once that the user can exit and run `warp-orchestrator` in this same
terminal to get the coordinator, named `Orchestrator`, and go on here if the user prefers.

Run `~/.agents/skills/warp-orchestrator/bin/warp-check`. If it exits non-zero, stop and tell the
user the reason it printed. Do not open tabs another way. If it is not found, tell the user to run
`~/.agents/skills/warp-orchestrator/install.sh`.

## Route

| The user asks for | Read |
|---|---|
| A new session, one task or ticket, or one session per item of a list | `references/open.md` |
| One session per subtask of an umbrella task | `references/umbrella.md` |
| Reopen a session that already exists | `references/resume.md` |
| What was opened | `warp-opened` (below) |

## Tools

Only `warp-orchestrator` is in the `PATH`, so the user's shell does not fill up with tools. The
others live in `~/.agents/skills/warp-orchestrator/bin/`: always call them with that folder, for
example `~/.agents/skills/warp-orchestrator/bin/warp-tab ...`. They are written short below.
`--help` prints the full usage.

```bash
warp-check                                   # exit 0 inside Warp on Linux; shortcut=<state>
warp-shortcut [install [KEY]]                # the group shortcut: live, pending, missing, taken
warp-name 78420 "Skill encarar: borrador"    # → 78420 Skill encarar
warp-name --group 78564 "Dev Tips en la era IA"  # → 78564 Dev Tips
warp-groups                                  # groups open in Warp: name, color, tabs, last tab link
warp-tab -d <dir> "<name>::<prompt>"         # one tab
warp-tab -d <dir> -g "<group>" "<n1>::<p1>" "<n2>::<p2>"   # several: join the open group or make one
warp-tab --agent warp-orchestrator "Orchestrator::"   # a session started with a Claude agent
warp-tab -d <dir> -r <session-id>            # resume; repeat -r to resume several
warp-orchestrator [--tab]                    # the coordinator here, "Orchestrator"; --tab: new yellow tab
warp-tab -a codex ...                        # other runtime: claude (default), codex, gemini
warp-tab --dry-run ...                       # print the tab configs, open nothing
warp-sessions <number or words>              # find existing sessions
warp-opened [--days N] [--group TEXT] [--open]   # tabs opened by warp-tab, open or closed
```

## Rules for every tab

- **Name:** `<task id> <short description>` whenever there is a task (`78420 Skill encarar`).
  Pass the full Odoo name: `warp-tab` shortens names that start with a task id. Name it by the
  task even when the session is about a PR. Without a task, say what it does
  (`Check Railway logs`). An empty session has no name.
- **Folder (`-d`):** the repo the request names; otherwise the coordinator's folder. For Claude, a
  folder without `hasTrustDialogAccepted: true` in `~/.claude.json` stops at the trust prompt: use
  the coordinator's folder and name the repo and its path in the prompt.
- **Runtime (`-a`):** `claude` unless the user asks for another.
- **Group (`-g`):** always with two or more tabs, so the user finds them together; with one tab
  that belongs to a group already open; and whenever the user asks for a group, even of one tab.
  - **Name:** short, 1 to 3 words. With a parent task, its id first: `78504 Codemode`. Without
    one, what the tabs have in common: `PRs en revisión`. Write the short name yourself;
    `warp-name --group` only cuts it to fit.
  - **Open group:** run `warp-groups` first. If a group with that name or the same leading task
    id is open (the user may have made it by hand), pass its exact name: `warp-tab` brings its
    last tab to the front and the new tabs join it, with its color. No keys are pressed.
  - **New group:** always in the coordinator's window. Warp creates groups only from its UI, so
    `warp-tab` presses the Warp shortcut of "Create tab group from active or selected tab(s)" with
    `xdotool` and types the name in the rename box Warp opens. Before running it, tell the user
    not to type for about 10 seconds. Never search Warp's command palette instead: a slow filter
    can pick a file and the group name gets typed into it.
  - **The shortcut:** `warp-check` prints `shortcut=<state>` and, when it is `missing`, binds the
    default key (`ctrl-alt-shift-G`) if nothing else uses it. Say nothing about it unless you are
    about to create a new group and the state is not `live`:
    - `pending <key>`: Warp loads the file only at launch. Tell the user to set it once in Warp,
      Settings > Keyboard shortcuts, search "Create tab group", key `Ctrl+Alt+Shift+G`; or to
      restart Warp. Open the tabs anyway: they get the color, without the native group.
    - `taken <key> <action>`: ask, with options: 1) another key you propose, bound with
      `warp-shortcut install <key>` (check it is free first); 2) the user sets one in Settings;
      3) open the tabs this time without the native group.
    - `no-xdotool`: say that new groups need `xdotool` (X11) and open without the group.
  - **Without keys:** `GROUP_MODE=inherit` in `~/.config/warp-orchestrator/config` (or
    `--inherit`) never presses keys: the tabs get the color, land after the active tab and join its
    group, if it has one. Use it only when the user asks. The group is saved in the registry
    either way.
- **Group tabs that are already open:** no script can move or close a Warp tab. Ask the user to
  close them (the sessions stay on disk), check with `warp-opened` that their `live` column says
  `closed`, then reopen them all in one call, keeping their context:
  `warp-tab -g "<group>" -r <id1> -r <id2> "<n1>::" "<n2>::"`. Never reopen a session that is
  still `open`: two processes would write the same session.
- **Coordinator agent:** `agents/warp-orchestrator.md` is the coordinator's identity.
  `warp-orchestrator` runs it in the current terminal, named `ORCHESTRATOR_NAME`
  (`Orchestrator`) from the config; `--tab` opens it in a new tab instead, also colored
  `ORCHESTRATOR_COLOR` (`yellow`). `--agent` works with any Claude agent.
- **Colors:** an open group keeps its color, read from Warp. A new group takes a color that no
  open group or tab uses, never the coordinator's; `~/.local/state/warp-orchestrator/groups.json`
  remembers it, so a group closed and opened again gets the same color while it is free. A group
  made with the shortcut has no color of its own in Warp: its tabs carry it. Colors are red,
  green, yellow, blue, magenta and cyan. Pass `-c` only when the user asks for a color.
- **Quota:** with more than 6 tabs that carry a prompt, show the list and ask first. With fewer,
  show one line per tab and open. Opening tabs needs no permission.
- **Load:** the tabs open at once, but each agent starts `START_GAP` seconds (config, 4) after the
  previous one, because many agents starting together, each with its MCP servers, can stall the
  machine. Open them in one call, never in parallel calls.
- **Report:** copy what the last line of `warp-tab` says: tabs opened, the group and its state
  (`created`, `joined` or `NOT created`, read back from Warp), and the color. Never say a group was
  made unless that line says `created` or `joined`. If `warp-tab` failed, quote its message as is.

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
- Focus: Warp has no way to open a tab in the background. Each new tab takes the focus for about
  half a second and the Warp window comes to the front; at the end `warp-tab` goes back to where
  the user was: the tab that ran it (Warp's `WARP_FOCUS_URL`) or the other app's window. A key
  pressed meanwhile lands in a new tab. Pass `--focus` only when the user wants to stay on the
  new tab.
- Screen control: only the `keys` group mode sends keys (`xdotool`). Everything else uses Warp's
  own files and `warp://` links.
- `warp-tab` writes a temporary tab config in Warp's `tab_configs` folder and opens it with a
  `warp://tab_config/<name>` link; it deletes the file 15 seconds later. The tab runs a launcher
  script from `~/.local/state/warp-orchestrator/launch/` that deletes itself and execs the agent.
  If a tab does not open, run again with `--dry-run` to see both files.
- Warp types the launcher command into the new tab. A key pressed in that second can land at its
  end; the launcher ignores it, so the agent still starts with the right arguments.
