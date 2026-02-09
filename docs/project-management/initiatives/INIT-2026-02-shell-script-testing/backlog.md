# Integration Test Backlog: `clean_git_branches.sh`

- Initiative ID: `INIT-2026-02-shell-script-testing`
- Status: Active
- Last updated: 2026-02-09
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
| FEAT-006 | PR handoff progress reporting | Ensure handoff includes initiative completion percentage and remaining feature counts after PR creation. |
| FEAT-007 | Integration test suite coverage and maintainability | Keep integration tests logically ordered and validate coverage completeness before closing integration-test hardening. |

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
| INT-040 | FEAT-007 | Validate integration-test coverage map and capture/add missing high-risk scenarios before closing FEAT-007 | P1 | M | in_progress |
| INT-041 | FEAT-001 | Non-interactive `--dry-run --force-delete-gone` without `--silent` has deterministic confirmation/preview behavior and explicit output contract | P1 | S | todo |
| INT-042 | FEAT-007 | Consolidate overlapping subdirectory integration scenarios into one broader context-coverage test to reduce runtime and maintenance overhead | P2 | S | todo |
| INT-043 | FEAT-007 | Consolidate overlapping dirty-worktree integration scenarios into one broader cleanup-plus-reporting test to reduce runtime and maintenance overhead | P2 | S | todo |
| INT-044 | FEAT-007 | Move integration assertions that are equally effective in mocked tests to `test/clean_git_branches.bats` and keep only stateful/destructive checks in integration suite | P1 | M | todo |

## Suggested Execution Order

1. Execute `INT-040` to validate coverage and add any missing high-risk integration scenarios.
2. Execute `INT-041` to lock down non-interactive dry-run behavior contract.
3. Execute `INT-044` to reduce runtime by shifting equivalent assertions from integration to mocked tests.
4. Execute `INT-042` and `INT-043` to consolidate duplicate integration coverage.

## Sprintable Next Slice

1. Continue `INT-040` and then implement `INT-041` to close the highest-risk remaining confirmation-path gap.
