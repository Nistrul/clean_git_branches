#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLEAN_SCRIPT="${CLEAN_SCRIPT:-${REPO_ROOT}/clean_git_branches.sh}"

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
echo "Creating two non-equivalent branches to validate divergence detail spacing..."

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

git switch -c feature/keep-unique-a >/dev/null 2>&1
printf 'branch a unique change\n' > keep-unique-a.txt
git add keep-unique-a.txt
git commit -m "Add unique branch A change" >/dev/null 2>&1
printf 'branch a follow-up unique change\n' >> keep-unique-a.txt
git add keep-unique-a.txt
git commit -m "Add unique branch A follow-up change" >/dev/null 2>&1
git push -u origin feature/keep-unique-a >/dev/null 2>&1
git switch main >/dev/null 2>&1
git push origin --delete feature/keep-unique-a >/dev/null 2>&1

git switch -c feature/keep-unique-b >/dev/null 2>&1
printf 'branch b unique change\n' > keep-unique-b.txt
git add keep-unique-b.txt
git commit -m "Add unique branch B change" >/dev/null 2>&1
printf 'branch b follow-up unique change\n' >> keep-unique-b.txt
git add keep-unique-b.txt
git commit -m "Add unique branch B follow-up change" >/dev/null 2>&1
git push -u origin feature/keep-unique-b >/dev/null 2>&1
git switch main >/dev/null 2>&1
git push origin --delete feature/keep-unique-b >/dev/null 2>&1

section "PREVIEW"
echo "Expected: divergence details render with clear whitespace between branch groups."
"${CLEAN_SCRIPT}"
