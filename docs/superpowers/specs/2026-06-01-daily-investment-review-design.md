# Daily Investment Review Design

## Summary

MONEYFY's daily investment review should become a saved writing workflow, not only a read-only report. The app creates an automatic draft from today's portfolio and transaction data, then the user completes the review by adding judgment, emotion, insight, and the next plan.

This first release focuses only on the daily review. Existing weekly and monthly review pages remain read-only and keep their current behavior.

## Goals

- Turn the current daily review summary into a concrete daily review document.
- Preserve the current automatic summary as the draft context.
- Let users save, resume, complete, and edit today's review.
- Support both trading days and no-trade days.
- Keep the first release local-first and deterministic.

## Non-Goals

- AI coach, AI writing, or AI feedback.
- Daily market news, market commentary, or news summaries.
- Benchmark comparison such as KOSPI or S&P 500.
- Weekly or monthly review writing workflows.
- Full trade journal support across every transaction screen.
- Remote sync schema changes for review drafts.

## Product Model

The daily review is a single document per calendar day.

The app builds a draft using existing local investment data:

- Daily period range.
- Pure investment performance.
- Realized profit and loss.
- Dividend or interest income.
- Buy, sell, income, and cash-flow activity counts.
- Current deterministic review signals and next actions.

The user completes the review through five sections:

1. Performance analysis.
2. Trade review or no-trade observation.
3. Risk and mental check.
4. Key insight.
5. Next investment plan.

## Daily Modes

The review automatically chooses one of two modes from today's activity.

### Trading Day Mode

Used when today has at least one buy or sell transaction.

The second section focuses on decision review:

- What did I buy or sell?
- Why did I make the decision?
- Was it planned, impulsive, FOMO-driven, rumor-driven, or risk-management driven?
- Was the process acceptable regardless of short-term result?
- What should I repeat or avoid next time?

### No-Trade Day Mode

Used when today has no buy or sell transaction.

The second section becomes an observation review:

- Why did I not trade today?
- Was I waiting by rule, missing an opportunity, or intentionally preserving cash?
- Did I notice a meaningful change in holdings, watchlist items, or risk?
- Did I avoid an impulsive trade?
- What condition should I check tomorrow?

Suggested no-trade reason chips:

- No setup matched my rules.
- Waiting for target price.
- Preserving cash.
- Need more analysis.
- Volatility was too high.
- Avoided impulsive trading.
- Nothing meaningful to record.

## Screen Structure

The existing investment review page keeps its Today, Weekly, and Monthly segmented control.

Only the Today tab changes to the writing workflow.

### Header

The header shows:

- Date.
- Review status.
- Generated draft timestamp if available.
- Primary action based on state.

Review statuses:

- `draft`: computed UI state when no saved row exists for today.
- `inProgress`: persisted state after the user saves at least one editable field.
- `completed`: persisted state after the user marks the review complete.

### Automatic Draft Context

The existing read-only report becomes the top context area:

- Narrative headline and summary.
- Period and activity pills.
- Key metrics.
- Review signals.
- Current next-action suggestions.

This area is recalculated from investment data, but it does not overwrite user-written fields.

### Five Writing Sections

Each section uses compact form controls suitable for repeated daily use.

Performance analysis:

- Shows automatic metrics.
- Provides an editable note field for what caused today's result.

Trade review or no-trade observation:

- Trading day mode shows today's buy/sell summary and decision reason inputs.
- No-trade day mode shows no-trade reason chips and an observation note.

Risk and mental check:

- Emotion chips, such as calm, anxious, impatient, regretful, confident.
- Principle check values: followed rules, broke rules, not applicable.
- Optional note for risk or mental state.

Key insight:

- Editable fields for what went well, what was weak, and what to repeat or avoid.

Next investment plan:

- Editable checklist or multiline plan for the next trading decision.

### Actions

- Save draft.
- Mark complete.
- Edit completed review.

Saving should be explicit. Navigating away with unsaved edits shows a discard confirmation.

## Home Card

The home card changes from a simple headline card to a daily review status card.

States:

- No saved review: "Today's review draft is ready."
- In progress: "You have an unfinished daily review."
- Completed: "Today's review is complete."

Button labels:

- Start.
- Continue.
- View.

The card may still show one or two automatic next-action hints, but the main signal is the writing status.

## Data Model

Add a local-only daily review table.

One row exists per review date.

Fields:

- `id`.
- `review_date`.
- `status`: inProgress, completed.
- `mode`: tradingDay, noTradeDay.
- `performance_note`.
- `trade_review_note`.
- `selected_decision_tags`.
- `selected_no_trade_reasons`.
- `selected_emotions`.
- `principle_check`.
- `risk_note`.
- `insight_good`.
- `insight_weak`.
- `insight_repeat_or_avoid`.
- `next_plan`.
- `created_at`.
- `updated_at`.
- `completed_at`.

The draft metrics and signals are not stored in the first release. They are rebuilt from current local investment data each time the page opens. User-written fields are stored and preserved.

## Data Flow

1. User opens Investment Review > Today.
2. App builds today's automatic `InvestmentReviewReport`.
3. App loads the saved daily review row for today's date, if one exists.
4. If no row exists, the UI starts from a computed draft state using the report mode.
5. User edits fields and saves.
6. App upserts the daily review row.
7. Home card and Today tab read the saved status.

## Empty And Edge States

No transactions and no performance data:

- Still allow review writing.
- Use no-trade day mode.
- Show the automatic context as low-data, then focus on observation and next-plan fields.

Transactions changed after a review was saved:

- Recalculate automatic context.
- Preserve user fields.
- If the mode changes because a trade was added later, show the new mode but keep existing notes.

Completed review:

- Opens in read-first mode.
- User can choose edit to modify it.

Save failure:

- Keep form contents in memory.
- Show a clear retry message.

## Component Boundaries

Domain:

- Daily review model and status enum.
- Local repository for loading and saving one review per date.
- Mapper that combines automatic report data with saved review state.

UI:

- Today review composer.
- Review status header.
- Automatic draft context section.
- Trading day decision section.
- No-trade observation section.
- Risk and mental check section.
- Insight section.
- Next plan section.
- Updated home status card.

Existing weekly and monthly report components should remain read-only and should not depend on daily review persistence.

## Testing

Unit tests:

- New daily review model handles draft, in-progress, and completed states.
- Repository upserts one row per date.
- Trading day mode is chosen when buy or sell activity exists.
- No-trade day mode is chosen when no buy or sell activity exists.

Widget tests:

- Today tab shows the writing workflow.
- Trading day mode shows trade review inputs.
- No-trade day mode shows observation reason chips.
- Saving a draft changes status to in progress.
- Marking complete changes status to completed.
- Weekly and monthly tabs still render the existing read-only report.
- Home card shows start, continue, and completed states.

## Acceptance Criteria

- A user can open today's review, see an automatic draft, write the five sections, save, leave, and return without losing content.
- A user can complete today's review and later reopen it for viewing or editing.
- A no-trade day still provides meaningful review prompts.
- Existing weekly and monthly review behavior is unchanged.
- No AI, market analysis, or benchmark feature is introduced in this release.
