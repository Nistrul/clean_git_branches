# Clean Git Branches

Clean Git Branches is a command-line tool that helps maintain a tidy Git repository by categorizing and displaying branches based on their status: deleted, untracked, tracked, and protected. It also streamlines branch management by automatically removing merged branches, excluding those specified as protected.

## Features

- Categorize and display branches by status (deleted, untracked, tracked, protected)
- Delete merged branches, excluding protected branches
- Easy-to-read, color-coded branch output
- Customizable protected branches

## Installation

1. Clone the clean_git_branches repository:

```bash
git clone https://github.com/yourusername/clean_git_branches.git
```

2. Make the script executable by running the following command in your terminal:

```bash
chmod +x clean_git_branches.sh
```

2. Add the clean_git_branches script to your shell configuration file (e.g. .bashrc, .zshrc, etc.):

```bash
source /path/to/clean_git_branches/clean_git_branches.sh
```

3. (Optional) Add the script to your system's **PATH** to use it from any directory. One way to do this is to create a symbolic link to the script in a directory that is already in your **PATH**. For example:

```bash
ln -s /path/to/clean_git_branches.sh /usr/local/bin/clean-git-branches
```

Replace **/path/to/clean_git_branches.sh** with the actual path to the script on your system. After doing this, you can run the script using the command **clean-git-branches**.

4. Set the **PROTECTED_BRANCHES** environment variable if you want to customize the protected branches. By default, the script protects the "main", "master", "prod", and "dev" branches. To set the variable, add the following line to your shell's configuration file (e.g., **.bashrc**, **.zshrc**, etc.):

```bash
export PROTECTED_BRANCHES="main|master|prod|dev|custom-branch"
```

5. Restart your terminal or run source on your shell configuration file to load the new functions.

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
