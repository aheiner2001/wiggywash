import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scorecard_config.dart';
import '../models/submission.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/profile_menu.dart';
import 'workers_screen.dart';

final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
final _dayLabel = DateFormat('EEEE, MMM d');
final _time = DateFormat('h:mm a');

/// Manager view: live team totals + per-employee breakdown, filterable by day.
class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  DateTime _day = DateTime.now();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _resetDay() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset this day?'),
        content: Text(
            'This permanently deletes every submission from ${_dayLabel.format(_day)}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) await Store.instance.resetDay(_day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Team roster',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WorkersScreen()),
            ),
            icon: const Icon(Icons.group_outlined),
          ),
          IconButton(
            tooltip: 'Pick date',
            onPressed: _pickDay,
            icon: const Icon(Icons.calendar_today_rounded),
          ),
          IconButton(
            tooltip: 'Reset day',
            onPressed: _resetDay,
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
          const ProfileAction(),
        ],
      ),
      body: AnimatedBuilder(
        animation: Store.instance,
        builder: (context, _) {
          final all = Store.instance.submissions
              .where((s) => _sameDay(s.submittedAt, _day))
              .toList();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
                children: [
                  _DayBar(
                    day: _day,
                    isToday: _sameDay(_day, DateTime.now()),
                    onTap: _pickDay,
                  ),
                  const SizedBox(height: 12),
                  _TeamTotals(submissions: all),
                  const SizedBox(height: 12),
                  if (all.isEmpty)
                    const _EmptyState()
                  else
                    ...(_byEmployee(all).entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _EmployeeCard(
                              name: e.key,
                              submissions: e.value,
                            ),
                          ),
                        )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, List<Submission>> _byEmployee(List<Submission> subs) {
    final map = <String, List<Submission>>{};
    for (final s in subs) {
      map.putIfAbsent(s.employeeName, () => []).add(s);
    }
    return map;
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.day, required this.isToday, required this.onTap});
  final DateTime day;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.event_rounded, color: AppColors.navy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dayLabel.format(day), style: TextStyles.subheading),
                Text(isToday ? 'Today — live' : 'Tap to change date',
                    style: TextStyles.caption),
              ],
            ),
          ),
          const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _TeamTotals extends StatelessWidget {
  const _TeamTotals({required this.submissions});
  final List<Submission> submissions;

  @override
  Widget build(BuildContext context) {
    final revenue =
        submissions.fold(0.0, (s, e) => s + e.grandTotalRevenue);
    final memberships =
        submissions.fold(0, (s, e) => s + e.totalMemberships);
    final singles = submissions.fold(0, (s, e) => s + e.totalSingleWashes);
    final shop = submissions.fold(0, (s, e) => s + e.totalShopSales);
    final totalWashes = memberships + singles;
    final conv = totalWashes == 0 ? 0.0 : memberships / totalWashes * 100;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Team Revenue', style: TextStyles.subheading),
              Text(_money.format(revenue),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Tile(label: 'Memberships', value: '$memberships'),
              _Tile(label: 'Singles', value: '$singles'),
              _Tile(label: 'Shop', value: '$shop'),
              _Tile(label: 'Team BA', value: '${conv.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 6),
          Text('${submissions.length} submission(s) today',
              style: TextStyles.caption),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                )),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.name, required this.submissions});
  final String name;
  final List<Submission> submissions;

  @override
  Widget build(BuildContext context) {
    final revenue = submissions.fold(0.0, (s, e) => s + e.grandTotalRevenue);
    final memberships = submissions.fold(0, (s, e) => s + e.totalMemberships);
    final singles = submissions.fold(0, (s, e) => s + e.totalSingleWashes);
    final shop = submissions.fold(0, (s, e) => s + e.totalShopSales);
    final totalWashes = memberships + singles;
    final conv = totalWashes == 0 ? 0.0 : memberships / totalWashes * 100;
    final latestGoal = submissions
        .reduce((a, b) => a.submittedAt.isAfter(b.submittedAt) ? a : b)
        .baGoal;
    final hitGoal = conv >= latestGoal && latestGoal > 0;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.navy,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyles.subheading),
                    Text('${submissions.length} shift(s)',
                        style: TextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hitGoal ? AppColors.success : AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'BA ${conv.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: hitGoal ? Colors.white : AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Tile(label: 'Members', value: '$memberships'),
              _Tile(label: 'Singles', value: '$singles'),
              _Tile(label: 'Shop', value: '$shop'),
              _Tile(label: 'Revenue', value: _money.format(revenue)),
            ],
          ),
          const SizedBox(height: 12),
          _Breakdown(submissions: submissions),
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.submissions});
  final List<Submission> submissions;

  int _count(String id) =>
      submissions.fold(0, (s, e) => s + e.countOf(id));

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: const Text('Full breakdown',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            )),
        children: [
          for (final section in WashSection.values) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Text(section.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.roseText,
                    )),
              ),
            ),
            for (final item in itemsFor(section))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.label, style: TextStyles.body),
                    Text('${_count(item.id)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        )),
                  ],
                ),
              ),
          ],
          const Divider(height: 20),
          for (final s in submissions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Shift at ${_time.format(s.submittedAt)}',
                      style: TextStyles.caption),
                  Text(_money.format(s.grandTotalRevenue),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: const [
          Icon(Icons.inbox_rounded, size: 64, color: AppColors.hairline),
          SizedBox(height: 12),
          Text('No submissions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
              )),
          SizedBox(height: 4),
          Text('Employee scorecards will appear here live.',
              style: TextStyles.caption),
        ],
      ),
    );
  }
}
