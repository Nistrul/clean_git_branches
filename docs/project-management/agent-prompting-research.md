# Agent Prompting Research: Workflow Reliability

- Last updated: 2026-02-11
- Purpose: Document prompt patterns that reduce workflow misses (branching, PR sequencing, and handoff checks).

## Problem

Agents can skip workflow steps when instructions are implied instead of explicit (for example: editing before branch alignment, or handing off before PR/rebase checks).

## Findings

1. Put high-priority process rules in explicit, top-level instructions.
2. Use ordered, deterministic checklists before and after implementation work.
3. Prefer fail-closed gates over best-effort reminders.
4. Encode required output fields as default handoff output contracts when process visibility is required (for example, post-PR progress metrics).
5. Keep examples concrete and imperative so action order is unambiguous.
6. For functional behavior changes, require one deterministic local demo per PR with before/after captures and a local diff gate so validation evidence is explicit.
7. Scope demo evidence to runtime behavior: prefer direct execution output over indirect test-signaling output unless the slice is explicitly test-behavior-only.
8. Treat PTY capture normalization as part of the artifact contract so platform-specific control-sequence noise does not leak into review artifacts.
9. Reset visual-validation artifact directories between slices so reviewers never inspect stale capture files from prior work.
10. Design demos with enough repeated structure (for example multiple entries in the changed layout region) so whitespace or grouping changes are obvious in plain-text diffs.
11. Enforce one canonical artifact filename set per slice and reject ad-hoc suffix/prefix variants so review always targets the current capture set.
12. For shared tracker files, use append-only bullet logs and remove manual current-focus metadata to reduce parallel PR conflict hotspots.
13. Use a repository-local gitignored scratch workspace for temporary files so sandbox restrictions do not block routine slice execution.

## Prompting Pattern We Adopted

1. Intake pre-flight on every request:
   - classify request type
   - run `git status --short --branch`
   - review remaining backlog work and pick the highest-priority unblocked slice
   - identify slice dependencies during prioritization (blocked-by and unblocks relationships)
   - check open PRs for overlapping scope before starting implementation
   - verify branch/scope alignment before any non-read command
   - treat "still on previous feature branch" as a normal start state; run routine alignment to `main` + new scoped branch
2. If alignment fails:
   - stop implementation
   - move/shelve unrelated work
   - branch from updated `main` using naming convention
3. Close-out checklist before handoff:
   - update trackers for delivered/deferred scope
   - create or update PR
   - sync latest `main` into feature branch (prefer rebase), rerun relevant tests only when rebase changes branch content or tests have not been run on the current HEAD, then push
4. Default post-PR reporting in handoff:
   - initiative completion percentage
   - features complete vs remaining
   - active initiative count and next initiative (or explicitly none)
   - concise prioritization summary covering what will be worked on next and why it is prioritized over other available tasks
5. Visual validation for functional-change PRs:
   - select or create exactly one deterministic demo before implementation
   - reset `pr-artifacts/` at slice start to remove stale captures
   - execute `clean_git_branches.sh` directly in the demo so evidence reflects actual CLI behavior
   - ensure the demo contains enough comparable output lines in the target UI region to make layout/spacing deltas visible
   - capture before and after ANSI output locally, sanitize raw PTY output with `demos/sanitize-ansi.py`, then create plain-text versions
   - keep exactly one canonical artifact set (`before.*`, `after.*`, `before-after.diff`); do not create alternate suffix files, and if the demo changes, reset and recapture canonical names
   - verify artifact naming before handoff with `ls -1 pr-artifacts`
   - review local `before` vs `after` diff as a gate
   - upload raw ANSI artifacts and keep one collapsible plain-text `Visual Validation` PR comment
6. For process/docs/tracker-only PRs with no runtime behavior change:
   - skip before/after visual-validation capture by default unless explicitly requested
7. Tracker conflict minimization defaults:
   - keep backlog execution logs append-only with unordered bullets
   - do not renumber or reorder historical log entries
   - avoid volatile metadata edits (for example `Last updated` and manual `Current Focus` fields) in routine feature slices
8. Overlap handling defaults:
   - if open PR scope overlaps the selected slice, continue on that existing branch/PR rather than creating a parallel duplicate slice
   - if overlap is partial or unclear, choose a non-overlapping highest-priority slice and record the overlap deferral in trackers
9. Prioritization dependency defaults:
   - record dependency notes when selecting the next slice (for example, prerequisite slice IDs and any slices unblocked by completion)
10. Temporary workspace defaults:
   - keep transient files for the current slice under repo-local `scratch/` (create with `mkdir -p scratch` when needed)
   - avoid OS temp paths (for example `/tmp`) for routine agent workflow artifacts in this repository

## Repository Mapping

The above pattern is enforced in `AGENTS.md` under `Prompt Intake Workflow (Mandatory)`.

## Template: Writing Future `AGENTS.md` Rules

Use this structure when adding new mandatory process rules.

```md
## <Rule Section Name> (Mandatory)

1. Trigger: On every <event>, run:
   - <explicit command/check 1>
   - <explicit command/check 2>
2. Gate: If <condition fails>, stop and do:
   - <recovery step 1>
   - <recovery step 2>
3. Prohibition: Do not <unsafe/ambiguous behavior>.
4. Close-out: Before handoff, always:
   - <verification step 1>
   - <verification step 2>
5. Output contract: If required by repository workflow, include:
   - <required metric 1>
   - <required metric 2>
```

### Rule Quality Checklist

1. Is the trigger explicit and testable?
2. Are commands concrete (no implied steps)?
3. Does the rule fail closed when checks fail?
4. Is prohibited behavior stated directly?
5. Is there a close-out checklist before handoff?
6. If reporting is required, are fields enumerated?
7. Is wording imperative and unambiguous?

## References

1. OpenAI Prompt Engineering Guide: https://platform.openai.com/docs/guides/prompt-engineering
2. OpenAI Model Spec: https://model-spec.openai.com/
3. OpenAI Cookbook prompting examples: https://cookbook.openai.com/examples/gpt-5/gpt-5_prompting_guide
