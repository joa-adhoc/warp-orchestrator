#!/usr/bin/env bash
# Link the scripts into ~/.local/bin, the skills into the user skill folders, and register the
# Claude Code SessionStart hook. Safe to run again.
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

for d in "$root"/skills/*/; do
  name="$(basename "$d")"
  ln -sfn "${d%/}" "$agents_dir/$name"
done
for name in warp-orchestrator $(ls "$root/skills"); do
  ln -sfn "$agents_dir/$name" "$claude_dir/$name"
done

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
