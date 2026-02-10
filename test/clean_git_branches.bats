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

@test "config true enables force delete in auto mode" {
  # Config-driven default should enable deletion without explicit CLI force flag.
  local work_dir="$TEST_TMPDIR/config-true"
  mkdir -p "$work_dir"
  echo "FORCE_DELETE_GONE_BRANCHES=true" > "$work_dir/.clean_git_branches.conf"

  run_with_mock_scenario_in_dir "test/fixtures/mock-git/default.env" "$work_dir" --silent

  [ "$status" -eq 0 ]
  assert_output_contains "Deleted remote-gone branches"
  assert_output_contains "feature/gone"
  assert_log_contains "branch -D feature/gone"
}

@test "cli no-force-delete-gone overrides config true" {
  # Explicit CLI disable must win over config enable.
  local work_dir="$TEST_TMPDIR/config-override-off"
  mkdir -p "$work_dir"
  echo "FORCE_DELETE_GONE_BRANCHES=true" > "$work_dir/.clean_git_branches.conf"

  run_with_mock_scenario_in_dir "test/fixtures/mock-git/default.env" "$work_dir" --no-force-delete-gone --silent

  [ "$status" -eq 0 ]
  assert_output_contains "Remote-gone branches (deletion disabled)"
  assert_output_contains "feature/gone"
}

@test "cli force-delete-gone overrides config false" {
  # Explicit CLI force must win over config disable.
  local work_dir="$TEST_TMPDIR/config-override-on"
  mkdir -p "$work_dir"
  echo "FORCE_DELETE_GONE_BRANCHES=false" > "$work_dir/.clean_git_branches.conf"

  run_with_mock_scenario_in_dir "test/fixtures/mock-git/default.env" "$work_dir" --force-delete-gone --silent

  [ "$status" -eq 0 ]
  assert_output_contains "Deleted remote-gone branches"
  assert_output_contains "feature/gone"
  assert_log_contains "branch -D feature/gone"
}

@test "config parser tolerates whitespace and case true-like values" {
  # Hand-edited config values should still parse as true when semantically true-like.
  local work_dir="$TEST_TMPDIR/config-whitespace-case"
  mkdir -p "$work_dir"
  echo " FORCE_DELETE_GONE_BRANCHES =  YeS  " > "$work_dir/.clean_git_branches.conf"

  run_with_mock_scenario_in_dir "test/fixtures/mock-git/default.env" "$work_dir" --silent

  [ "$status" -eq 0 ]
  assert_output_contains "Deleted remote-gone branches"
  assert_output_contains "feature/gone"
}

@test "malformed config value falls back to safe default behavior" {
  # Invalid values must default to report-only behavior.
  local work_dir="$TEST_TMPDIR/config-malformed"
  mkdir -p "$work_dir"
  echo "FORCE_DELETE_GONE_BRANCHES=definitely-not-a-boolean" > "$work_dir/.clean_git_branches.conf"

  run_with_mock_scenario_in_dir "test/fixtures/mock-git/default.env" "$work_dir" --silent

  [ "$status" -eq 0 ]
  assert_output_contains "Remote-gone branches (deletion disabled)"
  assert_output_contains "feature/gone"
  [[ "$output" != *"Deleted remote-gone branches"* ]]
}

@test "verbose flag emits formatted diagnostics for repository state and mode selection" {
  # Verbose diagnostics are a CLI contract and do not require real Git state transitions.
  local work_dir="$TEST_TMPDIR/verbose-diagnostics"
  mkdir -p "$work_dir"

  run_with_mock_scenario_in_dir "test/fixtures/mock-git/default.env" "$work_dir" --verbose --no-force-delete-gone --silent

  [ "$status" -eq 0 ]
  assert_output_contains "[verbose] Repository State"
  assert_output_contains "[verbose] Mode Selection"
  assert_output_contains "Repository:"
  assert_output_contains "Current branch:"
  assert_output_contains "main"
  assert_output_contains "Delete remote-gone mode:"
  assert_output_contains "off"
  assert_output_contains "Delete remote-gone effective:"
  assert_output_contains "0"
  assert_output_contains "Remote-gone deletion candidates: 1"
  assert_output_contains "Remote-gone mode: deletion disabled (report only)"
}
