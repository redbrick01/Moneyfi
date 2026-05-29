import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyfy/db/app_database.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/pages/analysis_page.dart';
import 'package:moneyfy/pages/app_shell_page.dart';
import 'package:moneyfy/pages/asset_detail_page.dart';
import 'package:moneyfy/pages/cash_account_detail_page.dart';
import 'package:moneyfy/pages/forms/transaction_form_page.dart';
import 'package:moneyfy/pages/holding_detail_page.dart';
import 'package:moneyfy/pages/portfolio_analysis_mvp_page.dart';
import 'package:moneyfy/pages/portfolio_dashboard_page.dart';
import 'package:moneyfy/pages/portfolio_page.dart';
import 'package:moneyfy/pages/statistics_page.dart';
import 'package:moneyfy/pages/transactions_page.dart';
import 'package:moneyfy/services/company_news_summary_service.dart';
import 'package:moneyfy/widgets/company_news_summary_card.dart';
import 'package:moneyfy/widgets/market_news_summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _installPathProviderMock();
  setUpAll(() async {
    await _loadScreenshotFonts();
    _seedIds = await _seedDesignMdData();
  });

  for (final screenshotCase in _designMdScreenshotCases) {
    testWidgets('design-md screenshot harness: ${screenshotCase.fileStem} '
        '${_formatWidthDp(screenshotCase.widthDp)}dp '
        'ts${_formatTextScale(screenshotCase.textScale)}', (tester) async {
      await _pumpScreenshotCase(tester, screenshotCase);

      await screenshotCase.prepare?.call(tester);
      await _waitForReadyFinder(
        tester,
        screenshotCase.readyFinder,
        allowRealAsync: screenshotCase.allowRealAsyncSettle,
      );
      await _settleScreenshotFrame(
        tester,
        allowRealAsync: screenshotCase.allowRealAsyncSettle,
      );

      final exception = tester.takeException();
      expect(exception, isNull);

      if (_shouldCaptureScreenshots && screenshotCase.captureEnabled) {
        await _captureScreenshot(
          fileName:
              '${screenshotCase.fileStem}_${_formatWidthDp(screenshotCase.widthDp)}dp'
              '_ts${_formatTextScale(screenshotCase.textScale)}.png',
        );
      }
    });
  }
}

const _screenshotRoot =
    'docs/features/simple_patches/design_md_full_compliance/screenshots/after';
const _surfaceHeightDp = 844.0;
const _captureEnvName = 'MONEYFY_CAPTURE_DESIGN_MD_SCREENSHOTS';
final _shouldCaptureScreenshots = Platform.environment[_captureEnvName] == '1';
final _screenshotBoundaryKey = GlobalKey();
final _testDocumentsDirectory = Directory.systemTemp.createTempSync(
  'moneyfy_design_md_screenshots_',
);
late final _DesignMdSeedIds _seedIds;

void _installPathProviderMock() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        return switch (call.method) {
          'getApplicationDocumentsDirectory' => _testDocumentsDirectory.path,
          'getTemporaryDirectory' => _testDocumentsDirectory.path,
          _ => null,
        };
      });
}

Future<void> _loadScreenshotFonts() async {
  final textFont = File('/System/Library/Fonts/AppleSDGothicNeo.ttc');
  if (textFont.existsSync()) {
    final textLoader = FontLoader('.SF Pro Text')
      ..addFont(_loadFontData(textFont.path));
    final displayLoader = FontLoader('.SF Pro Display')
      ..addFont(_loadFontData(textFont.path));
    await textLoader.load();
    await displayLoader.load();
  }

  final materialIconFont = File(
    '/usr/local/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (materialIconFont.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(_loadFontData(materialIconFont.path));
    await loader.load();
  }
}

Future<ByteData> _loadFontData(String path) async {
  final bytes = await File(path).readAsBytes();
  return ByteData.view(bytes.buffer);
}

