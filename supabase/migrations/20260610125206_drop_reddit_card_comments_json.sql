DROP INDEX IF EXISTS public.idx_reddit_post_cards_comments_gin;

ALTER TABLE public.reddit_post_cards
  DROP COLUMN IF EXISTS comments_json;
