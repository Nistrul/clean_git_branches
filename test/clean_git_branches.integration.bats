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

  echo "$work_dir"
}

create_merged_branch() {
  local work_dir="$1"
  local branch_name="$2"

  git -C "$work_dir" checkout -b "$branch_name" >/dev/null
  echo "merged branch content" >> "$work_dir/README.md"
  git -C "$work_dir" add README.md
  git -C "$work_dir" commit -m "merged branch commit" >/dev/null
  git -C "$work_dir" checkout main >/dev/null
  git -C "$work_dir" merge --no-ff "$branch_name" -m "merge $branch_name" >/dev/null
  git -C "$work_dir" push origin main >/dev/null
}

create_equivalent_diverged_branch() {
  local work_dir="$1"
  local branch_name="$2"
  local branch_file

  branch_file="${branch_name//\//_}.txt"

  git -C "$work_dir" checkout -b "$branch_name" >/dev/null
  echo "equivalent content for $branch_name" > "$work_dir/$branch_file"
  git -C "$work_dir" add "$branch_file"
  git -C "$work_dir" commit -m "equivalent commit for $branch_name" >/dev/null
  git -C "$work_dir" push -u origin "$branch_name" >/dev/null
  git -C "$work_dir" branch --unset-upstream "$branch_name" >/dev/null

  git -C "$work_dir" checkout main >/dev/null
  echo "main divergence anchor for $branch_name" >> "$work_dir/README.md"
  git -C "$work_dir" add README.md
  git -C "$work_dir" commit -m "main divergence anchor for $branch_name" >/dev/null
  git -C "$work_dir" cherry-pick "$branch_name" >/dev/null
  git -C "$work_dir" push origin main >/dev/null
}

make_equivalent_branch_ahead_unpushed() {
  local work_dir="$1"
  local branch_name="$2"
  local branch_file

  branch_file="${branch_name//\//_}_ahead.txt"

  create_equivalent_diverged_branch "$work_dir" "$branch_name"

  git -C "$work_dir" checkout "$branch_name" >/dev/null
  echo "unpushed but equivalent content for $branch_name" > "$work_dir/$branch_file"
  git -C "$work_dir" add "$branch_file"
  git -C "$work_dir" commit -m "ahead local equivalent commit for $branch_name" >/dev/null

  git -C "$work_dir" checkout main >/dev/null
  git -C "$work_dir" cherry-pick "$branch_name" >/dev/null
  git -C "$work_dir" push origin main >/dev/null
}

create_non_equivalent_branch() {
  local work_dir="$1"
  local branch_name="$2"

  git -C "$work_dir" checkout -b "$branch_name" >/dev/null
  echo "unique content for $branch_name" > "$work_dir/${branch_name//\//_}_unique.txt"
  git -C "$work_dir" add .
  git -C "$work_dir" commit -m "unique commit for $branch_name" >/dev/null
  git -C "$work_dir" push -u origin "$branch_name" >/dev/null
  git -C "$work_dir" checkout main >/dev/null
}

@test "integration: dirty worktree coverage validates preview and apply cleanup behavior" {
  local work_dir

  work_dir="$(create_repo_with_origin)"
  create_merged_branch "$work_dir" "feature/dirty-worktree-merged"
  echo "dirty tracked change" >> "$work_dir/README.md"
  echo "dirty untracked change" > "$work_dir/local-notes.txt"

  run env NO_COLOR= "$repo_root/test/helpers/run-in-repo.sh" "$work_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Execution mode: dry-run (preview only)"* ]]
  [[ "$output" == *"Current branch: main"* ]]
  [[ "$output" == *"Merged branches"* ]]
  [[ "$output" == *"feature/dirty-worktree-merged"* ]]
  [[ "$output" == *"preview only (use --apply to delete)"* ]]

  run git -C "$work_dir" branch --list feature/dirty-worktree-merged
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/dirty-worktree-merged"* ]]
  [[ "$output" != *$'\033['* ]]

  run git -C "$work_dir" status --short
  [ "$status" -eq 0 ]
  [[ "$output" == *" M README.md"* ]]
  [[ "$output" == *"?? local-notes.txt"* ]]

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --apply

  [ "$status" -eq 0 ]
  [[ "$output" == *"Execution results"* ]]
  [[ "$output" == *"Merged deleted: 1"* ]]

  run git -C "$work_dir" branch --list feature/dirty-worktree-merged
  [ "$status" -eq 0 ]
  [ -z "$output" ]

  run git -C "$work_dir" status --short
  [ "$status" -eq 0 ]
  [[ "$output" == *" M README.md"* ]]
  [[ "$output" == *"?? local-notes.txt"* ]]
}

