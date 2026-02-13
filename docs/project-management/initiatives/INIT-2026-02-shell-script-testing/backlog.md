# Integration Test Backlog: `clean_git_branches.sh`

- Initiative ID: `INIT-2026-02-shell-script-testing`
- Status: Active
- Tracker: `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/backlog-tracker.md`

## Prioritization Model

- `P0`: High regression risk or destructive behavior.
- `P1`: Important correctness and edge handling.
- `P2`: Hardening and rare-path behavior.
- Effort scale: `S` (small), `M` (medium), `L` (large).
- Status: `todo`, `in_progress`, `done`, `blocked`.

## Definition Of Done

1. Scenario is implemented in Bats integration tests.
2. Exit status and key output/side effects are asserted.
3. Test is deterministic and isolated (`mktemp`, local bare remote where needed).
4. Test passes in `test/run-tests.sh`.

## Feature Catalog

| Feature ID | Feature | Outcome |
|---|---|---|
| FEAT-001 | Deletion workflows and safety gates | Ensure merged/gone cleanup behavior is correct and safe in interactive and non-interactive modes. |
| FEAT-002 | Configuration parsing and precedence | Ensure repo config and CLI flags resolve predictably and safely. |
| FEAT-003 | Branch classification and protection rules | Ensure tracked/untracked/gone/protected behavior is classified and enforced correctly. |
| FEAT-004 | CLI contract and diagnostics | Ensure flag behavior, help output, and diagnostics are stable and testable. |
| FEAT-005 | Hardening and edge-path reliability | Ensure rare and failure-path behavior stays deterministic and safe. |
| FEAT-006 | PR handoff and visual validation reporting | Ensure handoff includes progress metrics and each PR includes deterministic local visual validation artifacts. |
| FEAT-007 | Integration test suite coverage and maintainability | Keep integration tests logically ordered and validate coverage completeness before closing integration-test hardening. |
| FEAT-008 | Test automation entrypoint | Ensure CI executes the existing deterministic test runner on pull requests and mainline updates. |
| FEAT-009 | Dry-run branch divergence diagnostics | Ensure dry-run output explains why non-merged branches differ and verifies classification parity across configured equivalence strategies. |
| FEAT-010 | Commit-ancestry branch-state reporting | Ensure classification can explain additional branch states using commit ancestry without changing deletion or cleanup behavior. |
| FEAT-011 | Git extension rename | Ensure the tool is renamed to `git-branch-tidy` and can be invoked as `git branch-tidy` while preserving existing behavior contracts. |
| FEAT-012 | Explicit target-directed cleanup UX | Ensure users can explicitly choose cleanup target refs (for example `main` or `develop`) while keeping reason-first diagnostics for all non-deleted branches. |

## Backlog

