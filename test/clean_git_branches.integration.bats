#!/usr/bin/env bats

load 'helpers/test_helper.bash'

setup() {
  setup_test_env
}

teardown() {
  teardown_test_env
}

create_repo_with_origin() {
  local origin_dir="$TEST_TMPDIR/origin.git"
  local work_dir="$TEST_TMPDIR/work"

  git init --bare "$origin_dir" >/dev/null
  git init "$work_dir" >/dev/null
  git -C "$work_dir" config user.name "Test User"
  git -C "$work_dir" config user.email "test@example.com"
  git -C "$work_dir" remote add origin "$origin_dir"

  echo "seed" > "$work_dir/README.md"
  git -C "$work_dir" add README.md
  git -C "$work_dir" commit -m "initial commit" >/dev/null
  git -C "$work_dir" branch -M main
  git -C "$work_dir" push -u origin main >/dev/null

  echo "$origin_dir|$work_dir"
}

create_gone_branch() {
  local work_dir="$1"
  local branch_name="${2:-feature/gone}"

  git -C "$work_dir" checkout -b "$branch_name" >/dev/null
  echo "gone branch content for $branch_name" >> "$work_dir/README.md"
  git -C "$work_dir" add README.md
  git -C "$work_dir" commit -m "gone branch commit for $branch_name" >/dev/null
  git -C "$work_dir" push -u origin "$branch_name" >/dev/null
  git -C "$work_dir" checkout main >/dev/null
  git -C "$work_dir" push origin --delete "$branch_name" >/dev/null
  git -C "$work_dir" fetch --prune >/dev/null
}

create_tracked_branch() {
  local work_dir="$1"
  local branch_name="$2"

  git -C "$work_dir" checkout -b "$branch_name" >/dev/null
  echo "tracked branch content for $branch_name" >> "$work_dir/README.md"
  git -C "$work_dir" add README.md
  git -C "$work_dir" commit -m "tracked branch commit for $branch_name" >/dev/null
  git -C "$work_dir" push -u origin "$branch_name" >/dev/null
  git -C "$work_dir" checkout main >/dev/null
}

create_local_only_branch() {
  local work_dir="$1"
  local branch_name="$2"

  git -C "$work_dir" checkout -b "$branch_name" >/dev/null
  echo "local only branch content for $branch_name" >> "$work_dir/README.md"
  git -C "$work_dir" add README.md
  git -C "$work_dir" commit -m "local only branch commit for $branch_name" >/dev/null
  git -C "$work_dir" checkout main >/dev/null
}

