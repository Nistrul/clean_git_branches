#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: test/helpers/run-scenario-command.sh <scenario-file> [script-args...]" >&2
  exit 1
fi

scenario_file="$1"
shift

# shellcheck disable=SC1090
source "$scenario_file"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

if [ -n "${SCENARIO_RUN_DIR:-}" ]; then
  mkdir -p "$SCENARIO_RUN_DIR"
  cd "$SCENARIO_RUN_DIR"
fi

"$repo_root/clean_git_branches.sh" "$@"
