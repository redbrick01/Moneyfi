-- Legacy cash rows without linked_transaction_id cannot form a complete
-- transfer/fx pair in the normalized ledger. Treat those one-sided rows as
-- external cash withdrawals so ledger semantics stay honest.

update public.transaction_events te
set kind = 'cash_flow'
where te.source = 'legacy'
  and te.legacy_source_table = 'cash_transactions'
  and te.kind in ('cash_transfer', 'fx_exchange')
  and te.deleted_at is null
  and exists (
    select 1
    from public.transaction_lines tl
    where tl.event_id = te.id
      and tl.deleted_at is null
      and tl.action in ('transfer_out', 'fx_out')
  )
  and not exists (
    select 1
    from public.transaction_lines tl
    where tl.event_id = te.id
      and tl.deleted_at is null
      and tl.action in ('transfer_in', 'fx_in')
  );

update public.transaction_lines tl
set action = 'withdrawal'
from public.transaction_events te
where te.id = tl.event_id
  and te.source = 'legacy'
  and te.legacy_source_table = 'cash_transactions'
  and te.kind = 'cash_flow'
  and tl.deleted_at is null
  and tl.action in ('transfer_out', 'fx_out')
  and not exists (
    select 1
    from public.transaction_lines paired
    where paired.event_id = te.id
      and paired.deleted_at is null
      and paired.action in ('transfer_in', 'fx_in')
  );
