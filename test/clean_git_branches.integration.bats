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

  git -C "$work_dir" checkout -b feature/gone >/dev/null
  echo "gone branch content" >> "$work_dir/README.md"
  git -C "$work_dir" add README.md
  git -C "$work_dir" commit -m "gone branch commit" >/dev/null
  git -C "$work_dir" push -u origin feature/gone >/dev/null
  git -C "$work_dir" checkout main >/dev/null

  git -C "$work_dir" push origin --delete feature/gone >/dev/null
  git -C "$work_dir" fetch --prune >/dev/null

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
