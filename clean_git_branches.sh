#!/bin/bash
# clean_git_branches.sh
#
# Safe local-branch cleanup utility.

function _clean_git_branches_display_help() {
  cat <<EOF_HELP
Usage: clean_git_branches [--help] [--apply] [--confirm] [--delete-equivalent] [--equivalence {cherry|patch-id}] [--force-delete-equivalent] [--prune] [--verbose]

Default behavior is dry-run. Nothing is deleted unless --apply is provided.

Options:
  --help                     Show this help message and exit
  --apply                    Execute deletions (default is preview only)
  --confirm                  Prompt before each deletion category (merged/equivalent)
  --delete-equivalent        Also delete patch-equivalent branches
  --equivalence METHOD       Equivalence method: cherry|patch-id (default: cherry)
  --force-delete-equivalent  For equivalent branches only, retry with -D if safe delete fails
  --prune                    Run fetch/prune before analysis
  --verbose                  Print detailed diagnostics and per-branch reasoning

Safety rules (always enforced):
  - Never delete current checked-out branch
  - Never delete branches with unpushed commits
  - Never delete branches ahead of upstream
  - Never delete branches with unique (non-equivalent) commits
EOF_HELP
}

APPLY=0
CONFIRM=0
DELETE_EQUIVALENT=0
EQUIVALENCE_METHOD="cherry"
FORCE_DELETE_EQUIVALENT=0
PRUNE=0
VERBOSE=0
ASSUME_TTY_FOR_TESTS="${CLEAN_GIT_BRANCHES_ASSUME_TTY:-0}"
VERBOSE_LINES=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --help)
      _clean_git_branches_display_help
      exit 0
      ;;
    --apply)
      APPLY=1
      ;;
    --confirm)
      CONFIRM=1
      ;;
    --delete-equivalent)
      DELETE_EQUIVALENT=1
      ;;
    --equivalence)
      shift
      if [ -z "${1:-}" ]; then
        echo "Missing value for --equivalence" >&2
        _clean_git_branches_display_help >&2
        exit 1
      fi
      case "$1" in
        cherry|patch-id)
          EQUIVALENCE_METHOD="$1"
          ;;
        *)
          echo "Invalid --equivalence value: $1" >&2
          _clean_git_branches_display_help >&2
          exit 1
          ;;
      esac
      ;;
    --force-delete-equivalent)
      FORCE_DELETE_EQUIVALENT=1
      ;;
    --prune)
      PRUNE=1
      ;;
    --verbose)
      VERBOSE=1
      ;;
    *)
      echo "Unknown option: $1" >&2
      _clean_git_branches_display_help >&2
      exit 1
      ;;
  esac
  shift
done

function _clean_git_branches_verbose() {
  if [ "$VERBOSE" -eq 1 ]; then
    VERBOSE_LINES="${VERBOSE_LINES}$*"$'\n'
  fi
}

function _clean_git_branches_repeat_char() {
  local count="$1"
  local char="$2"
  local output=""

  while [ "$count" -gt 0 ]; do
    output="${output}${char}"
    count=$((count - 1))
  done

  printf "%s" "$output"
}

function _clean_git_branches_header_color() {
  local title="$1"

  case "$title" in
    "Merged branches")
      printf "1;94"
      ;;
    "Equivalent branches")
      printf "1;96"
      ;;
    "Non-equivalent branches")
      printf "1;92"
      ;;
    "Safety exclusions")
      printf "1;93"
      ;;
    "Header")
      printf "1;95"
      ;;
    *)
      printf "1;97"
      ;;
  esac
}

function _clean_git_branches_require_git_repo() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not inside a Git repository." >&2
    return 1
  fi
}

function _clean_git_branches_detect_remote() {
  local upstream
  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>/dev/null || true)
  if [ -n "$upstream" ]; then
    echo "${upstream%%/*}"
    return
  fi

  git remote | head -n 1
}

function _clean_git_branches_detect_base_branch() {
  local remote="$1"
  local remote_head

  if [ -n "$remote" ]; then
    remote_head=$(git symbolic-ref --quiet --short "refs/remotes/$remote/HEAD" 2>/dev/null || true)
    if [ -n "$remote_head" ]; then
      echo "${remote_head#${remote}/}"
      return
    fi
  fi

  if git show-ref --verify --quiet refs/heads/main; then
    echo "main"
    return
  fi

  if git show-ref --verify --quiet refs/heads/master; then
    echo "master"
    return
  fi

  git branch --show-current
}

