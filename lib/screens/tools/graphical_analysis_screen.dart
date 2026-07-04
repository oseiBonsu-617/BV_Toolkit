import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/graphical_analysis.dart';
import '../../widgets/result_card.dart';
import '../../widgets/zcsbv_graph.dart';

class GraphicalAnalysisScreen extends StatefulWidget {
  const GraphicalAnalysisScreen({super.key});
  @override
  State<GraphicalAnalysisScreen> createState() =>
      _GraphicalAnalysisScreenState();
}

class _GraphicalAnalysisScreenState extends State<GraphicalAnalysisScreen> {
  final _scroll = ScrollController();

  final _pd = TextEditingController();
  final _pn = TextEditingController();
  final _ipd = TextEditingController(text: '64');
  final _nd = TextEditingController(text: '40');

  final _boDBlur = TextEditingController();
  final _boDBreak = TextEditingController();
  final _boNBlur = TextEditingController();
  final _boNBreak = TextEditingController();

  final _biDBlur = TextEditingController();
  final _biDBreak = TextEditingController();
  final _biNBlur = TextEditingController();
  final _biNBreak = TextEditingController();

  final _nra = TextEditingController();
  final _pra = TextEditingController();

  String _pdDir = 'Exo';
  String _pnDir = 'Exo';

