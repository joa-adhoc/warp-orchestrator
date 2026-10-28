# One session per subtask

Follow the rules in `SKILL.md` (name, folder, runtime, group, quota). Run `warp-check`
first; if it fails, stop and say why.

## Steps

1. **Read the umbrella** with the Odoo MCP (`tuqui-adhoc`), loading first the task skill its
   catalogue names:
   - The umbrella: `project.task`, `id = <umbrella>`, fields `id, name`.
   - Its subtasks: `project.task`, `parent_id = <umbrella>`, fields `id, name, state`. Leave out
     the closed ones: `state` in `1_done` or `1_canceled`.
2. **Group name:** `warp-name --group <umbrella id> "<umbrella name>"`.
3. **One tab per open subtask**, named `<id> <Odoo name>`, with this prompt unless the user gave
   another:

   ```text
   Task https://www.adhoc.inc/odoo/project.task/<id> (<short name>), subtask of umbrella <umbrella id>. Read the task, its chatter, the related PRs and what other sessions already solved. Answer in 5 lines: where it stands, what is missing and what I have to decide. Do not change code or write to Odoo until I ask.
   ```

4. **Quota:** more than 6 subtasks → show the list and ask which to open.
5. **Open** in one call:

   ```bash
   warp-tab -d <dir> -g "UM <id> · <short name>" "<id1> <name1>::<prompt1>" "<id2> <name2>::<prompt2>"
   ```

6. **Report** how many tabs opened, the group and its color. Say which subtasks were left out
   because they are closed.
