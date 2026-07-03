import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme.dart';
import '../../widgets/result_card.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});
  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _scroll = ScrollController();
  final _pd = TextEditingController();
  final _pn = TextEditingController();
  final _aca = TextEditingController();
  final _nb = TextEditingController();
  final _nr = TextEditingController();
  final _biBrk = TextEditingController();
  final _biBlur = TextEditingController();
  final _biRec = TextEditingController();
  final _boBrk = TextEditingController();
  final _boBlur = TextEditingController();
  final _boRec = TextEditingController();
  final _vergFac = TextEditingController();
  final _age = TextEditingController();
  final _amp = TextEditingController();
  final _facBin = TextEditingController();
  final _facMon = TextEditingController();
  final _mem = TextEditingController();
  final _nra = TextEditingController();
  final _pra = TextEditingController();

  String _pdDir = 'Exo';
  String _pnDir = 'Exo';
  String _facFail = '';
  List<_Diagnosis> _results = [];
  bool _noData = false;
  int _calcCount = 0;

  static const _failOptions = [
    ('', '— not tested —'),
    ('both', 'Both ±'),
    ('minus', 'Minus only'),
    ('plus', 'Plus only'),
    ('neither', 'Neither (normal)'),
  ];

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [
      _pd,
      _pn,
      _aca,
      _nb,
      _nr,
      _biBrk,
      _biBlur,
      _boBrk,
      _boBlur,
      _biRec,
      _boRec,
      _vergFac,
      _age,
      _amp,
      _facBin,
      _facMon,
      _mem,
      _nra,
      _pra,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _v(TextEditingController c) => double.tryParse(c.text.trim());
  double? _phoriaValue(TextEditingController c, String direction) =>
      PhoriaField.signedValue(c, direction);

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _runDiagnosis() {
    HapticFeedback.mediumImpact();
    final pd = _phoriaValue(_pd, _pdDir),
        pn = _phoriaValue(_pn, _pnDir),
        aca = _v(_aca);
    final nb = _v(_nb), nr = _v(_nr);
    final biBlur = _v(_biBlur), boBlur = _v(_boBlur);
    final biBrk = _v(_biBrk), boBrk = _v(_boBrk);
    final biRec = _v(_biRec), boRec = _v(_boRec);
    final vergFac = _v(_vergFac);
    final age = _v(_age), amp = _v(_amp);
    final facBin = _v(_facBin), facMon = _v(_facMon), mem = _v(_mem);
    final nra = _v(_nra), pra = _v(_pra);

    final hasPd = pd != null, hasPn = pn != null;
    final hasVerg =
        biBlur != null ||
        biBrk != null ||
        biRec != null ||
        boBlur != null ||
        boBrk != null ||
        boRec != null ||
        vergFac != null;
    final hasAcc =
        amp != null ||
        facBin != null ||
        facMon != null ||
        mem != null ||
        nra != null ||
        pra != null ||
        _facFail != '';

    if (!hasPd && !hasPn && !hasVerg && !hasAcc) {
      setState(() {
        _results = [];
        _noData = true;
        _calcCount++;
      });
      return;
    }

    final acaLow = aca != null && aca < 3;
    final acaHigh = aca != null && aca > 5;
    final acaVHigh = aca != null && aca > 7;
    final acaNorm = aca != null && aca >= 3 && aca <= 5;
    final npcRec = (nb != null && nb > 5) || (nr != null && nr > 7);
    final boRed =
        (boBlur != null && boBlur < 9) ||
        (boBrk != null && boBrk < 17) ||
        (boRec != null && boRec < 10);
    final biRed = (biBrk != null && biBrk < 5) || (biRec != null && biRec < 4);
    final vergFacLow = vergFac != null && vergFac < 15;
    final exoNearBig = pn != null && pn > 6;
    final esoNearBig = pn != null && pn < -2;
    final esoDistBig = pd != null && pd < -2;
    final exoDistBig = pd != null && pd > 2;
    final equalBoth =
        pd != null && pn != null && (pn.abs() - pd.abs()).abs() <= 2;
    final minAmp = age != null ? 15 - 0.25 * age : null;
    final ampLow = amp != null && minAmp != null && amp < minAmp;
    final ampNorm = amp != null && minAmp != null && amp >= minAmp;
    final lagHigh = mem != null && mem > 0.75;
    final lagLow = mem != null && mem < 0.25;
    final nraLow = nra != null && nra < 1.75;
    final nraHigh = nra != null && nra > 2.50;
    final praLow = pra != null && pra.abs() < 2.00;
    final failsMinus = _facFail == 'minus' || _facFail == 'both';
    final failsPlus = _facFail == 'plus' || _facFail == 'both';
    final failsBoth = _facFail == 'both';
    final facBinLow = facBin != null && facBin < 11;

    final conds = <_Diagnosis>[];

    if (exoNearBig || npcRec || boRed) {
      int s = 0;
      final m = <String>[];
      final ms = <String>[];
      if (exoNearBig) {
        s += 3;
        m.add('Exo near >6Δ');
      }
      if (pd == null || pd <= 2) {
        s += 1;
        m.add('Normal dist phoria');
      }
      if (acaLow) {
        s += 2;
        m.add('Low AC/A');
      } else if (aca == null) {
        ms.add('AC/A not tested');
      }
      if (npcRec) {
        s += 2;
        m.add('Receded NPC');
      } else if (nb == null) {
        ms.add('NPC not tested');
      }
      if (boRed) {
        s += 2;
        m.add('Reduced BO vergence');
      }
      if (s > 0) {
        conds.add(
          _Diagnosis(
            'Convergence Insufficiency',
            s,
            m,
            ms,
            'Vision therapy (convergence exercises) first-line. BI prism at near for symptomatic relief.',
          ),
        );
      }
    }
    if (esoNearBig || (acaHigh && pn != null && pn < 0)) {
      int s = 0;
      final m = <String>[];
      final ms = <String>[];
      if (esoNearBig) {
        s += 3;
        m.add('Eso at near');
      }
      if (pd == null || pd.abs() <= 2) {
        s += 1;
        m.add('Near > dist eso');
      }
      if (acaHigh) {
        s += 2;
        m.add('High AC/A (>5)');
      } else {
        ms.add('AC/A not tested');
      }
      if (s > 0) {
        conds.add(
          _Diagnosis(
            'Convergence Excess',
            s,
            m,
            ms,
            'Plus add at near. BI prism if lens therapy insufficient.',
          ),
        );
      }
    }
    if (esoDistBig && (pn == null || pn.abs() <= 2)) {
      int s = 3;
      final m = <String>[];
      final ms = <String>[];
      m.add('Eso at distance');
      if (acaLow) {
        s += 2;
        m.add('Low AC/A');
      } else {
        ms.add('AC/A not tested');
      }
      m.add('Exclude VI nerve palsy');
      conds.add(
        _Diagnosis(
          'Divergence Insufficiency',
          s,
          m,
          ms,
          'BI prism at distance. Exclude neurological cause before diagnosing functional DI.',
        ),
      );
    }
    if (exoDistBig && (pn == null || pn.abs() <= 4)) {
      int s = 3;
      final m = <String>[];
      final ms = <String>[];
      m.add('Exo at distance');
      if (acaHigh || acaNorm) {
        s += 1;
        m.add('Normal/high AC/A');
      }
      ms.add('Test with +3.00 DS at dist');
      conds.add(
        _Diagnosis(
          'Divergence Excess',
          s,
          m,
          ms,
          'Simulated DE: minus lenses. True DE: BO prism / VT.',
        ),
      );
    }
    if (pd != null && pn != null && pd > 0 && pn > 0 && equalBoth) {
      int s = 3;
      final m = <String>[];
      final ms = <String>[];
      m.add('Exo both distances');
      if (equalBoth) {
        s += 2;
        m.add('Similar magnitude');
      }
      if (acaNorm) {
        s += 2;
        m.add('Normal AC/A');
      } else {
        ms.add('AC/A not tested');
      }
      conds.add(
        _Diagnosis(
          'Basic Exophoria',
          s,
          m,
          ms,
          'VT (fusional vergence training). BO prism if symptomatic.',
        ),
      );
    }
    if (pd != null && pn != null && pd < 0 && pn < 0 && equalBoth) {
      int s = 3;
      final m = <String>[];
      final ms = <String>[];
      m.add('Eso both distances');
      if (equalBoth) {
        s += 2;
        m.add('Similar magnitude');
      }
      if (acaNorm) {
        s += 2;
        m.add('Normal AC/A');
      } else {
        ms.add('AC/A not tested');
      }
      conds.add(
        _Diagnosis(
          'Basic Esophoria',
          s,
          m,
          ms,
          'BI prism at near and/or distance. Plus add if accommodative component.',
        ),
      );
    }
    if (((boRed && biRed) || vergFacLow) && (pd == null || pd.abs() <= 2)) {
      int s = 4;
      final m = <String>[];
      final ms = <String>[];
      if (boRed && biRed) {
        m.add('Reduced BO & BI vergences');
      }
      if (vergFacLow) {
        s += 2;
        m.add('Low vergence facility (${vergFac.toStringAsFixed(0)} cpm)');
      }
      conds.add(
        _Diagnosis(
          'Fusional Vergence Dysfunction',
          s,
          m,
          ms,
          'VT targeting both BI and BO vergence amplitude and facility.',
        ),
      );
    }
    if (acaVHigh && (pn == null || pn < 0)) {
      int s = 3;
      final m = <String>[];
      final ms = <String>[];
      m.add('Very high AC/A (>7)');
      if (pn != null && pn < 0) {
        s += 2;
        m.add('Eso at near');
      }
      m.add('Cycloplegic refraction needed');
      conds.add(
        _Diagnosis(
          'Accommodative Esotropia (eval.)',
          s,
          m,
          ms,
          'Full cycloplegic refraction. Full hyperopic correction first. Refer if manifest tropia.',
        ),
      );
    }
    if (ampLow || (facBinLow && failsMinus) || lagHigh || nraLow) {
      int s = 0;
      final m = <String>[];
      final ms = <String>[];
      if (ampLow) {
        s += 3;
        m.add(
          'Amp ${amp.toStringAsFixed(1)}D < min (${minAmp.toStringAsFixed(1)}D)',
        );
      }
      if (lagHigh) {
        s += 2;
        m.add('High MEM lag (${mem.toStringAsFixed(2)}D)');
      }
      if (nraLow) {
        s += 2;
        m.add('Low NRA (${nra.toStringAsFixed(2)}D)');
      }
      if (failsMinus) {
        s += 2;
        m.add('Fails minus flipper');
      }
      if (facBinLow) {
        s += 1;
        m.add('Low bino. facility (${facBin.toStringAsFixed(0)} cpm)');
      }
      if (s > 0) {
        conds.add(
          _Diagnosis(
            'Accommodative Insufficiency',
            s,
            m,
            ms,
            'Accommodative facility training. Plus add at near if needed.',
          ),
        );
      }
    }
    if (lagLow || failsPlus || nraHigh || praLow) {
      int s = 0;
      final m = <String>[];
      final ms = <String>[];
      if (lagLow) {
        s += 3;
        m.add('Low MEM lag (${mem.toStringAsFixed(2)}D)');
      }
      if (failsPlus) {
        s += 2;
        m.add('Fails plus flipper');
      }
      if (nraHigh) {
        s += 1;
        m.add('High NRA (${nra.toStringAsFixed(2)}D)');
      }
      if (praLow) {
        s += 2;
        m.add('Low PRA (${pra.abs().toStringAsFixed(2)}D)');
      }
      if (ampNorm) {
        s += 1;
        m.add('Normal amplitude');
      }
      if (s > 0) {
        conds.add(
          _Diagnosis(
            'Accommodative Excess',
            s,
            m,
            ms,
            'Plus lenses; short-term cycloplegics in severe spasm. Facility training (relaxation side).',
          ),
        );
      }
    }
    if (failsBoth || (facBinLow && ampNorm)) {
      int s = 0;
      final m = <String>[];
      final ms = <String>[];
      if (failsBoth) {
        s += 4;
        m.add('Fails both ± flipper sides');
      }
      if (facBinLow) {
        s += 2;
        m.add('Low bino. facility (${facBin.toStringAsFixed(0)} cpm)');
      }
      if (ampNorm) {
        s += 1;
        m.add('Normal amplitude');
      }
      if (s > 0) {
        conds.add(
          _Diagnosis(
            'Accommodative Infacility',
            s,
            m,
            ms,
            'Flipper facility training (monocular then binocular). Hart chart near-far rock.',
          ),
        );
      }
    }

    conds.sort((a, b) => b.score.compareTo(a.score));
    setState(() {
      _results = conds;
      _noData = false;
      _calcCount++;
    });
    _scrollToBottom();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      children: [
        InfoBox(
          child: const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Enter findings. ',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                TextSpan(
                  text: 'Leave blank if not tested. Expand sections as needed.',
                ),
              ],
            ),
          ),
        ),
        _diagSection(
          icon: Icons.remove_red_eye_outlined,
          title: 'Phoria',
          initiallyExpanded: true,
          children: [
            PhoriaField(
              label: 'Distance magnitude (Δ)',
              controller: _pd,
              direction: _pdDir,
              onDirectionChanged: (v) => setState(() => _pdDir = v),
              placeholder: 'e.g. 2',
              step: 0.5,
            ),
            const SizedBox(height: 8),
            PhoriaField(
              label: 'Near magnitude (Δ)',
              controller: _pn,
              direction: _pnDir,
              onDirectionChanged: (v) => setState(() => _pnDir = v),
              placeholder: 'e.g. 8',
              step: 0.5,
            ),
          ],
        ),
        _diagSection(
          icon: Icons.functions,
          title: 'AC/A',
          children: [
            NumField(
              label: 'AC/A ratio (Δ/D)',
              controller: _aca,
              placeholder: 'e.g. 4',
              step: 0.5,
            ),
          ],
        ),
        _diagSection(
          icon: Icons.open_with,
          title: 'NPC',
          children: [
            Row(
              children: [
                Expanded(
                  child: NumField(
                    label: 'Break (cm)',
                    controller: _nb,
                    placeholder: '5',
                    step: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumField(
                    label: 'Recovery (cm)',
                    controller: _nr,
                    placeholder: '7',
                    step: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        _diagSection(
          icon: Icons.compare_arrows,
          title: 'Vergence',
          children: [
            const SectionLabel('Base-In'),
            Row(
              children: [
                Expanded(
                  child: NumField(
                    label: 'Blur (Δ)',
                    controller: _biBlur,
                    placeholder: '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumField(
                    label: 'Break (Δ)',
                    controller: _biBrk,
                    placeholder: '7',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            NumField(
              label: 'Recovery (Δ)',
              controller: _biRec,
              placeholder: '4',
            ),
            const SectionLabel('Base-Out'),
            Row(
              children: [
                Expanded(
                  child: NumField(
                    label: 'Blur (Δ)',
                    controller: _boBlur,
                    placeholder: '9',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumField(
                    label: 'Break (Δ)',
                    controller: _boBrk,
                    placeholder: '19',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            NumField(
              label: 'Recovery (Δ)',
              controller: _boRec,
              placeholder: '10',
            ),
            const SectionLabel('Facility'),
            NumField(
              label: 'Vergence flipper (cpm)',
              controller: _vergFac,
              placeholder: '≥15',
            ),
          ],
        ),
        _diagSection(
          icon: Icons.zoom_in,
          title: 'Accommodative',
          children: [
            Row(
              children: [
                Expanded(
                  child: NumField(
                    label: 'Age (yrs)',
                    controller: _age,
                    placeholder: '25',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumField(
                    label: 'Amplitude (D)',
                    controller: _amp,
                    placeholder: '8',
                    step: 0.25,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: NumField(
                    label: 'Bino. facility (cpm)',
                    controller: _facBin,
                    placeholder: '≥11',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumField(
                    label: 'Mono. facility (cpm)',
                    controller: _facMon,
                    placeholder: '≥13',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildFailSelect(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: NumField(
                    label: 'MEM lag (D)',
                    controller: _mem,
                    placeholder: '0.25–0.75',
                    step: 0.25,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: NumField(
                    label: 'NRA (D)',
                    controller: _nra,
                    placeholder: '+2.25',
                    step: 0.25,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumField(
                    label: 'PRA (D)',
                    controller: _pra,
                    placeholder: '-2.25',
                    step: 0.25,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        ElevatedButton.icon(
          onPressed: _runDiagnosis,
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text('Run diagnosis'),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildResults(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResults() {
    if (!_noData && _results.isEmpty) return const SizedBox.shrink();
    return FadeIn(
      key: ValueKey(_calcCount),
      child: Column(
        children: [
          if (_noData)
            _warningBox(
              'No findings.',
              'Enter at least phoria, vergence, or accommodative test results.',
            ),
          ..._results.asMap().entries.map(
            (e) => _buildDiagCard(e.key, e.value, context),
          ),
        ],
      ),
    );
  }

  Widget _diagSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 2,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: Icon(icon, color: kPrimary, size: 18),
            title: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            iconColor: kPrimary,
            collapsedIconColor: const Color(0xFF8E8E93),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildFailSelect(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flipper fail side',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _facFail,
              isExpanded: true,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black,
              ),
              dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              items: _failOptions
                  .map(
                    (opt) => DropdownMenuItem(
                      value: opt.$1,
                      child: Text(opt.$2, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _facFail = v ?? ''),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagCard(int index, _Diagnosis d, BuildContext context) {
    final isPrimary = index == 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confLabel = d.score >= 6
        ? 'High'
        : d.score >= 4
        ? 'Moderate'
        : 'Low';
    final confBadge = d.score >= 6
        ? Pill.normal(confLabel)
        : d.score >= 4
        ? Pill.warn(confLabel)
        : Pill(
            confLabel,
            bg: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF1EFE8),
            fg: isDark ? Colors.white70 : const Color(0xFF5F5E5A),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border.all(
          color: isPrimary
              ? kPrimary
              : (isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
          width: isPrimary ? 2 : 0.5,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPrimary ? 'Most likely' : 'Differential $index',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Flexible(
                child: Text(
                  d.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              confBadge,
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: d.met.map((x) => Pill.normal(x)).toList(),
          ),
          if (d.missing.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Not confirmed:',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6E6E73),
                  ),
                ),
                ...d.missing.map((x) => Pill.warn(x)),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF38383A)
                      : const Color(0xFFE5E5EA),
                  width: 0.5,
                ),
              ),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Management: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: d.management),
                ],
              ),
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6E6E73),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningBox(String bold, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kWarnBg,
        border: Border.all(color: kWarnBorder, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$bold ',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: kWarnTextDark,
              ),
            ),
            TextSpan(
              text: text,
              style: const TextStyle(color: kWarnTextDark),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 11, height: 1.5),
      ),
    );
  }
}

class _Diagnosis {
  final String name, management;
  final int score;
  final List<String> met, missing;
  _Diagnosis(this.name, this.score, this.met, this.missing, this.management);
}
