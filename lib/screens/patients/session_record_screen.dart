import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/assessment.dart';
import '../../models/test_session.dart';
import '../../services/assessment_engine.dart';
import '../../services/session_service.dart';
import '../../theme.dart';
import '../../widgets/diagnosis_plan_view.dart';
import '../../widgets/result_card.dart';

class SessionRecordScreen extends StatefulWidget {
  final String patientId;
  final Set<RecommendedSection>? recommendations;
  final String? assessmentImpression;
  const SessionRecordScreen({
    super.key,
    required this.patientId,
    this.recommendations,
    this.assessmentImpression,
  });
  @override
  State<SessionRecordScreen> createState() => _SessionRecordScreenState();
}

class _SessionRecordScreenState extends State<SessionRecordScreen> {
  // Visit
  DateTime _date = DateTime.now();
  final _noteCtrl = TextEditingController();

  // Phoria
  final _phDist = TextEditingController();
  final _phNear = TextEditingController();
  String _phDistDir = 'Exo';
  String _phNearDir = 'Exo';

  // AC/A
  int _acaSeg = 0;
  final _ipd = TextEditingController();
  final _ndist = TextEditingController(text: '40');
  final _gp1 = TextEditingController();
  final _gp2 = TextEditingController();
  final _glens = TextEditingController(text: '1.00');
  String _gp1Dir = 'Exo';
  String _gp2Dir = 'Exo';

  // NPC
  final _nbrk = TextEditingController();
  final _nrec = TextEditingController();

  // Vergence – distance
  final _biBlurD = TextEditingController();
  final _biBrkD = TextEditingController();
  final _biRecD = TextEditingController();
  final _boBlurD = TextEditingController();
  final _boBrkD = TextEditingController();
  final _boRecD = TextEditingController();

  // Vergence – near
  final _biBlurN = TextEditingController();
  final _biBrkN = TextEditingController();
  final _biRecN = TextEditingController();
  final _boBlurN = TextEditingController();
  final _boBrkN = TextEditingController();
  final _boRecN = TextEditingController();

  // Sheard's & Percival's are derived from the phoria + vergence above.

  // Diagnosis inputs — only the fields that can't be derived from above.
  final _dxAge = TextEditingController();
  final _dxAmp = TextEditingController();
  final _dxFacBin = TextEditingController();
  final _dxMem = TextEditingController();
  String _dxFacFail = '';

  bool _saving = false;

