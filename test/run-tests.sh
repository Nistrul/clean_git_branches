#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v bats >/dev/null 2>&1; then
  echo "bats is required to run tests. Install bats-core and rerun test/run-tests.sh." >&2
  exit 127
fi

run_suite() {
  local suite_name="$1"
  local suite_file="$2"
  local start_seconds="$SECONDS"

  if bats "$suite_file"; then
    local status=0
  else
    local status=$?
  fi

  local elapsed_seconds=$((SECONDS - start_seconds))
  printf '[timing] %s suite: %ss\n' "$suite_name" "$elapsed_seconds" >&2
  return "$status"
}

overall_start_seconds="$SECONDS"
overall_status=0

if ! run_suite "mocked/unit" "$repo_root/test/clean_git_branches.bats"; then
  overall_status=1
fi

if ! run_suite "integration" "$repo_root/test/clean_git_branches.integration.bats"; then
  overall_status=1
fi

overall_elapsed_seconds=$((SECONDS - overall_start_seconds))
printf '[timing] full test run: %ss\n' "$overall_elapsed_seconds" >&2

exit "$overall_status"
