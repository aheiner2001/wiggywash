import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/profile.dart';
import '../models/scorecard_config.dart';
import '../models/submission.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets/profile_menu.dart';
import '../widgets/tally_row.dart';
import 'help_screen.dart';
import 'reports_screen.dart';
import 'summary_screen.dart';

final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

/// The employee's digital scorecard — a 1:1 of the physical tally card.
class ScorecardScreen extends StatefulWidget {
  const ScorecardScreen({super.key, required this.profile});
  final Profile profile;

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  final _baGoal = TextEditingController(text: '40');
  final Map<String, int> _counts = {for (final i in kLineItems) i.id: 0};

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  void _restoreDraft() {
    final draft = Store.instance.loadDraft(widget.profile.name);
    if (draft == null) return;
    final counts = (draft['counts'] as Map?) ?? {};
    for (final entry in counts.entries) {
      final id = entry.key as String;
      if (_counts.containsKey(id)) {
        _counts[id] = (entry.value as num).toInt();
      }
    }
    final goal = draft['baGoal'];
    if (goal != null) {
      _baGoal.text = (goal as num) == (goal).roundToDouble()
          ? goal.toStringAsFixed(0)
          : goal.toString();
    }
  }

  void _persistDraft() {
    Store.instance.saveDraft(
      widget.profile.name,
      counts: Map.of(_counts),
      baGoal: double.tryParse(_baGoal.text.trim()) ?? 0,
    );
  }

  @override
  void dispose() {
    _baGoal.dispose();
    super.dispose();
  }

  Submission get _live => Submission(
        id: 'live',
        employeeName: widget.profile.name,
        baGoal: double.tryParse(_baGoal.text.trim()) ?? 0,
        counts: Map.of(_counts),
        submittedAt: DateTime.now(),
      );

  bool get _hasAnyTally => _counts.values.any((c) => c > 0);

  void _set(String id, int value) {
    setState(() => _counts[id] = value);
    _persistDraft();
  }

  Future<void> _resetCard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear scorecard?'),
        content: const Text('This resets every tally back to zero.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        for (final i in kLineItems) {
          _counts[i.id] = 0;
        }
      });
      await Store.instance.clearDraft(widget.profile.name);
    }
  }

  Future<void> _submit() async {
    final submission = Submission(
      id: const Uuid().v4(),
      employeeName: widget.profile.name,
      baGoal: double.tryParse(_baGoal.text.trim()) ?? 0,
      counts: Map.of(_counts),
      submittedAt: DateTime.now(),
    );
    await Store.instance.addSubmission(submission);
    await Store.instance.clearDraft(widget.profile.name);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SummaryScreen(submission: submission),
      ),
    );
    setState(() {
      for (final i in kLineItems) {
        _counts[i.id] = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final live = _live;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Scorecard'),
        actions: [
          IconButton(
            tooltip: 'How to view the breakdown',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HelpScreen(audience: HelpAudience.employee),
              ),
            ),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          IconButton(
            tooltip: 'Clear scorecard',
            onPressed: _hasAnyTally ? _resetCard : null,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const ProfileAction(),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AnimatedBuilder(
              animation: Store.instance,
              builder: (context, _) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 120),
                  children: [
                    _MyTotalsCard(employeeName: widget.profile.name),
                    if (Store.instance.seeAll) ...[
                      const SizedBox(height: 8),
                      _TeamButton(),
                    ],
                    const SizedBox(height: 8),
                    _HeaderCard(
                      name: widget.profile.name,
                      baController: _baGoal,
                      live: live,
                      onBaChanged: () {
                        setState(() {});
                        _persistDraft();
                      },
                    ),
                    const SizedBox(height: 8),
                    ..._buildSections(),
                    const SizedBox(height: 12),
                    _SummaryCard(live: live),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: ElevatedButton.icon(
          onPressed: _hasAnyTally ? _submit : null,
          icon: const Icon(Icons.send_rounded),
          label: const Text('Submit Shift'),
        ),
      ),
    );
  }

  List<Widget> _buildSections() {
    final widgets = <Widget>[];
    for (final section in WashSection.values) {
      widgets.add(SectionPill(section.title));
      for (final item in itemsFor(section)) {
        widgets.add(
          TallyRow(
            item: item,
            count: _counts[item.id] ?? 0,
            onChanged: (v) => _set(item.id, v),
          ),
        );
      }
    }
    return widgets;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.baController,
    required this.live,
    required this.onBaChanged,
  });

  final String name;
  final TextEditingController baController;
  final Submission live;
  final VoidCallback onBaChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SCORECARD',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: AppColors.navy,
              )),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Name', style: TextStyles.caption),
                    const SizedBox(height: 2),
                    Text(name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BA Goal', style: TextStyles.caption),
                    const SizedBox(height: 2),
                    TextField(
                      controller: baController,
                      onChanged: (_) => onBaChanged(),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        suffixText: '%',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BA Actual', style: TextStyles.caption),
                    const SizedBox(height: 2),
                    Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(AppRadius.field),
                      ),
                      child: Text(
                        '${live.conversionRate.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.live});
  final Submission live;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Shift Summary', style: TextStyles.subheading),
          const SizedBox(height: 14),
          _StatRow(label: 'Memberships', value: '${live.totalMemberships}'),
          _StatRow(label: 'Single washes', value: '${live.totalSingleWashes}'),
          _StatRow(label: 'Shop sales', value: '${live.totalShopSales}'),
          _StatRow(
            label: 'Conversion (BA)',
            value: '${live.conversionRate.toStringAsFixed(0)}%',
          ),
          const Divider(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Revenue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  )),
              Text(
                _money.format(live.grandTotalRevenue),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyles.body),
          Text(value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}

/// Top-of-page card showing the employee's own submitted totals for today.
/// Tapping it opens their personal report list.
class _MyTotalsCard extends StatelessWidget {
  const _MyTotalsCard({required this.employeeName});
  final String employeeName;

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final mine = Store.instance.submissions.where((s) =>
        _isToday(s.submittedAt) &&
        s.employeeName.toLowerCase() == employeeName.toLowerCase());
    final revenue = mine.fold(0.0, (s, e) => s + e.grandTotalRevenue);
    final members = mine.fold(0, (s, e) => s + e.totalMemberships);
    final singles = mine.fold(0, (s, e) => s + e.totalSingleWashes);
    final shifts = mine.length;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ReportsScreen(title: 'My reports', filterName: employeeName),
        ),
      ),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your total today', style: TextStyles.caption),
                  const SizedBox(height: 4),
                  Text(_money.format(revenue),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    '$members members • $singles singles • $shifts shift(s)',
                    style: TextStyles.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Visible only when the manager enables "see all" — lets employees view the
/// whole team's submissions for today.
class _TeamButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ReportsScreen(title: 'Team today'),
        ),
      ),
      icon: const Icon(Icons.groups_rounded),
      label: const Text('View team totals'),
    );
  }
}
