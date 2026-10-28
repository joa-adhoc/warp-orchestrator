# Open sessions in Warp

Follow the rules in `SKILL.md` (name, folder, runtime, group, quota). Run `warp-check`
first; if it fails, stop and say why.

## Steps

1. **Build the list of tabs:**
   - **An empty session:** `warp-tab` with no spec.
   - **A task or a ticket:** read its `name` with the Odoo MCP (`tuqui-adhoc`). One tab, named
     `<id> <Odoo name>`, with the task prompt below.
   - **A list:** one tab per item. If an item belongs to a task, name it by the task.
2. **Prompt:** if the user says what to do, use that. For a task with no instruction, use:

   ```text
   Task https://www.adhoc.inc/odoo/project.task/<id> (<short name>). Read the task, its chatter, the related PRs and what other sessions already solved. Answer in 5 lines: where it stands, what is missing and what I have to decide. Do not change code or write to Odoo until I ask.
   ```

   For a helpdesk ticket, use `helpdesk.ticket` in the link.
3. **Open:**

   ```bash
   warp-tab -d <dir> "<id> <Odoo name>::<prompt>"
   warp-tab -d <dir> -g "<group>" "<n1>::<p1>" "<n2>::<p2>"
   ```

   The group name says what is inside: `PRs in review`, `Rielec tickets`.
4. **Report** how many tabs opened and the group.
