#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: test/helpers/run-in-repo.sh <repo-dir> [--cwd <relative-subdir>] [script-args...]" >&2
  exit 1
fi

repo_dir="$1"
shift
run_subdir=""

if [ "${1:-}" = "--cwd" ]; then
  if [ "$#" -lt 2 ]; then
    echo "Missing value for --cwd" >&2
    exit 1
  fi
  run_subdir="$2"
  shift 2
fi

target_dir="$repo_dir"
if [ -n "$run_subdir" ]; then
  target_dir="$repo_dir/$run_subdir"
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

cd "$target_dir"
"$repo_root/clean_git_branches.sh" "$@"
