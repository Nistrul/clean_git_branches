# Tracker: Integration Test Backlog Execution

- Initiative ID: `INIT-2026-02-shell-script-testing`
- Scope: Execution tracking for `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/backlog.md`
- Status: Active

## Tracking Rules

1. Scenario status (`todo|in_progress|done|blocked`) is maintained in `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/backlog.md`.
2. This tracker logs execution slices, decisions, and handoff notes.
3. Execution-log entries are append-only bullets; do not renumber or reorder prior entries.
4. Do not edit volatile shared metadata in routine slices (for example `Last updated` or `Current Focus` fields).

## Execution Log

### 2026-02-15

- Intake check selected `INT-058` as the highest-priority unblocked existing `todo` slice; deferred that implementation due explicit user-requested pivot planning for target-directed cleanup UX.
- Confirmed open-PR overlap before planning changes: PR `#55` (`INT-057`) is ancestry-state reporting scope and does not overlap with explicit-target syntax planning.
- Per branch-alignment workflow, stashed unrelated in-progress `INT-057` work, switched to `main`, fast-forwarded, and created branch `feat/INIT-2026-02-shell-script-testing/FEAT-004-int-062-explicit-target-plan` before edits.
- Added `FEAT-012` and planning slice `INT-062` to define explicit target syntax (`--merged-into <ref>`) plus reason-first non-deletion diagnostics.
- Added follow-on implementation/test slices `INT-063` to `INT-065` with dependency notes:
  - `INT-062` unblocks `INT-063`, `INT-064`, `INT-065`
  - `INT-063` unblocks `INT-064`, `INT-065`
  - `INT-064` unblocks `INT-065`
- Added design contract document `feat-012-explicit-target-cleanup-plan.md` covering CLI semantics, reporting architecture, rollout sequence, and acceptance criteria.

### 2026-02-11

- Split a newly requested mixed scope into three separate PR-ready backlog slices so execution can proceed as isolated changesets.
- Added `FEAT-009` + `INT-056` for dry-run divergence diagnostics and equivalence-strategy parity verification for non-merged branches.
- Added `FEAT-010` + `INT-057` for safe-delete parity checks against Git `branch -d` viability, including explicit diagnostics and test coverage.
- Added `FEAT-011` + `INT-058` for renaming the tool to `git-branch-tidy` and enabling `git branch-tidy` invocation.
- Reopened initiative tracking status to `Active` and set `INT-056` as the next sprintable slice.
- Left implementation out of scope for this slice; this branch is tracking/planning updates only.

