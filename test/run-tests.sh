#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v bats >/dev/null 2>&1; then
  echo "bats is required to run tests. Install bats-core and rerun test/run-tests.sh." >&2
  exit 127
fi

bats "$repo_root/test/clean_git_branches.bats"
