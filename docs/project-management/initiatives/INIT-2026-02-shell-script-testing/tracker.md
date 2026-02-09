# Initiative Tracker: Shell Script Testing

- Initiative ID: `INIT-2026-02-shell-script-testing`
- Status: In Progress
- Current Feature Focus: `FEAT-007` coverage validation is in progress after test-ordering cleanup; CI entrypoint remains next milestone after coverage closure.
- Last updated: 2026-02-09

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

1. Complete `FEAT-007` coverage validation (`INT-040`) and add the non-interactive dry-run contract test (`INT-041`).
2. Reduce integration runtime by shifting equivalent assertions to mocked tests (`INT-044`) and consolidating overlap (`INT-042`, `INT-043`).
3. Add CI entrypoint for automated test execution.
