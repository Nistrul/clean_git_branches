#!/bin/bash
# clean_git_branches.sh
#
# A script to clean up git branches, including deleting merged branches,
# listing untracked, deleted, tracked, and protected branches.
#
# Copyright (C) 2023 Dale Freya
# This program is released under the terms of the MIT License.


# Display help
#
# Usage: _clean_git_branches_display_help
#
# This function displays a help message with usage instructions and available options for the
# clean_git_branches script. It provides an overview of the script's purpose, the actions it
# performs, and the supported command-line options and environment variables.
function _clean_git_branches_display_help() {
  cat <<EOF
Usage: clean_git_branches [--help] [--diagnose] [--force-delete-gone|--no-force-delete-gone] [--dry-run] [--silent]

This script is a utility to help manage your Git branches. It performs the following actions:

- Deletes merged branches, excluding protected branches
- Force deletes remote-gone branches when enabled
- Lists untracked branches
- Lists remote-gone branches that were not deleted
- Lists tracked branches, excluding protected branches
- Lists protected branches

Options:
  --help             Show this help message and exit
  --diagnose         Print diagnostic information while running
  --force-delete-gone      Force delete remote-gone branches (-D)
  --no-force-delete-gone   Do not delete remote-gone branches
  --dry-run                Show what would be deleted without deleting
  --silent                 Skip interactive confirmation prompt (dangerous)

Environment Variables:
  PROTECTED_BRANCHES   A pipe-separated list of protected branches, e.g., "main|master|prod|dev".
                       Defaults to "main|master|prod|dev" if not set.

Repository Config:
  .clean_git_branches.conf
    FORCE_DELETE_GONE_BRANCHES=true|false
    Defaults to false when unset. Command-line flags override config.

EOF
}

DIAGNOSE=0
DELETE_GONE_MODE="auto"
DRY_RUN=0
SILENT=0
for arg in "$@"; do
  case "$arg" in
    --help)
      _clean_git_branches_display_help
      exit 0
      ;;
    --diagnose)
      DIAGNOSE=1
      ;;
    --force-delete-gone)
      DELETE_GONE_MODE="on"
      ;;
    --no-force-delete-gone)
      DELETE_GONE_MODE="off"
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --silent)
      SILENT=1
      ;;
    *)
      echo "Unknown option: $arg" >&2
      _clean_git_branches_display_help >&2
      exit 1
      ;;
  esac
done

function _clean_git_branches_diagnose() {
  if [ "$DIAGNOSE" -eq 1 ]; then
    echo -e "\033[0;36m[diagnose]\033[0m $*" >&2
  fi
}

function _clean_git_branches_load_delete_gone_default() {
  local repo_root
  local config_file
  local config_value

  repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  config_file="$repo_root/.clean_git_branches.conf"

  DELETE_GONE_DEFAULT=0
  if [ -f "$config_file" ]; then
    config_value=$(grep -E '^[[:space:]]*FORCE_DELETE_GONE_BRANCHES[[:space:]]*=' "$config_file" | tail -n 1 | cut -d '=' -f 2- | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    if [ "$config_value" = "true" ] || [ "$config_value" = "1" ] || [ "$config_value" = "yes" ]; then
      DELETE_GONE_DEFAULT=1
    fi
    _clean_git_branches_diagnose "Config file: $config_file"
    _clean_git_branches_diagnose "Config FORCE_DELETE_GONE_BRANCHES: ${config_value:-unset}"
  else
    _clean_git_branches_diagnose "Config file: (none)"
  fi
}

function _clean_git_branches_should_delete_gone() {
  _clean_git_branches_load_delete_gone_default

  case "$DELETE_GONE_MODE" in
    on)
      DELETE_GONE_EFFECTIVE=1
      ;;
    off)
      DELETE_GONE_EFFECTIVE=0
      ;;
    *)
      DELETE_GONE_EFFECTIVE=$DELETE_GONE_DEFAULT
      ;;
  esac

  _clean_git_branches_diagnose "Delete remote-gone mode: $DELETE_GONE_MODE"
  _clean_git_branches_diagnose "Delete remote-gone effective: $DELETE_GONE_EFFECTIVE"
  _clean_git_branches_diagnose "Dry run: $DRY_RUN"
  _clean_git_branches_diagnose "Silent: $SILENT"
}

