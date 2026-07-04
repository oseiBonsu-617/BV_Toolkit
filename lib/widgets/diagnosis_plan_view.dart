import 'package:flutter/material.dart';
import '../models/assessment.dart';
import '../theme.dart';

/// Renders a [DiagnosisPlan] — diagnosis name, optional diagnostic criteria,
/// tiered management options, patient advice, review schedule and referral
/// criteria. Wrap it in an [AppCard] with your own [CardTitle].
class DiagnosisPlanView extends StatelessWidget {
  final DiagnosisPlan plan;
  final bool showCriteria;

  const DiagnosisPlanView({
    super.key,
    required this.plan,
    this.showCriteria = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73);

    final byTier = <ManagementTier, List<ManagementOption>>{};
    for (final o in plan.options) {
      byTier.putIfAbsent(o.tier, () => []).add(o);
    }
    const tierOrder = [
      ManagementTier.firstLine,
      ManagementTier.secondLine,
      ManagementTier.adjunct,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Diagnosis name
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: kPrimary.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kPrimary.withAlpha(50), width: 0.5),
          ),
          child: Text(
            plan.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
        ),

        // Diagnostic criteria
        if (showCriteria && plan.criteria.isNotEmpty) ...[
          _sectionHeading('Diagnostic criteria', muted),
          const SizedBox(height: 6),
          ...plan.criteria.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5, right: 8),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: kPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      c,
                      style: const TextStyle(fontSize: 13, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Management options by tier
        ...tierOrder.where(byTier.containsKey).expand((tier) {
          final (bg, fg) = switch (tier) {
            ManagementTier.firstLine => (kOkBg, kOkText),
            ManagementTier.secondLine => (kWarnBg, kWarnTextDark),
            ManagementTier.adjunct => (kBadgeBlueBg, kBadgeBlueText),
          };
          return [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tier.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: fg,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            ...byTier[tier]!.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      o.detail,
                      style: TextStyle(fontSize: 12, height: 1.5, color: muted),
                    ),
                  ],
                ),
              ),
            ),
          ];
        }),

        // Patient advice
        const SizedBox(height: 2),
        _iconSection(
          Icons.person_outline,
          'Patient advice',
          plan.patientAdvice,
          muted,
        ),
        const SizedBox(height: 8),
        _iconSection(
          Icons.event_outlined,
          'Review',
          plan.reviewSchedule,
          muted,
        ),

        // Referral criteria
        if (plan.referralCriteria.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...plan.referralCriteria.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kWarnBg,
                border: Border.all(color: kWarnBorder, width: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    size: 14,
                    color: kWarnTextDark,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kWarnTextDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeading(String text, Color muted) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
      color: muted,
    ),
  );

  Widget _iconSection(IconData icon, String label, String content, Color muted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: kPrimary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: kPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: TextStyle(fontSize: 12, height: 1.5, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