@test "integration: subdirectory context coverage validates nested preview and apply behavior" {
  local work_dir

  work_dir="$(create_repo_with_origin)"
  create_merged_branch "$work_dir" "feature/subdir-merged"
  create_non_equivalent_branch "$work_dir" "feature/subdir-non-equivalent"
  mkdir -p "$work_dir/nested/path"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --cwd nested/path

  [ "$status" -eq 0 ]
  [[ "$output" == *"Execution mode: dry-run (preview only)"* ]]
  [[ "$output" == *"Merged branches"* ]]
  [[ "$output" == *"feature/subdir-merged"* ]]
  [[ "$output" == *"Non-equivalent branches"* ]]
  [[ "$output" == *"feature/subdir-non-equivalent"* ]]

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --cwd nested/path --apply

  [ "$status" -eq 0 ]
  [[ "$output" == *"Execution results"* ]]
  [[ "$output" == *"Merged deleted: 1"* ]]
  [[ "$output" == *"feature/subdir-non-equivalent"* ]]

  run git -C "$work_dir" branch --list feature/subdir-merged
  [ "$status" -eq 0 ]
  [ -z "$output" ]

  run git -C "$work_dir" branch --list feature/subdir-non-equivalent
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/subdir-non-equivalent"* ]]
}

@test "integration: renderer emits color on TTY output" {
  local work_dir

  work_dir="$(create_repo_with_origin)"

  run env NO_COLOR= CLEAN_GIT_BRANCHES_ASSUME_TTY=1 "$repo_root/test/helpers/run-in-repo.sh" "$work_dir"

  [ "$status" -eq 0 ]
  [[ "$output" == *$'\033['* ]]
}

@test "integration: NO_COLOR suppresses color even when TTY is assumed" {
  local work_dir

  work_dir="$(create_repo_with_origin)"

  run env CLEAN_GIT_BRANCHES_ASSUME_TTY=1 NO_COLOR=1 "$repo_root/test/helpers/run-in-repo.sh" "$work_dir"

  [ "$status" -eq 0 ]
  [[ "$output" != *$'\033['* ]]
}

@test "integration: remote detection falls back when upstream resolves to literal token" {
  local work_dir
  local shim_dir
  local real_git

  work_dir="$(create_repo_with_origin)"
  shim_dir="$TEST_TMPDIR/git-shim"
  mkdir -p "$shim_dir"
  real_git="$(command -v git)"

  cat > "$shim_dir/git" <<EOF_SHIM
#!/usr/bin/env bash
if [ "\$1" = "rev-parse" ] && [ "\${2:-}" = "--abbrev-ref" ] && [ "\${3:-}" = "--symbolic-full-name" ] && [ "\${4:-}" = "@{upstream}" ]; then
  echo "@{upstream}"
  exit 0
fi
exec "$real_git" "\$@"
EOF_SHIM
  chmod +x "$shim_dir/git"

  run env PATH="$shim_dir:$PATH" "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --verbose

  [ "$status" -eq 0 ]
  [[ "$output" == *"Remote: origin"* ]]
  [[ "$output" != *"Remote: @{upstream}"* ]]
}

@test "integration: apply never deletes non-equivalent branches" {
  local work_dir

  work_dir="$(create_repo_with_origin)"
  create_non_equivalent_branch "$work_dir" "feature/non-equivalent"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --apply --delete-equivalent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Non-equivalent branches"* ]]
  [[ "$output" == *"keep: contains unique commits"* ]]
  [[ "$output" == *"feature/non-equivalent"* ]]

  run git -C "$work_dir" branch --list feature/non-equivalent
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/non-equivalent"* ]]
}

