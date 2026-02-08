#!/usr/bin/env bash

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

setup_test_env() {
  export TEST_TMPDIR="$(mktemp -d -t clean-git-branches-test.XXXXXX)"
  export MOCK_GIT_LOG="$TEST_TMPDIR/mock-git.log"
  : > "$MOCK_GIT_LOG"
}

teardown_test_env() {
  rm -rf "$TEST_TMPDIR"
}

setup() {
  setup_test_env
}

teardown() {
  teardown_test_env
}

run_with_mock_scenario() {
  local scenario_file="$1"
  shift

  local scenario_path="$repo_root/$scenario_file"
  if [ ! -f "$scenario_path" ]; then
    echo "Missing scenario file: $scenario_file" >&2
    return 1
  fi

  run env \
    PATH="$repo_root/test/mocks:$PATH" \
    MOCK_GIT_LOG="$MOCK_GIT_LOG" \
    "$repo_root/test/helpers/run-scenario-command.sh" \
    "$scenario_path" \
    "$@"
}

assert_output_contains() {
  local needle="$1"
  [[ "$output" == *"$needle"* ]]
}

assert_log_contains() {
  local needle="$1"
  grep -Fq "$needle" "$MOCK_GIT_LOG"
}
