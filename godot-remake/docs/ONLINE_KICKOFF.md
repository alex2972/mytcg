# Kickoff prompt for the autonomous online run

Paste this as the first message (model: Opus, extra effort):

---
You are running unattended for many hours; nobody will answer questions. Read `Z:\process\godot-remake\docs\ONLINE_PLAN.md` completely, then execute it phase by phase (phases 1 to 9) until its Definition of Done (section 11) is met.

Rules that matter most: never ask the user anything (decide, write the decision in `docs/ONLINE_DECISIONS.md`, continue); never block (stub with a `TODO(online)`, list it in `docs/ONLINE_STATUS.md`, move on); keep offline play working and all existing tests green after every phase; never touch the user's real save data under `%APPDATA%\Godot\app_userdata\Godot remake\`; first commit the current tree to a new git branch `online`, then commit per phase there; do not push or merge. Use `timeout 90` on every test run, run long jobs in the background, and edit files with small Python scripts or the Write tool (see the tooling gotchas in section 0).

Start by reading `C:\Users\Usuario\.claude\projects\Z--process\memory\joey-godot-rebuild.md`, `docs/SHOP.md`, `docs/DUEL_FLOW.md` and `docs/EFFECTS.md` for context, then begin Phase 1. When everything is done, write the final report to `docs/ONLINE_STATUS.md` and stop.
---