Future<_DesignMdSeedIds> _seedDesignMdData() async {
  final db = AppDatabase.instance;
  await db.clearAllLocalUserData();

  final stockAssetId = await db.createAsset(
    assetType: '주식',
    title: '주식',
    alias: '주식',
    hidden: false,
    currencyCode: 'KRW',
    value: '₩0',
    change: '+0.0%',
    icon: Icons.account_balance_rounded,
    quantityLabel: '보유',
    quantityValue: '0개',
    averageLabel: '수익률',
    averageValue: '+0.0%',
    note: 'Design-MD screenshot seed',
  );
  final coinAssetId = await db.createAsset(
    assetType: '코인',
    title: '코인',
    alias: '코인',
    hidden: false,
    currencyCode: 'KRW',
    value: '₩0',
    change: '+0.0%',
    icon: Icons.currency_bitcoin_rounded,
    quantityLabel: '보유',
    quantityValue: '0개',
    averageLabel: '수익률',
    averageValue: '+0.0%',
    note: 'Design-MD screenshot seed',
  );
  final cashAssetId = await db.createAsset(
    assetType: '현금',
    title: '현금',
    alias: '현금',
    hidden: false,
    currencyCode: 'KRW',
    value: '₩0',
    change: '+0.0%',
    icon: Icons.savings_rounded,
    quantityLabel: '계좌',
    quantityValue: '0개',
    averageLabel: '잔액',
    averageValue: '₩0',
    note: 'Design-MD screenshot seed',
  );

  final samsungHoldingId = await db.createHolding(
    assetId: stockAssetId,
    currencyCode: 'KRW',
    exchangeCode: 'KRX',
    name: '삼성전자',
    symbol: '',
    quantity: 12,
    averagePrice: 68000,
    currentPrice: 74200,
    note: '국내 대표 보유 종목',
  );
  final appleHoldingId = await db.createHolding(
    assetId: stockAssetId,
    currencyCode: 'KRW',
    exchangeCode: 'NAS',
    name: 'Apple Inc.',
    symbol: 'AAPL',
    quantity: 4,
    averagePrice: 245000,
    currentPrice: 285000,
    note: '해외 성장주',
  );
  final btcHoldingId = await db.createHolding(
    assetId: coinAssetId,
    currencyCode: 'KRW',
    exchangeCode: 'UPBIT',
    name: 'Bitcoin',
    symbol: 'BTC',
    quantity: 0.18234567,
    averagePrice: 96500000,
    currentPrice: 108400000,
    note: '소수점 수량 overflow 확인',
  );
  final cashHoldingId = await db.createHolding(
    assetId: cashAssetId,
    currencyCode: 'KRW',
    exchangeCode: '',
    name: '토스증권 위탁계좌',
    symbol: '',
    quantity: 3200000,
    averagePrice: 1,
    currentPrice: 1,
    note: '거래 대기 현금',
  );

  await db.createTransaction(
    assetId: stockAssetId,
    holdingId: samsungHoldingId,
    date: '2026.05.27',
    type: '매수',
    name: '삼성전자',
    amount: '74200',
    quantity: '2',
    includeInCalculations: false,
  );
  await db.createTransaction(
    assetId: stockAssetId,
    holdingId: appleHoldingId,
    date: '2026.05.26',
    type: '배당',
    name: 'Apple Inc.',
    amount: '18400',
    quantity: '',
    includeInCalculations: false,
  );
  await db.createTransaction(
    assetId: coinAssetId,
    holdingId: btcHoldingId,
    date: '2026.05.25',
    type: '매도',
    name: 'Bitcoin',
    amount: '108400000',
    quantity: '0.01234567',
    includeInCalculations: false,
    manualRealizedProfitAmount: 128000,
  );
  await db.createTransaction(
    assetId: cashAssetId,
    holdingId: cashHoldingId,
    date: '2026.05.24',
    type: '입금',
    name: '월 투자 예수금',
    amount: '1000000',
    quantity: '',
    includeInCalculations: false,
  );

  await db.saveAssetAllocationTargets({
    stockAssetId: 62,
    coinAssetId: 18,
    cashAssetId: 20,
  });

  return _DesignMdSeedIds(
    stockAssetId: stockAssetId,
    samsungHoldingId: samsungHoldingId,
    cashHoldingId: cashHoldingId,
  );
}

Future<void> _pumpScreenshotCase(
  WidgetTester tester,
  _DesignMdScreenshotCase screenshotCase,
) async {
  final view = tester.view;
  view.devicePixelRatio = 1.0;
  view.physicalSize = Size(screenshotCase.widthDp, _surfaceHeightDp);
  addTearDown(() {
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(screenshotCase.textScale)),
          child: RepaintBoundary(
            key: _screenshotBoundaryKey,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: screenshotCase.build(),
    ),
  );
  await _settleScreenshotFrame(
    tester,
    allowRealAsync: screenshotCase.allowRealAsyncSettle,
  );
}

