#!/usr/bin/env bats

load 'helpers/test_helper.bash'

@test "help flag exits successfully" {
  # Basic CLI contract: help output should succeed and show usage text.
  run "$repo_root/clean_git_branches.sh" --help

  [ "$status" -eq 0 ]
  assert_output_contains "Usage: clean_git_branches"
}

@test "default scenario reports sections with deletion disabled" {
  # Baseline mocked flow: verify normal report sections and key git calls in safe (no force-delete) mode.
  run_with_mock_scenario "test/fixtures/mock-git/default.env" --no-force-delete-gone

  [ "$status" -eq 0 ]
  assert_output_contains "Deleted merged branches"
  assert_output_contains "Remote-gone branches (deletion disabled)"
  assert_output_contains "Tracked branches"
  assert_log_contains "branch --merged"
  assert_log_contains "branch -vv"
}

@test "unknown option fails with help output" {
  # Invalid flags should fail fast and still point users to correct usage.
  run "$repo_root/clean_git_branches.sh" --not-a-real-flag

  [ "$status" -eq 1 ]
  assert_output_contains "Unknown option: --not-a-real-flag"
  assert_output_contains "Usage: clean_git_branches"
}

@test "force delete mode handles partial delete failure" {
  # If one branch delete fails and another succeeds, we still expect clear reporting of both outcomes.
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
  # Branches without upstream tracking are common; the script should continue safely instead of erroring out.
  run_with_mock_scenario "test/fixtures/mock-git/no-upstream.env" --no-force-delete-gone

  [ "$status" -eq 0 ]
  assert_output_contains "Deleted merged branches"
  assert_output_contains "Remote-gone branches (deletion disabled)"
  assert_log_contains "rev-parse --abbrev-ref --symbolic-full-name @{upstream}"
}
