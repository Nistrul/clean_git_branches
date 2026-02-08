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

@test "integration: deletes merged branches in real repository" {
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

@test "integration: force deletes remote-gone branches with local origin" {
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

@test "integration: no-force-delete-gone reports gone branches without deleting" {
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

@test "integration: non-interactive force delete requires confirmation without silent flag" {
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

@test "integration: config true enables force delete in auto mode" {
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