  GAGeometry? _geometry;
  List<GAFinding> _findings = const [];
  int _calcCount = 0;
  String? _error;

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [
      _pd, _pn, _ipd, _nd,
      _boDBlur, _boDBreak, _boNBlur, _boNBreak,
      _biDBlur, _biDBreak, _biNBlur, _biNBreak,
      _nra, _pra,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _v(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    final d = double.tryParse(t);
    return (d != null && d.isFinite) ? d : null;
  }

  double? _pos(TextEditingController c) {
    final v = _v(c);
    return (v != null && v > 0) ? v : null;
  }

  void _loadExample() {
    HapticFeedback.selectionClick();
    setState(() {
      _pd.text = '1';
      _pdDir = 'Exo';
      _pn.text = '3';
      _pnDir = 'Exo';
      _ipd.text = '65';
      _nd.text = '40';
      _boDBlur.text = '7';
      _boDBreak.text = '15';
      _boNBlur.text = '17';
      _boNBreak.text = '21';
      _biDBlur.text = '7';
      _biDBreak.text = '15';
      _biNBlur.text = '13';
      _biNBreak.text = '21';
      _nra.text = '2.00';
      _pra.text = '2.50';
    });
    _plot();
  }

  void _plot() {
    HapticFeedback.lightImpact();
    final pd = PhoriaField.signedValue(_pd, _pdDir);
    final pn = PhoriaField.signedValue(_pn, _pnDir);
    final ipd = _pos(_ipd);
    final nd = _pos(_nd);

    if (pd == null || pn == null || ipd == null || nd == null) {
      setState(() {
        _error =
            'Enter both phorias, a positive IPD and a positive near distance to plot.';
        _geometry = null;
        _findings = const [];
        _calcCount++;
      });
      return;
    }

    final inputs = GAInputs(
      distPhoria: pd,
      nearPhoria: pn,
      ipdMm: ipd,
      nearDistCm: nd,
      distBoBlur: _v(_boDBlur),
      distBoBreak: _v(_boDBreak),
      nearBoBlur: _v(_boNBlur),
      nearBoBreak: _v(_boNBreak),
      distBiBlur: _v(_biDBlur),
      distBiBreak: _v(_biDBreak),
      nearBiBlur: _v(_biNBlur),
      nearBiBreak: _v(_biNBreak),
      nra: _pos(_nra),
      pra: _pos(_pra),
    );

    final geometry = GAGeometry.from(inputs);
    setState(() {
      _error = null;
      _geometry = geometry;
      _findings = geometry.interpret();
      _calcCount++;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Graphical analysis'),
            Text(
              'ZCSBV plot',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _loadExample,
            child: const Text('Example', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(12),
        children: [
          _phoriaCard(),
          _reserveCard(
            title: 'Positive fusional vergence (BO)',
            icon: Icons.arrow_forward,
            dBlur: _boDBlur,
            dBreak: _boDBreak,
            nBlur: _boNBlur,
            nBreak: _boNBreak,
          ),
          _reserveCard(
            title: 'Negative fusional vergence (BI)',
            icon: Icons.arrow_back,
            dBlur: _biDBlur,
            dBreak: _biDBreak,
            nBlur: _biNBlur,
            nBreak: _biNBreak,
          ),
          _relativeAccCard(),
          ElevatedButton(
            onPressed: _plot,
            child: const Text('Plot & analyse'),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildOutput(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOutput() {
    if (_error != null) {
      return Padding(
        key: ValueKey('err$_calcCount'),
        padding: const EdgeInsets.only(top: 10),
        child: ResultCard(
          type: ResultType.warn,
          label: 'Input required',
          value: 'Cannot plot',
          note: _error,
        ),
      );
    }
    final g = _geometry;
    if (g == null) return const SizedBox.shrink();
    return FadeIn(
      key: ValueKey('out$_calcCount'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardTitle(
                  icon: Icons.show_chart,
                  text: 'Zone of clear single binocular vision',
                ),
                ZcsbvGraph(geometry: g),
                const SizedBox(height: 4),
                Text(
                  'Drag across the plot to read vergence / accommodation. Tap a legend chip to toggle a layer.',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.4,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6E6E73),
                  ),
                ),
              ],
            ),
          ),
          _statsCard(g),
          const SectionLabel('Interpretation'),
          ..._findings.map(
            (f) => ResultCard(
              type: f.type,
              label: f.label,
              value: f.value,
              note: f.note,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Interpretation is a clinical aid derived from the entered values — always correlate with symptoms and the full examination.',
              style: TextStyle(
                fontSize: 10.5,
                height: 1.45,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6E6E73),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input cards ──────────────────────────────────────────────────────────

  Widget _phoriaCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.remove_red_eye_outlined,
            text: 'Phoria & demand',
          ),
          InfoBox(
            child: const Text(
              'Distance and near phoria set the phoria line; IPD and near distance set the demand line.',
            ),
          ),
          PhoriaField(
            label: 'Distance phoria (Δ)',
            controller: _pd,
            direction: _pdDir,
            onDirectionChanged: (v) => setState(() => _pdDir = v),
            placeholder: 'e.g. 1',
            step: 0.5,
          ),
          const SizedBox(height: 8),
          PhoriaField(
            label: 'Near phoria (Δ)',
            controller: _pn,
            direction: _pnDir,
            onDirectionChanged: (v) => setState(() => _pnDir = v),
            placeholder: 'e.g. 3',
            step: 0.5,
          ),
          const SizedBox(height: 8),
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
                  label: 'Near distance (cm)',
                  controller: _nd,
                  placeholder: '40',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reserveCard({
    required String title,
    required IconData icon,
    required TextEditingController dBlur,
    required TextEditingController dBreak,
    required TextEditingController nBlur,
    required TextEditingController nBreak,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(icon: icon, text: title),
          const SectionLabel('Distance (6 m)'),
          Row(
            children: [
              Expanded(
                child: NumField(label: 'Blur (Δ)', controller: dBlur, placeholder: '—'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NumField(label: 'Break (Δ)', controller: dBreak, placeholder: '15'),
              ),
            ],
          ),
          const SectionLabel('Near (40 cm)'),
          Row(
            children: [
              Expanded(
                child: NumField(label: 'Blur (Δ)', controller: nBlur, placeholder: '17'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NumField(label: 'Break (Δ)', controller: nBreak, placeholder: '21'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _relativeAccCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.lens_blur_outlined,
            text: 'Relative accommodation',
          ),
          InfoBox(
            child: const Text(
              'NRA (plus-to-blur) and PRA (minus-to-blur) set the vertical height of the zone at near.',
            ),
          ),
          Row(
            children: [
              Expanded(
                child: NumField(
                  label: 'NRA (+D)',
                  controller: _nra,
                  placeholder: '2.00',
                  step: 0.25,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NumField(
                  label: 'PRA (−D)',
                  controller: _pra,
                  placeholder: '2.50',
                  step: 0.25,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats grid ─────────────────────────────────────────────────────────

  Widget _statsCard(GAGeometry g) {
    final i = g.input;
    String ph(double v) {
      final m = v.abs().toStringAsFixed(1);
      if (v == 0) return 'ortho';
      return v > 0 ? '$mΔ exo' : '$mΔ eso';
    }

    String pair(double? a, double? b, String suffix) {
      final l = a?.toStringAsFixed(0) ?? '—';
      final r = b?.toStringAsFixed(0) ?? '—';
      return '$l / $r$suffix';
    }

    final stats = <(String, String)>[
      ('Distance phoria', ph(i.distPhoria)),
      ('Near phoria', ph(i.nearPhoria)),
      ('Near demand', '${g.nearDemandV.toStringAsFixed(1)}Δ @ ${g.accNear.toStringAsFixed(2)}D'),
      ('PFV blur / break — distance', pair(i.distBoBlur, i.distBoBreak, 'Δ BO')),
      ('PFV blur / break — near', pair(i.nearBoBlur, i.nearBoBreak, 'Δ BO')),
      ('NFV blur / break — distance', pair(i.distBiBlur, i.distBiBreak, 'Δ BI')),
      ('NFV blur / break — near', pair(i.nearBiBlur, i.nearBiBreak, 'Δ BI')),
      if (i.nra != null) ('NRA at near', '+${i.nra!.toStringAsFixed(2)}D'),
      if (i.pra != null) ('PRA at near', '−${i.pra!.toStringAsFixed(2)}D'),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.table_chart_outlined, text: 'Measurements'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.9,
            children: stats
                .map(
                  (s) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
