# Initiative Tracker: Shell Script Testing

- Initiative ID: `INIT-2026-02-shell-script-testing`
- Status: In Progress
- Current Feature Focus: `FEAT-004` minimal CLI safety simplification (`INT-051`), color-system planning (`INT-047`), render-module extraction (`INT-048`), `FEAT-006` visual-validation workflow policy (`INT-052`, `INT-053`), and subdirectory context consolidation (`INT-042`) are complete. Dirty-worktree consolidation (`INT-043`) is next.
- Last updated: 2026-02-11

## Completion Legend

- `[x]` complete
- `[~]` in progress
- `[ ]` not started

## Current Milestones

1. `[x]` Create project-management docs folder and initiative plan.
2. `[x]` Add mocked `git` harness for non-repo layout/workflow development.
3. `[x]` Add scenario fixtures for deterministic behavior variants.
4. `[x]` Document mocked workflow in README.
5. `[x]` Scaffold Bats test harness.
6. `[x]` Add first mocked success-path test.
7. `[x]` Add mocked failure-path tests.
8. `[x]` Add real Git integration tests.
9. `[~]` Validate integration-test coverage and close remaining `FEAT-007` slices.
10. `[ ]` Add CI entrypoint for tests.

## Working Notes

- Mock `git` command is at `test/mocks/git`.
- Mocked run helper is at `test/helpers/run-with-mock-git.sh`.
- Scenarios are in `test/fixtures/mock-git/`.
- This tracker is the source of truth for what is done vs pending.
- Prioritized scenario backlog is in `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/backlog.md`.
- Backlog execution log is in `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/backlog-tracker.md`.

## Next Actions

1. Execute `INT-043` to consolidate overlapping dirty-worktree integration coverage into one broader cleanup/reporting test.
2. Add CI entrypoint for automated test execution.
