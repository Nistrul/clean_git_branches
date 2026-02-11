# Demo Catalog

This folder contains deterministic local demos used for PR visual validation.

## Usage

Run a demo directly:

```bash
./demos/minimal-safe-cleanup.sh
./demos/integration-context-coverage.sh
```

## Demos

| Demo ID | Script | Demonstrates |
|---|---|---|
| `minimal-safe-cleanup` | `demos/minimal-safe-cleanup.sh` | Deterministic preview of merged/equivalent/non-equivalent branch classification and deletion eligibility using isolated temporary Git fixtures. |
| `integration-context-coverage` | `demos/integration-context-coverage.sh` | Deterministic signal for `INT-042` by showing whether the consolidated subdirectory context integration test exists and running that targeted test when present. |
