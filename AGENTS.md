# AGENTS.md

## Purpose

This file defines repository-level operating rules for coding agents and contributors.

## Prompt Intake Workflow (Mandatory)

1. On every new user request, run a pre-flight workflow before making any non-read command:
   - classify request type (`implement`, `review`, `research`, `docs/process`)
   - run `git status --short --branch`
   - confirm current branch is correct for the requested slice
   - expected baseline: starting a new slice from the previous feature branch is normal; treat switching to `main`, updating, and branching as routine alignment
2. If branch/scope is wrong, stop and fix workflow first:
   - stash or commit in-progress unrelated work
   - switch to `main`, fast-forward, create a correctly scoped feature branch
   - only then start file edits
3. Fail closed on workflow checks:
   - do not start implementation while branch alignment is unresolved
   - do not continue on a branch that mixes unrelated slices
4. Before handoff, run an execution-close checklist:
   - ensure tracking docs reflect the delivered or deferred scope
   - apply PR creation/update and post-PR sync rules defined below (see Feature Branch and Pull Request sections)
5. After creating or updating a PR, include a post-PR progress report in handoff by default:
   - initiative completion percentage
   - features complete vs remaining
   - active initiative count and next initiative (or clearly state none is defined)
   - concise prioritization summary: what slice is next and why it is prioritized over other currently available tasks
6. When creating or modifying agent workflow/process rules, consult:
   - `docs/project-management/agent-prompting-research.md`
   - update that document in the same slice if prompting guidance changes

## Git Workflow Rules (Mandatory)

1. Run Git staging and commit steps sequentially.
2. Never run `git add` and `git commit` in parallel tool calls or parallel shell segments.
3. Before committing, confirm intended files with `git status --short`.
4. Stage explicitly (path-based), then commit in a separate command.
5. Run all Git commands sequentially; do not execute multiple Git commands in parallel tool calls or parallel shell segments.
6. If a Git command fails with `.git/index.lock` present (or lock-related error), assume another Git process is active and re-run the same command after a short wait.
7. Do not assume a lock is stale by default. Only treat it as stale after confirming no active Git process is running.
8. Never delete `.git/index.lock` preemptively; remove it only when explicitly confirmed stale.

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
11. After creating or updating a PR, sync the latest `main` into the feature branch (prefer rebase), resolve conflicts, and push the updated branch before handoff.
12. During post-PR sync rebase, rerun relevant tests only when either condition is true:
   - the rebase changed branch content
   - relevant tests have not yet been run on the current post-rebase HEAD
   If the rebase is a no-op and relevant tests already passed on the same HEAD, do not rerun tests.

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
5. Process and agent-instruction changes (for example, edits to `AGENTS.md`) must be delivered separately from functional feature implementation changes; however, cohesive process-slice updates (agent rules + supporting project-management docs/trackers) may be delivered together in one PR.
6. Documentation-only, tracker-only, and other non-code slices still require creating or updating a PR as the final step before handoff; do not skip PR creation because a change is "docs only."

## Visual Validation Demo Workflow (Mandatory)

1. For PRs that include a functional behavior change, demonstrate that behavior with exactly one deterministic local demo.
2. For documentation/process/tracker-only PRs with no functional behavior change, skip before/after demo capture unless explicitly requested.
3. For functional-change PRs in this repository, demos must execute `clean_git_branches.sh` directly so captured output reflects real CLI behavior.
4. Test-suite signaling demos (for example test counts or test-file diffs) are not valid as visual-validation evidence unless the requested slice itself is test-only behavior.
5. Select or create the demo before implementation starts so pre-change capture is always possible.
6. Prefer reusing an existing script under `demos/`; create a new demo only when no existing demo directly shows the behavior change.
7. Set `DEMO_ID` to the selected script basename (without `.sh`) before capture commands.
8. Demos must:
   - live at `demos/<demo-id>.sh`
   - create their own temporary Git repositories/fixtures
   - never modify the caller repository
   - print clearly labeled sections with normal ANSI-colored console output
   - exit non-zero on failure
   - run quickly (target under 10 seconds)
9. Keep a demo catalog in `demos/README.md` and update it when adding/changing demos.
10. Capture before output before implementation:
   - create artifacts directory: `mkdir -p pr-artifacts`
   - run selected demo (raw capture): `script -q pr-artifacts/before.raw.ansi ./demos/${DEMO_ID}.sh`
   - sanitize capture: `python3 demos/sanitize-ansi.py pr-artifacts/before.raw.ansi pr-artifacts/before.ansi`
   - generate plain text: `sed -E 's/\x1b\[[0-9;]*m//g' pr-artifacts/before.ansi > pr-artifacts/before.txt`
11. After implementation, run the same demo for after output:
   - `script -q pr-artifacts/after.raw.ansi ./demos/${DEMO_ID}.sh`
   - `python3 demos/sanitize-ansi.py pr-artifacts/after.raw.ansi pr-artifacts/after.ansi`
   - `sed -E 's/\x1b\[[0-9;]*m//g' pr-artifacts/after.ansi > pr-artifacts/after.txt`
12. Validate local behavior delta:
   - `diff -u pr-artifacts/before.txt pr-artifacts/after.txt > pr-artifacts/before-after.diff || true`
   - treat empty diffs (when change should be visible) or unexpected diffs as failures
13. `pr-artifacts/` must be gitignored; never commit artifacts, logs, or screenshots.
14. Publish artifacts in the PR:
   - upload raw `.ansi` and diff files (for download/view with `less -R`)
   - post or update one `Visual Validation` PR comment with plain-text before/after output in collapsible `<details>` blocks
   - keep only one active `Visual Validation` comment per PR
15. Use local-only execution for this workflow; do not depend on CI for visual validation capture.

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

1. `docs/project-management/index.md` (source of truth for planning/tracking file locations)
2. `docs/project-management/agent-prompting-research.md` (mandatory reference when adjusting workflow/process rules)

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