# Delete merged branches, excluding protected branches
#
# Usage: clean_git_branches_delete_merged
#
# This function deletes all branches that have been merged into the
# current branch, excluding branches specified in the PROTECTED_BRANCHES
# environment variable. If PROTECTED_BRANCHES is not set, it defaults to
# "main|master|prod|dev".
function _clean_git_branches_delete_merged() {
  local merged_candidates

  if [ -z "$PROTECTED_BRANCHES" ]; then
    PROTECTED_BRANCHES="main|master|prod|dev"
  fi

  merged_candidates=$(git branch --merged | egrep -v "(^\*|$PROTECTED_BRANCHES)")
  _clean_git_branches_diagnose "Protected branch regex: $PROTECTED_BRANCHES"
  _clean_git_branches_diagnose "Merged branch candidates: $(echo "$merged_candidates" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [ -n "$merged_candidates" ]; then
    _clean_git_branches_diagnose "Merged candidates list:"
    _clean_git_branches_diagnose "$(echo "$merged_candidates" | sed '/^$/d' | tr '\n' '; ')"
    printf '%s\n' "$merged_candidates" | xargs git branch -d
  fi
}

# List local branches whose upstream is gone, excluding protected branches
#
# Usage: _clean_git_branches_gone_branch_names
function _clean_git_branches_gone_branch_names() {
  if [ -z "$PROTECTED_BRANCHES" ]; then
    PROTECTED_BRANCHES="main|master|prod|dev"
  fi

  git branch -vv | grep -vE '^\*' | grep -E 'gone' | awk '{print $1}' | egrep -v "^($PROTECTED_BRANCHES)$"
}

# Delete remote-gone local branches using force delete (-D)
#
# Usage: _clean_git_branches_delete_gone
function _clean_git_branches_delete_gone() {
  local branch
  local output
  local branch_info
  local gone_candidates="$1"

  _clean_git_branches_diagnose "Remote-gone deletion candidates: $(echo "$gone_candidates" | sed '/^$/d' | wc -l | tr -d ' ')"

  while IFS= read -r branch; do
    [ -z "$branch" ] && continue
    branch_info=$(git branch -vv | awk -v b="$branch" '$1==b {print; exit}')
    if [ "$DRY_RUN" -eq 1 ]; then
      if [ -n "$branch_info" ]; then
        echo "  $(echo "$branch_info" | sed 's/^ *//')"
      else
        echo "  $branch"
      fi
    else
      output=$(git branch -D "$branch" 2>&1)
      if echo "$output" | grep -q "^Deleted branch "; then
        if [ -n "$branch_info" ]; then
          echo "  $(echo "$branch_info" | sed 's/^ *//')"
        else
          echo "  $branch"
        fi
      else
        _clean_git_branches_diagnose "Could not delete '$branch': $output"
      fi
    fi
  done <<< "$gone_candidates"
}

function _clean_git_branches_confirm_force_delete() {
  local candidate_count="$1"
  local candidate_list="$2"
  local assume_tty_for_tests="${CLEAN_GIT_BRANCHES_ASSUME_TTY:-0}"
  local response
  local branch_info

  if [ "$candidate_count" -eq 0 ]; then
    return 0
  fi

  if [ "$SILENT" -eq 1 ]; then
    return 0
  fi

  if [ ! -t 0 ] && [ "$assume_tty_for_tests" -ne 1 ]; then
    echo "Force deletion requires confirmation. Re-run with --silent to proceed non-interactively." >&2
    return 2
  fi

  echo >&2
  if [ "$DRY_RUN" -eq 1 ]; then
    echo -e "\033[1;93mRemote-gone force delete dry run\033[0m" >&2
  else
    echo -e "\033[1;91mRemote-gone force delete confirmation\033[0m" >&2
  fi
  echo "─────────────────────────────────────" >&2
  if [ "$DRY_RUN" -eq 1 ]; then
    echo -e "\033[1;93m  DRY RUN: no branches will be deleted.\033[0m" >&2
    echo -e "\033[1;93m  This preview shows branches that would be force deleted.\033[0m" >&2
    echo -e "\033[1;93m  Reason: each branch below has an upstream marked 'gone' by Git.\033[0m" >&2
  else
    echo -e "\033[1;91m  DANGER: this will permanently delete $candidate_count local branches.\033[0m" >&2
    echo -e "\033[1;93m  This action is destructive and cannot be undone by this script.\033[0m" >&2
    echo -e "\033[1;93m  Reason: each branch below has an upstream marked 'gone' by Git.\033[0m" >&2
  fi
  echo >&2
  echo -e "\033[1;96mBranches to be deleted\033[0m" >&2
  echo "──────────────────────" >&2
  while IFS= read -r branch; do
    [ -z "$branch" ] && continue
    branch_info=$(git branch -vv | awk -v b="$branch" '$1==b {print; exit}')
    if [ -n "$branch_info" ]; then
      echo "  $(echo "$branch_info" | sed 's/^ *//')" >&2
    else
      echo "  $branch [upstream: gone]" >&2
    fi
  done <<< "$candidate_list"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo >&2
    return 0
  fi

  echo >&2
  printf "\033[1;96mType DELETE to continue, or press Enter to skip:\033[0m " >&2
  read -r response
  case "$response" in
    DELETE)
      return 0
      ;;
    *)
      _clean_git_branches_diagnose "Force deletion skipped by user input"
      return 1
      ;;
  esac
}

