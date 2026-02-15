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
echo "Creating isolated repository fixture for explicit ancestry-state section reporting..."

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

git switch main >/dev/null 2>&1
git switch -c feature/main-contained >/dev/null 2>&1
printf 'main-contained\n' > main-contained.txt
git add main-contained.txt
git commit -m "Add main-contained branch commit" >/dev/null 2>&1
git push -u origin feature/main-contained >/dev/null 2>&1
git switch main >/dev/null 2>&1
git merge --no-ff feature/main-contained -m "Merge main-contained branch" >/dev/null 2>&1
git push >/dev/null 2>&1

git switch develop >/dev/null 2>&1
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
git push origin feature/head-contained >/dev/null 2>&1
git switch develop >/dev/null 2>&1
git merge --ff-only feature/head-contained >/dev/null 2>&1

section "STATE SUMMARY"
echo "Local branch fixtures:"
echo "- feature/main-contained: merged into main (and still tracked upstream)."
echo "- feature/upstream-contained: not merged into main/develop; tip is present in configured upstream."
echo "- feature/head-contained: merged into current HEAD (develop), but not merged into main."

section "PREVIEW (DEFAULT)"
echo "Expected: ancestry sections render as merged into upstream branches and merged into local develop."
echo "Merged into local is shown only when a branch is not merged into its upstream."
echo "Non-equivalent remains a separate section with inline details per branch."
echo "Any branch details are labeled and indented on child lines under the branch name."
"${CLEAN_SCRIPT}"
