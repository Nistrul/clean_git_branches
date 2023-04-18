#!/usr/bin/env ruby
# clean_git_branches.rb
#
# A Homebrew formula for the clean_git_branches script.
#
# Copyright (C) 2023 Dale Freya
# This program is released under the terms of the MIT License.

class CleanGitBranches < Formula
    desc "A command-line tool to help maintain a tidy Git branches."
    homepage "https://github.com/Nistrul/clean-git-branches"
    url "https://github.com/Nistrul/clean_git_branches/archive/refs/tags/v0.1.0.tar.gz"
    sha256 "582e3c062d087fa311043d94227b290b91e6e15011c38593b5d80d0df0a2f817"
    license "MIT"
  
    def install
      bin.install "clean_git_branches.sh"
    end
  
    test do
      system "#{bin}/clean_git_branches.sh", "--help"
    end
  end
  