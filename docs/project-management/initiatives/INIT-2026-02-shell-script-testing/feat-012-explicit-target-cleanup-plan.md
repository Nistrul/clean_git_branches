# FEAT-012 Plan: Explicit Target Cleanup + Reason-First Diagnostics

- Initiative ID: `INIT-2026-02-shell-script-testing`
- Feature ID: `FEAT-012`
- Related backlog slices: `INT-062`, `INT-063`, `INT-064`, `INT-065`

## 1. Problem Statement

Current output provides rich branch-state classification, but users can still be unsure which target ref cleanup is based on and why some branches are not deleted. This creates friction for teams that clean against multiple long-lived targets (for example `main` vs `develop`) and for users who need immediate investigative context for retained branches.

## 2. Goals

1. Add explicit cleanup-target selection so users can state intent directly (`--merged-into <ref>`).
2. Preserve safety-first behavior and keep delete gates unchanged.
3. Make non-deletion diagnostics first-class, deterministic, and easy to scan.
4. Keep preview-first workflow (`--apply` required for any deletion).

## 3. Non-Goals

1. Changing core safety exclusions (protected/current/ahead/unpushed/non-equivalent).
2. Introducing aggressive auto-delete behavior outside existing safe categories.
3. Replacing existing equivalence strategies.

## 4. Proposed CLI Contract

## New Flag

- `--merged-into <ref>`

## Semantics

1. `<ref>` is the explicit analysis/deletion base target.
2. If omitted, existing base auto-detection remains the fallback.
3. Invalid or unresolved refs fail fast with actionable error output.
4. `--apply` remains mandatory for actual deletion.

## Example Commands

1. `clean_git_branches --merged-into main`
2. `clean_git_branches --merged-into develop --apply`
3. `clean_git_branches --merged-into main --apply --delete-equivalent`

## Run Summary Contract

Run summary must always state whether base target is explicit or auto-detected:

1. `Base branch (explicit): develop`
2. `Base branch (auto-detected): main`

## 5. Reporting UX Contract

## Principles

1. Facts and actions must be separated.
2. Every branch should have one final action status in planning output.
3. Every non-deleted branch should have one primary keep reason.

## Target Structure

1. `Branch intelligence` section:
   - ancestry/equivalence/divergence facts
   - classification metadata only
2. `Cleanup plan` section:
   - one row per branch
   - final status (`DELETE_SAFE`, `DELETE_SAFE_OPT_IN`, `KEEP_*`)
   - one primary keep reason when status is keep

## Keep Reason Baseline

1. `KEEP_CURRENT_BRANCH`
2. `KEEP_PROTECTED`
3. `KEEP_AHEAD_OF_UPSTREAM`
4. `KEEP_UNPUSHED_COMMITS`
5. `KEEP_UNIQUE_COMMITS`
6. `KEEP_EQUIVALENT_OPT_IN_REQUIRED`

Verbose mode may append supporting evidence (for example commit counts/subjects), but primary reason code must remain stable in default output.

## 6. Safety and Behavior Guarantees

1. Explicit target selection must not bypass any existing safety rules.
2. Equivalent branch deletion remains opt-in.
3. Force fallback behavior remains constrained to equivalent branches when enabled.
4. Preview output and apply output must remain deterministic for tests and demos.

## 7. Delivery Plan

## `INT-062` (this slice)

1. Capture and align feature contract, rollout order, and acceptance criteria.

## `INT-063`

1. Implement `--merged-into <ref>`.
2. Add CLI/help validation and run-summary explicit-vs-auto output.
3. Preserve existing fallback behavior when flag is omitted.

## `INT-064`

1. Restructure rendering to `Branch intelligence` + `Cleanup plan`.
2. Ensure one plan status and one primary keep reason per branch.
3. Keep verbose evidence as progressive disclosure, not required for comprehension.

## `INT-065`

1. Add/refresh integration tests for explicit target usage and keep reasons.
2. Update demo(s) to show behavior delta clearly in before/after captures.
3. Verify deterministic artifact output for PR visual validation.

## 8. Acceptance Criteria

1. Users can explicitly set cleanup target ref with `--merged-into <ref>`.
2. Default behavior remains preview-only and safety gates are unchanged.
3. Output makes base-target source explicit (auto vs explicit).
4. Non-deleted branches always include a clear primary keep reason.
5. Integration tests and visual-validation demo evidence confirm new UX contract.