Future<void> _waitForReadyFinder(
  WidgetTester tester,
  Finder? finder, {
  required bool allowRealAsync,
}) async {
  if (finder == null) return;

  for (var i = 0; i < 40; i++) {
    if (finder.evaluate().isNotEmpty) return;
    if (allowRealAsync) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  expect(finder, findsWidgets);
}

Future<void> _settleScreenshotFrame(
  WidgetTester tester, {
  required bool allowRealAsync,
}) async {
  for (var i = 0; i < 28; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  if (allowRealAsync) {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      });
      await tester.pump(const Duration(milliseconds: 120));
    }
  }
}

Future<void> _captureScreenshot({required String fileName}) async {
  final boundary =
      _screenshotBoundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1);
  try {
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final directory = Directory(_screenshotRoot);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      await File('${directory.path}/$fileName').writeAsBytes(bytes);
    });
  } finally {
    image.dispose();
  }
}

String _formatTextScale(double value) {
  return value.toStringAsFixed(1).replaceAll('.', '_');
}

String _formatWidthDp(double value) {
  final rounded = value.roundToDouble();
  if (value == rounded) return rounded.toInt().toString();
  return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
}

final _designMdScreenshotCases = <_DesignMdScreenshotCase>[
  _DesignMdScreenshotCase(
    fileStem: 'dashboard_data',
    widthDp: 390,
    readyFinder: find.text('주식'),
    build: () => const PortfolioDashboardPage(),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'dashboard_data',
    widthDp: 430,
    readyFinder: find.text('주식'),
    build: () => const PortfolioDashboardPage(),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'portfolio_data',
    widthDp: 390,
    readyFinder: find.text('리밸런싱'),
    build: () => const PortfolioPage(),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'portfolio_data',
    widthDp: 430,
    readyFinder: find.text('리밸런싱'),
    build: () => const PortfolioPage(),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'transactions_data',
    widthDp: 390,
    readyFinder: find.text('삼성전자'),
    build: () => const TransactionsPage(),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'transactions_data',
    widthDp: 430,
    readyFinder: find.text('삼성전자'),
    build: () => const TransactionsPage(),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'transactions_overflow_risk',
    widthDp: 360,
    textScale: 1.3,
    readyFinder: find.text('삼성전자'),
    build: () => const TransactionsPage(),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'transaction_form_keyboard_risk',
    widthDp: 360,
    textScale: 1.3,
    build: () => TransactionFormPage(
      assetId: _seedIds.stockAssetId,
      holdingId: _seedIds.samsungHoldingId,
      defaultName: '삼성전자',
    ),
    prepare: (tester) async {
      final searchField = find.widgetWithText(
        TextField,
        '예: 005930, AAPL, BTC',
      );
      if (searchField.evaluate().isNotEmpty) {
        await tester.tap(searchField);
      }
    },
  ),
  _DesignMdScreenshotCase(
    fileStem: 'transaction_form_keyboard_risk',
    widthDp: 430,
    build: () => TransactionFormPage(
      assetId: _seedIds.stockAssetId,
      holdingId: _seedIds.samsungHoldingId,
      defaultName: '삼성전자',
    ),
    prepare: (tester) async {
      final searchField = find.widgetWithText(
        TextField,
        '예: 005930, AAPL, BTC',
      );
      if (searchField.evaluate().isNotEmpty) {
        await tester.tap(searchField);
      }
    },
  ),
  _DesignMdScreenshotCase(
    fileStem: 'asset_detail_data',
    widthDp: 390,
    readyFinder: find.text('삼성전자'),
    build: () => AssetDetailPage(assetId: _seedIds.stockAssetId),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'asset_detail_data',
    widthDp: 430,
    readyFinder: find.text('삼성전자'),
    build: () => AssetDetailPage(assetId: _seedIds.stockAssetId),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'holding_detail_data',
    widthDp: 390,
    readyFinder: find.text('삼성전자'),
    build: () => HoldingDetailPage(holdingId: _seedIds.samsungHoldingId),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'holding_detail_data',
    widthDp: 430,
    readyFinder: find.text('삼성전자'),
    build: () => HoldingDetailPage(holdingId: _seedIds.samsungHoldingId),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'cash_account_detail_data',
    widthDp: 390,
    readyFinder: find.text('토스증권 위탁계좌'),
    build: () => CashAccountDetailPage(holdingId: _seedIds.cashHoldingId),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'cash_account_detail_data',
    widthDp: 430,
    readyFinder: find.text('토스증권 위탁계좌'),
    build: () => CashAccountDetailPage(holdingId: _seedIds.cashHoldingId),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'portfolio_analysis_mvp_data',
    widthDp: 390,
    build: () => const PortfolioAnalysisMvpPage(),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'statistics_data',
    widthDp: 390,
    build: () => const StatisticsPage(),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'company_news_card_data',
    widthDp: 390,
    build: () => const _ScreenshotShell(
      child: CompanyNewsSummaryCard(items: _sampleCompanyNewsItems),
    ),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'market_news_card_data',
    widthDp: 390,
    build: () => const _ScreenshotShell(
      child: MarketNewsSummaryCard(summary: _sampleMarketNewsSummary),
    ),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'app_shell_data',
    widthDp: 390,
    captureEnabled: false,
    allowRealAsyncSettle: false,
    build: () => const AppShellPage(),
  ),
  _DesignMdScreenshotCase(
    fileStem: 'analysis_hub_data',
    widthDp: 390,
    captureEnabled: false,
    allowRealAsyncSettle: false,
    build: () => const AnalysisPage(),
  ),
];

