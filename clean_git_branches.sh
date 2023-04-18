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
Usage: clean_git_branches [--help]

This script is a utility to help manage your Git branches. It performs the following actions:

- Deletes merged branches, excluding protected branches
- Lists untracked branches
- Lists deleted branches
- Lists tracked branches, excluding protected branches
- Lists protected branches

Options:
  --help    Show this help message and exit

Environment Variables:
  PROTECTED_BRANCHES   A pipe-separated list of protected branches, e.g., "main|master|prod|dev".
                       Defaults to "main|master|prod|dev" if not set.

EOF
}

if [ "$1" == "--help" ]; then
  _clean_git_branches_display_help
  exit 0
fi

# Delete merged branches, excluding protected branches
#
# Usage: clean_git_branches_delete_merged
#
# This function deletes all branches that have been merged into the
# current branch, excluding branches specified in the PROTECTED_BRANCHES
# environment variable. If PROTECTED_BRANCHES is not set, it defaults to
# "main|master|prod|dev".
function _clean_git_branches_delete_merged() {
  if [ -z "$PROTECTED_BRANCHES" ]; then
    PROTECTED_BRANCHES="main|master|prod|dev"
  fi
  git branch --merged | egrep -v "(^\*|$PROTECTED_BRANCHES)" | xargs git branch -d
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
  git branch -vv | grep -vE '^\*' | grep -E 'gone'
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
  echo

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

  deleted=$(_clean_git_branches_show_deleted)
  if [ -n "$deleted" ]; then
    echo -e "\033[1;91mDeleted branches\033[0m"
    echo "───────────────"
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