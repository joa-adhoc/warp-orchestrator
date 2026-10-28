# Resume a session

Follow the rules in `SKILL.md`. Run `warp-check` first; if it fails, stop and say why.

## Steps

1. **Search:** `warp-sessions <number or words>`. Each line is:
   `last_used  runtime  session_id  context_tokens  match  title  cwd`.
2. **Pick:**
   - Take the first line if `match` is `title` or `first`.
   - If there are only `prompt` matches, or two similar candidates, show the first 3 and ask.
   - No lines: say so and offer a new session (`references/open.md`).
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

   Several sessions from the same folder go in one call, in a group: one `-r` per spec, in order.

   ```bash
   warp-tab -d <cwd> -g "<group>" -r <id1> -r <id2> "<n1>::" "<n2>::"
   ```

   Never resume a session whose tab is still open: ask the user to close it first.

6. **Report** which session opened and how many context tokens it had.

Gemini sessions cannot be resumed: Gemini resumes by per-project index, not by id.
