create or replace function public.get_equity_research_reports(
  p_limit integer default 30
)
returns jsonb
language sql
stable
security definer
set search_path = public, equity_research
as $$
  with ordered_reports as (
    select r.*
    from equity_research.research_reports r
    order by r.report_date desc, r.created_at desc, r.id desc
    limit greatest(1, least(coalesce(p_limit, 30), 100))
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', r.id,
        'company_id', r.company_id,
        'company', jsonb_build_object(
          'id', c.id,
          'ticker', c.ticker,
          'exchange', c.exchange,
          'company_name', c.company_name,
          'sector', c.sector,
          'industry', c.industry,
          'currency', c.currency
        ),
        'report_slug', r.report_slug,
        'title', r.title,
        'report_type', r.report_type,
        'report_date', r.report_date,
        'as_of_date', r.as_of_date,
        'author', r.author,
        'language', r.language,
        'summary', r.summary,
        'one_line_conclusion', r.one_line_conclusion,
        'investment_stance', r.investment_stance,
        'confidence_level', r.confidence_level,
        'is_investment_advice', r.is_investment_advice,
        'created_at', r.created_at,
        'updated_at', r.updated_at
      )
      order by r.report_date desc, r.created_at desc, r.id desc
    ),
    '[]'::jsonb
  )
  from ordered_reports r
  join equity_research.companies c on c.id = r.company_id;
$$;

create or replace function public.get_latest_equity_research_report(
  p_ticker text
)
returns jsonb
language sql
stable
security definer
set search_path = public, equity_research
as $$
  with selected_report as (
    select r.*
    from equity_research.research_reports r
    join equity_research.companies c on c.id = r.company_id
    where upper(c.ticker) = upper(trim(coalesce(p_ticker, '')))
    order by r.report_date desc, r.created_at desc, r.id desc
    limit 1
  )
  select jsonb_build_object(
    'id', r.id,
    'company_id', r.company_id,
    'company', jsonb_build_object(
      'id', c.id,
      'ticker', c.ticker,
      'exchange', c.exchange,
      'company_name', c.company_name,
      'sector', c.sector,
      'industry', c.industry,
      'currency', c.currency
    ),
    'report_slug', r.report_slug,
    'title', r.title,
    'report_type', r.report_type,
    'report_date', r.report_date,
    'as_of_date', r.as_of_date,
    'author', r.author,
    'language', r.language,
    'summary', r.summary,
    'one_line_conclusion', r.one_line_conclusion,
    'investment_stance', r.investment_stance,
    'confidence_level', r.confidence_level,
    'is_investment_advice', r.is_investment_advice,
    'created_at', r.created_at,
    'updated_at', r.updated_at
  )
  from selected_report r
  join equity_research.companies c on c.id = r.company_id;
$$;