- Completed `INT-048` (`FEAT-004`) on branch `feat/INIT-2026-02-shell-script-testing/FEAT-004-int-048-render-module-plan`.
- Extracted renderer boundaries in `clean_git_branches.sh` so section-token mapping, token-to-ANSI mapping, and color gating are centralized in dedicated renderer API functions.
- Replaced title-based hard-coded color selection with semantic renderer tokens aligned to `INT-047` color-system planning.
- Added TTY/`NO_COLOR` policy implementation so ANSI output is enabled only for TTY output (or test-assumed TTY) and suppressed for non-TTY or non-empty `NO_COLOR`.
- Added focused integration coverage for non-TTY plain output, TTY color emission, and `NO_COLOR` suppression behavior.
- Verified regression safety via `test/run-tests.sh` (16 tests passing total: 4 mocked + 12 integration).
- Updated initiative/backlog planning artifacts so `INT-048` is marked done and `INT-042` is the next sprintable slice.
- Completed process-slice `INT-052` (`FEAT-006`) on branch `feat/INIT-2026-02-shell-script-testing/FEAT-006-visual-validation-demo-workflow`.
- Added mandatory `AGENTS.md` workflow rules requiring exactly one deterministic local demo per PR, pre/post implementation capture, local before/after diff validation, and single-comment PR publication contract for visual validation artifacts.
- Updated `docs/project-management/agent-prompting-research.md` to include prompting guidance for deterministic demo selection-before-implementation and explicit visual validation evidence requirements.
- Added `demos/README.md` plus deterministic starter demo `demos/minimal-safe-cleanup.sh` that builds isolated temporary Git fixtures and prints labeled output sections.
- Added `pr-artifacts/` ignore coverage in `.gitignore` so generated visual-validation artifacts are never committed.
- Completed process refinement slice `INT-053` (`FEAT-006`) on branch `feat/INIT-2026-02-shell-script-testing/FEAT-006-int-053-functional-visual-validation-gate`.
- Refined `AGENTS.md` visual-validation rules so before/after capture is mandatory only for functional behavior changes, skipped by default for docs/process/tracker-only PRs, and required to show direct `clean_git_branches.sh` runtime output for functional-change slices.
- Updated `docs/project-management/agent-prompting-research.md` with explicit prompting guidance to avoid substituting indirect test-signaling output when runtime behavior evidence is expected.
- Completed `INT-042` (`FEAT-007`) on branch `feat/INIT-2026-02-shell-script-testing/FEAT-007-int-042-subdirectory-context-consolidation`.
- Added a consolidated integration scenario in `test/clean_git_branches.integration.bats` that runs from a nested subdirectory and validates both dry-run analysis and `--apply` behavior in one context-coverage test.
- Extended `test/helpers/run-in-repo.sh` with optional `--cwd <relative-subdir>` support so integration tests can run deterministically from nested repository paths without shell chaining.
- Kept `INT-042` validation as integration-test evidence only and removed non-runtime demo usage so demo workflows remain reserved for direct `clean_git_branches.sh` output.
- Verified regression safety via `bats test/clean_git_branches.integration.bats -f "subdirectory context coverage validates nested preview and apply behavior"` and `test/run-tests.sh` (17 tests passing total: 4 mocked + 13 integration).
- Completed `INT-043` (`FEAT-007`) on branch `feat/INIT-2026-02-shell-script-testing/FEAT-007-int-043-dirty-worktree-context-consolidation`.
- Consolidated overlapping dirty-worktree and merged-branch cleanup coverage into one broader integration scenario that validates dry-run reporting, `--apply` deletion, and preservation of local dirty state in a single flow.
- Removed the redundant standalone merged-apply integration scenario to reduce suite maintenance overhead while preserving deletion assertions.
- Verified regression safety via `bats test/clean_git_branches.integration.bats -f "dirty worktree coverage validates preview and apply cleanup behavior"` and `test/run-tests.sh` (16 tests passing total: 4 mocked + 12 integration).
- Completed `INT-054` (`FEAT-008`) on branch `feat/INIT-2026-02-shell-script-testing/FEAT-008-ci-entrypoint-automation`.
- Added `.github/workflows/tests.yml` to run `test/run-tests.sh` on pull requests and pushes to `main`.
- Installed Bats in CI via `apt-get` so the existing test runner can execute unchanged in GitHub-hosted Linux jobs.
- Updated `README.md` testing documentation to note CI runs the same local test command.
- Updated planning trackers so `FEAT-008` and `INT-054` are marked complete and no pending slice is currently defined.
- Verified regression safety via `test/run-tests.sh` (16 tests passing total: 4 mocked + 12 integration).
- Hardened CI-facing integration assertions in `test/clean_git_branches.integration.bats` so output-contract checks tolerate stable formatting variants (bullet prefix and safety-reason ordering) while still asserting required semantics.
- Completed `INT-055` (`FEAT-008`) by configuring global Git defaults in `.github/workflows/tests.yml` (`init.defaultBranch=main`, `advice.defaultBranchName=false`) to suppress `git init` default-branch advice noise in CI logs.
- Verified regression safety via `test/run-tests.sh` (16 tests passing total: 4 mocked + 12 integration).
- Further stabilized CI behavior by removing two remaining environment-sensitive string assertions (optional `ahead of upstream` and merged-confirmation summary wording) while retaining prompt and branch-state outcome checks.
- Identified and fixed a confirmation-flow bug in `clean_git_branches.sh`: decline/abort statuses were read incorrectly after `if ! func` (always observing status `0`), causing declined categories to proceed with deletion.
- Added test-only deterministic confirmation input support via `CLEAN_GIT_BRANCHES_CONFIRM_RESPONSES` and switched the confirm-category integration test to use scripted responses instead of piped stdin.
- Validated stability with a 40x targeted stress run of `integration: confirm prompts once per deletion category` plus full-suite pass via `test/run-tests.sh`.
- Completed process-slice `INT-059` (`FEAT-006`) on branch `feat/INIT-2026-02-shell-script-testing/FEAT-006-int-059-ansi-sanitization-workflow`.
- Added `demos/sanitize-ansi.py` as a canonical binary-safe normalization step for visual-validation capture artifacts.
- Updated `AGENTS.md` visual-validation commands to capture raw `script` output (`before.raw.ansi`/`after.raw.ansi`), sanitize into final `.ansi`, and only then derive `.txt`.
- Updated `demos/README.md` and `docs/project-management/agent-prompting-research.md` so capture normalization is part of the default artifact contract.
- Verified sanitizer behavior with a deterministic byte-level fixture (`^D\b\b\r\n` prefix + CRLF payload) and confirmed normalized output removed the prefix and emitted LF-only text.
- Completed `INT-056` (`FEAT-009`) on branch `feat/INIT-2026-02-shell-script-testing/FEAT-009-int-056-dry-run-divergence-diagnostics`.
- Expanded dry-run reporting for non-merged branches in `clean_git_branches.sh` to include commit-level divergence evidence (`unique commits ahead of <base>`, plus sample commit subjects) for both equivalent and non-equivalent categories.
- Added integration coverage in `test/clean_git_branches.integration.bats` to verify divergence-evidence output contract and parity across `--equivalence cherry` and `--equivalence patch-id`.
- Verified regression safety via targeted test `bats test/clean_git_branches.integration.bats -f "integration: dry-run reports non-merged divergence evidence across equivalence modes"` and full suite `test/run-tests.sh` (17 tests passing total: 4 mocked + 13 integration).
- Captured required visual-validation artifacts for functional behavior change using deterministic demo `minimal-safe-cleanup` with sanitized `before/after` ANSI transcripts and a local `before-after.diff`.
- Refined `INT-056` output UX based on review feedback: removed divergence annotations from equivalent branches to avoid implying they contain unique content.
- Added a dedicated multi-line `Non-equivalent divergence details` section that presents branch-only ancestry commit count and sample commit subjects with readable line breaks.
- Revalidated refinement via targeted parity test, full-suite run (`test/run-tests.sh`), and refreshed visual-validation artifacts/diff for PR update.

