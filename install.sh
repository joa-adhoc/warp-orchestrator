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

# warp-tab presses Warp's shortcut to make a tab group. Bind the default key unless it is taken.
shortcut="$("$root/bin/warp-shortcut")"
[ "$shortcut" != missing ] || shortcut="$("$root/bin/warp-shortcut" install || true)"
case "$shortcut" in
  live*) ;;
  pending*) echo "warp shortcut: ${shortcut#pending }; Warp loads it after a restart, or set it now in Settings > Keyboard shortcuts > 'Create tab group from active or selected tab(s)'" ;;
  *) echo "warp shortcut: $shortcut; set one in Settings > Keyboard shortcuts > 'Create tab group from active or selected tab(s)'" ;;
esac

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
