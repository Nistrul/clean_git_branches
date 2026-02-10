# FEAT-004 CLI Color System Plan (`INT-047`)

- Initiative: `INIT-2026-02-shell-script-testing`
- Feature: `FEAT-004` (CLI contract and diagnostics)
- Slice: `INT-047`
- Status: Approved plan (implementation deferred to render-module slice)
- Last updated: 2026-02-10

## Problem Summary

Current CLI output uses hard-coded ANSI values in section-header rendering. This keeps output readable in many terminals but does not yet define a durable token model, explicit accessibility contract, or color-disable behavior policy. Before render abstraction (`INT-048`), a stable color policy is required so output semantics do not drift during refactors.

## Design Goals

1. Use color only as a secondary cue; meaning must remain clear in plain text.
2. Keep section semantics consistent across preview, apply, confirm, and verbose paths.
3. Ensure predictable behavior across TTY, non-TTY, and user color preferences.
4. Preserve current layout contract (title + underline + indented list items).

## Semantic Roles And Tokens

Token names are implementation-agnostic and will map to ANSI values during renderer extraction.

| Token | Semantic role | Default ANSI fallback |
|---|---|---|
| `cli.color.section.merged` | Safe-to-delete merged candidates | `1;94` (bright blue) |
| `cli.color.section.equivalent` | Opt-in equivalent-delete candidates | `1;96` (bright cyan) |
| `cli.color.section.non_equivalent` | Protected-by-policy informational section | `1;92` (bright green) |
| `cli.color.section.safety` | Exclusion and warning context | `1;93` (bright yellow) |
| `cli.color.section.summary` | End-of-run summary and mode recap | `1;95` (bright magenta) |
| `cli.color.section.execution` | Real deletion execution status | `1;94` (bright blue) |
| `cli.color.section.error` | Deletion failures and error outcomes | `1;91` (bright red) |
| `cli.color.section.default` | Fallback for unmapped headers | `1;97` (bright white) |

## Section Mapping Contract

1. `Merged branches` -> `cli.color.section.merged`
2. `Equivalent branches` -> `cli.color.section.equivalent`
3. `Non-equivalent branches` -> `cli.color.section.non_equivalent`
4. `Safety exclusions` -> `cli.color.section.safety`
5. `Run summary` -> `cli.color.section.summary`
6. `Execution results` -> `cli.color.section.execution`
7. `Deletion failures` -> `cli.color.section.error`
8. Any future section title must explicitly map to one token, otherwise use `cli.color.section.default`.

## Accessibility And Contrast Constraints

1. Color cannot be the only indicator of category meaning; section titles and item text must remain explicit.
2. Header text must maintain at least WCAG AA contrast equivalent against typical dark and light terminal backgrounds when feasible with ANSI palette limits.
3. Error and warning states must be distinguishable in monochrome output by wording, not only hue.
4. Bold styling may be used to improve legibility, but meaning must not depend on bold support.
5. Verbose diagnostics remain text-first and do not require additional hue coding in `INT-047`.

## TTY And No-Color Behavior Policy

1. Default: emit color only when stdout is a TTY.
2. Non-TTY output: suppress ANSI sequences and print plain section titles/underlines.
3. Respect `NO_COLOR` when present and non-empty: disable ANSI output even on TTY.
4. Future opt-in (`--color=always|auto|never`) is deferred; `INT-047` defines policy only.
5. Existing test-only `CLEAN_GIT_BRANCHES_ASSUME_TTY=1` remains test harness behavior and must not override `NO_COLOR`.

## Deferred Visual Critique Checkpoint

Checkpoint is intentionally deferred until render-module boundaries from `INT-048` are in place.

Entry criteria:
1. Renderer API centralizes section-title printing.
2. Token-to-ANSI mapping lives in one location.
3. TTY and `NO_COLOR` gating is implemented once and shared by all sections.

Review scope at checkpoint:
1. Terminal screenshot sweep (macOS Terminal, iTerm2 default, GitHub Actions logs).
2. Legibility pass on light and dark backgrounds.
3. Distinguishability pass for warning vs error vs informational headings.
4. Decision on whether to keep current palette or adjust ANSI mappings.

## Implementation Handoff Notes For `INT-048`

1. Replace title-based color switch logic with token lookup.
2. Keep current section wording unchanged to avoid output-contract churn.
3. Add focused tests for:
   - TTY auto-color behavior
   - `NO_COLOR` suppression
   - non-TTY plain output with no escape sequences
4. Treat any palette adjustments as follow-up changes after checkpoint review, not in initial renderer migration.