### 2026-02-10

- Completed `INT-044` (`FEAT-007`) by moving config precedence/parsing and verbose diagnostic contract assertions from integration coverage into mocked coverage (`test/clean_git_branches.bats`).
- Added mocked harness support for run-directory execution via `SCENARIO_RUN_DIR` so config-file assertions can execute outside the repository root while still using mock Git behavior.
- Removed overlapping integration tests for config precedence/parsing and verbose diagnostics from `test/clean_git_branches.integration.bats` to keep integration coverage focused on stateful/destructive behavior.
- Verified migrated coverage and regression safety via `bats test/clean_git_branches.bats`, `bats test/clean_git_branches.integration.bats`, and `test/run-tests.sh` (38 tests passing).
- Completed `INT-045` (`FEAT-007`) by adding persistent suite timing output to `test/run-tests.sh` for mocked/unit, integration, and full-run elapsed seconds.
- Captured before-vs-after runtime comparison for `INT-044` with `/usr/bin/time -p`:
   - before (`main`): mocked/unit `2.01s`, integration `51.64s`
   - after (`feat/INIT-2026-02-shell-script-testing/FEAT-007-int-044-mock-assertion-shift`): mocked/unit `4.14s`, integration `42.44s`
- Verified updated runner output and regression safety via `test/run-tests.sh` (38 tests passing with `[timing]` lines).
- Captured new backlog investigation slice `INT-046` (`FEAT-003`) for diverged branches whose commits are already integrated into `main` by patch-equivalence (for example via squash/cherry-pick/rewrite paths).
- Recorded recommendations for `INT-046`: keep ancestor-merged auto-delete behavior unchanged, add a separate patch-equivalent-diverged classification, and validate with test-first simulated states before implementation (prototype permitted if needed to prove detection semantics).
- Captured new planning slice `INT-047` (`FEAT-004`) to define a UI/UX-guided CLI color system plan with semantic token roles, accessibility/contrast constraints, and TTY/no-color behavior expectations.
- Captured new planning slice `INT-048` (`FEAT-004`) to design a render module that centralizes section rendering and formatting while preserving the current indentation-based layout contract.
- Captured immediate follow-up hygiene slice `INT-049` (`FEAT-005`) to ensure `.DS_Store` files are not tracked and to add ignore/policy coverage in a dedicated branch/PR.
- Reprioritized next slices so `INT-046` remains first for classification/deletion safety validation, followed by output-system planning (`INT-047`, `INT-048`) and immediate `.DS_Store` hygiene (`INT-049`) before deferred integration-consolidation cleanup.
- Prioritized `INT-049` immediately on user request to remove `.DS_Store` artifacts from active workflow and prevent recurrence.
- Dropped the temporary stash created during branch alignment because it contained only untracked `.DS_Store` content.
- Completed `INT-049` by adding repository-level `.gitignore` coverage for `.DS_Store` and `**/.DS_Store`.
- Confirmed no `.DS_Store` files are tracked in the repository.
- Narrowed `INT-049` scope to repository ignore policy only (`.gitignore`) and removed extra README/test-runner hardening additions.
- Completed process refinement slice `INT-050` (`FEAT-006`) to avoid redundant post-PR sync test reruns when rebase is a no-op and relevant tests already passed on the current HEAD.
- Updated `AGENTS.md` and `docs/project-management/agent-prompting-research.md` so post-PR sync reruns relevant tests only when rebase changes content or the current HEAD has not yet been test-validated.
- Completed `INT-046` (`FEAT-003`) with test-first integration coverage for patch-equivalent diverged remote-gone branches plus a non-equivalent control scenario.
- Added safe classification policy in `clean_git_branches.sh`: keep ancestor-merged auto-delete behavior unchanged, exclude patch-equivalent diverged gone branches from force-delete candidates, and report them in a dedicated `Patch-equivalent diverged branches (not deleted)` section.
- Added deterministic integration helper setup to force true history divergence before cherry-pick so patch-equivalent scenarios cannot collapse into ancestor-merged commits during fast test runs.
- Verified regression safety via `bats test/clean_git_branches.integration.bats -f "patch-equivalent"` and `test/run-tests.sh` (40 tests passing total: 11 mocked + 29 integration).
- Extended `INT-046` with explicit opt-in deletion control via `--delete-patch-equivalent-diverged`, keeping patch-equivalent diverged branches report-only by default.
- Updated force-delete confirmation/dry-run output to show separate candidate groups for standard remote-gone vs patch-equivalent diverged branches when opt-in deletion is enabled.
- Added integration coverage for opt-in patch-equivalent deletion and confirmation-prompt category rendering.
- Verified regression safety via `test/run-tests.sh` (42 tests passing total: 11 mocked + 31 integration).
- Completed `INT-051` (`FEAT-004`) by replacing the legacy remote-gone force-delete model with a minimal safe cleanup contract: default dry-run preview, `--apply` for execution, and branch classification into merged/equivalent/non-equivalent.
- Removed deprecated flags and behaviors from `clean_git_branches.sh`: `--force-delete-gone`, `--no-force-delete-gone`, `--delete-patch-equivalent-diverged`, `--dry-run`, and `--silent`.
- Added new minimal CLI surface and behavior: `--apply`, `--confirm` (category-level prompts), `--delete-equivalent`, `--equivalence {cherry|patch-id}`, `--force-delete-equivalent`, `--prune`, and `--verbose`.
- Enforced non-overridable deletion safeguards for current branch, protected branches, ahead-of-upstream branches, unpushed branches, and non-equivalent branches.
- Reworked output contract to deterministic grouped sections with explicit reasons and optional per-branch diagnostics in verbose mode.
- Replaced legacy tests with contract-focused suites aligned to the new behavior model in `test/clean_git_branches.bats` and `test/clean_git_branches.integration.bats`.

