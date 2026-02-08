#!/usr/bin/env bats

load 'helpers/test_helper.bash'

@test "help flag exits successfully" {
  run "$repo_root/clean_git_branches.sh" --help

  [ "$status" -eq 0 ]
  assert_output_contains "Usage: clean_git_branches"
}

@test "default scenario reports sections with deletion disabled" {
  run_with_mock_scenario "test/fixtures/mock-git/default.env" --no-force-delete-gone

  [ "$status" -eq 0 ]
  assert_output_contains "Deleted merged branches"
  assert_output_contains "Remote-gone branches (deletion disabled)"
  assert_output_contains "Tracked branches"
  assert_log_contains "branch --merged"
  assert_log_contains "branch -vv"
}

@test "unknown option fails with help output" {
  run "$repo_root/clean_git_branches.sh" --not-a-real-flag

  [ "$status" -eq 1 ]
  assert_output_contains "Unknown option: --not-a-real-flag"
  assert_output_contains "Usage: clean_git_branches"
}

@test "force delete mode handles partial delete failure" {
  run_with_mock_scenario "test/fixtures/mock-git/delete-failure.env" --force-delete-gone --silent

  [ "$status" -eq 0 ]
  assert_output_contains "Deleted remote-gone branches"
  assert_output_contains "delete-ok"
  assert_output_contains "Remote-gone branches (not deleted)"
  assert_output_contains "cannot-delete"
  assert_log_contains "branch -D cannot-delete"
  assert_log_contains "branch -D delete-ok"
}

@test "missing upstream does not fail overall command" {
  run_with_mock_scenario "test/fixtures/mock-git/no-upstream.env" --no-force-delete-gone

  [ "$status" -eq 0 ]
  assert_output_contains "Deleted merged branches"
  assert_output_contains "Remote-gone branches (deletion disabled)"
  assert_log_contains "rev-parse --abbrev-ref --symbolic-full-name @{upstream}"
}