class _DesignMdScreenshotCase {
  const _DesignMdScreenshotCase({
    required this.fileStem,
    required this.widthDp,
    required this.build,
    this.textScale = 1.0,
    this.captureEnabled = true,
    this.allowRealAsyncSettle = true,
    this.readyFinder,
    this.prepare,
  });

  final String fileStem;
  final double widthDp;
  final double textScale;
  final bool captureEnabled;
  final bool allowRealAsyncSettle;
  final Finder? readyFinder;
  final Widget Function() build;
  final Future<void> Function(WidgetTester tester)? prepare;
}

class _DesignMdSeedIds {
  const _DesignMdSeedIds({
    required this.stockAssetId,
    required this.samsungHoldingId,
    required this.cashHoldingId,
  });

  final int stockAssetId;
  final int samsungHoldingId;
  final int cashHoldingId;
}

class _ScreenshotShell extends StatelessWidget {
  const _ScreenshotShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.contentHorizontalPadding),
          child: child,
        ),
      ),
    );
  }
}

const _sampleCompanyNewsItems = [
  CompanyNewsSummaryItem(
    symbol: 'AAPL',
    found: true,
    assetType: '주식',
    summaryDate: '2026-05-29',
    model: 'design-md-fixture',
    newsCount: 12,
    summary: {
      'company_summary': '신제품 수요와 서비스 매출이 동시에 주목받고 있어요.',
      'issues': [
        {
          'title': '서비스 매출 성장세',
          'summary': '구독 매출이 안정적으로 늘며 실적 방어력이 높아졌어요.',
          'importance': '3',
        },
        {
          'title': '환율과 공급망 비용',
          'summary': '달러 강세와 부품 비용은 단기 변동성 요인이에요.',
          'importance': '2',
        },
      ],
      'outlook': {'label': '중립', 'summary': '실적 안정성은 높지만 밸류에이션 부담은 확인이 필요해요.'},
    },
  ),
  CompanyNewsSummaryItem(
    symbol: 'BTC',
    found: true,
    assetType: '코인',
    summaryDate: '2026-05-29',
    model: 'design-md-fixture',
    newsCount: 9,
    summary: {
      'company_summary': 'ETF 자금 흐름과 금리 기대가 가격 움직임을 좌우하고 있어요.',
      'issues': [
        {
          'title': 'ETF 순유입 둔화',
          'summary': '단기 수급은 약해졌지만 장기 보유 수요는 유지되고 있어요.',
          'importance': '2',
        },
      ],
      'outlook': {'label': '주의', 'summary': '변동성이 커질 수 있어 비중 관리가 필요해요.'},
    },
  ),
];

const _sampleMarketNewsSummary = MarketNewsSummary(
  marketSummary: '금리 인하 기대와 반도체 실적 개선이 위험자산 선호를 지지하고 있어요.',
  keyRisk: '물가 재가속과 달러 강세',
  riskAssets: '미국 성장주, 반도체, 비트코인',
  safeAssets: '단기채, 달러 현금',
  newsCount: 18,
  model: 'design-md-fixture',
  updatedAt: '2026-05-29T09:00:00',
  issues: [
    MarketIssue(
      title: '금리 인하 기대 재부각',
      summary: '채권 금리가 낮아지며 성장주 할인율 부담이 완화됐어요.',
      importance: '3',
      stocks: '성장주에 긍정적',
      bondsRates: '장기금리 하락',
      fx: '달러 혼조',
      crypto: '위험 선호 개선',
    ),
    MarketIssue(
      title: '반도체 실적 전망 개선',
      summary: 'AI 서버 수요가 이어지며 관련 업종의 이익 전망이 상향됐어요.',
      importance: '2',
      stocks: '반도체 강세',
      bondsRates: '중립',
      fx: '원화 변동성 확대',
      crypto: '직접 영향 제한',
    ),
  ],
);
