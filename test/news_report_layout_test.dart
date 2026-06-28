import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/features/analysis/services/company_news_summary_service.dart';
import 'package:moneyfy/widgets/company_news_summary_card.dart';
import 'package:moneyfy/widgets/market_news_summary_card.dart';

void main() {
  Future<void> pumpReportCard(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('market news card separates insight from long report body', (
    tester,
  ) async {
    const summary = MarketNewsSummary(
      marketSummary: '핵심 결론: 지정학 리스크와 AI 수요가 동시에 시장을 흔들고 있어요.',
      keyRisk: '에너지 가격과 금리 변동성',
      riskAssets: '성장주, 반도체, 코인',
      safeAssets: '단기채, 현금',
      newsCount: 25,
      model: 'gemma4:latest',
      updatedAt: '2026-06-13T07:17:18Z',
      issues: [
        MarketIssue(
          title: '마켓 / general',
          summary:
              '첫 번째 문단입니다. 미국과 이란 협상 가능성이 커지면서 에너지 공급망 리스크가 재평가되고 있습니다.\n\n'
              '두 번째 문단입니다. 동시에 AI 데이터센터 수요가 전력 장비와 반도체 업종 기대를 끌어올리고 있습니다.',
          importance: '3',
          stocks: '위험자산 변동성 확대',
          bondsRates: null,
          fx: null,
          crypto: null,
        ),
        MarketIssue(
          title: 'AI 인프라',
          summary: '세 번째 문단입니다. 전력 장비와 데이터센터 투자가 리포트의 보조 논점입니다.',
          importance: '2',
          stocks: '전력 장비 수요 확인',
          bondsRates: null,
          fx: null,
          crypto: null,
        ),
      ],
    );

    await pumpReportCard(tester, const MarketNewsSummaryCard(summary: summary));

    expect(find.text('핵심 결론'), findsOneWidget);
    expect(find.text('리포트 본문'), findsNothing);
    expect(find.textContaining('첫 번째 문단입니다'), findsNothing);

    await tester.tap(find.text('전체 리포트 보기'));
    await tester.pumpAndSettle();

    expect(find.text('리포트 본문'), findsOneWidget);
    expect(find.text('이슈별 영향'), findsNothing);
    expect(find.text('종합 평가'), findsNothing);
    expect(find.textContaining('지정학 리스크'), findsOneWidget);
    expect(find.textContaining('첫 번째 문단입니다'), findsOneWidget);
  });

  testWidgets('market news card hides insight section without final insight', (
    tester,
  ) async {
    const summary = MarketNewsSummary(
      marketSummary: '',
      keyRisk: 'API가 만든 종합평가는 표시하지 않습니다.',
      riskAssets: '위험자산',
      safeAssets: '안전자산',
      newsCount: 25,
      model: 'gemma4:latest',
      updatedAt: '2026-06-13T07:17:18Z',
      issues: [
        MarketIssue(
          title: '마켓 / general',
          summary: '본문 문단입니다. final_insight_ko가 없으면 본문만 보여야 합니다.',
          importance: '3',
          stocks: null,
          bondsRates: null,
          fx: null,
          crypto: null,
        ),
      ],
    );

    await pumpReportCard(tester, const MarketNewsSummaryCard(summary: summary));

    expect(find.text('핵심 결론'), findsNothing);
    expect(find.text('종합 평가'), findsNothing);
    expect(find.text('리포트 본문'), findsNothing);
    expect(find.textContaining('본문 문단입니다'), findsNothing);

    await tester.tap(find.text('전체 리포트 보기'));
    await tester.pumpAndSettle();

    expect(find.text('리포트 본문'), findsOneWidget);
    expect(find.textContaining('본문 문단입니다'), findsOneWidget);
  });

  testWidgets('company news card expands into report reader layout', (
    tester,
  ) async {
    const item = CompanyNewsSummaryItem(
      symbol: 'TSLA',
      found: true,
      assetType: '주식',
      summaryDate: '2026-06-13',
      model: 'gemma4:latest',
      newsCount: 19,
      summary: {
        'company_summary': '스페이스X 상장 이슈가 테슬라 투자심리를 흔들고 있어요.',
        'issues': [
          {
            'title': 'TSLA',
            'summary':
                '첫 번째 문단입니다. 스페이스X 자금 유입과 테슬라 매도 압력이 동시에 관찰됩니다.\n\n'
                '두 번째 문단입니다. 에너지 저장장치 수요와 FSD 승인 여부가 다음 관전 포인트입니다.',
            'importance': '3',
          },
          {
            'title': 'TSLA',
            'summary': '세 번째 문단입니다. 충전 네트워크와 에너지 사업은 보조 논점입니다.',
            'importance': '2',
          },
        ],
        'outlook': {
          'business_impact': '본업 경쟁력 확인이 필요합니다.',
          'market_view': '단기 변동성이 확대될 수 있습니다.',
          'watchpoint': 'FSD 승인과 머스크 관련 자본 흐름',
        },
      },
    );

    await pumpReportCard(
      tester,
      const CompanyNewsSummaryCard(items: [item]),
    );

    expect(find.text('핵심 결론'), findsNothing);
    expect(find.text('리포트 본문'), findsNothing);
    expect(find.textContaining('첫 번째 문단입니다'), findsNothing);

    await tester.tap(find.text('TSLA').first);
    await tester.pumpAndSettle();

    expect(find.text('핵심 결론'), findsOneWidget);
    expect(find.text('리포트 본문'), findsOneWidget);
    expect(find.text('이슈별 영향'), findsNothing);
    expect(find.text('사업 영향'), findsNothing);
    expect(find.text('시장 시각'), findsNothing);
    expect(find.text('체크 포인트'), findsNothing);
    expect(find.textContaining('스페이스X 상장 이슈'), findsWidgets);
    expect(find.textContaining('첫 번째 문단입니다'), findsOneWidget);
  });

  testWidgets('company news card hides insight section without final insight', (
    tester,
  ) async {
    const item = CompanyNewsSummaryItem(
      symbol: 'TSLA',
      found: true,
      assetType: '주식',
      summaryDate: '2026-06-13',
      model: 'gemma4:latest',
      newsCount: 19,
      summary: {
        'company_summary': '',
        'issues': [
          {
            'title': 'TSLA',
            'summary': '본문 문단입니다. final_insight_ko가 없으면 본문만 보여야 합니다.',
            'importance': '3',
          },
        ],
      },
    );

    await pumpReportCard(
      tester,
      const CompanyNewsSummaryCard(items: [item]),
    );

    await tester.tap(find.text('TSLA').first);
    await tester.pumpAndSettle();

    expect(find.text('핵심 결론'), findsNothing);
    expect(find.text('리포트 본문'), findsOneWidget);
    expect(find.textContaining('본문 문단입니다'), findsOneWidget);
  });
}
