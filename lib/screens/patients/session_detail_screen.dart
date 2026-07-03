import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/assessment.dart';
import '../../models/test_session.dart';
import '../../services/assessment_engine.dart';
import '../../services/session_service.dart';
import '../../theme.dart';
import '../../widgets/criterion_graph.dart';
import '../../widgets/result_card.dart';

class SessionDetailScreen extends StatelessWidget {
  final TestSession session;
  const SessionDetailScreen({super.key, required this.session});

  double? _n(String key) => session.numVal(key);
  bool _isFinite(double? v) => v != null && v.isFinite;
  bool _isPositiveFinite(double? v) => _isFinite(v) && v! > 0;
  bool _has(List<String> keys) => keys.any((k) => session.data.containsKey(k));

  DiagnosisPlan? get _plan => AssessmentEngine().planFromSession(session);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(DateFormat('d MMM yyyy').format(session.date)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kBadText),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (session.visitNote != null) ...[
            _noteCard(isDark),
            const SizedBox(height: 10),
          ],
          if (_has(['ph_dist', 'ph_near'])) ...[
            _phoriaCard(isDark),
            const SizedBox(height: 10),
          ],
          if (_has(['ipd', 'gp1'])) ...[
            _acaCard(isDark),
            const SizedBox(height: 10),
          ],
          if (_has(['npc_brk', 'npc_rec'])) ...[
            _npcCard(isDark),
            const SizedBox(height: 10),
          ],
          if (_has([
            'bi_blur_d',
            'bi_brk_d',
            'bi_rec_d',
            'bo_blur_d',
            'bo_brk_d',
            'bo_rec_d',
          ])) ...[
            _vergenceCard(isDark, dist: true),
            const SizedBox(height: 10),
          ],
          if (_has([
            'bi_blur_n',
            'bi_brk_n',
            'bi_rec_n',
            'bo_blur_n',
            'bo_brk_n',
            'bo_rec_n',
          ])) ...[
            _vergenceCard(isDark, dist: false),
            const SizedBox(height: 10),
          ],
          if (_has(['sh_ph', 'sh_cv'])) ...[
            _sheardsCard(isDark),
            const SizedBox(height: 10),
          ],
          if (_has(['pc_bo', 'pc_bi'])) ...[
            _percivsCard(isDark),
            const SizedBox(height: 10),
          ],
          if (_has([
            'dx_pd',
            'dx_pn',
            'dx_aca',
            'dx_nb',
            'dx_age',
            'dx_amp',
            'dx_fac_bin',
            'dx_mem',
            'dx_bi_brk',
            'dx_bo_brk',
            'dx_fac_fail',
          ])) ...[
            _diagnosisCard(isDark),
            const SizedBox(height: 10),
          ],
          if (_plan != null) ...[
            _managementSection(isDark, _plan!),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ─── Note ──────────────────────────────────────────────────────────────────

  Widget _noteCard(bool isDark) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CardTitle(icon: Icons.notes_outlined, text: 'Visit note'),
        Text(
          session.visitNote!,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
    ),
  );

  // ─── Phoria ────────────────────────────────────────────────────────────────

