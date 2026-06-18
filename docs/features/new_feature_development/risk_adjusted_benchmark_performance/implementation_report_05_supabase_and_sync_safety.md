# Implementation Report 05: Supabase And Sync Safety

## Scope

Remote schema work is limited to analysis-derived tables and benchmark reference data. Sync payloads for core portfolio tables remain separate.

## Remote Safety Rules

- Do not update holdings as part of risk-adjusted performance rollout.
- Do not delete from holdings.
- Do not truncate portfolio source tables.
- Empty sync payloads must not overwrite existing asset or holding state.
- RLS is enabled for user-specific derived rows.

## Verification

Remote apply requires a fresh preflight before execution and a release gate record after execution.
