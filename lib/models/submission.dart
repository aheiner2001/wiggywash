import 'scorecard_config.dart';

/// A single submitted (or in-progress) shift scorecard.
class Submission {
  Submission({
    required this.id,
    required this.employeeName,
    required this.baGoal,
    required this.counts,
    required this.submittedAt,
  });

  final String id;
  final String employeeName;

  /// Business-average goal entered by the employee, as a percentage (e.g. 40).
  final double baGoal;

  /// Map of line-item id -> tally count.
  final Map<String, int> counts;
  final DateTime submittedAt;

  int countOf(String id) => counts[id] ?? 0;

  int sectionCount(WashSection section) => itemsFor(section)
      .fold(0, (sum, item) => sum + countOf(item.id));

  int get totalMemberships => sectionCount(WashSection.membership);
  int get totalSingleWashes => sectionCount(WashSection.single);
  int get totalShopSales => sectionCount(WashSection.shop);

  /// Total cars that bought any wash (memberships + single washes).
  int get totalWashes => totalMemberships + totalSingleWashes;

  double sectionRevenue(WashSection section) =>
      itemsFor(section).fold(0.0, (sum, item) {
        if (!item.hasPrice) return sum;
        return sum + countOf(item.id) * item.price!;
      });

  double get grandTotalRevenue =>
      kLineItems.fold(0.0, (sum, item) {
        if (!item.hasPrice) return sum;
        return sum + countOf(item.id) * item.price!;
      });

  /// BA Actual / conversion rate: share of washes that became memberships.
  double get conversionRate {
    if (totalWashes == 0) return 0;
    return totalMemberships / totalWashes * 100;
  }

  Submission copyWith({
    String? employeeName,
    double? baGoal,
    Map<String, int>? counts,
    DateTime? submittedAt,
  }) {
    return Submission(
      id: id,
      employeeName: employeeName ?? this.employeeName,
      baGoal: baGoal ?? this.baGoal,
      counts: counts ?? this.counts,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeName': employeeName,
        'baGoal': baGoal,
        'counts': counts,
        'submittedAt': submittedAt.toIso8601String(),
      };

  factory Submission.fromJson(Map<String, dynamic> json) {
    final rawCounts = (json['counts'] as Map?) ?? {};
    return Submission(
      id: json['id'] as String,
      employeeName: json['employeeName'] as String? ?? 'Unknown',
      baGoal: (json['baGoal'] as num?)?.toDouble() ?? 0,
      counts: rawCounts.map((k, v) => MapEntry(k as String, (v as num).toInt())),
      submittedAt:
          DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}
