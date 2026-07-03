import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/result_card.dart';

class PhoriaScreen extends StatefulWidget {
  const PhoriaScreen({super.key});
  @override
  State<PhoriaScreen> createState() => _PhoriaScreenState();
}

class _PhoriaScreenState extends State<PhoriaScreen> {
  final _scroll = ScrollController();
  final _pd = TextEditingController();
  final _pn = TextEditingController();
  final _ipd = TextEditingController();
  final _ndist = TextEditingController(text: '40');
  final _gp1 = TextEditingController();
  final _gp2 = TextEditingController();
  final _glens = TextEditingController(text: '1.00');
  final _cacBase = TextEditingController();
  final _cacPrismResponse = TextEditingController();
  final _cacPrism = TextEditingController();

  int _acaSeg = 0;
  String _pdDir = 'Exo';
  String _pnDir = 'Exo';
  String _gp1Dir = 'Exo';
  String _gp2Dir = 'Exo';
  List<_Result> _phoriaResults = [];
  _Result? _acaResult;
  _Result? _cacResult;
  int _phoriaCalcCount = 0;
  int _acaCalcCount = 0;
  int _cacCalcCount = 0;

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [
      _pd,
      _pn,
      _ipd,
      _ndist,
      _gp1,
      _gp2,
      _glens,
      _cacBase,
      _cacPrismResponse,
      _cacPrism,
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

  _Result _phoriaResult(double val, String label, {required bool near}) {
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

    return _Result(
      cls,
      label,
      '${a.toStringAsFixed(1)}Δ  $type',
      inNorm ? "Within Morgan's norm" : 'Outside norm',
    );
  }

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

  void _calcPhoria() {
    HapticFeedback.lightImpact();
    final results = <_Result>[];
    final pd = _phoriaValue(_pd, _pdDir);
    final pn = _phoriaValue(_pn, _pnDir);

    if (_isFinite(pd)) {
      results.add(_phoriaResult(pd!, 'Distance phoria', near: false));
    }
    if (_isFinite(pn)) {
      results.add(_phoriaResult(pn!, 'Near phoria', near: true));
    }
    if (results.isEmpty) {
      results.add(
        _Result(
          ResultType.warn,
          'Input required',
          'Enter at least one phoria',
          '',
        ),
      );
    }
    setState(() {
      _phoriaResults = results;
      _phoriaCalcCount++;
    });
    _scrollToBottom();
  }

  void _calcCAC() {
    HapticFeedback.lightImpact();
    final base = _v(_cacBase);
    final prismResponse = _v(_cacPrismResponse);
    final prism = _v(_cacPrism);
    if (!_isFinite(base) ||
        !_isFinite(prismResponse) ||
        !_isPositiveFinite(prism)) {
      setState(() {
        _cacResult = _Result(
          ResultType.warn,
          'Invalid input',
          'Enter both accommodative responses and positive BO prism',
          '',
        );
        _cacCalcCount++;
      });
      return;
    }

    final change = (prismResponse! - base!).abs();
    final ratio = change / prism!;
    final equivalentPrism = change == 0 ? null : prism / change;
    final note = equivalentPrism == null
        ? 'No measurable accommodation change for the entered convergence stimulus.'
        : 'Accommodation changed ${change.toStringAsFixed(2)}D with ${prism.toStringAsFixed(1)}Δ BO. Equivalent: 1D per ${equivalentPrism.toStringAsFixed(1)}Δ.';

    setState(() {
      _cacResult = _Result(
        ResultType.info,
        'CA/C ratio',
        '${ratio.toStringAsFixed(3)} D/Δ',
        note,
      );
      _cacCalcCount++;
    });
    _scrollToBottom();
  }

  void _calcACA() {
    HapticFeedback.lightImpact();
    double? ratio;
    if (_acaSeg == 0) {
      final ipd = _v(_ipd),
          pd = _phoriaValue(_pd, _pdDir),
          pn = _phoriaValue(_pn, _pnDir),
          nd = _v(_ndist);
      if (!_isPositiveFinite(ipd) ||
          !_isFinite(pd) ||
          !_isFinite(pn) ||
          !_isPositiveFinite(nd)) {
        setState(() {
          _acaResult = _Result(
            ResultType.warn,
            'Invalid input',
            'Enter positive IPD/distance + both phorias',
            '',
          );
          _acaCalcCount++;
        });
        return;
      }
      ratio = (ipd! / 10) + (pd! - pn!) / (1 / (nd! / 100));
    } else {
      final p1 = _phoriaValue(_gp1, _gp1Dir),
          p2 = _phoriaValue(_gp2, _gp2Dir),
          lens = _v(_glens);
      if (!_isFinite(p1) || !_isFinite(p2) || !_isFinite(lens) || lens == 0) {
        setState(() {
          _acaResult = _Result(
            ResultType.warn,
            'Invalid input',
            'Enter phoria values and non-zero lens power',
            '',
          );
          _acaCalcCount++;
        });
        return;
      }
      ratio = (p2! - p1!).abs() / lens!.abs();
    }
    final cls = ratio < 3 || ratio > 7
        ? ResultType.bad
        : ratio <= 5
        ? ResultType.ok
        : ResultType.warn;
    final lbl = ratio < 3
        ? 'Low AC/A'
        : ratio <= 5
        ? 'Normal AC/A'
        : ratio <= 7
        ? 'High AC/A'
        : 'Very high AC/A';
    final note = ratio < 3
        ? 'Associated with CI pattern.'
        : ratio <= 5
        ? 'Normal range (3–5 Δ/D).'
        : ratio <= 7
        ? 'Associated with CE pattern.'
        : 'Evaluate for accommodative ET.';
    setState(() {
      _acaResult = _Result(
        cls,
        'AC/A ratio',
        '${ratio!.toStringAsFixed(1)} : 1  $lbl',
        note,
      );
      _acaCalcCount++;
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
                icon: Icons.remove_red_eye_outlined,
                text: 'Phoria',
              ),
              InfoBox(
                child: const Text(
                  'Enter phoria magnitude and choose the direction.',
                ),
              ),
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
                placeholder: 'e.g. 4',
                step: 0.5,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _calcPhoria,
                child: const Text('Calculate'),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _phoriaResults.isEmpty
                    ? const SizedBox.shrink()
                    : FadeIn(
                        key: ValueKey(_phoriaCalcCount),
                        child: Column(
                          children: _phoriaResults
                              .map(
                                (r) => ResultCard(
                                  type: r.type,
                                  label: r.label,
                                  value: r.value,
                                  note: r.note,
                                ),
                              )
                              .toList(),
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
              const CardTitle(icon: Icons.functions, text: 'AC/A ratio'),
              SegmentedControl(
                labels: const ['Calculated', 'Gradient'],
                selected: _acaSeg,
                onChanged: (i) => setState(() {
                  _acaSeg = i;
                  _acaResult = null;
                }),
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
              ],
              ElevatedButton(
                onPressed: _calcACA,
                child: const Text('Calculate AC/A'),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _acaResult == null
                    ? const SizedBox.shrink()
                    : FadeIn(
                        key: ValueKey(_acaCalcCount),
                        child: ResultCard(
                          type: _acaResult!.type,
                          label: _acaResult!.label,
                          value: _acaResult!.value,
                          note: _acaResult!.note,
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
              const CardTitle(icon: Icons.sync_alt, text: 'CA/C ratio'),
              InfoBox(
                child: const Text(
                  'Response CA/C = change in accommodative response ÷ BO prism-induced convergence stimulus.',
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: NumField(
                      label: 'Habitual response (D)',
                      controller: _cacBase,
                      placeholder: '0.50',
                      step: 0.25,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumField(
                      label: 'With BO prism (D)',
                      controller: _cacPrismResponse,
                      placeholder: '1.00',
                      step: 0.25,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              NumField(
                label: 'BO prism stimulus (Δ)',
                controller: _cacPrism,
                placeholder: '10',
                step: 0.5,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _calcCAC,
                child: const Text('Calculate CA/C'),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _cacResult == null
                    ? const SizedBox.shrink()
                    : FadeIn(
                        key: ValueKey(_cacCalcCount),
                        child: ResultCard(
                          type: _cacResult!.type,
                          label: _cacResult!.label,
                          value: _cacResult!.value,
                          note: _cacResult!.note,
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

class _Result {
  final ResultType type;
  final String label, value;
  final String? note;
  _Result(this.type, this.label, this.value, this.note);
}
