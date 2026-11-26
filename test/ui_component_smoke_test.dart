import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

import 'package:moneyfy/components/buttons/app_buttons.dart';
import 'package:moneyfy/components/expandable/expandable_tile.dart';
import 'package:moneyfy/components/forms/form_design.dart';
import 'package:moneyfy/components/headers/detail_header_card.dart';
import 'package:moneyfy/components/metrics/app_metric_tile.dart';
import 'package:moneyfy/components/panels/app_detail_section.dart';
import 'package:moneyfy/components/panels/app_floating_menu_surface.dart';
import 'package:moneyfy/components/panels/app_inner_panel.dart';
import 'package:moneyfy/components/panels/app_sheet_surface.dart';
import 'package:moneyfy/components/rows/asset_row.dart';
import 'package:moneyfy/components/rows/transaction_row.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/components/states/empty_state.dart';
import 'package:moneyfy/components/states/inline_error.dart';
import 'package:moneyfy/components/states/retry_row.dart';
import 'package:moneyfy/design_system/app_theme.dart';
import 'package:moneyfy/design_system/app_typography.dart';
import 'package:moneyfy/design_system/brand/brand_palette.dart';
import 'package:moneyfy/design_system/tokens.dart';
import 'package:moneyfy/design_system/spec.dart';
import 'package:moneyfy/features/analysis/screens/investment_performance_page.dart';
import 'package:moneyfy/ui_scaffold/app_page_scaffold.dart';
import 'package:moneyfy/widgets/moneyfy_ui.dart';

