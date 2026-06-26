import 'package:flutter/material.dart';

import '../theme.dart';

/// Who is viewing the help — tailors a couple of lines of copy.
enum HelpAudience { employee, manager }

/// A friendly, illustrated walkthrough explaining how to open the
/// "Full breakdown" view, using annotated app screenshots with arrows
/// pointing at exactly where to tap.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, this.audience = HelpAudience.employee});

  final HelpAudience audience;

  bool get _isManager => audience == HelpAudience.manager;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to view the breakdown')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              const _Intro(),
              const SizedBox(height: 16),
              _StepCard(
                number: 1,
                title: 'Submit at least one scorecard',
                body: _isManager
                    ? 'A full breakdown only appears once an employee has '
                        'submitted at least one shift today. Until then their '
                        'totals show as \$0.'
                    : 'Your breakdown only appears after you tally a shift and '
                        'tap "Submit Shift" at least once today. Before that, '
                        'your total shows \$0.',
                icon: Icons.fact_check_outlined,
              ),
              const SizedBox(height: 12),
              _StepCard(
                number: 2,
                title: _isManager
                    ? 'Open the Team Dashboard'
                    : 'Tap "Your total today"',
                body: _isManager
                    ? 'Each teammate gets their own card. Tap "Full breakdown" '
                        'on a card to expand their line-by-line totals.'
                    : 'On your scorecard, tap the "Your total today" card at the '
                        'very top. The arrow below points to it.',
                icon: Icons.touch_app_outlined,
                shot: const _AnnotatedShot(
                  asset: 'assets/help_tap_total.png',
                  aspectRatio: 1394 / 1364,
                  highlight: Rect.fromLTWH(0.085, 0.012, 0.78, 0.16),
                  label: 'Tap here',
                  labelAlignment: Alignment(0.0, -0.45),
                ),
              ),
              const SizedBox(height: 12),
              _StepCard(
                number: 3,
                title: 'See the Full breakdown',
                body: 'Your "Full breakdown" card lists every membership, '
                    'single wash and shop sale, plus the revenue for each '
                    'shift. It opens expanded so you can read it at a glance.',
                icon: Icons.receipt_long_outlined,
                shot: const _AnnotatedShot(
                  asset: 'assets/help_full_breakdown.png',
                  aspectRatio: 1712 / 1354,
                  highlight: Rect.fromLTWH(0.10, 0.24, 0.80, 0.10),
                  label: 'Your full breakdown',
                  labelAlignment: Alignment(0.0, -0.08),
                ),
              ),
              const SizedBox(height: 16),
              const _ShareNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded,
                color: AppColors.navy),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Want to see — and share — every wash, membership and shop '
              'sale you logged? Follow these three quick steps.',
              style: TextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
    this.shot,
  });

  final int number;
  final String title;
  final String body;
  final IconData icon;
  final Widget? shot;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18, color: AppColors.navy),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(title, style: TextStyles.subheading),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(body, style: TextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          if (shot != null) ...[
            const SizedBox(height: 14),
            shot!,
          ],
        ],
      ),
    );
  }
}

/// Shows a screenshot with a highlight box + a labelled arrow pointing to the
/// area the user should tap or look at. [highlight] is expressed as fractions
/// (0–1) of the image's width/height so it scales on any screen.
class _AnnotatedShot extends StatelessWidget {
  const _AnnotatedShot({
    required this.asset,
    required this.aspectRatio,
    required this.highlight,
    required this.label,
    required this.labelAlignment,
  });

  final String asset;
  final double aspectRatio;
  final Rect highlight;
  final String label;
  final Alignment labelAlignment;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(AppRadius.field),
          color: AppColors.background,
        ),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  Positioned(
                    left: highlight.left * w,
                    top: highlight.top * h,
                    width: highlight.width * w,
                    height: highlight.height * h,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accent, width: 3),
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.accent.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Align(
                    alignment: labelAlignment,
                    child: _Callout(label: label),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.arrow_upward_rounded,
            color: AppColors.accent, size: 26),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShareNote extends StatelessWidget {
  const _ShareNote();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.ios_share_rounded, size: 18, color: AppColors.navy),
              SizedBox(width: 6),
              Text('Sharing your breakdown', style: TextStyles.subheading),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'To send your breakdown to someone, take a screenshot on your '
            'phone (Side button + Volume Up on iPhone, or Power + Volume Down '
            'on Android) once the Full breakdown is open, then share the image.',
            style: TextStyles.caption,
          ),
        ],
      ),
    );
  }
}
