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
SCRIPTED_CONFIRM_RESPONSES="${CLEAN_GIT_BRANCHES_CONFIRM_RESPONSES:-}"
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

COLOR_ENABLED=0
function _clean_git_branches_renderer_stdout_is_tty() {
  if [ -t 1 ] || [ "$ASSUME_TTY_FOR_TESTS" -eq 1 ]; then
    return 0
  fi

  return 1
}

function _clean_git_branches_renderer_init() {
  COLOR_ENABLED=0

  if [ -n "${NO_COLOR:-}" ]; then
    return
  fi

  if _clean_git_branches_renderer_stdout_is_tty; then
    COLOR_ENABLED=1
  fi
}

function _clean_git_branches_renderer_section_token() {
  local title="$1"

  case "$title" in
    "Merged branches")
      printf "cli.color.section.merged"
      ;;
    "Equivalent branches")
      printf "cli.color.section.equivalent"
      ;;
    "Non-equivalent branches"|"Non-equivalent divergence details"|"merged-into-main"|"merged-into-upstream"|"merged-into-head")
      printf "cli.color.section.non_equivalent"
      ;;
    "Safety exclusions")
      printf "cli.color.section.safety"
      ;;
    "Run summary")
      printf "cli.color.section.summary"
      ;;
    "Execution results")
      printf "cli.color.section.execution"
      ;;
    "Deletion failures")
      printf "cli.color.section.error"
      ;;
    *)
      printf "cli.color.section.default"
      ;;
  esac
}

function _clean_git_branches_renderer_token_color() {
  local token="$1"

  case "$token" in
    "cli.color.section.merged")
      printf "1;94"
      ;;
    "cli.color.section.equivalent")
      printf "1;96"
      ;;
    "cli.color.section.non_equivalent")
      printf "1;92"
      ;;
    "cli.color.section.safety")
      printf "1;93"
      ;;
    "cli.color.section.summary")
      printf "1;95"
      ;;
    "cli.color.section.execution")
      printf "1;94"
      ;;
    "cli.color.section.error")
      printf "1;91"
      ;;
    *)
      printf "1;97"
      ;;
  esac
}

