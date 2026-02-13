#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLEAN_SCRIPT="${CLEAN_SCRIPT_OVERRIDE:-${REPO_ROOT}/clean_git_branches.sh}"

if [[ ! -x "${CLEAN_SCRIPT}" ]]; then
  echo "error: expected executable script at ${CLEAN_SCRIPT}" >&2
  exit 1
fi

section() {
  printf '\n\033[1;36m== %s ==\033[0m\n' "$1"
}

temp_root="$(mktemp -d)"
trap 'rm -rf "${temp_root}"' EXIT

origin_repo="${temp_root}/origin.git"
work_repo="${temp_root}/work"

section "SETUP"
echo "Creating isolated repository fixture for ancestry-only merged-state reporting..."

git init --bare "${origin_repo}" >/dev/null 2>&1
git clone "${origin_repo}" "${work_repo}" >/dev/null 2>&1

cd "${work_repo}"
git config user.name "Demo User"
git config user.email "demo@example.com"

printf 'base\n' > README.md
git add README.md
git commit -m "Initial commit" >/dev/null 2>&1
git branch -M main >/dev/null 2>&1
git push -u origin main >/dev/null 2>&1

git switch -c develop >/dev/null 2>&1
git push -u origin develop >/dev/null 2>&1

git switch -c feature/upstream-contained >/dev/null 2>&1
printf 'upstream-contained\n' > upstream-contained.txt
git add upstream-contained.txt
git commit -m "Add upstream-contained branch commit" >/dev/null 2>&1
git push -u origin feature/upstream-contained >/dev/null 2>&1

git switch develop >/dev/null 2>&1
git switch -c feature/head-contained >/dev/null 2>&1
printf 'head-contained\n' > head-contained.txt
git add head-contained.txt
git commit -m "Add head-contained branch commit" >/dev/null 2>&1
git switch develop >/dev/null 2>&1
git merge --ff-only feature/head-contained >/dev/null 2>&1

section "STATE SUMMARY"
echo "Local branch fixtures:"
echo "- feature/upstream-contained: branch tip is present in configured upstream tracking branch."
echo "- feature/head-contained: branch tip is present in current HEAD branch (develop)."
echo "- both branches still contain unique commits vs base main, so they remain non-deletion candidates."

section "PREVIEW (DEFAULT)"
echo "Expected: ancestry-only merged-state reporting should include upstream and head context."
"${CLEAN_SCRIPT}"