| ID | Feature | Scenario | Priority | Effort | Status |
|---|---|---|---|---|---|
| INT-001 | FEAT-001 | Delete merged unprotected branch in real repo | P0 | S | done |
| INT-002 | FEAT-001 | Force-delete remote-gone branch with local bare `origin.git` | P0 | S | done |
| INT-003 | FEAT-001 | `--dry-run --force-delete-gone` previews but does not delete | P0 | S | done |
| INT-004 | FEAT-001 | `--no-force-delete-gone` reports gone branches only | P0 | S | done |
| INT-005 | FEAT-001 | Non-interactive force-delete without `--silent` returns confirmation error | P0 | S | done |
| INT-006 | FEAT-001 | Interactive confirm accepts `DELETE` and deletes gone branches | P0 | M | done |
| INT-007 | FEAT-001 | Interactive confirm with empty input skips deletion | P0 | M | done |
| INT-008 | FEAT-001 | Protected branch in gone state is never force-deleted | P0 | M | done |
| INT-009 | FEAT-001 | Mixed gone set where one delete fails and one succeeds | P0 | M | done |
| INT-010 | FEAT-004 | Unknown CLI flag exits non-zero and prints help | P0 | S | done |
| INT-011 | FEAT-002 | `.clean_git_branches.conf` true enables deletion in auto mode | P0 | M | done |
| INT-012 | FEAT-002 | CLI `--no-force-delete-gone` overrides config true | P0 | S | done |
| INT-013 | FEAT-002 | CLI `--force-delete-gone` overrides config false | P0 | S | done |
| INT-014 | FEAT-003 | Default protected branches (`main|master|prod|dev`) are preserved | P1 | S | done |
| INT-015 | FEAT-003 | Custom `PROTECTED_BRANCHES` prevents deletion of custom protected names | P1 | S | done |
| INT-016 | FEAT-003 | Mixed tracked/untracked/gone/protected branches are classified correctly | P1 | M | done |
| INT-017 | FEAT-003 | No merged branches yields no merged-deletion section noise | P1 | S | done |
| INT-018 | FEAT-003 | Branch names with slashes (`feature/a/b`) behave correctly | P1 | S | done |
| INT-019 | FEAT-003 | Branch names with dots/dashes/underscores behave correctly | P1 | S | done |
| INT-020 | FEAT-003 | Current branch with no upstream continues gracefully | P1 | S | done |
| INT-021 | FEAT-003 | Detached HEAD does not crash and still reports branch sections safely | P1 | M | done |
| INT-022 | FEAT-003 | Run from subdirectory within repo; behavior remains correct | P1 | S | done |
| INT-023 | FEAT-002 | Config parse tolerates whitespace/case (`TRUE`, ` yes `) | P1 | S | done |
| INT-024 | FEAT-002 | Malformed config falls back to safe default behavior | P1 | S | done |
| INT-025 | FEAT-004 | `--help` includes all supported flags and exits zero | P1 | S | done |
| INT-026 | FEAT-004 | `--verbose` emits expected diagnostic lines to stderr | P1 | S | done |
| INT-027 | FEAT-001 | `--silent` warning appears only for destructive force-delete mode | P1 | S | done |
| INT-028 | FEAT-003 | Worktree dirty state does not break classification/deletion flow | P1 | M | done |
| INT-029 | FEAT-005 | Large branch set executes reliably (stress sanity) | P2 | M | done |
| INT-030 | FEAT-005 | Branch names with spaces are handled or explicitly documented unsupported | P2 | L | done |
| INT-031 | FEAT-005 | Unicode branch names are handled or documented unsupported | P2 | M | done |
| INT-032 | FEAT-005 | `git rev-parse --show-toplevel` failure fallback path stays safe | P2 | M | done |
| INT-033 | FEAT-005 | `git branch -vv` failure path exits predictably | P2 | M | done |
| INT-034 | FEAT-005 | Remote fetch/prune timing edge still leaves deterministic assertions | P2 | M | done |
| INT-035 | FEAT-003 | Section headers only render when corresponding section has content | P2 | S | done |
| INT-036 | FEAT-004 | Replace `--diagnose` with `--verbose` and present richer formatted diagnostics | P2 | M | done |
| INT-037 | FEAT-006 | After PR creation, report initiative completeness %, completed vs remaining features, total initiatives, and next initiative before handoff | P1 | S | done |
| INT-038 | FEAT-005 | Add intent comments for non-obvious advanced integration tests to document failure modes | P2 | S | done |
| INT-039 | FEAT-007 | Reorder integration tests so related scenarios are grouped and the file has a logical progression | P2 | S | done |
| INT-040 | FEAT-007 | Validate integration-test coverage map and capture/add missing high-risk scenarios before closing FEAT-007 | P1 | M | done |
| INT-041 | FEAT-001 | Non-interactive `--dry-run --force-delete-gone` without `--silent` has deterministic confirmation/preview behavior and explicit output contract | P1 | S | done |
| INT-042 | FEAT-007 | Consolidate overlapping subdirectory integration scenarios into one broader context-coverage test to reduce runtime and maintenance overhead | P2 | S | done |
| INT-043 | FEAT-007 | Consolidate overlapping dirty-worktree integration scenarios into one broader cleanup-plus-reporting test to reduce runtime and maintenance overhead | P2 | S | done |
| INT-044 | FEAT-007 | Move integration assertions that are equally effective in mocked tests to `test/clean_git_branches.bats` and keep only stateful/destructive checks in integration suite | P1 | M | done |
| INT-045 | FEAT-007 | Add persistent mocked/integration/full-suite timing metrics to `test/run-tests.sh` and capture before-vs-after runtime comparison for `INT-044` | P2 | S | done |
| INT-046 | FEAT-003 | Investigate diverged branches whose commits are already integrated in `main` (patch-equivalent), define safe classification/deletion policy, and add explicit opt-in deletion control via test-first scenarios | P1 | M | done |
| INT-047 | FEAT-004 | Define CLI output color system plan (roles/tokens, semantic meanings, contrast/accessibility constraints, TTY/no-color behavior) using UI/UX review guidance and document deferred visual critique checkpoint | P1 | M | done |
| INT-048 | FEAT-004 | Plan and prototype-safe design for a render module so all output sections flow through consistent rendering APIs, preserving current indentation/layout while removing layout concerns from business logic | P1 | M | done |
| INT-049 | FEAT-005 | Add `.DS_Store` hygiene slice: verify no tracked `.DS_Store` files, add ignore coverage, and document policy so temporary OS files are not committed | P1 | S | done |
| INT-050 | FEAT-006 | In post-PR sync workflow, skip rerunning tests when rebase is a no-op and relevant tests already passed on the current HEAD | P1 | S | done |
| INT-051 | FEAT-004 | Simplify CLI to minimal safe model (`--apply` gated execution, merged/equivalent/non-equivalent classification, equivalent opt-in + force fallback, remove legacy flags, deterministic grouped output) | P0 | M | done |
| INT-052 | FEAT-006 | Add mandatory local visual-validation demo workflow (single deterministic demo, before/after capture, local diff gate, PR artifact/comment contract) | P1 | M | done |
| INT-053 | FEAT-006 | Clarify visual-validation scope so before/after demo capture is required only for functional behavior changes and must show direct CLI runtime output | P1 | S | done |
| INT-054 | FEAT-008 | Add GitHub Actions CI workflow that installs bats and runs `test/run-tests.sh` on pull requests and pushes to `main` | P1 | S | done |
| INT-055 | FEAT-008 | Suppress Git default-branch advice warnings in CI logs by setting deterministic global Git defaults in workflow setup | P2 | S | done |
| INT-056 | FEAT-009 | Expand dry-run reporting for non-merged branches with commit-level divergence evidence (for example unique commit subjects/counts) and verify parity under each equivalence strategy mode | P1 | M | done |
| INT-057 | FEAT-010 | ~~Add explicit safe-delete diagnostics that reflect whether Git `branch -d` would succeed for each candidate and validate classification alignment with actual `-d` behavior in tests~~ Add classification-only ancestry reporting for `merged-into-upstream` and `merged-into-head`, including upstream/HEAD names in output, with no deletion or cleanup behavior changes | P1 | M | done |
| INT-058 | FEAT-011 | Rename CLI to `git-branch-tidy`, add compatibility entrypoint for `git branch-tidy`, and update docs/tests/tooling references | P1 | S | todo |
| INT-059 | FEAT-006 | Normalize visual-validation ANSI captures before text derivation so PTY control-sequence artifacts (for example `^D\\b\\b`) do not pollute PR artifacts | P1 | S | done |
| INT-060 | FEAT-006 | Reduce tracking merge-conflict hotspots by removing manual current-focus fields, switching backlog execution logging to append-only bullets, avoiding volatile metadata churn in routine slices, requiring backlog-priority/open-PR overlap checks before implementation, and capturing dependency notes during slice prioritization | P1 | S | done |
| INT-061 | FEAT-006 | Route agent temporary workspace operations to repo-local gitignored `scratch/` paths instead of OS temp directories to avoid sandbox-policy friction during routine slices | P1 | S | done |
| INT-062 | FEAT-012 | Produce pivot design doc for explicit target syntax (`--merged-into <ref>`), reason-first `Not deleted` reporting contract, rollout sequencing, and acceptance checks | P1 | S | done |
| INT-063 | FEAT-012 | Implement explicit cleanup-target flag (`--merged-into <ref>`) with ref validation, help/usage updates, and deterministic run-summary output that distinguishes auto-detected vs user-selected target refs | P1 | M | todo |
| INT-064 | FEAT-012 | Restructure reporting into `Branch intelligence` + `Cleanup plan`, ensuring each branch renders one final action status plus one primary keep reason when not deleted | P1 | M | todo |
| INT-065 | FEAT-012 | Add integration coverage and visual-validation demo updates for explicit target cleanup and reason-first non-deletion diagnostics across preview/apply flows | P1 | M | todo |

