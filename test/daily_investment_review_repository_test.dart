import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/features/analysis/services/investment_review/daily_investment_review_models.dart';
import 'package:moneyfy/features/analysis/services/investment_review/daily_investment_review_repository.dart';

void main() {
  late AppDatabase db;
  late DailyInvestmentReviewRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DailyInvestmentReviewRepository(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('load returns null when no review exists for date', () async {
    final review = await repository.loadByDate(DateTime(2026, 6, 1));

    expect(review, isNull);
  });

  test('saveDraft upserts one in-progress row per date', () async {
    final date = DateTime(2026, 6, 1);

    await repository.saveDraft(
      DailyInvestmentReviewDraft(
        reviewDate: date,
        mode: DailyInvestmentReviewMode.noTradeDay,
        performanceNote: '성과 변동은 작았다.',
        tradeReviewNote: '원칙에 맞는 기회가 없었다.',
        selectedDecisionTags: const [],
        selectedNoTradeReasons: const ['원칙에 맞는 기회가 없었음'],
        selectedEmotions: const ['차분함'],
        principleCheck: DailyInvestmentReviewPrincipleCheck.followedRules,
        riskNote: '충동 매매 없음.',
        insightGood: '기다린 점이 좋았다.',
        insightWeak: '관심 종목 조건을 더 구체화해야 한다.',
        insightRepeatOrAvoid: '목표 가격 전에는 진입하지 않기.',
        nextPlan: '내일은 현금 비중과 관심 종목 가격만 확인한다.',
      ),
    );
    await repository.saveDraft(
      DailyInvestmentReviewDraft(
        reviewDate: date,
        mode: DailyInvestmentReviewMode.noTradeDay,
        performanceNote: '수정된 성과 메모',
        tradeReviewNote: '수정된 관망 메모',
        selectedDecisionTags: const [],
        selectedNoTradeReasons: const ['변동성이 커서 관망'],
        selectedEmotions: const ['불안함'],
        principleCheck: DailyInvestmentReviewPrincipleCheck.followedRules,
        riskNote: '진입을 참았다.',
        insightGood: '기다림.',
        insightWeak: '분석 부족.',
        insightRepeatOrAvoid: '뉴스만 보고 사지 않기.',
        nextPlan: '조건 재확인.',
      ),
    );

    final review = await repository.loadByDate(date);
    expect(review, isNotNull);
    expect(review!.status, DailyInvestmentReviewStatus.inProgress);
    expect(review.performanceNote, '수정된 성과 메모');

    final rows = await db
        .customSelect(
          'SELECT COUNT(*) AS count FROM daily_investment_reviews '
          'WHERE review_date = ?',
          variables: [Variable.withString('2026-06-01')],
        )
        .get();
    expect(rows.single.read<int>('count'), 1);
  });

  test(
    'markCompleted stores completed status and completed timestamp',
    () async {
      final date = DateTime(2026, 6, 1);
      await repository.saveDraft(
        DailyInvestmentReviewDraft.empty(
          reviewDate: date,
          mode: DailyInvestmentReviewMode.tradingDay,
        ).copyWith(performanceNote: '실현손익 확인', tradeReviewNote: '계획 매도'),
      );

      await repository.markCompleted(date);

      final review = await repository.loadByDate(date);
      expect(review, isNotNull);
      expect(review!.status, DailyInvestmentReviewStatus.completed);
      expect(review.completedAt, isNotNull);
    },
  );

  test('saveDraft preserves completed status for completed review', () async {
    final date = DateTime(2026, 6, 1);
    await repository.saveDraft(
      DailyInvestmentReviewDraft.empty(
        reviewDate: date,
        mode: DailyInvestmentReviewMode.tradingDay,
      ).copyWith(performanceNote: '실현손익 확인', tradeReviewNote: '계획 매도'),
    );
    await repository.markCompleted(date);
    final completed = await repository.loadByDate(date);

    await repository.saveDraft(
      DailyInvestmentReviewDraft.empty(
        reviewDate: date,
        mode: DailyInvestmentReviewMode.tradingDay,
      ).copyWith(performanceNote: '완료 후 수정', tradeReviewNote: '복기 보강'),
    );

    final review = await repository.loadByDate(date);
    expect(review, isNotNull);
    expect(review!.status, DailyInvestmentReviewStatus.completed);
    expect(review.completedAt, isNotNull);
    expect(review.completedAt, completed!.completedAt);
    expect(review.performanceNote, '완료 후 수정');
  });
}