### 2026-02-09

- Completed FEAT-004 follow-up polish on `feat/INIT-2026-02-shell-script-testing/FEAT-004-int-036-verbose-diagnostics`.
- Improved report readability in verbose mode by inserting a single separator newline before the first printed report section.
- Verified regression safety via full suite run: `test/run-tests.sh` (37 tests passing).
- Completed documentation hardening slice `INT-038` (`FEAT-005`) for non-obvious advanced integration tests.
- Added concise `Why` and regression-risk comments in integration tests to explain scenario intent and anticipated failure modes.
- Verified regression safety via full suite run: `test/run-tests.sh` (37 tests passing).
- Refined `INT-038` comment style based on review feedback by removing `Regression risk` lines and adding focused Git feature notes (for example `git branch -vv`, `fetch --prune`, detached HEAD, `rev-parse --show-toplevel`).
- Expanded the pre-prune/post-prune timing comment into a more explicit plain-language paragraph to explain why the same branch is expected to appear tracked before prune and remote-gone after prune.
- Expanded additional moderate/high-complexity integration-test comments into natural-language paragraphs so behavior and Git concepts remain understandable without deep Git background.
- Added concise plain-language intent comments to every remaining test in both Bats suites so each scenario is understandable at a glance.
- Simplified the two remaining hard-to-parse comments (`git branch -vv` failure and repo-top-folder fallback) to remove jargon and use direct plain-language phrasing.

