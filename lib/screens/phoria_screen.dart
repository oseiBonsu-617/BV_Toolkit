import 'package:flutter/material.dart';
import '../widgets/result_card.dart';

class PhoriaScreen extends StatefulWidget {
  const PhoriaScreen({super.key});
  @override
  State<PhoriaScreen> createState() => _PhoriaScreenState();
}

class _PhoriaScreenState extends State<PhoriaScreen> {
  final _pd = TextEditingController();
  final _pn = TextEditingController();
  final _ipd = TextEditingController();
  final _ndist = TextEditingController(text: '40');
  final _gp1 = TextEditingController();
  final _gp2 = TextEditingController();
  final _glens = TextEditingController(text: '1.00');

  int _acaSeg = 0;
  List<_Result> _phoriaResults = [];
  _Result? _acaResult;

  @override
  void dispose() {
    for (final c in [_pd, _pn, _ipd, _ndist, _gp1, _gp2, _glens]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _v(TextEditingController c) => double.tryParse(c.text.trim());

  void _calcPhoria() {
    final results = <_Result>[];
    final pd = _v(_pd), pn = _v(_pn);

    if (pd != null) {
      final a = pd.abs();
      final type = pd == 0 ? 'Orthophoria' : pd > 0 ? 'Exophoria' : 'Esophoria';
      final ok = a <= 2;
      final warn = a <= 4;
      final cls = pd == 0 || ok ? ResultType.ok : warn ? ResultType.warn : ResultType.bad;
      results.add(_Result(cls, 'Distance phoria', '${a.toStringAsFixed(1)}Δ  $type',
          a <= 2 ? 'Within Morgan\'s norm' : 'Outside norm'));
    }
    if (pn != null) {
      final a = pn.abs();
      final type = pn == 0 ? 'Orthophoria' : pn > 0 ? 'Exophoria' : 'Esophoria';
      final normLimit = pn > 0 ? 6 : 2;
      final cls = a <= normLimit ? ResultType.ok : a <= 10 ? ResultType.warn : ResultType.bad;
      results.add(_Result(cls, 'Near phoria', '${a.toStringAsFixed(1)}Δ  $type',
          a <= normLimit ? "Within Morgan's norm" : 'Outside norm'));
    }
    if (results.isEmpty) {
      results.add(_Result(ResultType.warn, 'Input required', 'Enter at least one phoria', ''));
    }
    setState(() => _phoriaResults = results);
  }

  void _calcACA() {
    double? ratio;
    if (_acaSeg == 0) {
      final ipd = _v(_ipd), pd = _v(_pd), pn = _v(_pn), nd = _v(_ndist);
      if (ipd == null || pd == null || pn == null || nd == null) {
        setState(() => _acaResult = _Result(ResultType.warn, 'Missing',
            'Enter IPD + both phorias', ''));
        return;
      }
      ratio = (ipd / 10) + (pn - pd) / (1 / (nd / 100));
    } else {
      final p1 = _v(_gp1), p2 = _v(_gp2), lens = _v(_glens);
      if (p1 == null || p2 == null || lens == null || lens == 0) {
        setState(() => _acaResult = _Result(ResultType.warn, 'Missing',
            'Enter phoria values and lens power', ''));
        return;
      }
      ratio = (p2 - p1).abs() / lens.abs();
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
    setState(() => _acaResult =
        _Result(cls, 'AC/A ratio', '${ratio!.toStringAsFixed(1)} : 1  $lbl', note));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle(icon: Icons.remove_red_eye_outlined, text: 'Phoria'),
          InfoBox(child: const Text.rich(TextSpan(children: [
            TextSpan(text: 'Convention: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
            TextSpan(text: '+ = exophoria, − = esophoria'),
          ]))),
          Row(children: [
            Expanded(child: NumField(label: 'Distance (Δ)', controller: _pd, placeholder: 'e.g. 2', step: 0.5)),
            const SizedBox(width: 8),
            Expanded(child: NumField(label: 'Near (Δ)', controller: _pn, placeholder: 'e.g. 4', step: 0.5)),
          ]),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _calcPhoria, child: const Text('Calculate')),
          ..._phoriaResults.map((r) => ResultCard(type: r.type, label: r.label, value: r.value, note: r.note)),
        ])),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle(icon: Icons.functions, text: 'AC/A ratio'),
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
            const SizedBox(height: 8),
            InfoBox(child: const Text('Uses phoria values above', style: TextStyle(fontSize: 10))),
          ] else ...[
            Row(children: [
              Expanded(child: NumField(label: 'Phoria habitual (Δ)', controller: _gp1, placeholder: '4', step: 0.5)),
              const SizedBox(width: 8),
              Expanded(child: NumField(label: 'Phoria + lens (Δ)', controller: _gp2, placeholder: '8', step: 0.5)),
            ]),
            const SizedBox(height: 8),
            NumField(label: 'Lens power (D)', controller: _glens, placeholder: '1.00', step: 0.25),
            const SizedBox(height: 8),
          ],
          ElevatedButton(onPressed: _calcACA, child: const Text('Calculate AC/A')),
          if (_acaResult != null)
            ResultCard(
              type: _acaResult!.type,
              label: _acaResult!.label,
              value: _acaResult!.value,
              note: _acaResult!.note,
            ),
        ])),
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
