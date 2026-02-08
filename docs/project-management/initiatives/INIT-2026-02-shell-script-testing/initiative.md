# Initiative: Add Reliable Tests for `clean_git_branches.sh`

- Initiative ID: `INIT-2026-02-shell-script-testing`
- Status: Proposed
- Owner: Engineering
- Last updated: 2026-02-07

## 1. Problem Statement

The project currently has no automated tests for `clean_git_branches.sh`, which increases regression risk for branch cleanup behavior, argument handling, and failure modes. Since the script depends on `git`, we need a strategy that is both deterministic and realistic.

## 2. Goals

1. Add repeatable automated tests for core CLI behavior.
2. Mock `git` for fast, deterministic coverage of edge cases.
3. Add a small set of integration tests using real temporary Git repositories.
4. Establish a maintainable test harness and contribution pattern for future cases.

## 3. Non-Goals

1. Rewriting the script into another language.
2. Exhaustively testing every Git version or platform combination.
3. Building a full CI matrix in this initiative (can be a follow-on).

## 4. Research Summary (What We Learned)

1. `bats-core` is purpose-built for shell testing and provides explicit mechanisms for asserting status/stdout/stderr.
2. In Bats, `run` itself succeeds unless status is explicitly asserted, so tests must validate `$status` (or use `run -N`/`run !`) to avoid false positives.
3. Mocking `git` via `PATH` shims is aligned with shell command-resolution behavior and is a sound approach.
4. `mktemp` and isolated directories are the safest default for test isolation.
5. Strict shell modes (`set -euo pipefail`) should be used intentionally and validated in failure-path tests.
6. A mixed strategy (fast unit-style mocked tests + fewer real Git integration tests) provides best tradeoff between speed and confidence.

## 5. Scope

### In Scope

1. Test harness setup (Bats + helper libraries if needed).
2. Unit-style tests with mocked `git` command via `PATH`.
3. Integration tests against temporary real repositories (`git init`).
4. Documentation for running tests locally.

### Out of Scope (for now)

1. Cross-shell support beyond the script's intended shell.
2. Performance benchmarking.
3. Flaky-test retry framework.

## 6. Implementation Plan

## Phase 1: Test Harness

1. Add test directory layout:
   - `test/`
   - `test/helpers/`
   - `test/mocks/` (or per-test temp mocks)
2. Add Bats entry tests and helper loader.
3. Add `make test` or equivalent run command in README.

## Phase 2: Mocked Unit-Style Tests

1. Implement `mock_git` helper that:
   - prepends a temporary mock bin directory to `PATH`
   - captures invocation args for assertions
   - returns fixture outputs for specific git subcommands
2. Add high-value cases:
   - valid default flow
   - `--help` and invalid arguments
   - dirty working tree behavior
   - detached HEAD behavior
   - missing remote or command failure propagation

## Phase 3: Integration Tests with Real Git

1. Create temporary repositories with `mktemp` + `git init`.
2. Build minimal branch topologies needed for script behavior.
3. Assert side effects on actual branches/remotes for 2-4 critical scenarios.

## Phase 4: Hardening and Docs

1. Verify deterministic output assumptions (sorting, timestamps, locale).
2. Add concise testing guide in README.
3. Add contributor guidance on when to choose mocked vs integration tests.

## 7. Work Breakdown (Initial Backlog)

1. Create base test directories and helper script skeleton.
2. Add first mocked test for success path.
3. Add mocked tests for key failure paths.
4. Add first integration test using real repository.
5. Add test execution docs.
6. Optional: wire tests into CI.

## 8. Acceptance Criteria

1. Tests run with a single documented command.
2. Both stdout/stderr and exit codes are asserted for command outcomes.
3. Mocked tests cover at least 5 core behavioral branches.
4. Integration tests cover at least 2 end-to-end workflows with real Git.
5. New contributors can add a test by following documented pattern.

## 9. Risks and Mitigations

1. Risk: Over-mocking diverges from real Git behavior.
   - Mitigation: Keep integration tests for critical paths.
2. Risk: Brittle assertions against exact output formatting.
   - Mitigation: Prefer stable substrings or semantic assertions.
3. Risk: Environment-dependent failures.
   - Mitigation: Use isolated temp dirs; pin assumptions in helpers.

## 10. References

1. Bats docs: writing tests and `run`
   - https://bats-core.readthedocs.io/en/stable/writing-tests.html
2. Bats gotchas (`run` behavior)
   - https://bats-core.readthedocs.io/en/stable/gotchas.html
3. Bash command search and execution
   - https://www.gnu.org/software/bash/manual/html_node/Command-Search-and-Execution.html
4. POSIX `command` utility / search model
   - https://pubs.opengroup.org/onlinepubs/9799919799.2024edition/utilities/command.html
5. GNU `mktemp`
   - https://www.gnu.org/software/coreutils/manual/html_node/mktemp-invocation.html
6. Git `init`
   - https://git-scm.com/docs/git-init
7. Git command usage (`-C`, `--git-dir`, `--work-tree`, env)
   - https://git-scm.com/docs/git
8. Bash `set` builtin (`-e`, `-u`, `pipefail`)
   - https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
9. Google Shell Style Guide
   - https://google.github.io/styleguide/shellguide.html
10. Git testing guidance: behavioral tests and unit tests
    - https://git-scm.com/docs/MyFirstContribution
    - https://git-scm.com/docs/unit-tests

## 11. Proposed Next Execution Step

Start Phase 1 and Phase 2 together by scaffolding Bats and adding one mocked success-path test plus one failure-path test to establish the pattern.
