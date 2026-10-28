---
name: warp-resume
description: Linux + Warp only; part of warp-orchestrator. Finds an existing Claude Code or Codex session by task number or words and reopens it in a new Warp tab, compacting it when it is large. Use when the user says "abrí la sesión de la 77768", "retomá la sesión de lo de mails", "volvé a la sesión donde vimos X".
---

# Resume a session

Follow the rules in `warp-orchestrator`. Run `warp-check` first; if it fails, stop and say why.

## Steps

1. **Search:** `warp-sessions <number or words>`. Each line is:
   `last_used  runtime  session_id  context_tokens  match  title  cwd`.
2. **Pick:**
   - Take the first line if `match` is `title` or `first`.
   - If there are only `prompt` matches, or two similar candidates, show the first 3 and ask.
   - No lines: say so and offer `warp-open` for a new session.
3. **Name:** the task number and its Odoo name, even when the old title already has the number.
   Without a task, keep the session's title.
4. **Compact:** if `context_tokens` is above 250000, send `/compact` as the prompt. An empty
   session already takes about 100000, so compacting a long one saves quota on every later
   message; a smaller one loses detail for nothing. If the user says to compact or not, do that.
5. **Open** with the session's `cwd` as `-d` (`claude --resume` looks for the session from there)
   and its runtime as `-a`:

   ```bash
   warp-tab -a <runtime> -d <cwd> -r <session_id> "<id> <Odoo name>::/compact"
   warp-tab -a <runtime> -d <cwd> -r <session_id> "<id> <Odoo name>::"
   ```

6. **Report** which session opened and how many context tokens it had.

Gemini sessions cannot be resumed: Gemini resumes by per-project index, not by id.
