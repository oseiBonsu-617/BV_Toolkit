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
      text: widget.patient.age?.toString() ?? '',
    );
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
      vaDistance: _vaDistCtrl.text.trim().isEmpty
          ? null
          : _vaDistCtrl.text.trim(),
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
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF2F2F7),
      appBar: AppBar(title: Text('Assess — ${widget.patient.firstName}')),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
                            : (isDark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6E6E73)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        symptom.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: selected ? Colors.white : null,
                          fontWeight: selected
                              ? FontWeight.w500
                              : FontWeight.normal,
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
          const CardTitle(
            icon: Icons.remove_red_eye_outlined,
            text: 'Cover Test',
          ),
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
          const CardTitle(
            icon: Icons.monitor_heart_outlined,
            text: 'Visual Acuity',
          ),
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
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6E6E73),
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
        border: Border.all(color: kPrimary.withAlpha(60), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: kPrimary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.track_changes_outlined,
                            color: kPrimary,
                            size: 18,
                          ),
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
                            color: isDark
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF6E6E73),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        result.rationale,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.55,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6E6E73),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
            icon: Icons.warning_amber_outlined,
            text: 'Clinical flags',
          ),
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
            icon: Icons.checklist_outlined,
            text: 'Recommended tests',
          ),
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
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
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
}