function _clean_git_branches_resolve_base_ref() {
  local remote="$1"
  local base_branch="$2"

  if git show-ref --verify --quiet "refs/heads/$base_branch"; then
    echo "$base_branch"
    return
  fi

  if [ -n "$remote" ] && git show-ref --verify --quiet "refs/remotes/$remote/$base_branch"; then
    echo "$remote/$base_branch"
    return
  fi

  echo "$base_branch"
}

function _clean_git_branches_is_protected() {
  local branch="$1"
  local pattern="${PROTECTED_BRANCHES:-main|master|prod|dev}"

  if echo "$branch" | egrep -q "^($pattern)$"; then
    return 0
  fi

  return 1
}

function _clean_git_branches_branch_upstream() {
  local branch="$1"
  git for-each-ref --format='%(upstream:short)' "refs/heads/$branch"
}

function _clean_git_branches_branch_has_unpushed() {
  local branch="$1"
  local commit

  commit=$(git rev-list --max-count=1 "$branch" --not --remotes 2>/dev/null || true)
  if [ -n "$commit" ]; then
    return 0
  fi

  return 1
}

function _clean_git_branches_branch_ahead_of_upstream() {
  local branch="$1"
  local upstream
  local counts
  local ahead_count

  upstream=$(_clean_git_branches_branch_upstream "$branch")
  if [ -z "$upstream" ]; then
    return 1
  fi

  counts=$(git rev-list --left-right --count "$upstream...$branch" 2>/dev/null || echo "0 0")
  ahead_count=$(echo "$counts" | awk '{print $2}')
  if [ "${ahead_count:-0}" -gt 0 ]; then
    return 0
  fi

  return 1
}

BASE_PATCH_IDS=""
BASE_PATCH_IDS_READY=0
function _clean_git_branches_load_base_patch_ids() {
  if [ "$BASE_PATCH_IDS_READY" -eq 1 ]; then
    return
  fi

  BASE_PATCH_IDS=$(git log "$BASE_REF" --no-merges -p --pretty=format: 2>/dev/null | git patch-id --stable 2>/dev/null | awk '{print $1}' | sort -u)
  BASE_PATCH_IDS_READY=1
}

function _clean_git_branches_is_equivalent_cherry() {
  local branch="$1"
  local cherry_output

  cherry_output=$(git cherry "$BASE_REF" "$branch" 2>/dev/null || true)
  if [ -z "$cherry_output" ]; then
    return 1
  fi

  if echo "$cherry_output" | grep -q '^+'; then
    return 1
  fi

  if echo "$cherry_output" | grep -q '^-'; then
    return 0
  fi

  return 1
}

function _clean_git_branches_is_equivalent_patch_id() {
  local branch="$1"
  local merge_commit
  local commits
  local commit
  local patch_id

  merge_commit=$(git rev-list --max-count=1 "$BASE_REF..$branch" --merges 2>/dev/null || true)
  if [ -n "$merge_commit" ]; then
    return 1
  fi

  commits=$(git rev-list "$BASE_REF..$branch" --no-merges 2>/dev/null || true)
  if [ -z "$commits" ]; then
    return 1
  fi

  _clean_git_branches_load_base_patch_ids
  for commit in $commits; do
    patch_id=$(git show --pretty=format: --no-notes --no-color "$commit" 2>/dev/null | git patch-id --stable 2>/dev/null | awk 'NR==1 {print $1}')
    if [ -z "$patch_id" ]; then
      return 1
    fi

    if ! echo "$BASE_PATCH_IDS" | grep -Fxq "$patch_id"; then
      return 1
    fi
  done

  return 0
}

function _clean_git_branches_is_equivalent() {
  local branch="$1"

  case "$EQUIVALENCE_METHOD" in
    cherry)
      _clean_git_branches_is_equivalent_cherry "$branch"
      ;;
    patch-id)
      _clean_git_branches_is_equivalent_patch_id "$branch"
      ;;
    *)
      return 1
      ;;
  esac
}

