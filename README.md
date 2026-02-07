# Clean Git Branches

Clean Git Branches is a command-line tool that helps maintain a tidy Git repository by categorizing and displaying branches based on their status: deleted, untracked, tracked, and protected. It also streamlines branch management by automatically removing merged branches and optionally force deleting remote-gone branches, excluding those specified as protected.

## Features

- Categorize and display branches by status (deleted, untracked, tracked, protected)
- Delete merged branches, excluding protected branches
- Optionally force delete remote-gone branches with `git branch -D`
- Easy-to-read, color-coded branch output
- Customizable protected branches
- Optional diagnostic mode for troubleshooting

## Installation

install the clean-git-branches script using Homebrew, first tap this repository:

```bash
brew tap Nistrul/clean-git-branches
```

Then, install the clean-git-branches script:

```bash
brew install clean-git-branches
```

## Usage

Simply run the clean_git_branches function in your terminal from inside a git repository:

```bash
clean_git_branches
```

The script will display branches categorized by status and remove merged branches, excluding those specified as protected.

Remote-gone branch deletion is optional and disabled by default. Enable force deletion with either:

```bash
clean_git_branches --force-delete-gone
```

or in repo config (`.clean_git_branches.conf`):

```bash
FORCE_DELETE_GONE_BRANCHES=true
```

Disable with:

```bash
clean_git_branches --no-force-delete-gone
```

Preview without deleting:

```bash
clean_git_branches --force-delete-gone --dry-run
```

Skip confirmation prompt (dangerous):

```bash
clean_git_branches --force-delete-gone --silent
```

To print additional runtime diagnostics while troubleshooting:

```bash
clean_git_branches --diagnose
```

## Configuration

Set the **PROTECTED_BRANCHES** environment variable if you want to customize the protected branches. By default, the script protects the "main", "master", "prod", and "dev" branches. To set the variable, add the following line to your shell's configuration file (e.g., **.bashrc**, **.zshrc**, etc.):

```bash
export PROTECTED_BRANCHES="main|master|prod|dev|custom-branch"
```

To configure remote-gone deletion for one repository, create `.clean_git_branches.conf` in the repo root:

```bash
FORCE_DELETE_GONE_BRANCHES=true
```

Command-line flags (`--force-delete-gone` / `--no-force-delete-gone`) override this config.

## Updating

To update the clean-git-branches script to the latest version, run:

```bash
brew update && brew upgrade clean-git-branches
```

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests to help improve Clean Git Branches.
