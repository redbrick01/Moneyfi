ALTER TABLE public.reddit_post_cards
  DROP COLUMN IF EXISTS title,
  DROP COLUMN IF EXISTS body,
  DROP COLUMN IF EXISTS author;
