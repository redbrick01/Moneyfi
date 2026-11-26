import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(() => new Response(JSON.stringify({ error: "removed", message: "Legacy news workflow has been removed. Use public.news_reports instead." }), { status: 410, headers: { "Content-Type": "application/json" } }));