### 2026-02-07

- Completed `P0` slice: `INT-003`, `INT-004`, `INT-005`, `INT-011`, `INT-012`, `INT-013`.
- Added integration coverage for dry-run preview, report-only mode, non-interactive confirmation error, and config/CLI precedence.
- Updated confirmation flow so non-interactive force-delete without `--silent` exits non-zero.
- Deferred higher-work `P0` scenarios for next pass: `INT-006`, `INT-007`, `INT-008`.

### 2026-02-08

- Completed remaining `P0` slice: `INT-006`, `INT-007`, `INT-008`.
- Added integration coverage for interactive confirmation accept (`DELETE`) and skip (empty input).
- Added integration coverage to ensure protected remote-gone branches are never force-deleted.
- Added `CLEAN_GIT_BRANCHES_ASSUME_TTY=1` test-only hook to exercise interactive confirmation flow in non-TTY test runners.
- Verified full suite passes via `test/run-tests.sh` (16 tests).
- Completed `FEAT-003` `P1` slice: `INT-014`, `INT-015`, `INT-016`.
- Added integration coverage for default protected branch preservation, custom protected branch preservation, and mixed tracked/untracked/gone/protected classification.
- Verified full suite passes via `test/run-tests.sh` (19 tests).
- Completed next `FEAT-003` `P1` slice: `INT-017`, `INT-018`, `INT-019`.
- Added integration coverage for no merged-deletion section noise and branch-name handling for slash and dot/dash/underscore patterns.
- Verified full suite passes via `test/run-tests.sh` (22 tests).
- Completed `FEAT-003` remaining `P1` slice: `INT-021`, `INT-022`, `INT-028`.
- Added integration coverage for detached HEAD stability, subdirectory execution behavior, and dirty worktree flow safety.
- Verified full suite passes via `test/run-tests.sh` (25 tests).
- Completed `FEAT-002` remaining `P1` slice: `INT-023`, `INT-024`.
- Added integration coverage for tolerant config parsing of whitespace/case true-like values and malformed-value safe fallback behavior.
- Verified full suite passes via `test/run-tests.sh` (27 tests).
- Added deferred low-priority backlog scenario `INT-036` under `FEAT-004` to replace `--diagnose` with `--verbose` and improve diagnostics formatting/readability.
- Completed `FEAT-004` remaining `P1` slice: `INT-026`.
- Added integration coverage asserting diagnostics output emits expected repository-state and mode-selection details.
- Verified full suite passes via `test/run-tests.sh` (30 tests).
- Completed first `FEAT-005` `P2` hardening slice: `INT-029`.
- Added stress-sanity integration coverage for a large mixed branch set (tracked, local-only, remote-gone) with deterministic assertions.
- Verified full suite passes via `test/run-tests.sh` (31 tests).
- Completed next `FEAT-005` `P2` hardening slice: `INT-030`.
- Added integration coverage documenting Git-ref-format rejection of branch names with spaces and verified normal classification remains stable.
- Documented branch-name constraint in `README.md` (`Branch Name Constraints`).
- Verified full suite passes via `test/run-tests.sh` (32 tests).
- Captured new request as deferred backlog slice `INT-037` (`FEAT-006`) for post-PR handoff progress reporting (initiative completeness %, feature complete/remaining counts, initiative totals, and next initiative).
- Completed next `FEAT-005` `P2` hardening slice: `INT-031`.
- Added integration coverage for Unicode tracked/local/gone branch names and verified remote-gone Unicode branch force deletion flow.
- Updated `README.md` `Branch Name Constraints` to document supported Unicode branch names under Git ref-format rules.
- Verified full suite passes via `test/run-tests.sh` (33 tests).
- Completed next `FEAT-005` `P2` hardening slice: `INT-032`.
- Added integration coverage for `git rev-parse --show-toplevel` failure fallback path and verified the run remains safe (report-only, no unintended force-delete).
- Verified full suite passes via `test/run-tests.sh` (34 tests).
- Completed next `FEAT-005` `P2` hardening slice: `INT-033`.
- Added integration coverage for a simulated `git branch -vv` failure path and asserted deterministic non-zero exit behavior with stable error output.
- Hardened script startup by failing fast when `git branch -vv` cannot list branches, returning deterministic non-zero behavior.
- Completed next `FEAT-005` `P2` hardening slice: `INT-034`.
- Added integration coverage for remote delete timing around local ref state: pre-prune run remains tracked/report-only deterministic, post-prune run deterministically reports remote-gone.
- Verified full suite passes via `test/run-tests.sh` (36 tests).
- Completed `FEAT-003` `P2` presentation slice: `INT-035`.
- Added integration coverage asserting section headers only render when corresponding sections have content.
- Verified full suite passes via `test/run-tests.sh` (37 tests).
- Completed request-driven reporting slice `INT-037` (`FEAT-006`) and standardized post-PR handoff reporting fields.
- Captured post-PR handoff metrics in the handoff format: initiative completion percentage, completed vs remaining feature counts, active initiative count, and next initiative (or explicit none).
- Clarified agent process rules so post-PR progress reporting is a default handoff requirement after PR create/update, not request-only.
- Clarified PR cohesion rule: process-slice changes may combine agent rules and supporting project-management docs in one PR, while remaining separate from functional feature implementation changes.
- Extended default post-PR handoff reporting to include a concise prioritization summary (next slice + rationale versus other currently available tasks).
- Added explicit workflow guidance that starting a new slice on the previous feature branch is normal and should trigger routine branch alignment (`main` update + new scoped branch), not error escalation.
- Completed `FEAT-004` diagnostics UX follow-up slice: `INT-036`.
- Replaced CLI diagnostics flag `--diagnose` with `--verbose` and upgraded diagnostics output to structured section + key/value formatting.
- Updated integration coverage to assert formatted verbose diagnostics for repository state and mode-selection output.
- Verified full suite passes via `test/run-tests.sh` (37 tests).
- Completed integration-test maintainability slice `INT-039` (`FEAT-007`) on branch `feat/INIT-2026-02-shell-script-testing/FEAT-007-integration-test-ordering`.
- Reordered `test/clean_git_branches.integration.bats` so related scenarios are grouped in a clearer top-to-bottom progression (cleanup modes, confirmation/protection, classification/naming, execution context, config/diagnostics, failure and stress).
- Verified regression safety via targeted integration run: `bats test/clean_git_branches.integration.bats` (32 tests passing).
- Rescoped `FEAT-007` from ordering-only to ongoing coverage-and-maintainability scope so the feature stays open for coverage validation follow-up work.
- Added `INT-040` under `FEAT-007` as `in_progress` to validate coverage completeness and add/capture missing high-risk integration scenarios before closing the feature.
- Completed a coverage-quality review pass focused on overlap and high-risk gaps in `test/clean_git_branches.integration.bats`.
- Added backlog item `INT-041` for uncovered non-interactive `--dry-run --force-delete-gone` behavior contract validation.
- Added backlog items `INT-042` and `INT-043` to consolidate overlapping subdirectory and dirty-worktree integration tests.
- Added backlog item `INT-044` to migrate integration assertions that are equally effective in mocked tests so the integration suite stays focused on stateful/destructive behaviors.
- Completed `INT-041` by adding a dedicated integration contract test for non-interactive `--dry-run --force-delete-gone` behavior without `--silent`.
- Updated force-delete confirmation flow so dry-run previews are allowed in non-interactive environments and no longer fail with a confirmation error.
- Completed `INT-040` coverage-contract closure by validating the gap was captured and exercised via the new high-risk dry-run scenario.
- Verified regression safety via full suite run: `test/run-tests.sh` (38 tests passing).
- Completed planning slice `INT-047` (`FEAT-004`) on branch `feat/INIT-2026-02-shell-script-testing/FEAT-004-int-047-cli-color-system-plan`.
- Added `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/feat-004-cli-color-system-plan.md` with semantic token roles, section mapping contract, accessibility/contrast constraints, and TTY/`NO_COLOR` behavior policy.
- Captured deferred visual critique checkpoint criteria and handoff constraints so palette review occurs after renderer centralization in `INT-048`.
- Updated backlog ordering and tracker next actions so `INT-048` is now the immediate next slice.
- Completed a whitespace-focused readability pass for `FEAT-009` dry-run divergence diagnostics on branch `feat/INIT-2026-02-shell-script-testing/FEAT-009-int-056-dry-run-divergence-diagnostics`.
- Updated raw section rendering to preserve intentional blank lines and added explicit spacing between non-equivalent divergence detail branch groups.
- Added deterministic visual-validation demo `demos/non-equivalent-divergence-layout.sh` plus catalog entry in `demos/README.md`.
- Verified regression safety via targeted integration run: `bats test/clean_git_branches.integration.bats --filter "dry-run reports non-merged divergence evidence across equivalence modes"` (passing).
- Added explicit visual-validation artifact workflow guardrails to `AGENTS.md`: mandatory `pr-artifacts` reset, canonical filename set, no suffix variants, and pre-handoff artifact-name verification.
- Synced workflow rationale updates into `docs/project-management/agent-prompting-research.md` for canonical artifact naming and single-set capture discipline.
- Added repository-local Codex permission rule `.codex/rules/default.rules` to allow `rm -rf pr-artifacts` without escalation during artifact resets.

