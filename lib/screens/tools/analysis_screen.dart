import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme.dart';
import '../../widgets/result_card.dart';
import 'graphical_analysis_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _scroll = ScrollController();
  final _shPh = TextEditingController();
  final _shCv = TextEditingController();
  final _pcBo = TextEditingController();
  final _pcBi = TextEditingController();
  final _saPh = TextEditingController();
  final _saAca = TextEditingController();

  String _shPhDir = 'Exo';
  String _saPhDir = 'Exo';
  _Res? _shResult, _pcResult, _saResult;
  int _shCalcCount = 0;
  int _pcCalcCount = 0;
  int _saCalcCount = 0;

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [_shPh, _shCv, _pcBo, _pcBi, _saPh, _saAca]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _v(TextEditingController c) => double.tryParse(c.text.trim());
  double? _phoriaValue(TextEditingController c, String direction) =>
      PhoriaField.signedValue(c, direction);
  bool _isFinite(double? v) => v != null && v.isFinite;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _calcSheards() {
    HapticFeedback.lightImpact();
    final ph = _phoriaValue(_shPh, _shPhDir), cv = _v(_shCv);
    if (!_isFinite(ph) || !_isFinite(cv)) {
      setState(() {
        _shResult = _Res(
          ResultType.warn,
          "Sheard's",
          'Input required',
          'Enter phoria and comp. vergence',
        );
        _shCalcCount++;
      });
      return;
    }
    final phoria = ph!;
    final compVergence = cv!;
    final a = phoria.abs();
    final pass = compVergence >= 2 * a;
    final prism = ((2 * a - compVergence) / 3).clamp(0, double.infinity);
    final dir = phoria >= 0 ? 'BI' : 'BO';
    setState(() {
      _shResult = pass
          ? _Res(
              ResultType.ok,
              "Sheard's",
              'Passes ✓',
              'CV (${compVergence.toStringAsFixed(0)}Δ) ≥ 2 × phoria (${a.toStringAsFixed(1)}Δ)',
            )
          : _Res(
              ResultType.bad,
              "Sheard's",
              'Fails ✗',
              'Prism needed: ${prism.toStringAsFixed(2)}Δ $dir',
            );
      _shCalcCount++;
    });
    _scrollToBottom();
  }

  void _calcSphericalAlteration() {
    HapticFeedback.lightImpact();
    final ph = _phoriaValue(_saPh, _saPhDir);
    final aca = _v(_saAca);
    if (!_isFinite(ph) || !_isFinite(aca) || aca! <= 0) {
      setState(() {
        _saResult = _Res(
          ResultType.warn,
          'Spherical alteration',
          'Input required',
          'Enter phoria magnitude, direction, and a positive AC/A.',
        );
        _saCalcCount++;
      });
      return;
    }

    final phoria = ph!;
    final lens = phoria.abs() / aca;
    if (phoria == 0 || lens == 0) {
      setState(() {
        _saResult = _Res(
          ResultType.ok,
          'Spherical alteration',
          'No alteration',
          'Orthophoria entered.',
        );
        _saCalcCount++;
      });
      _scrollToBottom();
      return;
    }

    final sign = phoria > 0 ? '-' : '+';
    final direction = phoria > 0 ? 'exo' : 'eso';
    setState(() {
      _saResult = _Res(
        ResultType.info,
        'Spherical alteration',
        '$sign${lens.toStringAsFixed(2)}D',
        'Estimated lens change to reduce ${phoria.abs().toStringAsFixed(1)}Δ $direction using AC/A ${aca.toStringAsFixed(1)} Δ/D.',
      );
      _saCalcCount++;
    });
    _scrollToBottom();
  }

  void _calcPercivals() {
    HapticFeedback.lightImpact();
    final bo = _v(_pcBo), bi = _v(_pcBi);
    if (!_isFinite(bo) || !_isFinite(bi)) {
      setState(() {
        _pcResult = _Res(
          ResultType.warn,
          "Percival's",
          'Input required',
          'Enter BO and BI values',
        );
        _pcCalcCount++;
      });
      return;
    }
    final boRange = bo!;
    final biRange = bi!;
    final G = boRange > biRange ? boRange : biRange;
    final L = boRange < biRange ? boRange : biRange;
    final pass = L >= G / 2;
    final prism = (G / 3 - (2 * L) / 3).clamp(0, double.infinity);
    final dir = boRange < biRange ? 'BI' : 'BO';
    setState(() {
      _pcResult = pass
          ? _Res(
              ResultType.ok,
              "Percival's",
              'Passes ✓',
              'Lesser (${L.toStringAsFixed(0)}Δ) ≥ half of greater (${G.toStringAsFixed(0)}Δ)',
            )
          : _Res(
              ResultType.bad,
              "Percival's",
              'Fails ✗',
              'Prism needed: ${prism.toStringAsFixed(2)}Δ $dir',
            );
      _pcCalcCount++;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardTitle(
                icon: Icons.show_chart,
                text: 'Graphical analysis',
              ),
              InfoBox(
                child: const Text(
                  'Plot the full Zone of Clear Single Binocular Vision (ZCSBV) from phoria, fusional reserves and NRA/PRA, with automatic interpretation.',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  appRoute(const GraphicalAnalysisScreen()),
                ),
                icon: const Icon(Icons.open_in_full, size: 16),
                label: const Text('Open ZCSBV plot'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary,
                  minimumSize: const Size(double.infinity, 46),
                  side: const BorderSide(color: kPrimary, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardTitle(
                icon: Icons.balance_outlined,
                text: "Sheard's criterion",
              ),
              InfoBox(
                child: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Passes if: ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(text: 'comp. vergence ≥ 2 × phoria'),
                    ],
                  ),
                ),
              ),
              PhoriaField(
                label: 'Phoria magnitude (Δ)',
                controller: _shPh,
                direction: _shPhDir,
                onDirectionChanged: (v) => setState(() => _shPhDir = v),
                placeholder: 'e.g. 8',
                step: 0.5,
              ),
              const SizedBox(height: 8),
              NumField(
                label: 'Comp. vergence break (Δ)',
                controller: _shCv,
                placeholder: 'e.g. 12',
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _calcSheards,
                child: const Text("Apply Sheard's"),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _shResult == null
                    ? const SizedBox.shrink()
                    : FadeIn(
                        key: ValueKey(_shCalcCount),
                        child: ResultCard(
                          type: _shResult!.type,
                          label: _shResult!.label,
                          value: _shResult!.value,
                          note: _shResult!.note,
                        ),
                      ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardTitle(
                icon: Icons.horizontal_distribute,
                text: "Percival's criterion",
              ),
              InfoBox(
                child: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Passes if: ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(text: 'lesser ≥ ½ × greater vergence'),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: NumField(
                      label: 'BO blur/break (Δ)',
                      controller: _pcBo,
                      placeholder: '17',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumField(
                      label: 'BI blur/break (Δ)',
                      controller: _pcBi,
                      placeholder: '13',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _calcPercivals,
                child: const Text("Apply Percival's"),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _pcResult == null
                    ? const SizedBox.shrink()
                    : FadeIn(
                        key: ValueKey(_pcCalcCount),
                        child: ResultCard(
                          type: _pcResult!.type,
                          label: _pcResult!.label,
                          value: _pcResult!.value,
                          note: _pcResult!.note,
                        ),
                      ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardTitle(
                icon: Icons.lens_blur_outlined,
                text: 'Spherical alteration',
              ),
              InfoBox(
                child: const Text(
                  'Estimates the spherical lens change needed to alter phoria through AC/A.',
                ),
              ),
              PhoriaField(
                label: 'Phoria magnitude (Δ)',
                controller: _saPh,
                direction: _saPhDir,
                onDirectionChanged: (v) => setState(() => _saPhDir = v),
                placeholder: 'e.g. 6',
                step: 0.5,
              ),
              const SizedBox(height: 8),
              NumField(
                label: 'AC/A ratio (Δ/D)',
                controller: _saAca,
                placeholder: '4',
                step: 0.5,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _calcSphericalAlteration,
                child: const Text('Calculate alteration'),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _saResult == null
                    ? const SizedBox.shrink()
                    : FadeIn(
                        key: ValueKey(_saCalcCount),
                        child: ResultCard(
                          type: _saResult!.type,
                          label: _saResult!.label,
                          value: _saResult!.value,
                          note: _saResult!.note,
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _Res {
  final ResultType type;
  final String label, value;
  final String? note;
  _Res(this.type, this.label, this.value, this.note);
}
