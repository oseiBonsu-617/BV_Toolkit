import 'package:flutter/material.dart';
import '../../models/assessment.dart';
import '../../models/patient.dart';
import '../../services/assessment_engine.dart';
import '../../theme.dart';
import '../../widgets/result_card.dart';
import '../patients/session_record_screen.dart';

class AssessmentScreen extends StatefulWidget {
  final Patient patient;
  const AssessmentScreen({super.key, required this.patient});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final Set<Symptom> _symptoms = {};
  CoverResult? _coverDist;
  CoverResult? _coverNear;
  final _vaDistCtrl = TextEditingController();
  final _vaNearCtrl = TextEditingController();
  late final TextEditingController _ageCtrl;
  AssessmentResult? _result;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _ageCtrl = TextEditingController(
        text: widget.patient.age?.toString() ?? '');
  }

  @override
  void dispose() {
    _vaDistCtrl.dispose();
    _vaNearCtrl.dispose();
    _ageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool get _canAssess =>
      _symptoms.isNotEmpty || _coverDist != null || _coverNear != null;

  void _assess() {
    final input = AssessmentInput(
      symptoms: Set.from(_symptoms),
      coverDistance: _coverDist,
      coverNear: _coverNear,
      vaDistance: _vaDistCtrl.text.trim().isEmpty ? null : _vaDistCtrl.text.trim(),
      vaNear: _vaNearCtrl.text.trim().isEmpty ? null : _vaNearCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()),
    );
    final result = AssessmentEngine().assess(input);
    setState(() => _result = result);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _beginSession(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionRecordScreen(
          patientId: widget.patient.id,
          recommendations: _result!.allSections,
          assessmentImpression: _result!.primaryImpression,
        ),
      ),
    ).then((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text('Assess — ${widget.patient.firstName}'),
      ),
      body: ListView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(14),
        children: [
          _symptomsCard(isDark),
          const SizedBox(height: 10),
          _coverCard(isDark),
          const SizedBox(height: 10),
          _vaCard(isDark),
          const SizedBox(height: 10),
          _ageCard(isDark),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _canAssess ? _assess : null,
            child: const Text('Assess'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _impressionCard(isDark),
            if (_result!.flags.isNotEmpty) _flagsCard(isDark),
            _recommendationsCard(isDark),
            if (_result!.plan != null) ...[
              _diagnosisCard(isDark),
              _managementCard(isDark),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _beginSession(context),
              child: const Text('Begin Session'),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── Symptoms card ─────────────────────────────────────────────────────────

  Widget _symptomsCard(bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.chat_bubble_outline, text: 'Symptoms'),
          const InfoBox(child: Text('Select all that apply')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Symptom.values.map((symptom) {
              final selected = _symptoms.contains(symptom);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _symptoms.remove(symptom);
                  } else {
                    _symptoms.add(symptom);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? kPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? kPrimary : kPrimary.withAlpha(100),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        symptom.icon,
                        size: 16,
                        color: selected
                            ? Colors.white
                            : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        symptom.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: selected ? Colors.white : null,
                          fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Cover card ────────────────────────────────────────────────────────────

  Widget _coverCard(bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.remove_red_eye_outlined, text: 'Cover Test'),
          const SectionLabel('Distance'),
          const SizedBox(height: 6),
          Row(
            children: CoverResult.values.map((r) {
              final sel = _coverDist == r;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _coverChip(r.label, sel, () {
                  setState(() => _coverDist = sel ? null : r);
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const SectionLabel('Near'),
          const SizedBox(height: 6),
          Row(
            children: CoverResult.values.map((r) {
              final sel = _coverNear == r;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _coverChip(r.label, sel, () {
                  setState(() => _coverNear = sel ? null : r);
                }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _coverChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? kPrimary : kPrimary.withAlpha(100),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : null,
            fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ─── VA card ────────────────────────────────────────────────────────────────

  Widget _vaCard(bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.monitor_heart_outlined, text: 'Visual Acuity'),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distance VA',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6E6E73),
                      ),
                    ),
                    const SizedBox(height: 3),
                    TextField(
                      controller: _vaDistCtrl,
                      decoration: const InputDecoration(
                        hintText: '6/6',
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Near VA',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6E6E73),
                      ),
                    ),
                    const SizedBox(height: 3),
                    TextField(
                      controller: _vaNearCtrl,
                      decoration: const InputDecoration(
                        hintText: 'N5',
                        hintStyle: TextStyle(fontSize: 13),
                      ),
                      style: const TextStyle(fontSize: 13),
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

  // ─── Age card ───────────────────────────────────────────────────────────────

  Widget _ageCard(bool isDark) {
    final autoFilled = widget.patient.age != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.person_outline, text: 'Patient details'),
          Text(
            'Age (years)',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 3),
          TextField(
            controller: _ageCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '25',
              hintStyle: TextStyle(fontSize: 13),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          if (autoFilled) ...[
            const SizedBox(height: 6),
            Text(
              'Auto-filled from date of birth',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Impression card ────────────────────────────────────────────────────────

  Widget _impressionCard(bool isDark) {
    final result = _result!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kPrimary.withAlpha(15),
        border: Border(
          left: BorderSide(color: kPrimary, width: 4),
          top: BorderSide(color: kPrimary.withAlpha(60), width: 0.5),
          right: BorderSide(color: kPrimary.withAlpha(60), width: 0.5),
          bottom: BorderSide(color: kPrimary.withAlpha(60), width: 0.5),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes_outlined, color: kPrimary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.primaryImpression,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (result.differential != null) ...[
            const SizedBox(height: 4),
            Text(
              'Consider: ${result.differential}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            result.rationale,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Flags card ─────────────────────────────────────────────────────────────

  Widget _flagsCard(bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
              icon: Icons.warning_amber_outlined, text: 'Clinical flags'),
          Column(
            children: _result!.flags.map((flag) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kWarnBg,
                  border: Border.all(color: kWarnBorder, width: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  flag,
                  style: const TextStyle(fontSize: 12, color: kWarnTextDark),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Recommendations card ────────────────────────────────────────────────

  Widget _recommendationsCard(bool isDark) {
    final recs = _result!.sorted;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
              icon: Icons.checklist_outlined, text: 'Recommended tests'),
          Column(
            children: recs.asMap().entries.map((entry) {
              final i = entry.key;
              final rec = entry.value;
              final isLast = i == recs.length - 1;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: isDark
                                ? const Color(0xFF38383A)
                                : const Color(0xFFE5E5EA),
                            width: 0.5,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.section.label,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rec.rationale,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6E6E73),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _priorityPill(rec.priority),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _priorityPill(TestPriority p) => switch (p) {
        TestPriority.high => Pill.normal('High'),
        TestPriority.medium => Pill.warn('Med'),
        TestPriority.low => Pill.info('Low'),
      };

  // ─── Diagnosis card ─────────────────────────────────────────────────────────

  Widget _diagnosisCard(bool isDark) {
    final plan = _result!.plan!;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle(icon: Icons.local_hospital_outlined, text: 'Diagnosis'),
        Text(plan.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text('Diagnostic criteria',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            )),
        const SizedBox(height: 6),
        ...plan.criteria.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              margin: const EdgeInsets.only(top: 5, right: 8),
              width: 5, height: 5,
              decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
            ),
            Expanded(child: Text(c, style: const TextStyle(fontSize: 13, height: 1.45))),
          ]),
        )),
      ]),
    );
  }

  // ─── Management card ─────────────────────────────────────────────────────────

  Widget _managementCard(bool isDark) {
    final plan = _result!.plan!;
    final byTier = <ManagementTier, List<ManagementOption>>{};
    for (final o in plan.options) {
      byTier.putIfAbsent(o.tier, () => []).add(o);
    }
    final tierOrder = [ManagementTier.firstLine, ManagementTier.secondLine, ManagementTier.adjunct];

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle(icon: Icons.healing_outlined, text: 'Management plan'),

        // Options grouped by tier
        ...tierOrder.where(byTier.containsKey).expand((tier) {
          final opts = byTier[tier]!;
          return [
            _tierLabel(tier, isDark),
            ...opts.map((o) => _managementOptionRow(o, isDark, opts.last == o)),
            const SizedBox(height: 4),
          ];
        }),

        // Patient advice
        const SizedBox(height: 4),
        _planSection(isDark, Icons.person_outline, 'Patient advice', plan.patientAdvice),

        // Review schedule
        const SizedBox(height: 8),
        _planSection(isDark, Icons.event_outlined, 'Review', plan.reviewSchedule),

        // Referral criteria
        if (plan.referralCriteria.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Referral criteria',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
              )),
          const SizedBox(height: 6),
          ...plan.referralCriteria.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kWarnBg,
              border: Border.all(color: kWarnBorder, width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_outlined, size: 14, color: kWarnTextDark),
              const SizedBox(width: 6),
              Expanded(child: Text(r,
                  style: const TextStyle(fontSize: 12, color: kWarnTextDark, height: 1.4))),
            ]),
          )),
        ],
      ]),
    );
  }

  Widget _tierLabel(ManagementTier tier, bool isDark) {
    final (bg, fg) = switch (tier) {
      ManagementTier.firstLine  => (kOkBg, kOkText),
      ManagementTier.secondLine => (kWarnBg, kWarnTextDark),
      ManagementTier.adjunct    => (kBadgeBlueBg, kBadgeBlueText),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(tier.label.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _managementOptionRow(ManagementOption opt, bool isDark, bool isLast) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(opt.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(opt.detail,
            style: TextStyle(
              fontSize: 12, height: 1.5,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            )),
      ]),
    );
  }

  Widget _planSection(bool isDark, IconData icon, String label, String content) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14, color: kPrimary),
      const SizedBox(width: 6),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kPrimary)),
        const SizedBox(height: 2),
        Text(content,
            style: TextStyle(
              fontSize: 12, height: 1.5,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            )),
      ])),
    ]);
  }
}