### 2026-02-12

- Completed process-slice `INT-060` (`FEAT-006`) to reduce tracking-document merge conflicts without splitting into per-slice files.
- Removed manual `Current Focus` sections and replaced initiative-level focus with backlog-derived status guidance in `tracker.md`.
- Converted `backlog-tracker.md` execution-log entries to append-only bullet formatting so parallel PRs no longer collide on sequential renumbering.
- Added explicit tracking hygiene rules in `AGENTS.md` and prompting guidance in `docs/project-management/agent-prompting-research.md` to avoid volatile metadata churn in routine PRs.
- Added intake guardrails requiring backlog-priority selection and open-PR overlap checks before implementation so duplicate slices are avoided by default.
- Added prioritization guidance requiring dependency notes (blocked-by and unblocks) when choosing the next slice.
- Rescoped `INT-057` (`FEAT-010`) from safe-delete parity diagnostics to classification-only commit-ancestry reporting, preserving existing deletion/cleanup behavior.
- Added explicit `INT-057` scope notes for `merged-into-upstream` and `merged-into-head` categories, including definition, detection checks, and required output context.
- Completed process-slice `INT-061` (`FEAT-006`) on branch `feat/INIT-2026-02-shell-script-testing/FEAT-006-int-061-scratch-temp-workflow`.
- Added repo-local temporary-workspace policy in `AGENTS.md` requiring agent temp artifacts to use gitignored `scratch/` paths instead of OS temp directories.
- Updated prompting guidance in `docs/project-management/agent-prompting-research.md` to encode `scratch/` as the default temporary workspace for routine slice execution.
- Added `.gitignore` entry for `scratch/` so transient workflow artifacts remain untracked.