function _clean_git_branches_renderer_print_header_line() {
  local text="$1"
  local token="$2"
  local color

  if [ "$COLOR_ENABLED" -eq 1 ]; then
    color=$(_clean_git_branches_renderer_token_color "$token")
    printf "\033[%sm%s\033[0m\n" "$color" "$text"
    return
  fi

  printf "%s\n" "$text"
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
  if [ -n "$upstream" ] && [ "$upstream" != "@{upstream}" ] && [ "$upstream" != "HEAD" ] && echo "$upstream" | grep -q '/'; then
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

function _clean_git_branches_branch_tip_merged_into_ref() {
  local branch="$1"
  local target_ref="$2"

  if [ -z "$target_ref" ]; then
    return 1
  fi

  if ! git rev-parse --verify --quiet "${target_ref}^{commit}" >/dev/null 2>&1; then
    return 1
  fi

  if git merge-base --is-ancestor "$branch" "$target_ref" >/dev/null 2>&1; then
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

function _clean_git_branches_branch_divergence_details() {
  local branch="$1"
  local unique_count
  local sample_subjects
  local sample_line

  unique_count=$(git rev-list --count "$BASE_REF..$branch" 2>/dev/null || echo "0")
  sample_subjects=$(git log "$BASE_REF..$branch" --format='%s' --no-merges 2>/dev/null | awk 'NF {print; if (++count == 2) exit}')

  printf -- "- %s\n" "$branch"
  printf "  branch-only commits vs %s (ancestry): %s\n" "$BASE_REF" "$unique_count"
  if [ -n "$sample_subjects" ]; then
    printf "  sample commit subjects:\n"
    while IFS= read -r sample_line; do
      [ -z "$sample_line" ] && continue
      printf "    - %s\n" "$sample_line"
    done <<< "$sample_subjects"
  fi
}

function _clean_git_branches_confirm_category() {
  local label="$1"
  local count="$2"
  local response

  if [ "$CONFIRM" -ne 1 ] || [ "$count" -eq 0 ]; then
    return 0
  fi

  if [ -n "$SCRIPTED_CONFIRM_RESPONSES" ]; then
    if [[ "$SCRIPTED_CONFIRM_RESPONSES" == *,* ]]; then
      response="${SCRIPTED_CONFIRM_RESPONSES%%,*}"
      SCRIPTED_CONFIRM_RESPONSES="${SCRIPTED_CONFIRM_RESPONSES#*,}"
    else
      response="$SCRIPTED_CONFIRM_RESPONSES"
      SCRIPTED_CONFIRM_RESPONSES=""
    fi
    printf "Delete %s (%s branch(es))? [y/N]: %s\n" "$label" "$count" "$response" >&2
  else
    if [ ! -t 0 ] && [ "$ASSUME_TTY_FOR_TESTS" -ne 1 ]; then
      echo "Cannot prompt for confirmation in non-interactive mode." >&2
      return 2
    fi

    echo
    printf "Delete %s (%s branch(es))? [y/N]: " "$label" "$count" >&2
    read -r response
  fi
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
  local mode="${4:-bullet}"
  local line
  local underline
  local token

  underline=$(_clean_git_branches_repeat_char "${#title}" "─")
  token=$(_clean_git_branches_renderer_section_token "$title")

  _clean_git_branches_renderer_print_header_line "$title" "$token"
  _clean_git_branches_renderer_print_header_line "$underline" "$token"
  if [ -n "$note" ]; then
    if [ "$COLOR_ENABLED" -eq 1 ]; then
      printf "\033[3;37m%s\033[0m\n" "$note"
    else
      printf "%s\n" "$note"
    fi
  fi
  if [ -n "$lines" ]; then
    while IFS= read -r line; do
      if [ "$mode" = "raw" ]; then
        if [ -z "$line" ]; then
          echo
          continue
        fi
        echo "$line"
      else
        [ -z "$line" ] && continue
        echo "- $line"
      fi
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
  local execution_lines
  local failure_lines
  local merged_deleted_count=0
  local equivalent_deleted_count=0
  local equivalent_force_deleted_count=0
  local merged_skipped=0
  local equivalent_skipped=0
  local confirm_status
  local non_equivalent_details=""
  local branch_divergence_details
  local merged_into_main_lines=""
  local merged_into_upstream_lines=""
  local merged_into_head_lines=""
  local merged_into_main_ref=""
  local head_context

  if ! _clean_git_branches_require_git_repo; then
    return 1
  fi

  _clean_git_branches_renderer_init

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
  if git rev-parse --verify --quiet "main^{commit}" >/dev/null 2>&1; then
    merged_into_main_ref="main"
  fi

  _clean_git_branches_verbose "Remote: ${remote_name:-<none>}"
  _clean_git_branches_verbose "Base branch: ${base_branch:-<none>}"
  if [ "$BASE_REF" != "$base_branch" ]; then
    _clean_git_branches_verbose "Base ref: ${BASE_REF:-<none>}"
  fi
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
        branch_divergence_details=$(_clean_git_branches_branch_divergence_details "$branch")
        if [ -n "$non_equivalent_details" ]; then
          non_equivalent_details="${non_equivalent_details}"$'\n\n'
        fi
        non_equivalent_details="${non_equivalent_details}${branch_divergence_details}"
        ;;
    esac

    if [ -n "$merged_into_main_ref" ] && _clean_git_branches_branch_tip_merged_into_ref "$branch" "$merged_into_main_ref"; then
      merged_into_main_lines="${merged_into_main_lines}${branch}"$'\n'
    fi

    if [ -n "$upstream" ] && _clean_git_branches_branch_tip_merged_into_ref "$branch" "$upstream"; then
      merged_into_upstream_lines="${merged_into_upstream_lines}${branch} - ${upstream}"$'\n'
    fi

    if _clean_git_branches_branch_tip_merged_into_ref "$branch" "HEAD"; then
      head_context="${current_branch:-HEAD}"
      merged_into_head_lines="${merged_into_head_lines}${branch} - ${head_context}"$'\n'
    fi

    if [ -n "$exclusion_reason" ]; then
      excluded_lines="${excluded_lines}${branch} - skipped: $exclusion_reason"$'\n'
    fi

    exclusion_reason=""
  done <<< "$branches"

  header_lines=""
  if [ "$APPLY" -eq 1 ]; then
    header_lines="${header_lines}Execution mode: apply"$'\n'
  else
    header_lines="${header_lines}Execution mode: dry-run (preview only)"$'\n'
  fi
  header_lines="${header_lines}Current branch: ${current_branch:-<detached>}"$'\n'
  header_lines="${header_lines}Base branch: ${base_branch:-<none>}"$'\n'
  if [ "$BASE_REF" != "$base_branch" ]; then
    header_lines="${header_lines}Base ref: $BASE_REF"$'\n'
  fi
  if [ "$VERBOSE" -eq 1 ] && [ -n "${VERBOSE_LINES%$'\n'}" ]; then
    header_lines="${header_lines}${VERBOSE_LINES%$'\n'}"$'\n'
  fi

  _clean_git_branches_print_section "Run summary" "" "${header_lines%$'\n'}"

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

  if [ -n "${merged_into_main_lines%$'\n'}" ]; then
    _clean_git_branches_print_section "merged-into-main" "classification only; no deletion behavior changes" "${merged_into_main_lines%$'\n'}"
  fi
  if [ -n "${merged_into_upstream_lines%$'\n'}" ]; then
    _clean_git_branches_print_section "merged-into-upstream" "classification only; no deletion behavior changes" "${merged_into_upstream_lines%$'\n'}"
  fi
  if [ -n "${merged_into_head_lines%$'\n'}" ]; then
    _clean_git_branches_print_section "merged-into-head" "classification only; no deletion behavior changes" "${merged_into_head_lines%$'\n'}"
  fi

  if [ -n "${non_equivalent_lines%$'\n'}" ]; then
    _clean_git_branches_print_section "Non-equivalent branches" "keep: contains unique commits" "${non_equivalent_lines%$'\n'}"
  fi
  if [ -n "${non_equivalent_details%$'\n'}" ]; then
    _clean_git_branches_print_section "Non-equivalent divergence details" "dry-run evidence for non-equivalent branches" "${non_equivalent_details%$'\n'}" "raw"
  fi
  if [ -n "${excluded_lines%$'\n'}" ]; then
    _clean_git_branches_print_section "Safety exclusions" "hard safety rules (never deleted)" "${excluded_lines%$'\n'}"
  fi

  if [ "$APPLY" -ne 1 ]; then
    return 0
  fi

  _clean_git_branches_confirm_category "merged" "$merged_delete_count"
  confirm_status=$?
  if [ "$confirm_status" -ne 0 ]; then
    case "$confirm_status" in
      1)
        merged_skipped=1
        merged_delete_list=""
        ;;
      2)
        return 1
        ;;
    esac
  fi

  _clean_git_branches_confirm_category "equivalent" "$equivalent_delete_count"
  confirm_status=$?
  if [ "$confirm_status" -ne 0 ]; then
    case "$confirm_status" in
      1)
        equivalent_skipped=1
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
      merged_deleted_count=$((merged_deleted_count + 1))
    else
      failure_lines="${failure_lines}merged: $branch"$'\n'
    fi
  done <<< "$merged_delete_list"

  while IFS= read -r branch; do
    [ -z "$branch" ] && continue

    safe_delete_failed=0
    if delete_output=$(git branch -d "$branch" 2>&1); then
      equivalent_deleted_count=$((equivalent_deleted_count + 1))
      continue
    fi

    safe_delete_failed=1

    if [ "$safe_delete_failed" -eq 1 ] && [ "$FORCE_DELETE_EQUIVALENT" -eq 1 ]; then
      if delete_output=$(git branch -D "$branch" 2>&1); then
        equivalent_force_deleted_count=$((equivalent_force_deleted_count + 1))
      else
        failure_lines="${failure_lines}equivalent: $branch"$'\n'
      fi
    else
      failure_lines="${failure_lines}equivalent (safe-delete failed): $branch"$'\n'
    fi
  done <<< "$equivalent_delete_list"

  execution_lines=""
  execution_lines="${execution_lines}Merged deleted: $merged_deleted_count"$'\n'
  execution_lines="${execution_lines}Equivalent deleted (safe): $equivalent_deleted_count"$'\n'
  if [ "$equivalent_force_deleted_count" -gt 0 ]; then
    execution_lines="${execution_lines}Equivalent deleted (force): $equivalent_force_deleted_count"$'\n'
  fi
  if [ "$merged_skipped" -eq 1 ]; then
    execution_lines="${execution_lines}Merged deletions skipped by confirmation"$'\n'
  fi
  if [ "$equivalent_skipped" -eq 1 ]; then
    execution_lines="${execution_lines}Equivalent deletions skipped by confirmation"$'\n'
  fi

  _clean_git_branches_print_section "Execution results" "" "${execution_lines%$'\n'}"
  if [ -n "${failure_lines%$'\n'}" ]; then
    _clean_git_branches_print_section "Deletion failures" "manual review required" "${failure_lines%$'\n'}"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  clean_git_branches
fi
