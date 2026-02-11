# Initiative Tracker: Shell Script Testing

- Initiative ID: `INIT-2026-02-shell-script-testing`
- Status: Active
- Current Feature Focus: `FEAT-010` safe-delete parity with Git `-d` (`INT-057`) and `FEAT-011` git-extension rename (`INT-058`).
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
9. `[x]` Validate integration-test coverage and close remaining `FEAT-007` slices.
10. `[x]` Add CI entrypoint for tests.
11. `[x]` Add dry-run divergence diagnostics and strategy-parity verification.
12. `[ ]` Align safe-delete diagnostics with Git `branch -d` viability.
13. `[ ]` Rename CLI to `git-branch-tidy` and support `git branch-tidy`.

## Working Notes

- Mock `git` command is at `test/mocks/git`.
- Mocked run helper is at `test/helpers/run-with-mock-git.sh`.
- Scenarios are in `test/fixtures/mock-git/`.
- This tracker is the source of truth for what is done vs pending.
- Prioritized scenario backlog is in `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/backlog.md`.
- Backlog execution log is in `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/backlog-tracker.md`.

## Next Actions

1. Start `INT-057` (`FEAT-010`) to add explicit safe-delete diagnostics that mirror `git branch -d` viability per branch.
