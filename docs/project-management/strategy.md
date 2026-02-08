# Project Management Strategy and Process

## 1. Purpose

Define a lightweight, scalable planning and tracking system for human + agent collaboration that stays clear as work grows.

## 2. Work Hierarchy and Naming

Use a three-level hierarchy:

1. Initiative: outcome-level effort that may contain multiple deliverables.
2. Feature: a shippable capability within an initiative.
3. Task/Scenario: a concrete implementation or verification item.

Naming rules:

1. Use "initiative" for top-level planning artifacts.
2. Use "feature" for grouped deliverables inside an initiative backlog.
3. Use "task" or "scenario" for executable items (tests, scripts, docs, refactors).

## 3. File Structure Standard

### Current standard (simple and valid)

Each active initiative should have:

1. Initiative plan file (scope, goals, non-goals, milestones).
2. Initiative tracker (high-level progress and next actions).
3. Backlog file (feature/task list with status).
4. Backlog tracker (execution log and handoffs).

### Scaling standard (preferred as initiative count grows)

Use one folder per initiative and a central index:

```text
docs/project-management/
  index.md
  strategy.md
  initiatives/
    INIT-YYYY-MM-short-name/
      initiative.md
      backlog.md
      tracker.md (optional)
      backlog-tracker.md (optional)
  archive/
    YYYY/
      INIT-.../
```

Adopt these split thresholds:

1. Default to two files per initiative: `initiative.md` + `backlog.md`.
2. Add `tracker.md` when milestone history becomes noisy.
3. Add `backlog-tracker.md` when execution logs exceed one screen of active context or multiple contributors are logging slices.

## 4. Source of Truth Rules

1. `index.md` is the portfolio view for all active initiatives.
2. Initiative plan defines intent; backlog defines executable scope.
3. Backlog status field is canonical for item state (`todo|in_progress|done|blocked`).
4. Tracker files capture chronology, decisions, and deferrals.

## 5. Operating Workflow (Human + Agent)

1. Select initiative and identify the next smallest shippable slice.
2. Move selected backlog items to `in_progress`.
3. Implement code/tests/docs for that slice.
4. Run relevant verification commands.
5. Update backlog and tracker in the same change set as implementation.
6. Mark item `done` only after acceptance checks pass.
7. Update initiative tracker with milestone-level status and next actions.

## 6. Status and Acceptance

Statuses:

1. `todo`: not started.
2. `in_progress`: active work.
3. `blocked`: cannot proceed due to dependency/risk.
4. `done`: implemented and verified.

Definition of done for any item:

1. Implementation complete.
2. Relevant tests added/updated and passing locally.
3. Planning/tracking documents updated to reflect reality.
4. Commit message accurately reflects completed scope.

## 7. Cadence and Hygiene

1. Update trackers during execution, not at the end of a long batch.
2. Keep initiative trackers high-level; keep scenario detail in backlog artifacts.
3. Keep cross-links between initiative, backlog, and trackers current.
4. Archive completed initiatives to `archive/YYYY/` to keep active views small.

## 8. Practical Guidance on File Count

1. Avoid one giant file for all work; it becomes hard to navigate and merge.
2. Avoid creating too many files too early; start with two files per initiative.
3. Introduce extra tracker files only when complexity demands it.
4. Keep active initiative folders focused; archive aggressively once closed.
