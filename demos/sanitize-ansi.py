#!/usr/bin/env python3
"""Normalize captured ANSI transcripts from PTY recorders."""

from __future__ import annotations

import sys


def main() -> int:
  if len(sys.argv) != 3:
    print("usage: sanitize-ansi.py <input.ansi> <output.ansi>", file=sys.stderr)
    return 1

  input_path = sys.argv[1]
  output_path = sys.argv[2]

  with open(input_path, "rb") as infile:
    data = infile.read()

  # BSD script can prepend this literal control-sequence artifact.
  prefix = b"^D\x08\x08\r\n"
  if data.startswith(prefix):
    data = data[len(prefix):]

  # Strip occasional leading PTY NUL padding.
  data = data.lstrip(b"\x00")

  # Keep line endings deterministic for text derivation.
  data = data.replace(b"\r\n", b"\n")

  with open(output_path, "wb") as outfile:
    outfile.write(data)

  return 0


if __name__ == "__main__":
  raise SystemExit(main())