function _clean_git_branches_confirm_category() {
  local label="$1"
  local count="$2"
  local response

  if [ "$CONFIRM" -ne 1 ] || [ "$count" -eq 0 ]; then
    return 0
  fi

  if [ ! -t 0 ] && [ "$ASSUME_TTY_FOR_TESTS" -ne 1 ]; then
    echo "Cannot prompt for confirmation in non-interactive mode." >&2
    return 2
  fi

  echo
  printf "Delete %s (%s branch(es))? [y/N]: " "$label" "$count" >&2
  read -r response
  case "$response" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

function _clean_git_branches_print_section() {
  local title="$1"
  local note="$2"
  local lines="$3"
  local line
  local underline
  local color

  underline=$(_clean_git_branches_repeat_char "${#title}" "─")
  color=$(_clean_git_branches_header_color "$title")

  printf "\033[%sm%s\033[0m\n" "$color" "$title"
  printf "\033[%sm%s\033[0m\n" "$color" "$underline"
  if [ -n "$note" ]; then
    printf "\033[3;37m%s\033[0m\n" "$note"
  fi
  if [ -n "$lines" ]; then
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      echo "- $line"
    done <<< "$lines"
  fi
  echo
}

function clean_git_branches() {
  local current_branch
  local remote_name
  local base_branch
  local branch
  local branches
  local merged_lines=""
  local equivalent_lines=""
  local non_equivalent_lines=""
  local excluded_lines=""
  local merged_delete_list=""
  local equivalent_delete_list=""
  local merged_delete_count=0
  local equivalent_delete_count=0
  local redundant_type
  local upstream
  local safety_reasons
  local exclusion_reason
  local delete_output
  local safe_delete_failed
  local merged_note
  local equivalent_note
  local header_lines

  if ! _clean_git_branches_require_git_repo; then
    return 1
  fi

  if [ "$PRUNE" -eq 1 ]; then
    _clean_git_branches_verbose "Running fetch --prune before analysis"
    if ! git fetch --prune >/dev/null 2>&1; then
      echo "Failed to run git fetch --prune." >&2
      return 1
    fi
  fi

  current_branch=$(git branch --show-current)
  remote_name=$(_clean_git_branches_detect_remote)
  base_branch=$(_clean_git_branches_detect_base_branch "$remote_name")
  BASE_REF=$(_clean_git_branches_resolve_base_ref "$remote_name" "$base_branch")

  _clean_git_branches_verbose "Current branch: ${current_branch:-<detached>}"
  _clean_git_branches_verbose "Remote: ${remote_name:-<none>}"
  _clean_git_branches_verbose "Base branch: ${base_branch:-<none>}"
  _clean_git_branches_verbose "Base ref: ${BASE_REF:-<none>}"
  _clean_git_branches_verbose "Mode: $([ "$APPLY" -eq 1 ] && echo apply || echo dry-run)"
  _clean_git_branches_verbose "Delete equivalent: $DELETE_EQUIVALENT"
  _clean_git_branches_verbose "Equivalence method: $EQUIVALENCE_METHOD"
  _clean_git_branches_verbose "Force delete equivalent: $FORCE_DELETE_EQUIVALENT"

  branches=$(git for-each-ref --format='%(refname:short)' refs/heads | sort)

  while IFS= read -r branch; do
    [ -z "$branch" ] && continue

    if [ "$branch" = "$current_branch" ]; then
      excluded_lines="${excluded_lines}${branch} - skipped: current checked-out branch"$'\n'
      continue
    fi

    if _clean_git_branches_is_protected "$branch"; then
      excluded_lines="${excluded_lines}${branch} - skipped: protected branch"$'\n'
      continue
    fi

    if git merge-base --is-ancestor "$branch" "$BASE_REF" >/dev/null 2>&1; then
      redundant_type="merged"
    elif _clean_git_branches_is_equivalent "$branch"; then
      redundant_type="equivalent"
    else
      redundant_type="non-equivalent"
    fi

    safety_reasons=""
    upstream=$(_clean_git_branches_branch_upstream "$branch")

    if _clean_git_branches_branch_has_unpushed "$branch"; then
      safety_reasons="has unpushed commits"
    fi

    if _clean_git_branches_branch_ahead_of_upstream "$branch"; then
      if [ -n "$safety_reasons" ]; then
        safety_reasons="$safety_reasons; ahead of upstream"
      else
        safety_reasons="ahead of upstream"
      fi
    fi

    case "$redundant_type" in
      merged)
        if [ -n "$safety_reasons" ]; then
          exclusion_reason="$safety_reasons"
        elif [ "$APPLY" -eq 1 ]; then
          merged_delete_list="${merged_delete_list}${branch}"$'\n'
          merged_delete_count=$((merged_delete_count + 1))
        fi

        merged_lines="${merged_lines}${branch}"$'\n'
        ;;
      equivalent)
        if [ "$DELETE_EQUIVALENT" -ne 1 ]; then
          :
        elif [ -n "$safety_reasons" ]; then
          exclusion_reason="$safety_reasons"
        elif [ "$APPLY" -eq 1 ]; then
          equivalent_delete_list="${equivalent_delete_list}${branch}"$'\n'
          equivalent_delete_count=$((equivalent_delete_count + 1))
        fi

        equivalent_lines="${equivalent_lines}${branch}"$'\n'
        ;;
      non-equivalent)
        non_equivalent_lines="${non_equivalent_lines}${branch}"$'\n'
        ;;
    esac

    if [ -n "$exclusion_reason" ]; then
      excluded_lines="${excluded_lines}${branch} - skipped: $exclusion_reason"$'\n'
    fi

    if [ "$VERBOSE" -eq 1 ]; then
      _clean_git_branches_verbose "branch=$branch type=$redundant_type upstream=${upstream:-<none>} safety=${safety_reasons:-none}"
    fi
    exclusion_reason=""
  done <<< "$branches"

  header_lines=""
  if [ "$APPLY" -eq 1 ]; then
    header_lines="${header_lines}Execution mode: apply"$'\n'
  else
    header_lines="${header_lines}Execution mode: dry-run (preview only)"$'\n'
  fi
  header_lines="${header_lines}Base ref: $BASE_REF"$'\n'
  if [ "$VERBOSE" -eq 1 ] && [ -n "${VERBOSE_LINES%$'\n'}" ]; then
    header_lines="${header_lines}${VERBOSE_LINES%$'\n'}"$'\n'
  fi

  _clean_git_branches_print_section "Header" "" "${header_lines%$'\n'}"

  if [ "$APPLY" -eq 1 ]; then
    merged_note="fully merged into $BASE_REF; candidates are deleted with git branch -d"
  else
    merged_note="fully merged into $BASE_REF; preview only (use --apply to delete)"
  fi
  if [ -n "${merged_lines%$'\n'}" ]; then
    _clean_git_branches_print_section "Merged branches" "$merged_note" "${merged_lines%$'\n'}"
  fi

  equivalent_note="patch-equivalent to $BASE_REF via $EQUIVALENCE_METHOD; default keep (use --delete-equivalent to include deletion)"
  if [ "$DELETE_EQUIVALENT" -eq 1 ]; then
    if [ "$APPLY" -eq 1 ]; then
      equivalent_note="patch-equivalent to $BASE_REF via $EQUIVALENCE_METHOD; candidates are deleted with git branch -d"
    else
      equivalent_note="patch-equivalent to $BASE_REF via $EQUIVALENCE_METHOD; preview only (use --apply to delete)"
    fi
  fi
  if [ -n "${equivalent_lines%$'\n'}" ]; then
    _clean_git_branches_print_section "Equivalent branches" "$equivalent_note" "${equivalent_lines%$'\n'}"
  fi

  if [ -n "${non_equivalent_lines%$'\n'}" ]; then
    _clean_git_branches_print_section "Non-equivalent branches" "keep: contains unique commits" "${non_equivalent_lines%$'\n'}"
  fi
  if [ -n "${excluded_lines%$'\n'}" ]; then
    _clean_git_branches_print_section "Safety exclusions" "hard safety rules (never deleted)" "${excluded_lines%$'\n'}"
  fi

  if [ "$APPLY" -ne 1 ]; then
    return 0
  fi

  if ! _clean_git_branches_confirm_category "merged" "$merged_delete_count"; then
    case "$?" in
      1)
        echo "Skipped merged deletions."
        merged_delete_list=""
        ;;
      2)
        return 1
        ;;
    esac
  fi

  if ! _clean_git_branches_confirm_category "equivalent" "$equivalent_delete_count"; then
    case "$?" in
      1)
        echo "Skipped equivalent deletions."
        equivalent_delete_list=""
        ;;
      2)
        return 1
        ;;
    esac
  fi

  while IFS= read -r branch; do
    [ -z "$branch" ] && continue
    if delete_output=$(git branch -d "$branch" 2>&1); then
      echo "Deleted merged branch: $branch"
    else
      echo "Could not delete merged branch: $branch"
    fi
  done <<< "$merged_delete_list"

  while IFS= read -r branch; do
    [ -z "$branch" ] && continue

    safe_delete_failed=0
    if delete_output=$(git branch -d "$branch" 2>&1); then
      echo "Deleted equivalent branch: $branch"
      continue
    fi

    safe_delete_failed=1

    if [ "$safe_delete_failed" -eq 1 ] && [ "$FORCE_DELETE_EQUIVALENT" -eq 1 ]; then
      if delete_output=$(git branch -D "$branch" 2>&1); then
        echo "Deleted equivalent branch with force: $branch"
      else
        echo "Could not delete equivalent branch: $branch"
      fi
    else
      echo "Could not safely delete equivalent branch: $branch"
    fi
  done <<< "$equivalent_delete_list"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  clean_git_branches
fi
