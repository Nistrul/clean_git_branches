# Clean Git Branches

Clean Git Branches is a command-line tool that helps maintain a tidy Git repository by categorizing and displaying branches based on their status: deleted, untracked, tracked, and protected. It also streamlines branch management by automatically removing merged branches, excluding those specified as protected.

## Features

- Categorize and display branches by status (deleted, untracked, tracked, protected)
- Delete merged branches, excluding protected branches
- Easy-to-read, color-coded branch output
- Customizable protected branches

## Installation

install the clean-git-branches script using Homebrew, first tap this repository:

```bash
brew tap your-username/clean-git-branches
```

Then, install the clean-git-branches script:

```bash
brew install clean-git-branches
```

## Updating

To update the clean-git-branches script to the latest version, run:

```bash
brew update && brew upgrade clean-git-branches
```

## Configuration

Set the **PROTECTED_BRANCHES** environment variable if you want to customize the protected branches. By default, the script protects the "main", "master", "prod", and "dev" branches. To set the variable, add the following line to your shell's configuration file (e.g., **.bashrc**, **.zshrc**, etc.):

```bash
export PROTECTED_BRANCHES="main|master|prod|dev|custom-branch"
```

## Usage

Simply run the clean_git_branches function in your terminal:

```bash
clean_git_branches
```

The script will display branches categorized by status and remove any merged branches, excluding those specified as protected.

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests to help improve Clean Git Branches.