### 2026-02-13

- Completed `INT-057` (`FEAT-010`) on branch `feat/INIT-2026-02-shell-script-testing/FEAT-010-int-057-ancestry-classification`.
- Added classification-only ancestry reporting in `clean_git_branches.sh` for `merged-into-upstream` and `merged-into-head`, including upstream/HEAD context in output with no deletion behavior changes.
- Added integration coverage in `test/clean_git_branches.integration.bats` to verify ancestry-state reporting and assert the branches remain non-deletion candidates in apply mode.
- Added deterministic visual-validation demo `demos/ancestry-merged-states.sh` and catalog entry in `demos/README.md`.
- Captured required visual-validation artifacts in `pr-artifacts/` and validated the local `before-after.diff` behavior delta.
- Verified regression safety via targeted test `bats test/clean_git_branches.integration.bats -f "integration: ancestry-only merged states report upstream and head context without changing deletion behavior"` and full suite `test/run-tests.sh` (18 tests passing total: 4 mocked + 14 integration).
- Refined `INT-057` output presentation to render three explicit sections: `merged-into-main`, `merged-into-upstream`, and `merged-into-head` (classification-only).
- Updated ancestry integration coverage to use a more realistic mixed branch topology and verify section-specific rendering plus unchanged deletion safety behavior.
- Refreshed visual-validation artifacts with updated demo output so before/after diff explicitly demonstrates the three new ancestry sections.