# List untracked branches
#
# Usage: _clean_git_branches_show_untracked
#
# This function lists all untracked branches in the Git repository. Untracked branches are
# local branches that do not have a remote-tracking branch.
function _clean_git_branches_show_untracked() {
  git branch -vv | grep -vE '^\*' | grep -vE '\[origin/' | grep -vE 'gone'
}

# List deleted branches
#
# Usage: _clean_git_branches_show_deleted
#
# This function lists all deleted branches in the Git repository. Deleted branches are
# branches that have been deleted from the remote repository but still exist locally.
function _clean_git_branches_show_deleted() {
  local deleted

  deleted=$(git branch -vv | grep -vE '^\*' | grep -E 'gone')
  _clean_git_branches_diagnose "Remote-gone local branches: $(echo "$deleted" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [ -n "$deleted" ]; then
    _clean_git_branches_diagnose "Remote-gone branch list:"
    _clean_git_branches_diagnose "$(echo "$deleted" | sed '/^$/d' | awk '{print $1}' | tr '\n' '; ')"
  fi
  echo "$deleted"
}

# List tracked branches, excluding protected branches
#
# Usage: _clean_git_branches_show_tracked
#
# This function lists all tracked branches in the Git repository, excluding branches specified
# in the PROTECTED_BRANCHES environment variable. Tracked branches are local branches that
# have a remote-tracking branch. If PROTECTED_BRANCHES is not set, it defaults to
# "main|master|prod|dev".
function _clean_git_branches_show_tracked() {
  if [ -z "$PROTECTED_BRANCHES" ]; then
    PROTECTED_BRANCHES="main|master|prod|dev"
  fi
  git branch -vv | grep -vE '^\*' | grep -E '\[origin/' | grep -vE 'gone' | egrep -v "($PROTECTED_BRANCHES)"
}

# List protected branches
#
# Usage: _clean_git_branches_show_protected
#
# This function lists all protected branches in the Git repository, as specified by the
# PROTECTED_BRANCHES environment variable. If PROTECTED_BRANCHES is not set, it defaults to
# "main|master|prod|dev".
function _clean_git_branches_show_protected() {
  if [ -z "$PROTECTED_BRANCHES" ]; then
    PROTECTED_BRANCHES="main|master|prod|dev"
  fi
  git branch -vv | egrep "($PROTECTED_BRANCHES)"
}

