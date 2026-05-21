import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/assessment.dart';
import '../../services/session_service.dart';
import '../../theme.dart';
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

  // AC/A
  int _acaSeg = 0;
  final _ipd = TextEditingController();
  final _ndist = TextEditingController(text: '40');
  final _gp1 = TextEditingController();
  final _gp2 = TextEditingController();
  final _glens = TextEditingController(text: '1.00');

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

  // Analysis
  final _shPh = TextEditingController();
  final _shCv = TextEditingController();
  final _pcBo = TextEditingController();
  final _pcBi = TextEditingController();

  // Diagnosis inputs
  final _dxPd = TextEditingController();
  final _dxPn = TextEditingController();
  final _dxAca = TextEditingController();
  final _dxNb = TextEditingController();
  final _dxNr = TextEditingController();
  final _dxBiBlur = TextEditingController();
  final _dxBiBrk = TextEditingController();
  final _dxBoBlur = TextEditingController();
  final _dxBoBrk = TextEditingController();
  final _dxCv = TextEditingController();
  final _dxLv = TextEditingController();
  final _dxGv = TextEditingController();
  final _dxAge = TextEditingController();
  final _dxAmp = TextEditingController();
  final _dxFacBin = TextEditingController();
  final _dxFacMon = TextEditingController();
  final _dxMem = TextEditingController();
  String _dxFacFail = '';

  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _noteCtrl, _phDist, _phNear, _ipd, _ndist, _gp1, _gp2, _glens,
      _nbrk, _nrec,
      _biBlurD, _biBrkD, _biRecD, _boBlurD, _boBrkD, _boRecD,
      _biBlurN, _biBrkN, _biRecN, _boBlurN, _boBrkN, _boRecN,
      _shPh, _shCv, _pcBo, _pcBi,
      _dxPd, _dxPn, _dxAca, _dxNb, _dxNr,
      _dxBiBlur, _dxBiBrk, _dxBoBlur, _dxBoBrk,
      _dxCv, _dxLv, _dxGv, _dxAge, _dxAmp,
      _dxFacBin, _dxFacMon, _dxMem,
    ]) { c.dispose(); }
    super.dispose();
  }

  double? _v(TextEditingController c) => double.tryParse(c.text.trim());
  bool _hasAny(List<TextEditingController> cs) => cs.any((c) => c.text.trim().isNotEmpty);

  bool _isRec(RecommendedSection s) => widget.recommendations?.contains(s) ?? false;

  // ─── Save ─────────────────────────────────────────────────────────────────

  bool get _hasData =>
      _hasAny([_phDist, _phNear, _nbrk, _nrec,
                _biBlurD, _biBrkD, _boBlurD, _boBrkD,
                _biBlurN, _biBrkN, _boBlurN, _boBrkN,
                _shPh, _shCv, _pcBo, _pcBi,
                _dxPd, _dxPn]);

  Future<void> _save() async {
    if (!_hasData) {
      showAppSnackBar(context, 'Enter at least one test result before saving.', error: true);
      return;
    }
    setState(() => _saving = true);
    final data = <String, dynamic>{
      'ph_dist': _v(_phDist), 'ph_near': _v(_phNear),
      'aca_method': _acaSeg == 0 ? 'calc' : 'grad',
      'ipd': _v(_ipd), 'ndist': _v(_ndist),
      'gp1': _v(_gp1), 'gp2': _v(_gp2), 'glens': _v(_glens),
      'npc_brk': _v(_nbrk), 'npc_rec': _v(_nrec),
      'bi_blur_d': _v(_biBlurD), 'bi_brk_d': _v(_biBrkD), 'bi_rec_d': _v(_biRecD),
      'bo_blur_d': _v(_boBlurD), 'bo_brk_d': _v(_boBrkD), 'bo_rec_d': _v(_boRecD),
      'bi_blur_n': _v(_biBlurN), 'bi_brk_n': _v(_biBrkN), 'bi_rec_n': _v(_biRecN),
      'bo_blur_n': _v(_boBlurN), 'bo_brk_n': _v(_boBrkN), 'bo_rec_n': _v(_boRecN),
      'sh_ph': _v(_shPh), 'sh_cv': _v(_shCv),
      'pc_bo': _v(_pcBo), 'pc_bi': _v(_pcBi),
      'dx_pd': _v(_dxPd), 'dx_pn': _v(_dxPn), 'dx_aca': _v(_dxAca),
      'dx_nb': _v(_dxNb), 'dx_nr': _v(_dxNr),
      'dx_bi_blur': _v(_dxBiBlur), 'dx_bi_brk': _v(_dxBiBrk),
      'dx_bo_blur': _v(_dxBoBlur), 'dx_bo_brk': _v(_dxBoBrk),
      'dx_cv': _v(_dxCv), 'dx_lv': _v(_dxLv), 'dx_gv': _v(_dxGv),
      'dx_age': _v(_dxAge), 'dx_amp': _v(_dxAmp),
      'dx_fac_bin': _v(_dxFacBin), 'dx_fac_mon': _v(_dxFacMon),
      'dx_fac_fail': _dxFacFail.isEmpty ? null : _dxFacFail,
      'dx_mem': _v(_dxMem),
    }..removeWhere((_, v) => v == null);

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

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Record session'),
        leading: const CloseButton(),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))
                : const Text('Save', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
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
          const SizedBox(height: 24),
        ],
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
          color: isRec ? kPrimary.withAlpha(100) : (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
          width: isRec ? 1.0 : 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: expanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: Icon(icon, color: isRec ? kPrimary : const Color(0xFF8E8E93), size: 18),
            title: Row(children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              if (isRec) ...[const SizedBox(width: 6), Pill.normal('Recommended')],
            ]),
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
      child: Row(children: [
        const Icon(Icons.track_changes_outlined, size: 15, color: kPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Assessment: ${widget.assessmentImpression}',
            style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  Widget _visitContent(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Date', style: _labelStyle()),
          const SizedBox(height: 4),
          Text(DateFormat('d MMM yyyy').format(_date),
              style: const TextStyle(fontSize: 15)),
        ])),
        TextButton(
          onPressed: _pickDate,
          child: const Text('Change', style: TextStyle(color: kPrimary)),
        ),
      ]),
      const SizedBox(height: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Visit note (optional)', style: _labelStyle()),
        const SizedBox(height: 4),
        TextField(
          controller: _noteCtrl,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'e.g. Follow-up, first visit…'),
        ),
      ]),
    ]);
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
    final pd = _v(_phDist), pn = _v(_phNear);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: NumField(label: 'Distance (Δ)', controller: _phDist,
            placeholder: 'e.g. 2', step: 0.5)),
        const SizedBox(width: 8),
        Expanded(child: NumField(label: 'Near (Δ)', controller: _phNear,
            placeholder: 'e.g. 4', step: 0.5)),
      ]),
      if (pd != null) _phoriaResult(pd, 'Distance phoria'),
      if (pn != null) _phoriaResult(pn, 'Near phoria', near: true),
    ]);
  }

  Widget _phoriaResult(double val, String label, {bool near = false}) {
    final a = val.abs();
    final type = val == 0 ? 'Orthophoria' : val > 0 ? 'Exophoria' : 'Esophoria';
    final limit = near && val > 0 ? 6 : 2;
    final cls = a == 0 || a <= limit ? ResultType.ok
        : a <= (near ? 10 : 4) ? ResultType.warn : ResultType.bad;
    return ResultCard(type: cls, label: label,
        value: '${a.toStringAsFixed(1)}Δ  $type',
        note: a <= limit ? "Within Morgan's norm" : 'Outside norm');
  }

  Widget _acaContent() {
    double? ratio;
    if (_acaSeg == 0) {
      final ipd = _v(_ipd), pd = _v(_phDist), pn = _v(_phNear), nd = _v(_ndist);
      if (ipd != null && pd != null && pn != null && nd != null) {
        ratio = (ipd / 10) + (pn - pd) / (1 / (nd / 100));
      }
    } else {
      final p1 = _v(_gp1), p2 = _v(_gp2), lens = _v(_glens);
      if (p1 != null && p2 != null && lens != null && lens != 0) {
        ratio = (p2 - p1).abs() / lens.abs();
      }
    }
    final cls = ratio == null ? null
        : ratio < 3 || ratio > 7 ? ResultType.bad
        : ratio <= 5 ? ResultType.ok : ResultType.warn;
    final lbl = ratio == null ? null
        : ratio < 3 ? 'Low AC/A' : ratio <= 5 ? 'Normal AC/A'
        : ratio <= 7 ? 'High AC/A' : 'Very high AC/A';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SegmentedControl(
        labels: const ['Calculated', 'Gradient'],
        selected: _acaSeg,
        onChanged: (i) => setState(() => _acaSeg = i),
      ),
      if (_acaSeg == 0) ...[
        Row(children: [
          Expanded(child: NumField(label: 'IPD (mm)', controller: _ipd, placeholder: '64')),
          const SizedBox(width: 8),
          Expanded(child: NumField(label: 'Near dist (cm)', controller: _ndist, placeholder: '40')),
        ]),
        InfoBox(child: const Text('Uses phoria values above', style: TextStyle(fontSize: 10))),
      ] else ...[
        Row(children: [
          Expanded(child: NumField(label: 'Phoria habitual (Δ)', controller: _gp1,
              placeholder: '4', step: 0.5)),
          const SizedBox(width: 8),
          Expanded(child: NumField(label: 'Phoria + lens (Δ)', controller: _gp2,
              placeholder: '8', step: 0.5)),
        ]),
        const SizedBox(height: 8),
        NumField(label: 'Lens power (D)', controller: _glens, placeholder: '1.00', step: 0.25),
        const SizedBox(height: 4),
      ],
      if (ratio != null && cls != null && lbl != null)
        ResultCard(type: cls, label: 'AC/A ratio',
            value: '${ratio.toStringAsFixed(1)} : 1  $lbl',
            note: ratio < 3 ? 'Associated with CI.'
                : ratio <= 5 ? 'Normal range (3–5 Δ/D).'
                : ratio <= 7 ? 'Associated with CE.' : 'Evaluate for accommodative ET.'),
    ]);
  }

  Widget _npcContent() {
    final b = _v(_nbrk), r = _v(_nrec);
    ResultType? cls; String? lbl;
    if (b != null && r != null) {
      final bOk = b <= 5, rOk = r <= 7;
      cls = (bOk && rOk) ? ResultType.ok : (!bOk && !rOk) ? ResultType.bad : ResultType.warn;
      lbl = (bOk && rOk) ? 'Normal NPC' : (!bOk && !rOk) ? 'Receded NPC' : 'Borderline NPC';
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InfoBox(child: const Text('Norms: break ≤ 5 cm, recovery ≤ 7 cm')),
      Row(children: [
        Expanded(child: NumField(label: 'Break (cm)', controller: _nbrk,
            placeholder: '5', step: 0.5)),
        const SizedBox(width: 8),
        Expanded(child: NumField(label: 'Recovery (cm)', controller: _nrec,
            placeholder: '7', step: 0.5)),
      ]),
      if (cls != null && lbl != null)
        ResultCard(type: cls, label: 'NPC status', value: lbl,
            note: 'Break ${b!.toStringAsFixed(1)} cm / Recovery ${r!.toStringAsFixed(1)} cm'),
    ]);
  }

  Widget _vergenceContent({required bool dist}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final norms = dist
        ? {'bi_brk': 7.0, 'bi_rec': 4.0, 'bo_blur': 9.0, 'bo_brk': 19.0, 'bo_rec': 10.0}
        : {'bi_blur': 13.0, 'bi_brk': 21.0, 'bi_rec': 13.0, 'bo_blur': 17.0, 'bo_brk': 21.0, 'bo_rec': 11.0};
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

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionLabel('Base-In'),
      Row(children: [
        Expanded(child: NumField(label: 'Blur (Δ)', controller: biBlur,
            placeholder: norms['bi_blur']?.toStringAsFixed(0) ?? '—')),
        const SizedBox(width: 8),
        Expanded(child: NumField(label: 'Break (Δ)', controller: biBrk,
            placeholder: norms['bi_brk']!.toStringAsFixed(0))),
      ]),
      const SizedBox(height: 8),
      NumField(label: 'Recovery (Δ)', controller: biRec,
          placeholder: norms['bi_rec']!.toStringAsFixed(0)),
      SectionLabel('Base-Out'),
      Row(children: [
        Expanded(child: NumField(label: 'Blur (Δ)', controller: boBlur,
            placeholder: norms['bo_blur']!.toStringAsFixed(0))),
        const SizedBox(width: 8),
        Expanded(child: NumField(label: 'Break (Δ)', controller: boBrk,
            placeholder: norms['bo_brk']!.toStringAsFixed(0))),
      ]),
      const SizedBox(height: 8),
      NumField(label: 'Recovery (Δ)', controller: boRec,
          placeholder: norms['bo_rec']!.toStringAsFixed(0)),
      if (fields.isNotEmpty) ...[
        const SizedBox(height: 8),
        _vergRows(fields, isDark),
      ],
    ]);
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
          String badge = ''; Color badgeBg = kOkBg; Color badgeFg = kOkText;
          if (norm != null) {
            final diff = val - norm;
            if (diff.abs() <= 2) { badge = 'Norm'; }
            else if (diff < 0) {
              badge = '${diff.abs().toStringAsFixed(0)}Δ low';
              badgeBg = kBadBg; badgeFg = kBadTextDark;
            } else {
              badge = '${diff.toStringAsFixed(0)}Δ high';
              badgeBg = kWarnBg; badgeFg = kWarnTextDark;
            }
          }
          final isLast = fields.last == f;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(
                color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA), width: 0.5)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(f.label, style: TextStyle(fontSize: 11,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73))),
              Row(children: [
                Text('${val.toStringAsFixed(0)}Δ',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                if (badge.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                    child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: badgeFg)),
                  ),
                ],
              ]),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _sheardsContent() {
    final ph = _v(_shPh), cv = _v(_shCv);
    Widget? result;
    if (ph != null && cv != null) {
      final a = ph.abs();
      final pass = cv >= 2 * a;
      final prism = ((2 * a - cv) / 3).clamp(0, double.infinity);
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InfoBox(child: const Text.rich(TextSpan(children: [
        TextSpan(text: 'Passes if: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        TextSpan(text: 'comp. vergence ≥ 2 × phoria'),
      ]))),
      NumField(label: 'Phoria (Δ)  + exo / − eso', controller: _shPh,
          placeholder: 'e.g. 8', step: 0.5),
      const SizedBox(height: 8),
      NumField(label: 'Comp. vergence break (Δ)', controller: _shCv, placeholder: 'e.g. 12'),
      ?result,
    ]);
  }

  Widget _percivsContent() {
    final bo = _v(_pcBo), bi = _v(_pcBi);
    Widget? result;
    if (bo != null && bi != null) {
      final G = bo > bi ? bo : bi, L = bo < bi ? bo : bi;
      final pass = L >= G / 2;
      final prism = (G / 3 - (2 * L) / 3).clamp(0, double.infinity);
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InfoBox(child: const Text.rich(TextSpan(children: [
        TextSpan(text: 'Passes if: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        TextSpan(text: 'lesser ≥ ½ × greater vergence'),
      ]))),
      Row(children: [
        Expanded(child: NumField(label: 'BO blur/break (Δ)', controller: _pcBo, placeholder: '17')),
        const SizedBox(width: 8),
        Expanded(child: NumField(label: 'BI blur/break (Δ)', controller: _pcBi, placeholder: '13')),
      ]),
      ?result,
    ]);
  }

  Widget _diagnosisContent(bool isDark) {
    const opts = [('', '—'), ('minus', 'Fails −'), ('plus', 'Fails +'), ('both', 'Fails ±'), ('neither', 'Normal')];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InfoBox(child: const Text('Fill in to record diagnosis inputs for this session.')),
      Row(children: [
        Expanded(child: NumField(label: 'Dist phoria (Δ)', controller: _dxPd,
            placeholder: 'e.g. 2', step: 0.5)),
        const SizedBox(width: 8),
        Expanded(child: NumField(label: 'Near phoria (Δ)', controller: _dxPn,
            placeholder: 'e.g. 8', step: 0.5)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: NumField(label: 'AC/A (Δ/D)', controller: _dxAca,
            placeholder: 'e.g. 4', step: 0.5)),
        const SizedBox(width: 8),
        Expanded(child: NumField(label: 'Age (yrs)', controller: _dxAge, placeholder: '25')),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: NumField(label: 'Amplitude (D)', controller: _dxAmp,
            placeholder: '8', step: 0.25)),
        const SizedBox(width: 8),
        Expanded(child: NumField(label: 'Bino. facility (cpm)', controller: _dxFacBin,
            placeholder: '≥11')),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: NumField(label: 'MEM lag (D)', controller: _dxMem,
            placeholder: '0.25–0.75', step: 0.25)),
        const SizedBox(width: 8),
        Expanded(child: NumField(label: 'NPC break (cm)', controller: _dxNb,
            placeholder: '5', step: 0.5)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: NumField(label: 'BI break (Δ)', controller: _dxBiBrk, placeholder: '7')),
        const SizedBox(width: 8),
        Expanded(child: NumField(label: 'BO break (Δ)', controller: _dxBoBrk, placeholder: '19')),
      ]),
      const SizedBox(height: 10),
      Text('Flipper fail side', style: _labelStyle()),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 6, children: opts.map((o) {
        final sel = _dxFacFail == o.$1;
        return GestureDetector(
          onTap: () => setState(() => _dxFacFail = sel ? '' : o.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: sel ? kPrimary : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sel ? kPrimary :
                  (isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA))),
            ),
            child: Text(o.$2, style: TextStyle(fontSize: 12, color: sel ? Colors.white : null)),
          ),
        );
      }).toList()),
    ]);
  }

  TextStyle _labelStyle() => const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
      color: Color(0xFF8E8E93));
}

class _VF {
  final String label;
  final TextEditingController ctrl;
  final double? norm;
  _VF(this.label, this.ctrl, this.norm);
}