@test "integration: deletes merged branches in real repository" {
  # This is the baseline merged-branch cleanup behavior in a real Git repo (not mocks). We create a feature
  # branch, merge it into main, run the script, and then confirm the merged branch is actually deleted.
  local dirs
  local origin_dir
  local work_dir

  dirs="$(create_repo_with_origin)"
  origin_dir="${dirs%%|*}"
  work_dir="${dirs##*|}"

  git -C "$work_dir" checkout -b feature/merged >/dev/null
  echo "feature change" >> "$work_dir/README.md"
  git -C "$work_dir" add README.md
  git -C "$work_dir" commit -m "feature commit" >/dev/null
  git -C "$work_dir" checkout main >/dev/null
  git -C "$work_dir" merge --no-ff feature/merged -m "merge feature" >/dev/null

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --no-force-delete-gone

  [ "$status" -eq 0 ]
  [[ "$output" == *"Deleted merged branches"* ]]
  [[ "$output" == *"feature/merged"* ]]

  run git -C "$work_dir" branch --list feature/merged
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "integration: no merged branches does not print merged deletion section" {
  # When nothing is merged, we should avoid noisy output that suggests merged cleanup happened. This keeps the
  # report honest and easier to scan.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_tracked_branch "$work_dir" "feature/not-merged"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --no-force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" != *"Deleted merged branches"* ]]
  [[ "$output" == *"Tracked branches"* ]]
  [[ "$output" == *"feature/not-merged"* ]]
}

@test "integration: no-force-delete-gone reports gone branches without deleting" {
  # This checks report-only mode for gone branches. We still want visibility into stale branches, but no local
  # deletion should happen when force-delete is off.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "feature/report-gone"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --no-force-delete-gone

  [ "$status" -eq 0 ]
  [[ "$output" == *"Remote-gone branches (deletion disabled)"* ]]
  [[ "$output" == *"feature/report-gone"* ]]

  run git -C "$work_dir" branch --list feature/report-gone
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/report-gone"* ]]
}

@test "integration: force deletes remote-gone branches with local origin" {
  # Here we verify the destructive "gone branch cleanup" path when force-delete is enabled. The branch tracks
  # origin, then we delete it on the remote so local Git marks it as gone; after running the script, it should
  # be removed locally.
  local dirs
  local origin_dir
  local work_dir

  dirs="$(create_repo_with_origin)"
  origin_dir="${dirs%%|*}"
  work_dir="${dirs##*|}"

  create_gone_branch "$work_dir" "feature/gone"

  run git -C "$work_dir" branch -vv
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/gone"* ]]
  [[ "$output" == *"gone"* ]]

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Deleted remote-gone branches"* ]]
  [[ "$output" == *"feature/gone"* ]]

  run git -C "$work_dir" branch --list feature/gone
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "integration: dry run with force delete previews gone branches and does not delete" {
  # Dry-run mode should show what would be deleted without changing branch state. This test confirms we get the
  # preview message and that the branch still exists afterward.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "feature/dry-run-gone"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --dry-run --force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Would delete remote-gone branches (dry run)"* ]]
  [[ "$output" == *"feature/dry-run-gone"* ]]

  run git -C "$work_dir" branch --list feature/dry-run-gone
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/dry-run-gone"* ]]
}

@test "integration: remote delete before local prune remains deterministic across pre and post prune runs" {
  # We delete the branch on the remote first, but we intentionally do not prune local tracking data yet.
  # On the first run, Git can still make this branch look like a normal tracked branch because local metadata
  # has not caught up. After `git fetch --prune`, Git removes the stale tracking reference, and the same branch
  # now appears as "gone". This test proves that both runs are correct and predictable for their moment in time:
  # before prune we classify it as tracked, and after prune we classify it as remote-gone.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"

  create_tracked_branch "$work_dir" "feature/fetch-prune-edge"
  git -C "$work_dir" push origin --delete "feature/fetch-prune-edge" >/dev/null

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --no-force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Tracked branches"* ]]
  [[ "$output" == *"feature/fetch-prune-edge"* ]]
  [[ "$output" != *"Remote-gone branches (deletion disabled)"* ]]

  git -C "$work_dir" fetch --prune >/dev/null

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --no-force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Remote-gone branches (deletion disabled)"* ]]
  [[ "$output" == *"feature/fetch-prune-edge"* ]]
}

@test "integration: non-interactive force delete requires confirmation without silent flag" {
  # This test simulates a non-interactive environment by closing stdin (`</dev/null`), which is what often
  # happens in CI jobs and scripted automation. In that situation, there is no safe way for a user to type
  # the required confirmation word, so the script must refuse to force-delete and exit with a clear message.
  # We then verify the branch still exists, proving no destructive action happened.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "feature/non-interactive"

  run bash -c "'$repo_root/test/helpers/run-in-repo.sh' '$work_dir' --force-delete-gone </dev/null"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Force deletion requires confirmation"* ]]
  [[ "$output" == *"Skipped remote-gone force deletion"* ]]

  run git -C "$work_dir" branch --list feature/non-interactive
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/non-interactive"* ]]
}

@test "integration: interactive confirm accepts DELETE and deletes gone branches" {
  # This test covers the "intentional destructive action" path. We simulate a user typing `DELETE`, which is
  # our hard-confirm token, and force TTY behavior so the prompt path is exercised during tests. The key idea
  # is that only explicit confirmation should unlock deletion. If this input is accepted, the gone branch
  # should actually be removed from local branches.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "feature/interactive-delete"

  run bash -c "printf 'DELETE\\n' | CLEAN_GIT_BRANCHES_ASSUME_TTY=1 '$repo_root/test/helpers/run-in-repo.sh' '$work_dir' --force-delete-gone"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Type DELETE to continue, or press Enter to skip:"* ]]
  [[ "$output" == *"Deleted remote-gone branches"* ]]
  [[ "$output" == *"feature/interactive-delete"* ]]

  run git -C "$work_dir" branch --list feature/interactive-delete
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "integration: interactive confirm with empty input skips deletion" {
  # This is the safety counterpart to the previous test. Here the user just presses Enter (empty input), and
  # the expected behavior is "do nothing destructive." We assert the skip message appears and that the branch
  # still exists, so a distracted or unsure user gets a safe default outcome.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "feature/interactive-skip"

  run bash -c "printf '\\n' | CLEAN_GIT_BRANCHES_ASSUME_TTY=1 '$repo_root/test/helpers/run-in-repo.sh' '$work_dir' --force-delete-gone"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Type DELETE to continue, or press Enter to skip:"* ]]
  [[ "$output" == *"Skipped remote-gone force deletion"* ]]

  run git -C "$work_dir" branch --list feature/interactive-skip
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/interactive-skip"* ]]
}

@test "integration: protected gone branch is never force deleted" {
  # Even with force-delete enabled, protected branches must never be removed. We use `dev` to prove protection
  # rules override gone-branch deletion candidates.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "dev"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" != *"Deleted remote-gone branches"* ]]
  [[ "$output" == *"Remote-gone branches (not deleted)"* ]]
  [[ "$output" == *"dev"* ]]

  run git -C "$work_dir" branch --list dev
  [ "$status" -eq 0 ]
  [[ "$output" == *"dev"* ]]
}

@test "integration: default protected branches are preserved during merged and gone cleanup" {
  # This scenario intentionally puts `dev` in multiple "would normally delete" buckets at once: it is merged
  # into main and also remote-gone after remote deletion plus prune. The purpose is to prove protection rules
  # win over cleanup candidates. Even when a branch looks deletable from multiple angles, protected names must
  # be preserved and reported as protected, not deleted.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"

  git -C "$work_dir" checkout -b dev >/dev/null
  echo "dev branch content" >> "$work_dir/README.md"
  git -C "$work_dir" add README.md
  git -C "$work_dir" commit -m "dev branch commit" >/dev/null
  git -C "$work_dir" push -u origin dev >/dev/null
  git -C "$work_dir" checkout main >/dev/null
  git -C "$work_dir" merge --no-ff dev -m "merge dev branch" >/dev/null
  git -C "$work_dir" push origin --delete dev >/dev/null
  git -C "$work_dir" fetch --prune >/dev/null

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" != *"Deleted merged branches"* ]]
  [[ "$output" != *"Deleted remote-gone branches"* ]]
  [[ "$output" == *"Remote-gone branches (not deleted)"* ]]
  [[ "$output" == *"dev"* ]]
  [[ "$output" == *"Protected branches"* ]]
  [[ "$output" == *"main"* ]]
  [[ "$output" == *"dev"* ]]

  run git -C "$work_dir" branch --list dev
  [ "$status" -eq 0 ]
  [[ "$output" == *"dev"* ]]
}

@test "integration: custom protected branch names are preserved when gone" {
  # This verifies that custom protection rules are honored, not just built-in defaults. We mark `release` as
  # protected and confirm it is reported but not deleted when remote-gone.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "release"

  run bash -c "PROTECTED_BRANCHES='main|release' '$repo_root/test/helpers/run-in-repo.sh' '$work_dir' --force-delete-gone --silent"

  [ "$status" -eq 0 ]
  [[ "$output" != *"Deleted remote-gone branches"* ]]
  [[ "$output" == *"Remote-gone branches (not deleted)"* ]]
  [[ "$output" == *"release"* ]]
  [[ "$output" == *"Protected branches"* ]]
  [[ "$output" == *"release"* ]]

  run git -C "$work_dir" branch --list release
  [ "$status" -eq 0 ]
  [[ "$output" == *"release"* ]]
}

@test "integration: mixed tracked untracked gone and protected branches are classified correctly" {
  # This is a full mixed-state classification test. In one repository snapshot, we create a normal tracked
  # branch, a local-only branch, a remote-gone branch, and a protected branch. The goal is to confirm each
  # branch lands in exactly the right output section. This makes it easier to trust that the script is reading
  # branch metadata correctly when real repos contain a mixture of branch states.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"

  create_tracked_branch "$work_dir" "feature/tracked"
  create_local_only_branch "$work_dir" "feature/local-only"
  create_gone_branch "$work_dir" "feature/gone"
  create_tracked_branch "$work_dir" "dev"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --no-force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Untracked branches"* ]]
  [[ "$output" == *"feature/local-only"* ]]
  [[ "$output" == *"Remote-gone branches (deletion disabled)"* ]]
  [[ "$output" == *"feature/gone"* ]]
  [[ "$output" == *"Tracked branches"* ]]
  [[ "$output" == *"feature/tracked"* ]]
  [[ "$output" == *"Protected branches"* ]]
  [[ "$output" == *"dev"* ]]
}

@test "integration: branch names with slashes are classified correctly" {
  # Branch names often include path-style slashes (`feature/a/b`). This test confirms those names are parsed
  # correctly across tracked, local-only, and gone classifications.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"

  create_tracked_branch "$work_dir" "feature/a/b"
  create_local_only_branch "$work_dir" "feature/local/only"
  create_gone_branch "$work_dir" "feature/gone/a"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --no-force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Tracked branches"* ]]
  [[ "$output" == *"feature/a/b"* ]]
  [[ "$output" == *"Untracked branches"* ]]
  [[ "$output" == *"feature/local/only"* ]]
  [[ "$output" == *"Remote-gone branches (deletion disabled)"* ]]
  [[ "$output" == *"feature/gone/a"* ]]
}

@test "integration: branch names with dots dashes and underscores are handled correctly" {
  # This covers common punctuation-heavy branch names to ensure parsing and deletion logic do not accidentally
  # break on separators like `.`, `-`, or `_`.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"

  create_tracked_branch "$work_dir" "feature/release.v1-2_3"
  create_local_only_branch "$work_dir" "feature/local.v1-2_3"
  create_gone_branch "$work_dir" "feature/gone.v1-2_3"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Deleted remote-gone branches"* ]]
  [[ "$output" == *"feature/gone.v1-2_3"* ]]
  [[ "$output" == *"Tracked branches"* ]]
  [[ "$output" == *"feature/release.v1-2_3"* ]]
  [[ "$output" == *"Untracked branches"* ]]
  [[ "$output" == *"feature/local.v1-2_3"* ]]

  run git -C "$work_dir" branch --list feature/gone.v1-2_3
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "integration: unicode branch names are handled correctly" {
  # This test protects UTF-8 handling across the full pipeline. The script uses standard shell tools for
  # parsing and filtering branch data, and those tools can behave badly if quoting or encoding assumptions are
  # wrong. By creating Unicode tracked, local-only, and gone branches, we verify names are preserved exactly
  # and that deletion/classification still works with non-ASCII branch names.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"

  create_tracked_branch "$work_dir" "feature/unicode-ßeta"
  create_local_only_branch "$work_dir" "feature/unicode-東京-local"
  create_gone_branch "$work_dir" "feature/unicode-gone-ñ"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Deleted remote-gone branches"* ]]
  [[ "$output" == *"feature/unicode-gone-ñ"* ]]
  [[ "$output" == *"Tracked branches"* ]]
  [[ "$output" == *"feature/unicode-ßeta"* ]]
  [[ "$output" == *"Untracked branches"* ]]
  [[ "$output" == *"feature/unicode-東京-local"* ]]

  run git -C "$work_dir" branch --list "feature/unicode-gone-ñ"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "integration: branch names with spaces are unsupported by git ref format" {
  # This test documents a Git rule that can be surprising if you only think at script level: branch names
  # cannot contain spaces. `git branch "feature/space name"` fails before our script even gets a chance to
  # classify anything. We keep a valid control case in the same test to show the script still behaves normally
  # once branch names obey Git ref-format rules.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"

  run git -C "$work_dir" branch "feature/space name"
  [ "$status" -ne 0 ]

  create_tracked_branch "$work_dir" "feature/space-control"
  create_gone_branch "$work_dir" "feature/space-control-gone"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --no-force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Tracked branches"* ]]
  [[ "$output" == *"feature/space-control"* ]]
  [[ "$output" == *"Remote-gone branches (deletion disabled)"* ]]
  [[ "$output" == *"feature/space-control-gone"* ]]
}

@test "integration: detached HEAD does not crash and still reports branch sections safely" {
  # In detached HEAD, Git is pointing directly at a commit instead of an active branch, so commands like
  # `git branch --show-current` return an empty value. That can easily break scripts that assume a current
  # branch always exists. This test verifies our script still runs safely and continues to classify/report
  # other branches correctly even without a normal checked-out branch context.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_tracked_branch "$work_dir" "feature/detached-tracked"

  git -C "$work_dir" checkout --detach >/dev/null

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --no-force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Tracked branches"* ]]
  [[ "$output" == *"feature/detached-tracked"* ]]
  [[ "$output" == *"Protected branches"* ]]
  [[ "$output" == *"main"* ]]
}

@test "integration: running from subdirectory in repo keeps behavior correct" {
  # Users often run utilities from deep inside a repository, not from repo root. This test starts in a nested
  # directory and verifies behavior stays identical. Conceptually, the script should discover the repository
  # root (typically via `git rev-parse --show-toplevel`) and operate on repository state, not on the current
  # shell folder.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_tracked_branch "$work_dir" "feature/subdir-tracked"
  mkdir -p "$work_dir/src/components"

  run bash -c "cd '$work_dir/src/components' && '$repo_root/clean_git_branches.sh' --no-force-delete-gone --silent"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Tracked branches"* ]]
  [[ "$output" == *"feature/subdir-tracked"* ]]
  [[ "$output" == *"Protected branches"* ]]
  [[ "$output" == *"main"* ]]
}

@test "integration: running from repo subdirectory keeps classification behavior correct" {
  # This is a broader subdirectory case that includes tracked/local-only/gone classes together. Running from
  # nested paths should not change classification results.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  mkdir -p "$work_dir/sub/dir"

  create_tracked_branch "$work_dir" "feature/subdir-tracked"
  create_local_only_branch "$work_dir" "feature/subdir-local-only"
  create_gone_branch "$work_dir" "feature/subdir-gone"

  run bash -c "cd '$work_dir/sub/dir' && '$repo_root/clean_git_branches.sh' --no-force-delete-gone --silent"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Tracked branches"* ]]
  [[ "$output" == *"feature/subdir-tracked"* ]]
  [[ "$output" == *"Untracked branches"* ]]
  [[ "$output" == *"feature/subdir-local-only"* ]]
  [[ "$output" == *"Remote-gone branches (deletion disabled)"* ]]
  [[ "$output" == *"feature/subdir-gone"* ]]
}

@test "integration: dirty worktree does not break classification and reporting flow" {
  # This is a reporting-focused dirty-worktree scenario. We verify output sections remain correct and that the
  # original uncommitted file change is still present after the run.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"

  create_tracked_branch "$work_dir" "feature/dirty-tracked"
  create_local_only_branch "$work_dir" "feature/dirty-local-only"
  create_gone_branch "$work_dir" "feature/dirty-gone"
  echo "dirty change" >> "$work_dir/README.md"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --no-force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Tracked branches"* ]]
  [[ "$output" == *"feature/dirty-tracked"* ]]
  [[ "$output" == *"Untracked branches"* ]]
  [[ "$output" == *"feature/dirty-local-only"* ]]
  [[ "$output" == *"Remote-gone branches (deletion disabled)"* ]]
  [[ "$output" == *"feature/dirty-gone"* ]]

  run git -C "$work_dir" status --short
  [ "$status" -eq 0 ]
  [[ "$output" == *"README.md"* ]]
}

@test "integration: dirty worktree does not break cleanup and classification flow" {
  # Users often run cleanup with uncommitted changes present. This test confirms branch classification/deletion
  # still works and the script does not require a clean working tree.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"

  git -C "$work_dir" checkout -b feature/dirty-merged >/dev/null
  echo "dirty merged content" >> "$work_dir/README.md"
  git -C "$work_dir" add README.md
  git -C "$work_dir" commit -m "dirty merged commit" >/dev/null
  git -C "$work_dir" checkout main >/dev/null
  git -C "$work_dir" merge --no-ff feature/dirty-merged -m "merge dirty branch" >/dev/null

  create_tracked_branch "$work_dir" "feature/dirty-tracked"
  create_local_only_branch "$work_dir" "feature/dirty-local"

  echo "uncommitted change" >> "$work_dir/README.md"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --no-force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Deleted merged branches"* ]]
  [[ "$output" == *"feature/dirty-merged"* ]]
  [[ "$output" == *"Tracked branches"* ]]
  [[ "$output" == *"feature/dirty-tracked"* ]]
  [[ "$output" == *"Untracked branches"* ]]
  [[ "$output" == *"feature/dirty-local"* ]]

  run git -C "$work_dir" branch --list feature/dirty-merged
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "integration: section headers render only when their sections have content" {
  # This test keeps output readable and trustworthy. If a section has no items, we do not want to print an
  # empty header because that suggests some action or category exists when it does not. We disable protected
  # matching and assert all section headers stay hidden in an all-empty result.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"

  run bash -c "PROTECTED_BRANCHES='^$' '$repo_root/test/helpers/run-in-repo.sh' '$work_dir' --no-force-delete-gone --silent"

  [ "$status" -eq 0 ]
  [[ "$output" != *"Deleted merged branches"* ]]
  [[ "$output" != *"Untracked branches"* ]]
  [[ "$output" != *"Remote-gone branches"* ]]
  [[ "$output" != *"Tracked branches"* ]]
  [[ "$output" != *"Protected branches"* ]]
}

@test "integration: config true enables force delete in auto mode" {
  # In auto mode, repo config can choose behavior. This test checks that setting
  # `FORCE_DELETE_GONE_BRANCHES=true` enables deletion even without CLI override flags.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "feature/config-true"
  echo "FORCE_DELETE_GONE_BRANCHES=true" > "$work_dir/.clean_git_branches.conf"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Deleted remote-gone branches"* ]]
  [[ "$output" == *"feature/config-true"* ]]

  run git -C "$work_dir" branch --list feature/config-true
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "integration: cli no-force-delete-gone overrides config true" {
  # CLI flags should win over config for predictability. Here config says "delete", but explicit CLI
  # `--no-force-delete-gone` must switch behavior back to report-only.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "feature/config-override-off"
  echo "FORCE_DELETE_GONE_BRANCHES=true" > "$work_dir/.clean_git_branches.conf"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --no-force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Remote-gone branches (deletion disabled)"* ]]
  [[ "$output" == *"feature/config-override-off"* ]]

  run git -C "$work_dir" branch --list feature/config-override-off
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/config-override-off"* ]]
}

@test "integration: cli force-delete-gone overrides config false" {
  # This is the opposite precedence case: config says "do not delete", but explicit CLI
  # `--force-delete-gone` must take priority and perform deletion.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "feature/config-override-on"
  echo "FORCE_DELETE_GONE_BRANCHES=false" > "$work_dir/.clean_git_branches.conf"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Deleted remote-gone branches"* ]]
  [[ "$output" == *"feature/config-override-on"* ]]

  run git -C "$work_dir" branch --list feature/config-override-on
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "integration: config parsing tolerates whitespace and case for true-like values" {
  # Real config files are hand-edited, so values may have extra spaces and mixed case (for example ` YeS `).
  # This test confirms the parser is intentionally tolerant and still interprets those forms as enabled.
  # Without this, users could think force-delete is on while the script silently treats it as off.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "feature/config-whitespace-case"
  echo " FORCE_DELETE_GONE_BRANCHES =  YeS  " > "$work_dir/.clean_git_branches.conf"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Deleted remote-gone branches"* ]]
  [[ "$output" == *"feature/config-whitespace-case"* ]]

  run git -C "$work_dir" branch --list feature/config-whitespace-case
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "integration: malformed config value falls back to safe default behavior" {
  # This is the invalid-config safety check. If the setting is not a recognized boolean, the script should
  # choose the safer behavior and only report remote-gone branches instead of deleting them. The assertions
  # verify both: no deletion banner and the branch still present locally.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "feature/config-malformed"
  echo "FORCE_DELETE_GONE_BRANCHES=definitely-not-a-boolean" > "$work_dir/.clean_git_branches.conf"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Remote-gone branches (deletion disabled)"* ]]
  [[ "$output" == *"feature/config-malformed"* ]]
  [[ "$output" != *"Deleted remote-gone branches"* ]]

  run git -C "$work_dir" branch --list feature/config-malformed
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/config-malformed"* ]]
}

@test "integration: verbose flag emits formatted diagnostics for repository state and mode selection" {
  # Verbose mode is a troubleshooting aid. This test verifies the diagnostic sections and key lines remain
  # stable so users can trust the output when debugging behavior.
  local dirs
  local work_dir

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "feature/verbose-gone"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --verbose --no-force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"[verbose] Repository State"* ]]
  [[ "$output" == *"[verbose] Mode Selection"* ]]
  [[ "$output" == *"Repository: "* ]]
  [[ "$output" == *"Current branch: main"* ]]
  [[ "$output" == *"Delete remote-gone mode:         off"* ]]
  [[ "$output" == *"Delete remote-gone effective:    0"* ]]
  [[ "$output" == *"Remote-gone deletion candidates: 1"* ]]
  [[ "$output" == *"Remote-gone mode: deletion disabled (report only)"* ]]
}

@test "integration: branch vv failure exits non-zero with predictable error output" {
  # The script asks Git for a detailed branch list using `git branch -vv`. That list tells us which branches
  # are connected to a remote branch and which ones are no longer connected because the remote branch was
  # deleted. In this test, we force that command to fail on purpose. We expect the script to stop immediately
  # with a clear error, instead of continuing with half-missing data and printing confusing results.
  local dirs
  local work_dir
  local real_git
  local shim_dir
  local shim_git

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "feature/branch-vv-failure"

  real_git="$(command -v git)"
  shim_dir="$TEST_TMPDIR/git-shim-branch-vv"
  shim_git="$shim_dir/git"
  mkdir -p "$shim_dir"
  cat > "$shim_git" <<EOF
#!/usr/bin/env bash
if [ "\${1:-}" = "branch" ] && [ "\${2:-}" = "-vv" ]; then
  echo "simulated git branch -vv failure" >&2
  exit 23
fi
exec "$real_git" "\$@"
EOF
  chmod +x "$shim_git"

  run env PATH="$shim_dir:$PATH" bash -c "cd '$work_dir' && '$repo_root/clean_git_branches.sh' --no-force-delete-gone --silent"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Failed to list branches via 'git branch -vv'."* ]]
}

@test "integration: rev-parse show-toplevel failure falls back safely to current directory" {
  # The script normally asks Git for the repository "top folder" path using
  # `git rev-parse --show-toplevel`. We run from a nested folder and make that command fail once on purpose.
  # The important behavior here is safety: if the script cannot find the top folder in that moment, it should
  # still run in a safe, non-destructive way and avoid deleting branches unexpectedly.
  local dirs
  local work_dir
  local real_git
  local shim_dir
  local shim_git

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"
  create_gone_branch "$work_dir" "feature/rev-parse-fallback-gone"
  mkdir -p "$work_dir/sub/dir"
  echo "FORCE_DELETE_GONE_BRANCHES=true" > "$work_dir/.clean_git_branches.conf"

  real_git="$(command -v git)"
  shim_dir="$TEST_TMPDIR/git-shim"
  shim_git="$shim_dir/git"
  mkdir -p "$shim_dir"
  cat > "$shim_git" <<EOF
#!/usr/bin/env bash
if [ "\${1:-}" = "rev-parse" ] && [ "\${2:-}" = "--show-toplevel" ]; then
  marker_file="$shim_dir/rev-parse-failed-once"
  if [ ! -f "\$marker_file" ]; then
    touch "\$marker_file"
    exit 1
  fi
fi
exec "$real_git" "\$@"
EOF
  chmod +x "$shim_git"

  run env PATH="$shim_dir:$PATH" bash -c "cd '$work_dir/sub/dir' && '$repo_root/clean_git_branches.sh' --silent"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Remote-gone branches (deletion disabled)"* ]]
  [[ "$output" == *"feature/rev-parse-fallback-gone"* ]]
  [[ "$output" != *"Deleted remote-gone branches"* ]]

  run git -C "$work_dir" branch --list feature/rev-parse-fallback-gone
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/rev-parse-fallback-gone"* ]]
}

@test "integration: large branch set executes reliably with mixed branch classes" {
  # This is a stress-style reliability check. We create many tracked, local-only, and remote-gone branches
  # and run the cleanup flow once. The goal is to prove behavior does not degrade as branch counts grow:
  # gone branches are all removed, tracked/local-only branches remain, and classification output still includes
  # representative entries from each class.
  local dirs
  local work_dir
  local i
  local branch_name

  dirs="$(create_repo_with_origin)"
  work_dir="${dirs##*|}"

  for i in $(seq 1 12); do
    create_tracked_branch "$work_dir" "feature/stress-tracked-$i"
    create_local_only_branch "$work_dir" "feature/stress-local-$i"
  done

  for i in $(seq 1 12); do
    branch_name="feature/stress-gone-$i"
    git -C "$work_dir" checkout -b "$branch_name" >/dev/null
    echo "stress gone branch content for $branch_name" >> "$work_dir/README.md"
    git -C "$work_dir" add README.md
    git -C "$work_dir" commit -m "stress gone branch commit for $branch_name" >/dev/null
    git -C "$work_dir" push -u origin "$branch_name" >/dev/null
    git -C "$work_dir" checkout main >/dev/null
    git -C "$work_dir" push origin --delete "$branch_name" >/dev/null
  done
  git -C "$work_dir" fetch --prune >/dev/null

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --force-delete-gone --silent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Deleted remote-gone branches"* ]]
  [[ "$output" == *"feature/stress-gone-1"* ]]
  [[ "$output" == *"feature/stress-gone-12"* ]]
  [[ "$output" == *"Tracked branches"* ]]
  [[ "$output" == *"feature/stress-tracked-1"* ]]
  [[ "$output" == *"feature/stress-tracked-12"* ]]
  [[ "$output" == *"Untracked branches"* ]]
  [[ "$output" == *"feature/stress-local-1"* ]]
  [[ "$output" == *"feature/stress-local-12"* ]]

  run bash -c "git -C '$work_dir' branch --list 'feature/stress-gone-*' | wc -l | tr -d ' '"
  [ "$status" -eq 0 ]
  [ "$output" -eq 0 ]

  run bash -c "git -C '$work_dir' branch --list 'feature/stress-tracked-*' | wc -l | tr -d ' '"
  [ "$status" -eq 0 ]
  [ "$output" -eq 12 ]

  run bash -c "git -C '$work_dir' branch --list 'feature/stress-local-*' | wc -l | tr -d ' '"
  [ "$status" -eq 0 ]
  [ "$output" -eq 12 ]
}
