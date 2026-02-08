#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: test/helpers/run-with-mock-git.sh <scenario-file> [script-args...]" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
scenario_file="$1"
shift

if [ ! -f "$scenario_file" ]; then
  echo "Scenario file not found: $scenario_file" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$scenario_file"

log_file="$(mktemp -t mock-git-log.XXXXXX)"
export MOCK_GIT_LOG="$log_file"
export PATH="$repo_root/test/mocks:$PATH"

echo "[mock-git] scenario: $scenario_file" >&2
echo "[mock-git] log: $MOCK_GIT_LOG" >&2

"$repo_root/clean_git_branches.sh" "$@"
