# Rune Cast development workflow

Each `RC-###` task is a separate chat with a recorded starting point and handoff. Use [the current project plan](project-plan.md) as the task list and [verification](verification.md) for actual evidence.

## Start a task

1. Read applicable `AGENTS.md` instructions, the current task entry, prerequisite handoffs, and relevant design/setup documents. Check prerequisites against the repository rather than assuming an earlier chat finished them.
2. Inspect `git status --short --branch`, `git log -5 --oneline`, staged and unstaged diffs, and untracked files. Record the starting revision; if there is no commit, record that explicitly. Preserve unrelated work.
3. Keep the existing baseline branch (`master` for RC-001). When a new task needs a branch, use a descriptive `codex/` name, for example `git switch -c codex/rc-003-combat-presentation`. Do not switch branches under another active chat or carry unrelated changes without reviewing them.
4. Identify the task's files, deliverables, exclusions, and acceptance checks from its request before editing. A new chat does not create an isolated checkout.

## Coordinate separate chats

Run state, core, UI, and shared-data edits sequentially in a shared checkout. Read-only reviews can happen alongside implementation. When parallel asset work is explicitly requested, assign each task a distinct asset folder and delivery note; update shared manifests and integrate the assets sequentially afterward. Avoid concurrent engine imports, captures, or staging in the same checkout.

Preserve gameplay and approved artwork outside the task's scope. The October 8, 2026 [Home, Combat, Map, and Menu references](visual-reference.md) take precedence over older mockups. Preserve their originals and generation history.

## Verify and checkpoint

Review the changed files and run checks relevant to the task. The complete desktop baseline sequence is:

```powershell
.\tools\godot.ps1 -Action version
.\tools\godot.ps1 -Action import
.\tools\godot.ps1 -Action test
.\tools\godot.ps1 -Action smoke
.\tools\godot.ps1 -Action capture
```

Run each command separately and inspect its exit code and output. Visually inspect the fresh `output/qa/foundation-screen.png`; check its modification time because an unchanged image hash can still be a new capture. Record actual counts, failures, engine version, and date. A zero exit code does not excuse errors in the output. Distinguish environment/permission failures, Android export warnings, and desktop defects. Follow [setup](setup.md) for the pinned engine; do not silently upgrade it or install mobile prerequisites for a desktop task.

The reviewed baseline and RC-003 comparison PNGs in `output/qa/` are intentional checkpoint evidence. Other QA output, logs, caches, downloaded tools, builds, and signing credentials are ignored. Keep source, scenes, data, `.gd.uid` companions, asset import settings, runtime assets, reference images, and generation prompts. Inspect large or unexpected files before staging.

1. Update the task status and handoff with files/artifacts, decisions, actual validation, blockers, and next-ready task IDs. Append dated verification results; preserve earlier records and any capture needed to support them.
2. Stage reviewed task paths, then inspect `git diff --cached --stat`, `git diff --cached --name-status`, `git diff --cached`, and `git diff --cached --check`. Do not include unrelated work by accident.
3. Use the configured Git identity and make a clear local checkpoint when authorized. If identity is missing, ask the owner; never invent it or change global configuration. Record partial status if the checkpoint cannot be made.
4. Verify the commit with `git log -1 --format=fuller` and verify the remaining changes with `git status --short --branch` and `git diff`. Report the actual commit hash in the handoff to the user. Within the commit's own documentation, use its subject as the checkpoint reference rather than its own hash.

Do not check off a task until its required checks, documentation, and checkpoint exist. Never discard unrelated files with destructive reset/clean operations. Remotes, pushes, pull requests, and CI require their own requested scope.
