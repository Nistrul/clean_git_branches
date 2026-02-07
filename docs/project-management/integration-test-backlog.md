# Integration Test Backlog: `clean_git_branches.sh`

- Initiative ID: `INIT-2026-02-shell-script-testing`
- Status: Active
- Last updated: 2026-02-07

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

## Backlog

| ID | Scenario | Priority | Effort | Status |
|---|---|---|---|---|
| INT-001 | Delete merged unprotected branch in real repo | P0 | S | done |
| INT-002 | Force-delete remote-gone branch with local bare `origin.git` | P0 | S | done |
| INT-003 | `--dry-run --force-delete-gone` previews but does not delete | P0 | S | todo |
| INT-004 | `--no-force-delete-gone` reports gone branches only | P0 | S | todo |
| INT-005 | Non-interactive force-delete without `--silent` returns confirmation error | P0 | S | todo |
| INT-006 | Interactive confirm accepts `DELETE` and deletes gone branches | P0 | M | todo |
| INT-007 | Interactive confirm with empty input skips deletion | P0 | M | todo |
| INT-008 | Protected branch in gone state is never force-deleted | P0 | M | todo |
| INT-009 | Mixed gone set where one delete fails and one succeeds | P0 | M | done |
| INT-010 | Unknown CLI flag exits non-zero and prints help | P0 | S | done |
| INT-011 | `.clean_git_branches.conf` true enables deletion in auto mode | P0 | M | todo |
| INT-012 | CLI `--no-force-delete-gone` overrides config true | P0 | S | todo |
| INT-013 | CLI `--force-delete-gone` overrides config false | P0 | S | todo |
| INT-014 | Default protected branches (`main|master|prod|dev`) are preserved | P1 | S | todo |
| INT-015 | Custom `PROTECTED_BRANCHES` prevents deletion of custom protected names | P1 | S | todo |
| INT-016 | Mixed tracked/untracked/gone/protected branches are classified correctly | P1 | M | todo |
| INT-017 | No merged branches yields no merged-deletion section noise | P1 | S | todo |
| INT-018 | Branch names with slashes (`feature/a/b`) behave correctly | P1 | S | todo |
| INT-019 | Branch names with dots/dashes/underscores behave correctly | P1 | S | todo |
| INT-020 | Current branch with no upstream continues gracefully | P1 | S | done |
| INT-021 | Detached HEAD does not crash and still reports branch sections safely | P1 | M | todo |
| INT-022 | Run from subdirectory within repo; behavior remains correct | P1 | S | todo |
| INT-023 | Config parse tolerates whitespace/case (`TRUE`, ` yes `) | P1 | S | todo |
| INT-024 | Malformed config falls back to safe default behavior | P1 | S | todo |
| INT-025 | `--help` includes all supported flags and exits zero | P1 | S | done |
| INT-026 | `--diagnose` emits expected diagnostic lines to stderr | P1 | S | todo |
| INT-027 | `--silent` warning appears only for destructive force-delete mode | P1 | S | done |
| INT-028 | Worktree dirty state does not break classification/deletion flow | P1 | M | todo |
| INT-029 | Large branch set executes reliably (stress sanity) | P2 | M | todo |
| INT-030 | Branch names with spaces are handled or explicitly documented unsupported | P2 | L | todo |
| INT-031 | Unicode branch names are handled or documented unsupported | P2 | M | todo |
| INT-032 | `git rev-parse --show-toplevel` failure fallback path stays safe | P2 | M | todo |
| INT-033 | `git branch -vv` failure path exits predictably | P2 | M | todo |
| INT-034 | Remote fetch/prune timing edge still leaves deterministic assertions | P2 | M | todo |
| INT-035 | Section headers only render when corresponding section has content | P2 | S | todo |

## Suggested Execution Order

1. Complete remaining `P0` scenarios (`INT-003` to `INT-013`).
2. Execute `P1` correctness/classification scenarios.
3. Execute `P2` hardening scenarios and decide support boundaries.

## Sprintable Next Slice

1. `INT-003`
2. `INT-004`
3. `INT-005`
4. `INT-011`
5. `INT-012`
6. `INT-013`
