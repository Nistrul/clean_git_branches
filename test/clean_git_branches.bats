#!/usr/bin/env bats

load 'helpers/test_helper.bash'

@test "help flag exits successfully and shows minimal CLI" {
  run "$repo_root/clean_git_branches.sh" --help

  [ "$status" -eq 0 ]
  assert_output_contains "Usage: clean_git_branches"
  assert_output_contains "--apply"
  assert_output_contains "--confirm"
  assert_output_contains "--delete-equivalent"
  assert_output_contains "--equivalence"
  assert_output_contains "--force-delete-equivalent"
  assert_output_contains "--prune"
  [[ "$output" != *"--force-delete-gone"* ]]
  [[ "$output" != *"--no-force-delete-gone"* ]]
  [[ "$output" != *"--delete-patch-equivalent-diverged"* ]]
  [[ "$output" != *"--dry-run"* ]]
  [[ "$output" != *"--silent"* ]]
}

@test "unknown option fails with help output" {
  run "$repo_root/clean_git_branches.sh" --not-a-real-flag

  [ "$status" -eq 1 ]
  assert_output_contains "Unknown option: --not-a-real-flag"
  assert_output_contains "Usage: clean_git_branches"
}

@test "legacy removed option fails" {
  run "$repo_root/clean_git_branches.sh" --force-delete-gone

  [ "$status" -eq 1 ]
  assert_output_contains "Unknown option: --force-delete-gone"
}

@test "invalid equivalence mode fails" {
  run "$repo_root/clean_git_branches.sh" --equivalence nope

  [ "$status" -eq 1 ]
  assert_output_contains "Invalid --equivalence value: nope"
}
