insert into public.sources (source_type, display_name)
values ('finnhub', 'Finnhub')
on conflict (source_type) do update
set display_name = excluded.display_name,
    updated_at = now();
