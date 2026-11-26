import 'package:flutter/material.dart';
import 'package:moneyfy/components/section_card.dart';
import 'package:moneyfy/design_system/context_extensions.dart';
import 'package:moneyfy/features/analysis/services/company_news_summary_service.dart';
import 'package:moneyfy/widgets/company_news_summary_card.dart';
import 'package:moneyfy/widgets/market_news_summary_card.dart';

class AnalysisNewsCards extends StatelessWidget {
  const AnalysisNewsCards({
    super.key,
    required this.marketNews,
    required this.companyNews,
  });

  final Future<MarketNewsSummary?> marketNews;
  final Future<List<CompanyNewsSummaryItem>> companyNews;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder<MarketNewsSummary?>(
          future: marketNews,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SectionCard(
                title: '종합 뉴스',
                child: LinearProgressIndicator(),
              );
            }
            return MarketNewsSummaryCard(summary: snapshot.data);
          },
        ),
        SizedBox(height: context.spacing.sectionGap),
        FutureBuilder<List<CompanyNewsSummaryItem>>(
          future: companyNews,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SectionCard(
                title: '종목별 뉴스',
                child: LinearProgressIndicator(),
              );
            }
            return CompanyNewsSummaryCard(items: snapshot.data ?? const []);
          },
        ),
      ],
    );
  }
}
