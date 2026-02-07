# AGENTS.md

## Purpose

This file defines repository-level operating rules for coding agents and contributors.

## Git Workflow Rules (Mandatory)

1. Run Git staging and commit steps sequentially.
2. Never run `git add` and `git commit` in parallel tool calls or parallel shell segments.
3. Before committing, confirm intended files with `git status --short`.
4. Stage explicitly (path-based), then commit in a separate command.
5. If `.git/index.lock` exists, stop, resolve lock state safely, then continue sequentially.

Recommended commit sequence:

```bash
git status --short
git add <explicit-file-paths>
git status --short
git commit -m "<clear message>"
```

## Project Management Approach (Best Practice)

Use a three-layer tracking model with clear separation of concerns:

1. Initiative Plan: scope, goals, non-goals, and strategy.
2. Initiative Tracker: milestone-level progress and next actions.
3. Backlog + Backlog Tracker: scenario/task status plus execution log.

Current project-management files:

1. `docs/project-management/initiative-shell-script-testing.md`
2. `docs/project-management/initiative-shell-script-testing-tracker.md`
3. `docs/project-management/integration-test-backlog.md`
4. `docs/project-management/integration-test-backlog-tracker.md`

## Tracking Hygiene Rules (Mandatory)

1. Keep trackers up to date in the same change set as the implementation work.
2. Update backlog status (`todo|in_progress|done|blocked`) when scenario state changes.
3. Record execution slices and deferrals in the backlog tracker.
4. Keep initiative tracker high-level; keep scenario-level detail in backlog artifacts.
5. Keep cross-links between related planning/tracking files accurate.
6. Do not close a task as done unless tests and acceptance checks are complete.

## Definition of Done for Work Items

1. Code change is implemented.
2. Relevant tests are added/updated and pass locally.
3. Tracking docs are updated to reflect real status.
4. Commit message reflects the actual scope.
