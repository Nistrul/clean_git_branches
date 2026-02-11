# Demo Catalog

This folder contains deterministic local demos used for PR visual validation.

## Usage

Run a demo directly:

```bash
./demos/minimal-safe-cleanup.sh
```

## Demos

| Demo ID | Script | Demonstrates |
|---|---|---|
| `minimal-safe-cleanup` | `demos/minimal-safe-cleanup.sh` | Deterministic preview of merged/equivalent/non-equivalent branch classification and deletion eligibility using isolated temporary Git fixtures. |

## Capture Utilities

1. `demos/sanitize-ansi.py` normalizes raw PTY captures for deterministic artifact output.
2. Use it after `script` capture before deriving plain text:

```bash
script -q pr-artifacts/before.raw.ansi ./demos/${DEMO_ID}.sh
python3 demos/sanitize-ansi.py pr-artifacts/before.raw.ansi pr-artifacts/before.ansi
sed -E 's/\x1b\[[0-9;]*m//g' pr-artifacts/before.ansi > pr-artifacts/before.txt
```
