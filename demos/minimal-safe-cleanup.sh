#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLEAN_SCRIPT="${REPO_ROOT}/clean_git_branches.sh"

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
echo "Creating isolated temporary repositories and deterministic branch fixtures..."

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

git switch -c feature/merged-cleanup >/dev/null 2>&1
printf 'merged branch change\n' > merged.txt
git add merged.txt
git commit -m "Add merged branch change" >/dev/null 2>&1
git push -u origin feature/merged-cleanup >/dev/null 2>&1
git switch main >/dev/null 2>&1
git merge --no-ff feature/merged-cleanup -m "Merge merged-cleanup branch" >/dev/null 2>&1
git push >/dev/null 2>&1
git push origin --delete feature/merged-cleanup >/dev/null 2>&1

git switch -c feature/equivalent-cleanup >/dev/null 2>&1
printf 'equivalent branch change\n' > equivalent.txt
git add equivalent.txt
git commit -m "Add equivalent branch change" >/dev/null 2>&1
equivalent_commit="$(git rev-parse HEAD)"
git push -u origin feature/equivalent-cleanup >/dev/null 2>&1
git switch main >/dev/null 2>&1
printf 'force divergence before cherry-pick\n' >> README.md
git add README.md
git commit -m "Create divergence before equivalent cherry-pick" >/dev/null 2>&1
git cherry-pick "${equivalent_commit}" >/dev/null 2>&1
git push >/dev/null 2>&1
git push origin --delete feature/equivalent-cleanup >/dev/null 2>&1

git switch -c feature/keep-unique >/dev/null 2>&1
printf 'non equivalent branch change\n' > keep-unique.txt
git add keep-unique.txt
git commit -m "Add unique branch change" >/dev/null 2>&1
git push -u origin feature/keep-unique >/dev/null 2>&1
git switch main >/dev/null 2>&1
git push origin --delete feature/keep-unique >/dev/null 2>&1

section "STATE SUMMARY"
echo "Local branch fixtures:"
echo "- feature/merged-cleanup: merged and remote-gone (safe delete candidate)"
echo "- feature/equivalent-cleanup: patch-equivalent diverged and remote-gone"
echo "- feature/keep-unique: remote-gone with unique commits (must not delete)"

section "PREVIEW (DEFAULT)"
echo "Expected: merged candidates only; equivalent and unique branches remain protected by default."
"${CLEAN_SCRIPT}"

section "PREVIEW (WITH --delete-equivalent)"
echo "Expected: merged + equivalent candidates; unique branch remains protected."
"${CLEAN_SCRIPT}" --delete-equivalent
