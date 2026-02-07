# Initiative Tracker: Shell Script Testing

- Initiative ID: `INIT-2026-02-shell-script-testing`
- Status: In Progress
- Last updated: 2026-02-07

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
9. `[ ]` Add CI entrypoint for tests.

## Working Notes

- Mock `git` command is at `test/mocks/git`.
- Mocked run helper is at `test/helpers/run-with-mock-git.sh`.
- Scenarios are in `test/fixtures/mock-git/`.
- This tracker is the source of truth for what is done vs pending.

## Next Actions

1. Add CI entrypoint for automated test execution.
2. Expand mocked scenarios for additional edge cases as needed.
3. Add one more integration test for confirmation prompt behavior.
