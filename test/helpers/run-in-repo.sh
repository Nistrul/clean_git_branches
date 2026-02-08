#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: test/helpers/run-in-repo.sh <repo-dir> [script-args...]" >&2
  exit 1
fi

repo_dir="$1"
shift

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

cd "$repo_dir"
"$repo_root/clean_git_branches.sh" "$@"
