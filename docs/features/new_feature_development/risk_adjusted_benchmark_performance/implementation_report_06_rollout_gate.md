# Implementation Report 06: Rollout Gate

## Scope

The rollout gate records whether the risk-adjusted performance schema and UI can proceed from local verification to remote availability.

## Gate Criteria

- Calculation contract tests pass.
- Derived daily return tests pass.
- Benchmark fixture tests pass.
- UI handles 데이터 부족 without breaking the page.
- Remote schema draft is reviewed before apply.
- Release gate documents the remote apply result and destructive-write checks.

## Decision

Proceed only when source portfolio data remains unchanged and advanced metrics degrade gracefully.
