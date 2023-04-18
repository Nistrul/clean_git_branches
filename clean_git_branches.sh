# Delete merged branches, excluding protected branches
function clean_git_branches_delete_merged() {
  if [ -z "$PROTECTED_BRANCHES" ]; then
    PROTECTED_BRANCHES="main|master|prod|dev"
  fi
  git branch --merged | egrep -v "(^\*|$PROTECTED_BRANCHES)" | xargs git branch -d
}

# List untracked branches
function clean_git_branches_show_untracked() {
  git branch -vv | grep -vE '^\*' | grep -vE '\[origin/' | grep -vE 'gone'
}

# List deleted branches
function clean_git_branches_show_deleted() {
  git branch -vv | grep -vE '^\*' | grep -E 'gone'
}

# List tracked branches, excluding protected branches
function clean_git_branches_show_tracked() {
  if [ -z "$PROTECTED_BRANCHES" ]; then
    PROTECTED_BRANCHES="main|master|prod|dev"
  fi
  git branch -vv | grep -vE '^\*' | grep -E '\[origin/' | grep -vE 'gone' | egrep -v "($PROTECTED_BRANCHES)"
}

# List protected branches
function clean_git_branches_show_protected() {
  if [ -z "$PROTECTED_BRANCHES" ]; then
    PROTECTED_BRANCHES="main|master|prod|dev"
  fi
  git branch -vv | egrep "($PROTECTED_BRANCHES)"
}

# Function to call all functions above
function clean_git_branches() {
  echo

  deleted_merged=$(clean_git_branches_delete_merged)
  if [ -n "$deleted_merged" ]; then
    echo -e "\033[1;94mDeleted merged branches\033[0m"
    echo "─────────────────────"
    echo "$deleted_merged"
    echo
  fi

  untracked=$(clean_git_branches_show_untracked)
  if [ -n "$untracked" ]; then
    echo -e "\033[1;93mUntracked branches\033[0m"
    echo "───────────────────"
    echo "$untracked"
    echo
  fi

  deleted=$(clean_git_branches_show_deleted)
  if [ -n "$deleted" ]; then
    echo -e "\033[1;91mDeleted branches\033[0m"
    echo "───────────────"
    echo "$deleted"
    echo
  fi

  tracked=$(clean_git_branches_show_tracked)
  if [ -n "$tracked" ]; then
    echo -e "\033[1;92mTracked branches\033[0m"
    echo "───────────────"
    echo "$tracked"
  fi

  echo

  protected=$(clean_git_branches_show_protected)
  if [ -n "$protected" ]; then
    echo -e "\033[1;95mProtected branches\033[0m"
    echo "─────────────────"
    echo "$protected"
  fi

  echo
}