## Suggested Execution Order

1. `INT-057` (`FEAT-010`) to land open PR scope for ancestry-state reporting on `main` before additional reporting pivots are implemented.
2. `INT-062` (`FEAT-012`) to finalize and merge the explicit-target + reason-first UX design contract before behavior changes.
3. `INT-063` (`FEAT-012`) to implement explicit target selection syntax and output contract.
4. `INT-064` (`FEAT-012`) to split reporting into intelligence vs action-plan views with single-reason keep diagnostics.
5. `INT-065` (`FEAT-012`) to lock behavior with integration tests and refreshed visual-validation demo evidence.
6. `INT-058` (`FEAT-011`) to rename the CLI after the explicit-target UX pivot is stable.

## Sprintable Next Slice

1. `INT-062` (`FEAT-012`): merge explicit-target and reason-first UX planning contract so implementation slices can proceed with stable acceptance criteria.

## INT-062-INT-065 Dependency Notes

- `INT-062` blocked by: none. Unblocks: `INT-063`, `INT-064`, `INT-065`.
- `INT-063` blocked by: `INT-062` design contract merge. Unblocks: `INT-064`, `INT-065`.
- `INT-064` blocked by: `INT-063` target-flag behavior contract. Unblocks: `INT-065`.
- `INT-065` blocked by: merged behavior from `INT-063` and `INT-064`; visual-validation demo must reflect final reporting contract.

## INT-057 Scope Notes

### Goal

Improve reporting so the tool can explain more branch states using commit ancestry, without changing deletion or cleanup behavior. These new states are classification only.

### Category: `merged-into-upstream`

- Definition: branch tip commit is already contained in the branch's configured upstream tracking branch.
- Detection:
  - Resolve upstream ref for the branch.
  - If upstream exists, run `git merge-base --is-ancestor <branch_tip_commit> <upstream_ref>`.
  - If true, classify as `merged-into-upstream`.
- Output: include upstream name, for example `merged into upstream origin/develop`.

### Category: `merged-into-head`

- Definition: branch tip commit is already contained in the currently checked-out branch (`HEAD`).
- Detection: run `git merge-base --is-ancestor <branch_tip_commit> HEAD`.
- If true, classify as `merged-into-head`.
- Output: include current branch name, for example `merged into current HEAD develop`.