create or replace function public.get_equity_research_report_detail(
  p_report_id bigint
)
returns jsonb
language sql
stable
security definer
set search_path = public, equity_research
as $$
  select jsonb_build_object(
    'report_id', p_report_id,
    'sections', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', s.id,
          'parent_section_id', s.parent_section_id,
          'section_no', s.section_no,
          'title', s.title,
          'section_type', s.section_type,
          'sort_order', s.sort_order,
          'body', s.body
        )
        order by s.sort_order, s.id
      )
      from equity_research.report_sections s
      where s.report_id = p_report_id
    ), '[]'::jsonb),
    'metrics', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', m.id,
          'metric_name', m.metric_name,
          'metric_value', m.metric_value,
          'metric_text', m.metric_text,
          'metric_unit', m.metric_unit,
          'currency', m.currency,
          'fiscal_period', m.fiscal_period,
          'period_end_date', m.period_end_date,
          'yoy_change_pct', m.yoy_change_pct,
          'qoq_change_pct', m.qoq_change_pct,
          'notes', m.notes
        )
        order by m.id
      )
      from equity_research.company_metrics m
      where m.report_id = p_report_id
    ), '[]'::jsonb),
    'theses', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', t.id,
          'thesis_side', t.thesis_side,
          'title', t.title,
          'thesis_text', t.thesis_text,
          'importance_score', t.importance_score,
          'sort_order', t.sort_order
        )
        order by t.sort_order nulls last, t.id
      )
      from equity_research.investment_theses t
      where t.report_id = p_report_id
    ), '[]'::jsonb),
    'risks', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', r.id,
          'risk_category', r.risk_category,
          'title', r.title,
          'description', r.description,
          'probability_level', r.probability_level,
          'impact_level', r.impact_level,
          'time_horizon', r.time_horizon,
          'mitigation_or_watchpoint', r.mitigation_or_watchpoint,
          'sort_order', r.sort_order
        )
        order by r.sort_order nulls last, r.id
      )
      from equity_research.risks r
      where r.report_id = p_report_id
    ), '[]'::jsonb),
    'catalysts', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', c.id,
          'catalyst_category', c.catalyst_category,
          'title', c.title,
          'description', c.description,
          'expected_timing', c.expected_timing,
          'expected_direction', c.expected_direction,
          'sort_order', c.sort_order
        )
        order by c.sort_order nulls last, c.id
      )
      from equity_research.catalysts c
      where c.report_id = p_report_id
    ), '[]'::jsonb),
    'valuation_views', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', v.id,
          'valuation_method', v.valuation_method,
          'stance', v.stance,
          'rating', v.rating,
          'price_at_analysis', v.price_at_analysis,
          'target_price', v.target_price,
          'target_price_low', v.target_price_low,
          'target_price_high', v.target_price_high,
          'fair_value', v.fair_value,
          'implied_upside_pct', v.implied_upside_pct,
          'currency', v.currency,
          'time_horizon', v.time_horizon,
          'key_assumptions', v.key_assumptions,
          'notes', v.notes
        )
        order by v.id
      )
      from equity_research.valuation_views v
      where v.report_id = p_report_id
    ), '[]'::jsonb),
    'scenarios', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', sc.id,
          'scenario_name', sc.scenario_name,
          'scenario_title', sc.scenario_title,
          'summary', sc.summary,
          'valuation_anchor', sc.valuation_anchor,
          'expected_outcome', sc.expected_outcome,
          'sort_order', sc.sort_order
        )
        order by sc.sort_order nulls last, sc.id
      )
      from equity_research.scenarios sc
      where sc.report_id = p_report_id
    ), '[]'::jsonb),
    'monitoring_indicators', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', mi.id,
          'area', mi.area,
          'indicator_name', mi.indicator_name,
          'positive_signal', mi.positive_signal,
          'negative_signal', mi.negative_signal,
          'check_frequency', mi.check_frequency,
          'source_hint', mi.source_hint,
          'sort_order', mi.sort_order
        )
        order by mi.sort_order nulls last, mi.id
      )
      from equity_research.monitoring_indicators mi
      where mi.report_id = p_report_id
    ), '[]'::jsonb),
    'source_documents', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', d.id,
          'source_name', d.source_name,
          'publisher', d.publisher,
          'analyst_or_author', d.analyst_or_author,
          'document_title', d.document_title,
          'document_type', d.document_type,
          'published_date', d.published_date,
          'url', d.url,
          'access_type', d.access_type,
          'source_quality_grade', d.source_quality_grade,
          'stance', d.stance,
          'rating', d.rating,
          'price_target', d.price_target,
          'price_target_currency', d.price_target_currency,
          'fair_value', d.fair_value,
          'fair_value_currency', d.fair_value_currency,
          'notes', d.notes
        )
        order by rd.sort_order nulls last, d.published_date desc nulls last, d.id
      )
      from equity_research.report_source_documents rd
      join equity_research.source_documents d on d.id = rd.source_document_id
      where rd.report_id = p_report_id
    ), '[]'::jsonb)
  );
$$;

revoke all on function public.get_equity_research_reports(integer)
from public;
revoke all on function public.get_latest_equity_research_report(text)
from public;
revoke all on function public.get_equity_research_report_detail(bigint)
from public;

grant execute on function public.get_equity_research_reports(integer)
to anon, authenticated;
grant execute on function public.get_latest_equity_research_report(text)
to anon, authenticated;
grant execute on function public.get_equity_research_report_detail(bigint)
to anon, authenticated;