@test "integration: equivalent branch requires force flag when safe delete fails" {
  local work_dir

  work_dir="$(create_repo_with_origin)"
  create_equivalent_diverged_branch "$work_dir" "feature/equivalent-safe-fail"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --apply --delete-equivalent --equivalence cherry

  [ "$status" -eq 0 ]
  [[ "$output" == *"patch-equivalent to main via cherry; candidates are deleted with git branch -d"* ]]
  [[ "$output" == *"feature/equivalent-safe-fail"* ]]
  [[ "$output" == *"Deletion failures"* ]]
  [[ "$output" == *"equivalent (safe-delete failed): feature/equivalent-safe-fail"* ]]

  run git -C "$work_dir" branch --list feature/equivalent-safe-fail
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/equivalent-safe-fail"* ]]
}

@test "integration: cherry mode force deletes equivalent branch when enabled" {
  local work_dir

  work_dir="$(create_repo_with_origin)"
  create_equivalent_diverged_branch "$work_dir" "feature/equivalent-cherry-force"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --apply --delete-equivalent --equivalence cherry --force-delete-equivalent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Execution results"* ]]
  [[ "$output" == *"Equivalent deleted (force): 1"* ]]

  run git -C "$work_dir" branch --list feature/equivalent-cherry-force
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "integration: patch-id mode force deletes equivalent branch when enabled" {
  local work_dir

  work_dir="$(create_repo_with_origin)"
  create_equivalent_diverged_branch "$work_dir" "feature/equivalent-patch-id"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --apply --delete-equivalent --equivalence patch-id --force-delete-equivalent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Execution results"* ]]
  [[ "$output" == *"Equivalent deleted (force): 1"* ]]

  run git -C "$work_dir" branch --list feature/equivalent-patch-id
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "integration: ahead and unpushed equivalent branch is never deleted" {
  local work_dir

  work_dir="$(create_repo_with_origin)"
  make_equivalent_branch_ahead_unpushed "$work_dir" "feature/equivalent-ahead-unpushed"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --apply --delete-equivalent --force-delete-equivalent

  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/equivalent-ahead-unpushed"* ]]
  [[ "$output" == *"feature/equivalent-ahead-unpushed - skipped:"* ]]
  [[ "$output" == *"has unpushed commits"* ]]
  [[ "$output" == *"Equivalent deleted (safe): 0"* ]]
  [[ "$output" != *"Equivalent deleted (force): 1"* ]]

  run git -C "$work_dir" branch --list feature/equivalent-ahead-unpushed
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/equivalent-ahead-unpushed"* ]]
}

@test "integration: confirm prompts once per deletion category" {
  local work_dir

  work_dir="$(create_repo_with_origin)"
  create_merged_branch "$work_dir" "feature/merged-confirm"
  create_equivalent_diverged_branch "$work_dir" "feature/equivalent-confirm"

  run env CLEAN_GIT_BRANCHES_CONFIRM_RESPONSES="n,y" "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --apply --confirm --delete-equivalent --force-delete-equivalent

  [ "$status" -eq 0 ]
  [[ "$output" == *"Delete merged (1 branch(es))? [y/N]:"* ]]
  [[ "$output" == *"Delete equivalent (1 branch(es))? [y/N]:"* ]]
  [[ "$output" == *"Equivalent deleted (force): 1"* ]]

  run git -C "$work_dir" rev-parse --verify --quiet refs/heads/feature/merged-confirm
  [ "$status" -eq 0 ]
  [[ -n "$output" ]]

  run git -C "$work_dir" rev-parse --verify --quiet refs/heads/feature/equivalent-confirm
  [ "$status" -eq 1 ]
}

@test "integration: prune flag runs safely with analysis" {
  local work_dir

  work_dir="$(create_repo_with_origin)"
  create_non_equivalent_branch "$work_dir" "feature/prune-check"

  run "$repo_root/test/helpers/run-in-repo.sh" "$work_dir" --prune

  [ "$status" -eq 0 ]
  [[ "$output" == *"Execution mode: dry-run (preview only)"* ]]
  [[ "$output" == *"feature/prune-check"* ]]
}
