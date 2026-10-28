#!/usr/bin/env bash
# Link the scripts into ~/.local/bin, the skill and the agent into the user folders, register the
# Claude Code hooks and the Warp shortcut for tab groups. Safe to run again.
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
bin_dir="$HOME/.local/bin"
agents_dir="$HOME/.agents/skills"
claude_dir="$HOME/.claude/skills"

mkdir -p "$bin_dir" "$agents_dir" "$claude_dir"
chmod +x "$root"/bin/* "$root"/hooks/*

for f in "$root"/bin/*; do
  ln -sfn "$f" "$bin_dir/$(basename "$f")"
done

# Only the entry skill is registered; references/ are read by it, so they stay out of the / menu.
ln -sfn "$agents_dir/warp-orchestrator" "$claude_dir/warp-orchestrator"

# The group mode "keys" presses Warp's shortcut for this action. Add one unless the user has it.
# Warp reads keybindings.yaml only at launch: until a restart, set the same key in
# Settings > Keyboard shortcuts.
keybindings="${XDG_CONFIG_HOME:-$HOME/.config}/warp-terminal/keybindings.yaml"
action='"workspace:new_tab_group_from_active_or_selected_tabs"'
if ! grep -qs "$action" "$keybindings"; then
  mkdir -p "$(dirname "$keybindings")"
  echo "$action: ctrl-alt-shift-G" >> "$keybindings"
  # warp-tab compares this with Warp's start time to know whether Warp has loaded the shortcut.
  state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/warp-orchestrator"
  mkdir -p "$state_dir"
  stat -c %Y "$keybindings" > "$state_dir/keybindings.mark"
  echo "warp shortcut: ctrl-alt-shift-G for 'Create tab group from active or selected tab(s)'; restart Warp or set it in Settings > Keyboard shortcuts"
fi

mkdir -p "$HOME/.claude/agents"
for f in "$root"/agents/*.md; do
  ln -sfn "$f" "$HOME/.claude/agents/$(basename "$f")"
done

python3 -I - "$HOME/.claude/settings.json" "$root/hooks" <<'PY'
import json, os, sys
path, hooks_dir = sys.argv[1:]
cfg = json.load(open(path)) if os.path.exists(path) else {}
wanted = [
    ("SessionStart", ".*", "session-start", "warp-orchestrator:session-start"),
    ("Stop", ".*", "agent-event done", "warp-orchestrator:done"),
    ("Notification", "permission_prompt|idle_prompt", "agent-event attention", "warp-orchestrator:attention"),
]
changed = False
for event, matcher, script, name in wanted:
    entries = cfg.setdefault("hooks", {}).setdefault(event, [])
    if any(h.get("name") == name for e in entries for h in e.get("hooks", [])):
        continue
    script_path, *args = script.split()
    command = " ".join([f'bash "{os.path.join(hooks_dir, script_path)}"', *args])
    entries.append({"matcher": matcher, "hooks": [{"type": "command", "command": command, "name": name}]})
    changed = True
    print(f"claude hook: registered {name}")
if changed:
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
else:
    print("claude hooks: already registered")
PY

case ":$PATH:" in *":$bin_dir:"*) ;; *) echo "warning: $bin_dir is not in PATH" ;; esac
echo "installed from $root"