# Function clean your git branches and show you their status
#
# Usage: clean_git_branches
#
# This function calls all of the other functions in this script to delete merged branches,
# and list untracked, deleted, tracked, and protected branches.
function clean_git_branches() {
  local current_branch
  local upstream_branch
  local branch_vv_probe_output
  local gone_candidates
  local gone_candidate_count
  local show_remote_gone_report=1

  echo

  current_branch=$(git branch --show-current)
  upstream_branch=$(git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>/dev/null || true)
  _clean_git_branches_diagnose "Repository: $(pwd)"
  _clean_git_branches_diagnose "Current branch: $current_branch"
  if [ -n "$upstream_branch" ]; then
    _clean_git_branches_diagnose "Current branch upstream: $upstream_branch"
  else
    _clean_git_branches_diagnose "Current branch upstream: (none)"
  fi
  _clean_git_branches_diagnose "Branch status: $(git status -sb | head -n 1)"
  _clean_git_branches_should_delete_gone
  if ! branch_vv_probe_output=$(git branch -vv 2>&1); then
    echo "Failed to list branches via 'git branch -vv'." >&2
    echo "$branch_vv_probe_output" >&2
    return 1
  fi
  gone_candidates=$(_clean_git_branches_gone_branch_names)
  gone_candidate_count=$(echo "$gone_candidates" | sed '/^$/d' | wc -l | tr -d ' ')
  _clean_git_branches_diagnose "Remote-gone deletion candidates: $gone_candidate_count"

  deleted_merged=$(_clean_git_branches_delete_merged)
  if [ -n "$deleted_merged" ]; then
    echo -e "\033[1;94mDeleted merged branches\033[0m"
    echo "─────────────────────"
    echo "$deleted_merged"
    echo
  fi

  untracked=$(_clean_git_branches_show_untracked)
  if [ -n "$untracked" ]; then
    echo -e "\033[1;93mUntracked branches\033[0m"
    echo "───────────────────"
    echo "$untracked"
    echo
  fi

  if [ "$DELETE_GONE_EFFECTIVE" -eq 1 ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      _clean_git_branches_diagnose "Remote-gone mode: dry run (force-delete preview only)"
    else
      _clean_git_branches_diagnose "Remote-gone mode: force delete enabled"
    fi
  else
    _clean_git_branches_diagnose "Remote-gone mode: deletion disabled (report only)"
  fi

  if [ "$DELETE_GONE_EFFECTIVE" -eq 1 ]; then
    if [ "$SILENT" -eq 1 ] && [ "$DRY_RUN" -eq 0 ]; then
      echo -e "\033[1;91mWARNING: --silent skips the destructive confirmation prompt.\033[0m"
      echo
    fi
    if _clean_git_branches_confirm_force_delete "$gone_candidate_count" "$gone_candidates"; then
      deleted_gone=$(_clean_git_branches_delete_gone "$gone_candidates")
      if [ -n "$deleted_gone" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
          echo -e "\033[1;93mWould delete remote-gone branches (dry run)\033[0m"
          echo "──────────────────────────────────────────"
          show_remote_gone_report=0
        else
          echo -e "\033[1;94mDeleted remote-gone branches\033[0m"
          echo "────────────────────────────"
        fi
        echo "$deleted_gone"
        echo
      fi
    else
      confirmation_status=$?
      echo -e "\033[1;93mSkipped remote-gone force deletion\033[0m"
      echo "──────────────────────────────────"
      echo "You chose to skip force deletion."
      echo
      show_remote_gone_report=0
      if [ "$confirmation_status" -eq 2 ]; then
        return 1
      fi
    fi
  else
    _clean_git_branches_diagnose "Skipping remote-gone deletions"
  fi

  deleted=$(_clean_git_branches_show_deleted)
  if [ "$show_remote_gone_report" -eq 1 ] && [ -n "$deleted" ]; then
    if [ "$DELETE_GONE_EFFECTIVE" -eq 1 ]; then
      if [ "$DRY_RUN" -eq 1 ]; then
        echo -e "\033[1;91mRemote-gone branches (dry run, not deleted)\033[0m"
        echo "───────────────────────────────────────────"
      else
        echo -e "\033[1;91mRemote-gone branches (not deleted)\033[0m"
        echo "──────────────────────────────────"
      fi
    else
      echo -e "\033[1;91mRemote-gone branches (deletion disabled)\033[0m"
      echo "─────────────────────────────────────────"
    fi
    echo "$deleted"
    echo
  fi

  tracked=$(_clean_git_branches_show_tracked)
  if [ -n "$tracked" ]; then
    echo -e "\033[1;92mTracked branches\033[0m"
    echo "───────────────"
    echo "$tracked"
  fi

  echo

  protected=$(_clean_git_branches_show_protected)
  if [ -n "$protected" ]; then
    echo -e "\033[1;95mProtected branches\033[0m"
    echo "─────────────────"
    echo "$protected"
  fi

  echo
}

# Call the clean_git_branches function when the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  clean_git_branches
fi