### 2026-02-15

- Refined `INT-057` ancestry-state reporting to make sections mutually exclusive using ordered precedence: `merged-into-main`, then `merged-into-upstream`, then `merged-into-head`.
- Updated section headers to document exclusions inline: `merged-into-upstream (not main)` and `merged-into-head (not main/upstream)`.
- Added integration assertion coverage that `feature/main-contained` no longer appears in upstream ancestry output while preserving apply-mode deletion behavior checks.
- Refreshed deterministic visual-validation artifacts with `demos/ancestry-merged-states.sh` and verified the expected before/after delta in `pr-artifacts/before-after.diff`.
- Refined `INT-057` classification/output interplay so branches shown under `merged-into-head (not main/upstream)` include explicit divergence context (`divergent from <base>`) when applicable.
- Updated reporting exclusivity so branches in `merged-into-head` are omitted from `Non-equivalent branches` and `Non-equivalent divergence details` to avoid duplicate categorization.
- Expanded ancestry integration assertions to verify head-category divergence labeling and non-equivalent-section exclusion for the same branch.
- Restructured ancestry output to treat `Merged branches` as an outer heading only (no direct branch list), with branch entries rendered only in descendant ancestry sections.
- Added an `Unmerged branches` outer heading above `Non-equivalent branches` to clarify top-level state grouping.
- Collapsed non-equivalent divergence reporting into inline per-branch details within `Non-equivalent branches`, removing the separate `Non-equivalent divergence details` section and duplicate listing.
- Updated integration assertions and visual-validation demo expectations to verify heading hierarchy and single-list branch presentation.
- Refined ancestry detail rendering so branch metadata is printed on labeled, indented child lines (for example `merged into upstream: ...`, `merged into head: ...`, `divergent from <base>: yes|no`) rather than inline suffixes on the branch line.
- Updated renderer token mapping so `Unmerged branches` uses the non-equivalent section color token instead of falling through to default bright white.
- Expanded ancestry integration assertions and visual-validation demo expectations to verify labeled detail indentation beneath branch rows.
- Removed `Merged branches` and `Unmerged branches` outer headings from ancestry reporting so section hierarchy is flatter and branch lists are not duplicated under wrapper titles.
- Replaced ancestry section headers with `Merged into upstream branches` and dynamic `Merged into local <current-branch>`, and kept local-section eligibility restricted to branches not merged into upstream.
- Removed `merged-into-main` reporting so upstream/local sections define the ancestry classification surface, with per-branch labeled details preserved.
