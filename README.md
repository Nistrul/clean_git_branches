# Clean Git Branches

Clean Git Branches is a safety-first CLI for local branch cleanup.

It only deletes branches that are provably redundant:
- `merged` branches (fully merged into the detected base)
- `equivalent` branches (patch-equivalent to base, opt-in)

Branches with potentially unique local work are never deleted.

## Installation

Install with Homebrew:

```bash
brew tap Nistrul/clean-git-branches
brew install clean-git-branches
```

## Usage

Default mode is preview-only (dry-run semantics):

```bash
clean_git_branches
```

Execute deletions:

```bash
clean_git_branches --apply
```

Also delete equivalent branches (still safe-delete first):

```bash
clean_git_branches --apply --delete-equivalent
```

Allow equivalent fallback force delete (`-D`) only when safe delete fails:

```bash
clean_git_branches --apply --delete-equivalent --force-delete-equivalent
```

Choose equivalence detection mode:

```bash
clean_git_branches --equivalence cherry
clean_git_branches --equivalence patch-id
```

Prompt once per deletion category:

```bash
clean_git_branches --apply --confirm
```

Refresh remote state before analysis:

```bash
clean_git_branches --prune
```

Verbose diagnostics (shown in the `Run summary` section):

```bash
clean_git_branches --verbose
```

This includes run-level diagnostics (for example mode/base/prune details), without extra per-branch verbose lines.

## CLI Flags

- `--help`
- `--apply`
- `--confirm`
- `--delete-equivalent`
- `--equivalence {cherry|patch-id}`
- `--force-delete-equivalent`
- `--prune`
- `--verbose`

Removed legacy flags:
- `--force-delete-gone`
- `--no-force-delete-gone`
- `--delete-patch-equivalent-diverged`
- `--dry-run`
- `--silent`

## Safety Guarantees

The tool never deletes:
- current checked-out branch
- branches with unpushed commits
- branches ahead of upstream
- branches with unique (non-equivalent) commits

## Protected Branches

`PROTECTED_BRANCHES` is supported as a pipe-separated regex list.
Default: `main|master|prod|dev`.

Example:

```bash
export PROTECTED_BRANCHES="main|master|prod|dev|release"
```

## Testing

Run all tests:

```bash
test/run-tests.sh
```

CI runs the same command in GitHub Actions on pushes to `main` and on pull requests.

## Project Management

- `docs/project-management/index.md`
- `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/initiative.md`
- `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/tracker.md`
- `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/backlog.md`
- `docs/project-management/initiatives/INIT-2026-02-shell-script-testing/backlog-tracker.md`

## License

MIT
