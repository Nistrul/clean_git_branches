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

## Sandbox Command Policy (Mandatory)

1. Always start commands with the actual executable token.
2. Do not prefix commands with inline environment-variable assignments.
3. Do not wrap commands in `sh -c` / `bash -lc` unless explicitly required.

Good:
- `git -c core.editor=true rebase --continue`

Bad:
- `GIT_EDITOR=true git rebase --continue`
- `VAR=1 cmd ...`
- `sh -c "<command>"`
- `bash -lc "<command>"`

## Feature Branch and Merge Strategy (Mandatory)

1. Create the feature branch before making any code or documentation changes for that slice.
2. Branch from `main` for each feature slice; do not combine unrelated features on one branch.
3. Align branch scope to one backlog slice under one feature (or a tightly coupled pair of slices).
4. Keep branches cohesive and small:
   - target 1-3 focused commits
   - target completion within 1-2 working days
   - if a branch grows beyond ~300 net lines changed or multiple unrelated filesets, split it
5. Branch naming must map to planning artifacts:
   - format: `feat/<initiative-id>/<feature-id>-<short-slug>`
   - example: `feat/INIT-2026-02-shell-script-testing/FEAT-001-delete-safety-gates`
6. Before merge, if the branch is out of date with `main`, rebase onto `main`, resolve conflicts, and rerun relevant tests.
7. Merge only when all are true:
   - linked backlog items are `done`
   - acceptance checks/tests pass locally
   - trackers are updated in the same change set
   - commit message(s) match delivered scope
8. Use squash merge into `main` for feature branches so main history stays cohesive and readable.
9. If scope expands mid-branch, stop and split remaining work into a new branch and backlog slice.
10. End each completed slice with a pull request (create a new PR or update an existing PR for that branch) before handoff.
11. After creating or updating a PR, sync the latest `main` into the feature branch (prefer rebase), resolve conflicts, rerun relevant tests, and push the updated branch before handoff.

## Pull Request Formatting Rules (Mandatory)

1. Use explicit markdown headings and bullets in PR descriptions (`## Summary`, `## Testing`).
2. Do not pass literal escaped newline sequences (`\n`) as PR body text.
3. When using `gh`, provide PR body with one of these safe patterns:
   - ANSI-C quoting: `--body $'line1\nline2\n'`
   - file input: `--body-file <path-to-markdown>`
4. After create/edit, verify rendered formatting with `gh pr view <number>` before handoff.
5. If formatting is wrong, immediately fix with `gh pr edit` and re-verify.

## Pull Request Decision Rules (Mandatory)

1. The agent decides when to create or update a pull request; do not ask for approval on routine PR timing.
2. After completing a slice, the default action is to create a new PR or update the existing PR for that branch before handoff.
3. If the agent defers PR creation, it must have a concrete cohesion or sequencing reason and continue until a PR-ready slice boundary is reached.
4. Keep PRs maximally cohesive: one feature slice (or tightly coupled slices) per PR, with aligned code, tests, and tracker updates.
5. Process changes and agent-instruction changes (for example, edits to `AGENTS.md`) must be delivered in a separate PR from feature implementation changes.

## Title Style Rules (Mandatory)

1. Write commit subjects and PR titles in imperative mood.
2. Use this test: prepend `This change will ...`; if the result reads naturally, the title is acceptable.
3. Avoid past tense, gerunds, and vague nouns in titles.
4. PR titles must comply with this rule.
5. Squash-merge commit titles must comply with this rule.

Good examples:
- `Add integration test for interactive DELETE confirmation`
- `Prevent force deletion of protected gone branches`

Bad examples:
- `Added integration test for interactive DELETE confirmation`
- `Interactive DELETE confirmation changes`

## Project Management Approach (Best Practice)

Use a three-layer tracking model with clear separation of concerns:

1. Initiative Plan: scope, goals, non-goals, and strategy.
2. Initiative Tracker: milestone-level progress and next actions.
3. Backlog + Backlog Tracker: scenario/task status plus execution log.

Current project-management files:

1. `docs/project-management/index.md`
2. `docs/project-management/strategy.md`
3. `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/initiative.md`
4. `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/tracker.md`
5. `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/backlog.md`
6. `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/backlog-tracker.md`

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