  Widget _phoriaCard(bool isDark) {
    final pd = _n('ph_dist'), pn = _n('ph_near');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.remove_red_eye_outlined, text: 'Phoria'),
          if (_isFinite(pd)) _phoriaResult(pd!, 'Distance phoria'),
          if (_isFinite(pn)) _phoriaResult(pn!, 'Near phoria', near: true),
        ],
      ),
    );
  }

  Widget _phoriaResult(double val, String label, {bool near = false}) {
    final a = val.abs();
    final type = val == 0
        ? 'Orthophoria'
        : val > 0
        ? 'Exophoria'
        : 'Esophoria';
    final exoLimit = near ? 6.0 : 4.0;
    final inNorm = val == 0 || (val > 0 && val <= exoLimit);
    final isLarge = a > 10 || val < -4;
    final cls = inNorm
        ? ResultType.ok
        : isLarge
        ? ResultType.bad
        : ResultType.warn;
    return ResultCard(
      type: cls,
      label: label,
      value: '${a.toStringAsFixed(1)}Δ  $type',
      note: inNorm ? "Within Morgan's norm" : 'Outside norm',
    );
  }

  // ─── AC/A ──────────────────────────────────────────────────────────────────

  Widget _acaCard(bool isDark) {
    final method = session.str('aca_method') ?? 'calc';
    double? ratio;
    if (method == 'calc') {
      final ipd = _n('ipd'),
          pd = _n('ph_dist'),
          pn = _n('ph_near'),
          nd = _n('ndist');
      if (_isPositiveFinite(ipd) &&
          _isFinite(pd) &&
          _isFinite(pn) &&
          _isPositiveFinite(nd)) {
        ratio = (ipd! / 10) + (pd! - pn!) / (1 / (nd! / 100));
      }
    } else {
      final p1 = _n('gp1'), p2 = _n('gp2'), lens = _n('glens');
      if (_isFinite(p1) && _isFinite(p2) && _isFinite(lens) && lens != 0) {
        ratio = (p2! - p1!).abs() / lens!.abs();
      }
    }
    final cls = ratio == null
        ? null
        : ratio < 3 || ratio > 7
        ? ResultType.bad
        : ratio <= 5
        ? ResultType.ok
        : ResultType.warn;
    final lbl = ratio == null
        ? null
        : ratio < 3
        ? 'Low AC/A'
        : ratio <= 5
        ? 'Normal AC/A'
        : ratio <= 7
        ? 'High AC/A'
        : 'Very high AC/A';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.functions, text: 'AC/A ratio'),
          _dataRow(
            isDark,
            'Method',
            method == 'calc' ? 'Calculated' : 'Gradient',
          ),
          if (_n('ipd') != null)
            _dataRow(isDark, 'IPD', '${_n('ipd')!.toStringAsFixed(0)} mm'),
          if (_n('ndist') != null)
            _dataRow(
              isDark,
              'Near dist',
              '${_n('ndist')!.toStringAsFixed(0)} cm',
            ),
          if (_n('gp1') != null)
            _dataRow(
              isDark,
              'Phoria habitual',
              '${_n('gp1')!.toStringAsFixed(1)}Δ',
            ),
          if (_n('gp2') != null)
            _dataRow(
              isDark,
              'Phoria + lens',
              '${_n('gp2')!.toStringAsFixed(1)}Δ',
            ),
          if (_n('glens') != null)
            _dataRow(
              isDark,
              'Lens power',
              '${_n('glens')!.toStringAsFixed(2)} D',
            ),
          if (ratio != null && cls != null && lbl != null)
            ResultCard(
              type: cls,
              label: 'AC/A ratio',
              value: '${ratio.toStringAsFixed(1)} : 1  $lbl',
              note: ratio < 3
                  ? 'Associated with CI.'
                  : ratio <= 5
                  ? 'Normal range (3–5 Δ/D).'
                  : ratio <= 7
                  ? 'Associated with CE.'
                  : 'Evaluate for accommodative ET.',
            ),
        ],
      ),
    );
  }

  // ─── NPC ───────────────────────────────────────────────────────────────────

  Widget _npcCard(bool isDark) {
    final b = _n('npc_brk'), r = _n('npc_rec');
    ResultType? cls;
    String? lbl;
    if (b != null && r != null) {
      final bOk = b <= 5, rOk = r <= 7;
      cls = (bOk && rOk)
          ? ResultType.ok
          : (!bOk && !rOk)
          ? ResultType.bad
          : ResultType.warn;
      lbl = (bOk && rOk)
          ? 'Normal NPC'
          : (!bOk && !rOk)
          ? 'Receded NPC'
          : 'Borderline NPC';
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.open_with, text: 'NPC'),
          if (b != null)
            _dataRow(isDark, 'Break', '${b.toStringAsFixed(1)} cm'),
          if (r != null)
            _dataRow(isDark, 'Recovery', '${r.toStringAsFixed(1)} cm'),
          if (cls != null && lbl != null)
            ResultCard(
              type: cls,
              label: 'NPC status',
              value: lbl,
              note:
                  'Break ${b!.toStringAsFixed(1)} cm / Recovery ${r!.toStringAsFixed(1)} cm',
            ),
        ],
      ),
    );
  }

  // ─── Vergence ──────────────────────────────────────────────────────────────

  Widget _vergenceCard(bool isDark, {required bool dist}) {
    final sfx = dist ? 'd' : 'n';
    final label = dist ? 'Vergence — Distance' : 'Vergence — Near';
    final normMap = dist
        ? <String, double?>{
            'bi_blur': null,
            'bi_brk': 7,
            'bi_rec': 4,
            'bo_blur': 9,
            'bo_brk': 19,
            'bo_rec': 10,
          }
        : <String, double?>{
            'bi_blur': 13,
            'bi_brk': 21,
            'bi_rec': 13,
            'bo_blur': 17,
            'bo_brk': 21,
            'bo_rec': 11,
          };

    final rows = <_VD>[];
    for (final entry in normMap.entries) {
      final v = _n('${entry.key}_$sfx');
      if (v != null) rows.add(_VD(_vergLabel(entry.key), v, entry.value));
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(icon: Icons.compare_arrows, text: label),
          ...rows.asMap().entries.map(
            (e) => _vergRow(isDark, e.value, e.key == rows.length - 1),
          ),
        ],
      ),
    );
  }

  String _vergLabel(String key) => switch (key) {
    'bi_blur' => 'BI blur',
    'bi_brk' => 'BI break',
    'bi_rec' => 'BI recovery',
    'bo_blur' => 'BO blur',
    'bo_brk' => 'BO break',
    'bo_rec' => 'BO recovery',
    _ => key,
  };

  Widget _vergRow(bool isDark, _VD row, bool isLast) {
    final norm = row.norm;
    String badge = '';
    Color badgeBg = kOkBg;
    Color badgeFg = kOkText;
    if (norm != null) {
      final diff = row.val - norm;
      if (diff.abs() <= 2) {
        badge = 'Norm';
      } else if (diff < 0) {
        badge = '${diff.abs().toStringAsFixed(0)}Δ low';
        badgeBg = kBadBg;
        badgeFg = kBadTextDark;
      } else {
        badge = '${diff.toStringAsFixed(0)}Δ high';
        badgeBg = kWarnBg;
        badgeFg = kWarnTextDark;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            row.label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            ),
          ),
          Row(
            children: [
              Text(
                '${row.val.toStringAsFixed(0)}Δ',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (badge.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: badgeFg,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Sheard's ──────────────────────────────────────────────────────────────

  Widget _sheardsCard(bool isDark) {
    final ph = _n('sh_ph'), cv = _n('sh_cv');
    Widget? result;
    if (ph != null && cv != null) {
      final a = ph.abs();
      final pass = cv >= 2 * a;
      final prism = ((2 * a - cv) / 3).clamp(0.0, double.infinity);
      final dir = ph >= 0 ? 'BI' : 'BO';
      result = ResultCard(
        type: pass ? ResultType.ok : ResultType.bad,
        label: "Sheard's",
        value: pass ? 'Passes ✓' : 'Fails ✗',
        note: pass
            ? 'CV (${cv.toStringAsFixed(0)}Δ) ≥ 2 × phoria (${a.toStringAsFixed(1)}Δ)'
            : 'Prism needed: ${prism.toStringAsFixed(2)}Δ $dir',
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.balance_outlined,
            text: "Sheard's criterion",
          ),
          if (ph != null)
            _dataRow(isDark, 'Phoria', '${ph.toStringAsFixed(1)}Δ'),
          if (cv != null)
            _dataRow(isDark, 'Comp. vergence', '${cv.toStringAsFixed(0)}Δ'),
          ?result,
          if (_isFinite(ph) && _isFinite(cv))
            SheardsGraph(phoria: ph!, compensatingVergence: cv!),
        ],
      ),
    );
  }

  // ─── Percival's ────────────────────────────────────────────────────────────

  Widget _percivsCard(bool isDark) {
    final bo = _n('pc_bo'), bi = _n('pc_bi');
    Widget? result;
    if (bo != null && bi != null) {
      final G = bo > bi ? bo : bi, L = bo < bi ? bo : bi;
      final pass = L >= G / 2;
      final prism = (G / 3 - (2 * L) / 3).clamp(0.0, double.infinity);
      final dir = bo < bi ? 'BI' : 'BO';
      result = ResultCard(
        type: pass ? ResultType.ok : ResultType.bad,
        label: "Percival's",
        value: pass ? 'Passes ✓' : 'Fails ✗',
        note: pass
            ? 'Lesser (${L.toStringAsFixed(0)}Δ) ≥ half of greater (${G.toStringAsFixed(0)}Δ)'
            : 'Prism needed: ${prism.toStringAsFixed(2)}Δ $dir',
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.horizontal_distribute,
            text: "Percival's criterion",
          ),
          if (bo != null)
            _dataRow(isDark, 'BO blur/break', '${bo.toStringAsFixed(0)}Δ'),
          if (bi != null)
            _dataRow(isDark, 'BI blur/break', '${bi.toStringAsFixed(0)}Δ'),
          ?result,
          if (_isFinite(bo) && _isFinite(bi)) PercivalsGraph(bo: bo!, bi: bi!),
        ],
      ),
    );
  }

  // ─── Diagnosis ─────────────────────────────────────────────────────────────

  Widget _diagnosisCard(bool isDark) {
    final rows = <Widget>[];
    void addNum(String lbl, String key, String Function(double) fmt) {
      final v = _n(key);
      if (v != null) rows.add(_dataRow(isDark, lbl, fmt(v)));
    }

    addNum('Dist phoria', 'dx_pd', (v) => '${v.toStringAsFixed(1)}Δ');
    addNum('Near phoria', 'dx_pn', (v) => '${v.toStringAsFixed(1)}Δ');
    addNum('AC/A', 'dx_aca', (v) => '${v.toStringAsFixed(1)} : 1');
    addNum('NPC break', 'dx_nb', (v) => '${v.toStringAsFixed(1)} cm');
    addNum('Age', 'dx_age', (v) => '${v.toStringAsFixed(0)} yrs');
    addNum('Amplitude', 'dx_amp', (v) => '${v.toStringAsFixed(2)} D');
    addNum(
      'Bino. facility',
      'dx_fac_bin',
      (v) => '${v.toStringAsFixed(0)} cpm',
    );
    addNum('MEM lag', 'dx_mem', (v) => '${v.toStringAsFixed(2)} D');
    addNum('BI break', 'dx_bi_brk', (v) => '${v.toStringAsFixed(0)}Δ');
    addNum('BO break', 'dx_bo_brk', (v) => '${v.toStringAsFixed(0)}Δ');
    final facFail = session.str('dx_fac_fail');
    if (facFail != null && facFail.isNotEmpty) {
      rows.add(_dataRow(isDark, 'Flipper fail', facFail));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.medical_services_outlined,
            text: 'Diagnosis inputs',
          ),
          ...rows,
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _dataRow(bool isDark, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  // ─── Management plan (derived from measurements) ──────────────────────────

  Widget _managementSection(bool isDark, DiagnosisPlan plan) {
    final byTier = <ManagementTier, List<ManagementOption>>{};
    for (final o in plan.options) {
      byTier.putIfAbsent(o.tier, () => []).add(o);
    }
    final tierOrder = [
      ManagementTier.firstLine,
      ManagementTier.secondLine,
      ManagementTier.adjunct,
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.healing_outlined,
            text: 'Management plan',
          ),

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

          // Options by tier
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6E6E73),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          }),

          // Patient advice
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person_outline, size: 14, color: kPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient advice',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.patientAdvice,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6E6E73),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Review
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.event_outlined, size: 14, color: kPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Review',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.reviewSchedule,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6E6E73),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete session?'),
        content: Text(
          'Remove session from ${DateFormat('d MMM yyyy').format(session.date)}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<SessionService>().delete(session);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: kBadText)),
          ),
        ],
      ),
    );
  }
}

class _VD {
  final String label;
  final double val;
  final double? norm;
  _VD(this.label, this.val, this.norm);
}
