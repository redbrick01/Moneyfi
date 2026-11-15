alter table public.reddit_post_cards enable row level security;

revoke insert, update, delete, truncate, references, trigger
on table public.reddit_post_cards
from anon, authenticated;

grant select
on table public.reddit_post_cards
to authenticated;

drop policy if exists reddit_post_cards_public_read
on public.reddit_post_cards;

create policy reddit_post_cards_public_read
on public.reddit_post_cards
for select
to authenticated
using (true);