void main() {
  Future<void> pumpUi(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('SectionCard renders with title/body', (tester) async {
    await pumpUi(tester, const SectionCard(title: '섹션', child: Text('내용')));
    expect(find.text('섹션'), findsOneWidget);
    expect(find.text('내용'), findsOneWidget);
  });

  testWidgets('DetailHeaderCard renders metrics', (tester) async {
    await pumpUi(
      tester,
      const DetailHeaderCard(
        title: '종목명',
        primaryText: '₩12,300,000',
        secondaryRows: [Text('당일 +1.2%')],
      ),
    );
    expect(find.text('종목명'), findsOneWidget);
    expect(find.text('₩12,300,000'), findsOneWidget);
  });

  testWidgets('Panel surfaces render child content', (tester) async {
    await pumpUi(
      tester,
      const Column(
        children: [
          AppInnerPanel(child: Text('내부 패널')),
          AppFloatingMenuSurface(child: Text('메뉴 표면')),
          AppSheetSurface(child: AppSheetHandle()),
          AppDetailSection(title: '상세 섹션', child: Text('섹션 내용')),
          AppMetricTile(label: '수익률', value: '+4.2%'),
        ],
      ),
    );
    expect(find.text('내부 패널'), findsOneWidget);
    expect(find.text('메뉴 표면'), findsOneWidget);
    expect(find.text('상세 섹션'), findsOneWidget);
    expect(find.text('섹션 내용'), findsOneWidget);
    expect(find.text('수익률'), findsOneWidget);
    expect(find.text('+4.2%'), findsOneWidget);
  });

  testWidgets('AssetRow and TransactionRow render tap targets', (tester) async {
    await pumpUi(
      tester,
      Column(
        children: const [
          AssetRow(
            leading: Icon(Icons.pie_chart_outline_rounded),
            title: '주식',
            subtitle: 'KRW',
            amountText: '₩5,000,000',
          ),
          TransactionRow(
            typeLabel: '매수',
            title: '삼성전자',
            subtitle: '2026.03.20 · 수량 2',
            amountText: '₩140,000',
          ),
        ],
      ),
    );
    expect(find.text('주식'), findsOneWidget);
    expect(find.text('매수'), findsOneWidget);
  });

  testWidgets('AssetRow can reserve at least half width for title', (
    tester,
  ) async {
    await pumpUi(
      tester,
      SizedBox(
        width: 320,
        child: AssetRow(
          leading: const SizedBox.shrink(),
          showLeading: false,
          title: '미국AI테스트보유종목장기이름',
          subtitle: 'TEST · 20',
          amountText: '₩1,923,040',
          titleMinWidthFraction: 0.5,
          deltaChip: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('+₩367,600'),
                SizedBox(width: 8),
                Text('+32.9%'),
              ],
            ),
          ),
        ),
      ),
    );

    final titleBox = tester.renderObject<RenderBox>(
      find.text('미국AI테스트보유종목장기이름'),
    );
    expect(titleBox.constraints.maxWidth, greaterThanOrEqualTo(100));
  });

  testWidgets('State widgets render', (tester) async {
    await pumpUi(
      tester,
      SizedBox(
        width: 360,
        child: Column(
          children: [
            EmptyStateCard(
              title: '데이터 없음',
              description: '새 항목을 추가하세요.',
              actionLabel: '추가',
              onAction: () {},
            ),
            const InlineError(message: '네트워크 오류'),
            RetryRow(message: '다시 시도해 주세요', onRetry: () {}),
          ],
        ),
      ),
    );
    expect(find.text('데이터 없음'), findsOneWidget);
    expect(find.text('네트워크 오류'), findsOneWidget);
    expect(find.text('재시도'), findsOneWidget);
  });

  testWidgets('MoneyfyPage paints scaffold background on pushed pages', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const MoneyfyPage(title: '분석', children: [Text('내용')]),
      ),
    );
    await tester.pumpAndSettle();

    final material = tester.widget<Material>(
      find.ancestor(of: find.text('분석'), matching: find.byType(Material)).first,
    );

    expect(material.color, AppTheme.light.scaffoldBackgroundColor);
    expect(find.text('내용'), findsOneWidget);
  });

  testWidgets('ExpandableTile expands and collapses', (tester) async {
    await pumpUi(
      tester,
      const ExpandableTile(
        title: '이슈 제목',
        subtitle: '요약',
        children: [Text('확장 내용')],
      ),
    );
    expect(find.text('확장 내용'), findsNothing);
    await tester.tap(find.text('이슈 제목'));
    await tester.pumpAndSettle();
    expect(find.text('확장 내용'), findsOneWidget);
  });

  test('default typography is achromatic and readable on app surfaces', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final type = theme.extension<AppTypography>()!;
      final surfaces = theme.extension<AppSurfaceRoles>()!;
      expect(type.pageTitle.color, type.sectionTitle.color);
      expect(type.heroNumber.color, type.pageTitle.color);
      expect(type.pageTitle.color, type.body.color);
      expect(type.body.color, theme.colorScheme.onSurface);
      expect(type.caption.color, theme.colorScheme.onSurfaceVariant);
      for (final color in [type.body.color!, type.caption.color!]) {
        expect(color.r, color.g);
        expect(color.g, color.b);
      }
      for (final surface in [
        surfaces.appBackground,
        surfaces.surfaceBase,
        surfaces.surfaceRaised,
      ]) {
        for (final text in [type.pageTitle, type.body, type.caption]) {
          final a = text.color!.computeLuminance() + 0.05;
          final b = surface.computeLuminance() + 0.05;
          expect(a > b ? a / b : b / a, greaterThanOrEqualTo(4.5));
        }
      }
    }
  });

  test('warning text has contrast on common theme surfaces', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final colors = theme.extension<BrandColors>()!;
      final surfaces = theme.extension<AppSurfaceRoles>()!;
      for (final background in [
        surfaces.appBackground,
        surfaces.surfaceBase,
        surfaces.surfaceRaised,
      ]) {
        final warning = colors.warningOn.computeLuminance() + 0.05;
        final surface = background.computeLuminance() + 0.05;
        final contrast = warning > surface
            ? warning / surface
            : surface / warning;
        expect(contrast, greaterThanOrEqualTo(4.5));
      }
    }
  });

  test('theme actions and status text use the brand colors', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final scheme = theme.colorScheme;
      expect(scheme.primary, VisualSpec.brand.seedColor);
      expect(scheme.onPrimary, VisualSpec.brand.lightSurface);
      final brand = theme.extension<BrandColors>()!;
      expect(brand.gainOn, VisualSpec.brand.brandRed);
      expect(brand.lossOn, scheme.primary);
      expect(brand.positiveOn, scheme.primary);
      expect(brand.negativeOn, VisualSpec.brand.brandRed);
      expect(scheme.error, VisualSpec.brand.brandRed);
      expect(scheme.onErrorContainer, VisualSpec.brand.brandRed);
      expect(
        scheme.onPrimaryContainer,
        scheme.brightness == Brightness.light ? scheme.primary : scheme.onPrimary,
      );
    }
  });

  testWidgets('transaction labels fit at narrow widths with larger type', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpUi(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.3),
          ),
          child: const TransactionRow(
            typeLabel: '배당·분배금',
            title: '테스트 자산',
            subtitle: '2026-11-21',
            amountText: '+₩100,000',
          ),
        ),
      ),
    );
    for (final width in [360.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpAndSettle();
      final label = tester.renderObject<RenderParagraph>(find.text('배당·분배금'));
      expect(label.didExceedMaxLines, isFalse, reason: 'width: $width');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('positive and negative attribution use semantic foregrounds', (
    tester,
  ) async {
    await pumpUi(
      tester,
      buildPerformanceAttributionForTesting({
        '실현 손익': 2000,
        '평가 손익': -1000,
      }),
    );

    final colors = AppTheme.light.extension<BrandColors>()!;
    for (final (label, color) in [
      ('+₩2,000', colors.negativeOn),
      ('-₩1,000', colors.positiveOn),
    ]) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.style?.color, color);
    }
    expect(tester.takeException(), isNull);
  });

  test('web app manifest uses the light theme brand and canvas', () {
    final manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final theme = AppTheme.light;
    String hex(Color color) =>
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

    expect(
      manifest['theme_color'].toString().toLowerCase(),
      hex(VisualSpec.brand.seedColor),
    );
    expect(
      manifest['background_color'].toString().toLowerCase(),
      hex(theme.scaffoldBackgroundColor),
    );
  });

  testWidgets('edit forms use the shared primary button', (tester) async {
    var saves = 0;
    await pumpUi(
      tester,
      MoneyfyFormScaffold(
        title: '편집',
        actionLabel: '저장',
        isSaving: false,
        onSave: () => saves++,
        children: const [Text('입력 필드')],
      ),
    );

    expect(find.byType(AppPrimaryButton), findsOneWidget);
    final button = find.widgetWithText(FilledButton, '저장');
    expect(
      tester.getSize(button).height,
      greaterThanOrEqualTo(VisualSpec.icon.minTapTarget),
    );
    await tester.tap(button);
    expect(saves, 1);
  });

  testWidgets('AppPageScaffold form renders fixed CTA', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: AppPageScaffold.form(
          title: '폼',
          primaryActionLabel: '저장',
          onPrimaryActionPressed: () {},
          body: const Text('입력 필드'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('폼'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
  });
}
