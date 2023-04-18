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

2. Add the clean_git_branches script to your shell configuration file (e.g. .bashrc, .zshrc, etc.):

```bash
source /path/to/clean_git_branches/clean_git_branches.sh
```

3. Restart your terminal or run source on your shell configuration file to load the new functions.

## Usage

Simply run the clean_git_branches function in your terminal:

```bash
clean_git_branches
```

The script will display branches categorized by status and remove any merged branches, excluding those specified as protected.

To customize protected branches, set the **PROTECTED_BRANCHES** environment variable in your shell configuration file:

```bash
export PROTECTED_BRANCHES="main|master|prod|dev|custom_branch"
```

## License

This project is licensed under the MIT License.

Copyright (c) 2023 Dale Freya

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests to help improve Clean Git Branches.
