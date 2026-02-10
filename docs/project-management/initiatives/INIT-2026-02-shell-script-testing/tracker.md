# Initiative Tracker: Shell Script Testing

- Initiative ID: `INIT-2026-02-shell-script-testing`
- Status: In Progress
- Current Feature Focus: `FEAT-003` patch-equivalent diverged-branch classification investigation (`INT-046`) remains next; `FEAT-004` output-system planning (`INT-047`, `INT-048`) is queued after `INT-046`. `.DS_Store` hygiene (`INT-049`) is complete.
- Last updated: 2026-02-10

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

1. Execute `INT-046` to validate classification policy for diverged branches whose commits are already integrated into `main` by patch-equivalence, using test-first simulated states (prototype optional if needed to prove semantics).
2. Execute `INT-047` to define a UI/UX-guided color system plan for CLI output semantics and accessibility constraints.
3. Execute `INT-048` to plan render-module extraction that keeps current indentation layout but moves section rendering out of business logic.
4. Consolidate overlapping integration scenarios (`INT-042`, `INT-043`) after the planning slices.
5. Add CI entrypoint for automated test execution.
