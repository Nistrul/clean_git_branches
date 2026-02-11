#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

print_section() {
  printf '\n\033[1;94m== %s ==\033[0m\n' "$1"
}

cleanup() {
  if [ -n "${demo_tmpdir:-}" ] && [ -d "$demo_tmpdir" ]; then
    rm -rf "$demo_tmpdir"
  fi
}
trap cleanup EXIT

demo_tmpdir="$(mktemp -d -t clean-git-branches-demo-context.XXXXXX)"
fixture_repo="$demo_tmpdir/fixture"

print_section "Fixture setup"
git init "$fixture_repo" >/dev/null
git -C "$fixture_repo" config user.name "Demo User"
git -C "$fixture_repo" config user.email "demo@example.com"
printf 'seed\n' > "$fixture_repo/README.md"
git -C "$fixture_repo" add README.md
git -C "$fixture_repo" commit -m "initial commit" >/dev/null
mkdir -p "$fixture_repo/nested/path"
printf 'Created isolated repo fixture: %s\n' "$fixture_repo"

print_section "Context coverage signal"
context_test_pattern='^@test "integration: subdirectory context coverage validates nested preview and apply behavior"'
context_test_matches="$(rg -n "$context_test_pattern" "$repo_root/test/clean_git_branches.integration.bats" || true)"
if [ -n "$context_test_matches" ]; then
  context_test_count="$(printf '%s\n' "$context_test_matches" | wc -l | tr -d ' ')"
else
  context_test_count="0"
fi
printf 'Subdirectory context integration tests: %s\n' "$context_test_count"

print_section "Targeted integration run"
if [ "$context_test_count" -eq 0 ]; then
  printf 'No context-coverage integration test matches expected ID yet.\n'
else
  bats "$repo_root/test/clean_git_branches.integration.bats" -f "subdirectory context coverage validates nested preview and apply behavior"
fi
