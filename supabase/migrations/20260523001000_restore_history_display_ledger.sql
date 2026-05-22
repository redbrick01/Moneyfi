-- Restore historical ledger rows for calendar/snapshot detail display.
--
-- Snapshot restore opening rows are the calculation baseline. The historical
-- rows restored here are kept active only for display and are excluded from
-- app-side state/performance recalculation by source = 'history_display'.

insert into public.transaction_events (
  id,
  user_id,
  client_id,
  occurred_at,
  kind,
  title,
  memo,
  source,
  legacy_source_table,
  legacy_source_id,
  sort_order,
  created_at,
  updated_at,
  deleted_at
)
select
  archived.id,
  archived.user_id,
  archived.client_id,
  archived.occurred_at,
  archived.kind,
  archived.title,
  archived.memo,
  'history_display',
  archived.legacy_source_table,
  archived.legacy_source_id,
  archived.sort_order,
  archived.created_at,
  now(),
  null
from recovery_archive.transaction_events_before_snapshot_restore_20260522 archived
where archived.deleted_at is null
  and archived.source = 'legacy'
  and not exists (
    select 1
    from public.transaction_events current
    where current.id = archived.id
  );

update public.transaction_events current
set
  source = 'history_display',
  deleted_at = null,
  updated_at = now()
from recovery_archive.transaction_events_before_snapshot_restore_20260522 archived
where current.id = archived.id
  and archived.deleted_at is null
  and archived.source = 'legacy';

insert into public.transaction_lines (
  id,
  user_id,
  event_id,
  asset_id,
  holding_id,
  cash_account_id,
  client_id,
  legacy_source_table,
  legacy_source_id,
  action,
  currency_code,
  quantity_delta,
  cash_delta,
  unit_price,
  gross_amount,
  fee_amount,
  tax_amount,
  cost_basis_delta,
  realized_pnl,
  fx_rate,
  sort_order,
  created_at,
  updated_at,
  deleted_at
)
select
  archived.id,
  archived.user_id,
  archived.event_id,
  archived.asset_id,
  archived.holding_id,
  archived.cash_account_id,
  archived.client_id,
  archived.legacy_source_table,
  archived.legacy_source_id,
  archived.action,
  archived.currency_code,
  archived.quantity_delta,
  archived.cash_delta,
  archived.unit_price,
  archived.gross_amount,
  archived.fee_amount,
  archived.tax_amount,
  archived.cost_basis_delta,
  archived.realized_pnl,
  archived.fx_rate,
  archived.sort_order,
  archived.created_at,
  now(),
  null
from recovery_archive.transaction_lines_before_snapshot_restore_20260522 archived
join public.transaction_events current_event
  on current_event.id = archived.event_id
 and current_event.source = 'history_display'
where archived.deleted_at is null
  and not exists (
    select 1
    from public.transaction_lines current
    where current.id = archived.id
  );

update public.transaction_lines current
set
  deleted_at = null,
  updated_at = now()
from recovery_archive.transaction_lines_before_snapshot_restore_20260522 archived
join public.transaction_events current_event
  on current_event.id = archived.event_id
 and current_event.source = 'history_display'
where current.id = archived.id
  and archived.deleted_at is null;