  final _scroll = ScrollController();
  DiagnosisPlan? _plan;
  bool _diagnosed = false;

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [
      _noteCtrl,
      _phDist,
      _phNear,
      _ipd,
      _ndist,
      _gp1,
      _gp2,
      _glens,
      _nbrk,
      _nrec,
      _biBlurD,
      _biBrkD,
      _biRecD,
      _boBlurD,
      _boBrkD,
      _boRecD,
      _biBlurN,
      _biBrkN,
      _biRecN,
      _boBlurN,
      _boBrkN,
      _boRecN,
      _dxAge,
      _dxAmp,
      _dxFacBin,
      _dxMem,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _v(TextEditingController c) => double.tryParse(c.text.trim());
  double? _phoriaValue(TextEditingController c, String direction) =>
      PhoriaField.signedValue(c, direction);
  bool _isFinite(double? v) => v != null && v.isFinite;
  bool _isPositiveFinite(double? v) => _isFinite(v) && v! > 0;
  bool _hasAny(List<TextEditingController> cs) =>
      cs.any((c) => c.text.trim().isNotEmpty);

  bool _isRec(RecommendedSection s) =>
      widget.recommendations?.contains(s) ?? false;

  // ─── Save ─────────────────────────────────────────────────────────────────

  bool get _hasData => _hasAny([
    _phDist,
    _phNear,
    _nbrk,
    _nrec,
    _biBlurD,
    _biBrkD,
    _boBlurD,
    _boBrkD,
    _biBlurN,
    _biBrkN,
    _boBlurN,
    _boBrkN,
    _dxAge,
    _dxAmp,
    _dxFacBin,
    _dxMem,
  ]);

  /// AC/A ratio computed from the AC/A section (calculated or gradient method).
  double? _computeAca() {
    if (_acaSeg == 0) {
      final ipd = _v(_ipd),
          pd = _phoriaValue(_phDist, _phDistDir),
          pn = _phoriaValue(_phNear, _phNearDir),
          nd = _v(_ndist);
      if (_isPositiveFinite(ipd) &&
          _isFinite(pd) &&
          _isFinite(pn) &&
          _isPositiveFinite(nd)) {
        return (ipd! / 10) + (pd! - pn!) / (1 / (nd! / 100));
      }
    } else {
      final p1 = _phoriaValue(_gp1, _gp1Dir),
          p2 = _phoriaValue(_gp2, _gp2Dir),
          lens = _v(_glens);
      if (_isFinite(p1) && _isFinite(p2) && _isFinite(lens) && lens != 0) {
        return (p2! - p1!).abs() / lens!.abs();
      }
    }
    return null;
  }

  // Derived Sheard's / Percival's from the phoria + vergence entered above.
  _Sheards? _sheardsFor(double? phoriaSigned, double? boBrk, double? biBrk) {
    if (phoriaSigned == null || phoriaSigned == 0) return null;
    final exo = phoriaSigned > 0;
    final comp = exo ? boBrk : biBrk;
    if (comp == null) return null;
    final mag = phoriaSigned.abs();
    final prism = ((2 * mag - comp) / 3).clamp(0.0, double.infinity);
    return _Sheards(
      phoria: phoriaSigned,
      comp: comp,
      pass: comp >= 2 * mag,
      prism: prism.toDouble(),
      dir: exo ? 'BI' : 'BO',
    );
  }

  _Percivals? _percivalsFor(double? boBrk, double? biBrk) {
    if (boBrk == null || biBrk == null) return null;
    final g = boBrk > biBrk ? boBrk : biBrk;
    final l = boBrk < biBrk ? boBrk : biBrk;
    final prism = (g / 3 - 2 * l / 3).clamp(0.0, double.infinity);
    return _Percivals(
      bo: boBrk,
      bi: biBrk,
      pass: l >= g / 2,
      prism: prism.toDouble(),
      dir: boBrk < biBrk ? 'BI' : 'BO',
    );
  }

  Map<String, dynamic> _collectData() {
    final pd = _phoriaValue(_phDist, _phDistDir);
    final pn = _phoriaValue(_phNear, _phNearDir);
    final aca = _computeAca();
    final npcBrk = _v(_nbrk);
    final biBrkD = _v(_biBrkD), boBrkD = _v(_boBrkD);
    final biBrkN = _v(_biBrkN), boBrkN = _v(_boBrkN);

    // Sheard's / Percival's derived from the phoria + vergence above,
    // preferring near findings (the usual symptomatic distance).
    final sheards =
        _sheardsFor(pn, boBrkN, biBrkN) ?? _sheardsFor(pd, boBrkD, biBrkD);
    final percivals =
        _percivalsFor(boBrkN, biBrkN) ?? _percivalsFor(boBrkD, biBrkD);

    return <String, dynamic>{
      'ph_dist': pd,
      'ph_near': pn,
      'aca_method': _acaSeg == 0 ? 'calc' : 'grad',
      'ipd': _v(_ipd),
      'ndist': _v(_ndist),
      'gp1': _phoriaValue(_gp1, _gp1Dir),
      'gp2': _phoriaValue(_gp2, _gp2Dir),
      'glens': _v(_glens),
      'npc_brk': npcBrk,
      'npc_rec': _v(_nrec),
      'bi_blur_d': _v(_biBlurD),
      'bi_brk_d': biBrkD,
      'bi_rec_d': _v(_biRecD),
      'bo_blur_d': _v(_boBlurD),
      'bo_brk_d': boBrkD,
      'bo_rec_d': _v(_boRecD),
      'bi_blur_n': _v(_biBlurN),
      'bi_brk_n': biBrkN,
      'bi_rec_n': _v(_biRecN),
      'bo_blur_n': _v(_boBlurN),
      'bo_brk_n': boBrkN,
      'bo_rec_n': _v(_boRecN),
      // Derived analysis (stored so the saved session shows them too).
      'sh_ph': sheards?.phoria,
      'sh_cv': sheards?.comp,
      'pc_bo': percivals?.bo,
      'pc_bi': percivals?.bi,
      // Diagnosis inputs — auto-filled from above + practitioner-entered.
      'dx_pd': pd,
      'dx_pn': pn,
      'dx_aca': aca,
      'dx_nb': npcBrk,
      'dx_bi_brk': biBrkD,
      'dx_bo_brk': boBrkD,
      'dx_age': _v(_dxAge),
      'dx_amp': _v(_dxAmp),
      'dx_fac_bin': _v(_dxFacBin),
      'dx_fac_fail': _dxFacFail.isEmpty ? null : _dxFacFail,
      'dx_mem': _v(_dxMem),
    }..removeWhere((_, v) => v == null);
  }

  Future<void> _save() async {
    if (!_hasData) {
      showAppSnackBar(
        context,
        'Enter at least one test result before saving.',
        error: true,
      );
      return;
    }
    setState(() => _saving = true);
    final data = _collectData();

    try {
      await context.read<SessionService>().save(
        patientId: widget.patientId,
        date: _date,
        visitNote: _noteCtrl.text,
        data: data,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAppSnackBar(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _diagnose() {
    HapticFeedback.lightImpact();
    if (!_hasData) {
      showAppSnackBar(
        context,
        'Enter phoria or diagnosis inputs before running a diagnosis.',
        error: true,
      );
      return;
    }
    final session = TestSession(
      id: '',
      patientId: widget.patientId,
      userId: '',
      date: _date,
      data: _collectData(),
      createdAt: DateTime.now(),
    );
    setState(() {
      _plan = AssessmentEngine().planFromSession(session);
      _diagnosed = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Record session'),
        leading: const CloseButton(),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kPrimary,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(14),
        children: [
          if (widget.assessmentImpression != null) ...[
            _assessmentBanner(isDark),
            const SizedBox(height: 6),
          ],
          _sectionTile(
            icon: Icons.calendar_today_outlined,
            title: 'Visit details',
            initiallyExpanded: true,
            child: _visitContent(isDark),
          ),
          _sectionTile(
            icon: Icons.remove_red_eye_outlined,
            title: 'Phoria',
            section: RecommendedSection.phoria,
            child: _phoriaContent(),
          ),
          _sectionTile(
            icon: Icons.functions,
            title: 'AC/A ratio',
            section: RecommendedSection.acaRatio,
            child: _acaContent(),
          ),
          _sectionTile(
            icon: Icons.open_with,
            title: 'NPC',
            section: RecommendedSection.npc,
            child: _npcContent(),
          ),
          _sectionTile(
            icon: Icons.compare_arrows,
            title: 'Vergence — Distance',
            section: RecommendedSection.vergenceDistance,
            child: _vergenceContent(dist: true),
          ),
          _sectionTile(
            icon: Icons.compare_arrows,
            title: 'Vergence — Near',
            section: RecommendedSection.vergenceNear,
            child: _vergenceContent(dist: false),
          ),
          _sectionTile(
            icon: Icons.balance_outlined,
            title: "Sheard's criterion",
            section: RecommendedSection.analysis,
            child: _sheardsContent(),
          ),
          _sectionTile(
            icon: Icons.horizontal_distribute,
            title: "Percival's criterion",
            section: RecommendedSection.analysis,
            child: _percivsContent(),
          ),
          _sectionTile(
            icon: Icons.medical_services_outlined,
            title: 'Diagnosis inputs',
            section: RecommendedSection.diagnosis,
            child: _diagnosisContent(isDark),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _diagnose,
            icon: const Icon(Icons.medical_services_outlined, size: 18),
            label: const Text('Run diagnosis'),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _diagnosed
                ? _diagnosisResult(isDark)
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Diagnosis result ────────────────────────────────────────────────────

  Widget _diagnosisResult(bool isDark) {
    final plan = _plan;
    return Padding(
      key: ValueKey(plan?.name ?? 'none'),
      padding: const EdgeInsets.only(top: 10),
      child: plan == null
          ? ResultCard(
              type: ResultType.warn,
              label: 'Diagnosis',
              value: 'No clear pattern',
              note:
                  'The entered values don\'t match a specific diagnostic pattern. Record distance & near phoria (or the Diagnosis inputs) to classify. You can still save this session.',
            )
          : AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CardTitle(
                    icon: Icons.healing_outlined,
                    text: 'Diagnosis & management',
                  ),
                  DiagnosisPlanView(plan: plan),
                  const SizedBox(height: 4),
                  Text(
                    'Derived from the entered measurements. Correlate with the full examination before prescribing. Tap Save to record this session.',
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6E6E73),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── Section tile ──────────────────────────────────────────────────────────

  Widget _sectionTile({
    required IconData icon,
    required String title,
    required Widget child,
    bool initiallyExpanded = false,
    RecommendedSection? section,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRec = section != null && _isRec(section);
    final expanded = initiallyExpanded || isRec;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRec
              ? kPrimary.withAlpha(100)
              : (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
          width: isRec ? 1.0 : 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: expanded,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 2,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: Icon(
              icon,
              color: isRec ? kPrimary : const Color(0xFF8E8E93),
              size: 18,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (isRec) ...[
                  const SizedBox(width: 6),
                  Pill.normal('Recommended'),
                ],
              ],
            ),
            iconColor: kPrimary,
            collapsedIconColor: const Color(0xFF8E8E93),
            children: [child],
          ),
        ),
      ),
    );
  }

  // ─── Section contents ──────────────────────────────────────────────────────

  Widget _assessmentBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kPrimary.withAlpha(18),
        border: Border.all(color: kPrimary.withAlpha(60), width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.track_changes_outlined, size: 15, color: kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Assessment: ${widget.assessmentImpression}',
              style: const TextStyle(
                fontSize: 12,
                color: kPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visitContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date', style: _labelStyle()),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM yyyy').format(_date),
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _pickDate,
              child: const Text('Change', style: TextStyle(color: kPrimary)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Visit note (optional)', style: _labelStyle()),
            const SizedBox(height: 4),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Follow-up, first visit…',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Widget _phoriaContent() {
    final pd = _phoriaValue(_phDist, _phDistDir);
    final pn = _phoriaValue(_phNear, _phNearDir);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PhoriaField(
          label: 'Distance magnitude (Δ)',
          controller: _phDist,
          direction: _phDistDir,
          onDirectionChanged: (v) => setState(() => _phDistDir = v),
          placeholder: 'e.g. 2',
          step: 0.5,
        ),
        const SizedBox(height: 8),
        PhoriaField(
          label: 'Near magnitude (Δ)',
          controller: _phNear,
          direction: _phNearDir,
          onDirectionChanged: (v) => setState(() => _phNearDir = v),
          placeholder: 'e.g. 4',
          step: 0.5,
        ),
        if (_isFinite(pd)) _phoriaResult(pd!, 'Distance phoria'),
        if (_isFinite(pn)) _phoriaResult(pn!, 'Near phoria', near: true),
      ],
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

  Widget _acaContent() {
    final ratio = _computeAca();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedControl(
          labels: const ['Calculated', 'Gradient'],
          selected: _acaSeg,
          onChanged: (i) => setState(() => _acaSeg = i),
        ),
        if (_acaSeg == 0) ...[
          Row(
            children: [
              Expanded(
                child: NumField(
                  label: 'IPD (mm)',
                  controller: _ipd,
                  placeholder: '64',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NumField(
                  label: 'Near dist (cm)',
                  controller: _ndist,
                  placeholder: '40',
                ),
              ),
            ],
          ),
          InfoBox(
            child: const Text(
              'Uses phoria values above',
              style: TextStyle(fontSize: 10),
            ),
          ),
        ] else ...[
          PhoriaField(
            label: 'Habitual magnitude (Δ)',
            controller: _gp1,
            direction: _gp1Dir,
            onDirectionChanged: (v) => setState(() => _gp1Dir = v),
            placeholder: '4',
            step: 0.5,
          ),
          const SizedBox(height: 8),
          PhoriaField(
            label: 'With lens magnitude (Δ)',
            controller: _gp2,
            direction: _gp2Dir,
            onDirectionChanged: (v) => setState(() => _gp2Dir = v),
            placeholder: '8',
            step: 0.5,
          ),
          const SizedBox(height: 8),
          NumField(
            label: 'Lens power (D)',
            controller: _glens,
            placeholder: '1.00',
            step: 0.25,
          ),
          const SizedBox(height: 4),
        ],
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
    );
  }

  Widget _npcContent() {
    final b = _v(_nbrk), r = _v(_nrec);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoBox(child: const Text('Norms: break ≤ 5 cm, recovery ≤ 7 cm')),
        Row(
          children: [
            Expanded(
              child: NumField(
                label: 'Break (cm)',
                controller: _nbrk,
                placeholder: '5',
                step: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NumField(
                label: 'Recovery (cm)',
                controller: _nrec,
                placeholder: '7',
                step: 0.5,
              ),
            ),
          ],
        ),
        if (cls != null && lbl != null)
          ResultCard(
            type: cls,
            label: 'NPC status',
            value: lbl,
            note:
                'Break ${b!.toStringAsFixed(1)} cm / Recovery ${r!.toStringAsFixed(1)} cm',
          ),
      ],
    );
  }

  Widget _vergenceContent({required bool dist}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final norms = dist
        ? {
            'bi_brk': 7.0,
            'bi_rec': 4.0,
            'bo_blur': 9.0,
            'bo_brk': 19.0,
            'bo_rec': 10.0,
          }
        : {
            'bi_blur': 13.0,
            'bi_brk': 21.0,
            'bi_rec': 13.0,
            'bo_blur': 17.0,
            'bo_brk': 21.0,
            'bo_rec': 11.0,
          };
    final biBlur = dist ? _biBlurD : _biBlurN;
    final biBrk = dist ? _biBrkD : _biBrkN;
    final biRec = dist ? _biRecD : _biRecN;
    final boBlur = dist ? _boBlurD : _boBlurN;
    final boBrk = dist ? _boBrkD : _boBrkN;
    final boRec = dist ? _boRecD : _boRecN;

    final fields = [
      _VF('BI blur', biBlur, norms['bi_blur']),
      _VF('BI break', biBrk, norms['bi_brk']),
      _VF('BI recovery', biRec, norms['bi_rec']),
      _VF('BO blur', boBlur, norms['bo_blur']),
      _VF('BO break', boBrk, norms['bo_brk']),
      _VF('BO recovery', boRec, norms['bo_rec']),
    ].where((f) => _v(f.ctrl) != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Base-In'),
        Row(
          children: [
            Expanded(
              child: NumField(
                label: 'Blur (Δ)',
                controller: biBlur,
                placeholder: norms['bi_blur']?.toStringAsFixed(0) ?? '—',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NumField(
                label: 'Break (Δ)',
                controller: biBrk,
                placeholder: norms['bi_brk']!.toStringAsFixed(0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        NumField(
          label: 'Recovery (Δ)',
          controller: biRec,
          placeholder: norms['bi_rec']!.toStringAsFixed(0),
        ),
        SectionLabel('Base-Out'),
        Row(
          children: [
            Expanded(
              child: NumField(
                label: 'Blur (Δ)',
                controller: boBlur,
                placeholder: norms['bo_blur']!.toStringAsFixed(0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NumField(
                label: 'Break (Δ)',
                controller: boBrk,
                placeholder: norms['bo_brk']!.toStringAsFixed(0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        NumField(
          label: 'Recovery (Δ)',
          controller: boRec,
          placeholder: norms['bo_rec']!.toStringAsFixed(0),
        ),
        if (fields.isNotEmpty) ...[
          const SizedBox(height: 8),
          _vergRows(fields, isDark),
        ],
      ],
    );
  }

  Widget _vergRows(List<_VF> fields, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: fields.map((f) {
          final val = _v(f.ctrl)!;
          final norm = f.norm;
          String badge = '';
          Color badgeBg = kOkBg;
          Color badgeFg = kOkText;
          if (norm != null) {
            final diff = val - norm;
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
          final isLast = fields.last == f;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
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
                  f.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6E6E73),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${val.toStringAsFixed(0)}Δ',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (badge.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
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
        }).toList(),
      ),
    );
  }

  Widget _sheardsContent() {
    final pd = _phoriaValue(_phDist, _phDistDir);
    final pn = _phoriaValue(_phNear, _phNearDir);
    final dist = _sheardsFor(pd, _v(_boBrkD), _v(_biBrkD));
    final near = _sheardsFor(pn, _v(_boBrkN), _v(_biBrkN));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoBox(
          child: const Text(
            'Derived from the phoria and vergence above. Passes if the compensating vergence ≥ 2 × phoria.',
          ),
        ),
        if (dist == null && near == null)
          _derivedHint(
            'Enter a phoria and its compensating vergence break (BO for exo, BI for eso) above.',
          )
        else ...[
          if (dist != null) _sheardsCard('Distance', dist),
          if (near != null) _sheardsCard('Near', near),
        ],
      ],
    );
  }

  Widget _sheardsCard(String at, _Sheards s) => ResultCard(
    type: s.pass ? ResultType.ok : ResultType.bad,
    label: "Sheard's — $at",
    value: s.pass ? 'Passes ✓' : 'Fails ✗',
    note: s.pass
        ? 'Comp. vergence (${s.comp.toStringAsFixed(0)}Δ) ≥ 2 × phoria (${s.phoria.abs().toStringAsFixed(1)}Δ)'
        : 'Prism needed: ${s.prism.toStringAsFixed(2)}Δ ${s.dir}',
  );

  Widget _percivsContent() {
    final dist = _percivalsFor(_v(_boBrkD), _v(_biBrkD));
    final near = _percivalsFor(_v(_boBrkN), _v(_biBrkN));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoBox(
          child: const Text(
            'Derived from the vergence breaks above. Passes if the lesser reserve ≥ ½ × the greater.',
          ),
        ),
        if (dist == null && near == null)
          _derivedHint('Enter both BO and BI break (distance or near) above.')
        else ...[
          if (dist != null) _percivsCard('Distance', dist),
          if (near != null) _percivsCard('Near', near),
        ],
      ],
    );
  }

  Widget _percivsCard(String at, _Percivals p) {
    final lesser = p.bo < p.bi ? p.bo : p.bi;
    final greater = p.bo > p.bi ? p.bo : p.bi;
    return ResultCard(
      type: p.pass ? ResultType.ok : ResultType.bad,
      label: "Percival's — $at",
      value: p.pass ? 'Passes ✓' : 'Fails ✗',
      note: p.pass
          ? 'Lesser (${lesser.toStringAsFixed(0)}Δ) ≥ half of greater (${greater.toStringAsFixed(0)}Δ)'
          : 'Prism needed: ${p.prism.toStringAsFixed(2)}Δ ${p.dir}',
    );
  }

  Widget _derivedHint(String text) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(text, style: _labelStyle()),
  );

  Widget _diagnosisContent(bool isDark) {
    const opts = [
      ('', '—'),
      ('minus', 'Fails −'),
      ('plus', 'Fails +'),
      ('both', 'Fails ±'),
      ('neither', 'Normal'),
    ];
    final auto = <(String, String)>[
      ('Dist phoria', _fmtPhoria(_phoriaValue(_phDist, _phDistDir))),
      ('Near phoria', _fmtPhoria(_phoriaValue(_phNear, _phNearDir))),
      ('AC/A', _computeAca()?.toStringAsFixed(1) ?? '—'),
      ('NPC break', _fmtCm(_v(_nbrk))),
      ('BI break (dist)', _fmtDelta(_v(_biBrkD))),
      ('BO break (dist)', _fmtDelta(_v(_boBrkD))),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoBox(
          child: const Text(
            'Auto-filled from the tests above. Add the accommodative findings below that aren\'t captured elsewhere.',
          ),
        ),
        _autoFilledBox(isDark, auto),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: NumField(
                label: 'Amplitude (D)',
                controller: _dxAmp,
                placeholder: '8',
                step: 0.25,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NumField(
                label: 'Bino. facility (cpm)',
                controller: _dxFacBin,
                placeholder: '≥11',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: NumField(
                label: 'MEM lag (D)',
                controller: _dxMem,
                placeholder: '0.25–0.75',
                step: 0.25,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NumField(
                label: 'Age (yrs)',
                controller: _dxAge,
                placeholder: '25',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('Flipper fail side', style: _labelStyle()),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: opts.map((o) {
            final sel = _dxFacFail == o.$1;
            return GestureDetector(
              onTap: () => setState(() => _dxFacFail = sel ? '' : o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: sel
                      ? kPrimary
                      : (isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sel
                        ? kPrimary
                        : (isDark
                              ? const Color(0xFF48484A)
                              : const Color(0xFFE5E5EA)),
                  ),
                ),
                child: Text(
                  o.$2,
                  style: TextStyle(
                    fontSize: 12,
                    color: sel ? Colors.white : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _autoFilledBox(bool isDark, List<(String, String)> items) {
    final divider = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: divider, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.value.$1, style: _labelStyle()),
                Text(
                  e.value.$2,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _fmtPhoria(double? v) {
    if (v == null) return '—';
    if (v == 0) return 'Ortho';
    return '${v.abs().toStringAsFixed(1)}Δ ${v > 0 ? 'exo' : 'eso'}';
  }

  String _fmtDelta(double? v) => v == null ? '—' : '${v.toStringAsFixed(0)}Δ';
  String _fmtCm(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)} cm';

  TextStyle _labelStyle() => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Color(0xFF8E8E93),
  );
}

class _VF {
  final String label;
  final TextEditingController ctrl;
  final double? norm;
  _VF(this.label, this.ctrl, this.norm);
}

class _Sheards {
  final double phoria; // signed (exo +, eso -)
  final double comp; // compensating (opposing) vergence break
  final bool pass;
  final double prism;
  final String dir;
  _Sheards({
    required this.phoria,
    required this.comp,
    required this.pass,
    required this.prism,
    required this.dir,
  });
}

class _Percivals {
  final double bo;
  final double bi;
  final bool pass;
  final double prism;
  final String dir;
  _Percivals({
    required this.bo,
    required this.bi,
    required this.pass,
    required this.prism,
    required this.dir,
  });
}
