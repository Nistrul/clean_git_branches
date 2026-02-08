# Integration Test Backlog: `clean_git_branches.sh`

- Initiative ID: `INIT-2026-02-shell-script-testing`
- Status: Active
- Last updated: 2026-02-08
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
| INT-026 | FEAT-004 | `--diagnose` emits expected diagnostic lines to stderr | P1 | S | todo |
| INT-027 | FEAT-001 | `--silent` warning appears only for destructive force-delete mode | P1 | S | done |
| INT-028 | FEAT-003 | Worktree dirty state does not break classification/deletion flow | P1 | M | done |
| INT-029 | FEAT-005 | Large branch set executes reliably (stress sanity) | P2 | M | todo |
| INT-030 | FEAT-005 | Branch names with spaces are handled or explicitly documented unsupported | P2 | L | todo |
| INT-031 | FEAT-005 | Unicode branch names are handled or documented unsupported | P2 | M | todo |
| INT-032 | FEAT-005 | `git rev-parse --show-toplevel` failure fallback path stays safe | P2 | M | todo |
| INT-033 | FEAT-005 | `git branch -vv` failure path exits predictably | P2 | M | todo |
| INT-034 | FEAT-005 | Remote fetch/prune timing edge still leaves deterministic assertions | P2 | M | todo |
| INT-035 | FEAT-003 | Section headers only render when corresponding section has content | P2 | S | todo |

## Suggested Execution Order

1. `FEAT-004` CLI contract and diagnostics
   - Execute remaining `P1` CLI scenario: `INT-026`.
2. `FEAT-005` Hardening and edge-path reliability
   - Execute `P2` hardening scenarios: `INT-029`, `INT-030`, `INT-031`, `INT-032`, `INT-033`, `INT-034`.
3. `FEAT-003` Branch classification and protection rules
   - Execute remaining `P2` presentation scenario: `INT-035`.

## Sprintable Next Slice

1. `FEAT-004`: `INT-026`
2. `FEAT-005`: `INT-029` (or `INT-035` as an alternative small slice)
