import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/scorecard_config.dart';
import '../models/submission.dart';
import '../theme.dart';

final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
final _date = DateFormat('EEE, MMM d • h:mm a');

/// Clean, screenshot-friendly recap shown right after a shift is submitted.
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key, required this.submission});
  final Submission submission;

  String _shareText() {
    final b = StringBuffer()
      ..writeln('🚗 WIGGY WASH — Shift Scorecard')
      ..writeln(submission.employeeName)
      ..writeln(_date.format(submission.submittedAt))
      ..writeln('')
      ..writeln('Memberships: ${submission.totalMemberships}')
      ..writeln('Single washes: ${submission.totalSingleWashes}')
      ..writeln('Shop sales: ${submission.totalShopSales}')
      ..writeln(
          'BA: ${submission.conversionRate.toStringAsFixed(0)}% (goal ${submission.baGoal.toStringAsFixed(0)}%)')
      ..writeln('Total revenue: ${_money.format(submission.grandTotalRevenue)}');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final hitGoal = submission.conversionRate >= submission.baGoal &&
        submission.baGoal > 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Submitted'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: hitGoal ? AppColors.success : AppColors.navy,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          hitGoal
                              ? Icons.emoji_events_rounded
                              : Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hitGoal ? 'Goal smashed!' : 'Shift logged',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _RecapCard(submission: submission),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () => Share.share(_shareText()),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Share to BA chat'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to scorecard'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecapCard extends StatelessWidget {
  const _RecapCard({required this.submission});
  final Submission submission;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(submission.employeeName, style: TextStyles.heading),
          Text(_date.format(submission.submittedAt),
              style: TextStyles.caption),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'BA Actual',
                  value:
                      '${submission.conversionRate.toStringAsFixed(0)}%',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'BA Goal',
                  value: '${submission.baGoal.toStringAsFixed(0)}%',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Revenue',
                  value: _money.format(submission.grandTotalRevenue),
                  highlight: true,
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          for (final section in WashSection.values)
            _SectionBlock(section: section, submission: submission),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section, required this.submission});
  final WashSection section;
  final Submission submission;

  @override
  Widget build(BuildContext context) {
    final rows = itemsFor(section)
        .where((i) => submission.countOf(i.id) > 0)
        .toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionPill(section.title),
        const SizedBox(height: 4),
        for (final item in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${item.label}  ×${submission.countOf(item.id)}',
                    style: TextStyles.body),
                Text(
                  item.hasPrice
                      ? _money.format(submission.countOf(item.id) * item.price!)
                      : '—',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: highlight ? AppColors.success : AppColors.navy,
            )),
        const SizedBox(height: 2),
        Text(label, style: TextStyles.caption),
      ],
    );
  }
}
