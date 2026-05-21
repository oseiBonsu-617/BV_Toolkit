import 'package:flutter/material.dart';
import '../widgets/result_card.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _shPh = TextEditingController();
  final _shCv = TextEditingController();
  final _pcBo = TextEditingController();
  final _pcBi = TextEditingController();

  _Res? _shResult, _pcResult;

  @override
  void dispose() {
    for (final c in [_shPh, _shCv, _pcBo, _pcBi]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _v(TextEditingController c) => double.tryParse(c.text.trim());

  void _calcSheards() {
    final ph = _v(_shPh), cv = _v(_shCv);
    if (ph == null || cv == null) {
      setState(() => _shResult = _Res(ResultType.warn, "Sheard's",
          'Input required', 'Enter phoria and comp. vergence'));
      return;
    }
    final a = ph.abs();
    final pass = cv >= 2 * a;
    final prism = ((2 * a - cv) / 3).clamp(0, double.infinity);
    final dir = ph >= 0 ? 'BI' : 'BO';
    setState(() => _shResult = pass
        ? _Res(ResultType.ok, "Sheard's", 'Passes ✓',
            'CV (${cv.toStringAsFixed(0)}Δ) ≥ 2 × phoria (${a.toStringAsFixed(1)}Δ)')
        : _Res(ResultType.bad, "Sheard's", 'Fails ✗',
            'Prism needed: ${prism.toStringAsFixed(2)}Δ $dir'));
  }

  void _calcPercivals() {
    final bo = _v(_pcBo), bi = _v(_pcBi);
    if (bo == null || bi == null) {
      setState(() => _pcResult = _Res(ResultType.warn, "Percival's",
          'Input required', 'Enter BO and BI values'));
      return;
    }
    final G = bo > bi ? bo : bi;
    final L = bo < bi ? bo : bi;
    final pass = L >= G / 2;
    final prism = (G / 3 - (2 * L) / 3).clamp(0, double.infinity);
    final dir = bo < bi ? 'BI' : 'BO';
    setState(() => _pcResult = pass
        ? _Res(ResultType.ok, "Percival's", 'Passes ✓',
            'Lesser (${L.toStringAsFixed(0)}Δ) ≥ half of greater (${G.toStringAsFixed(0)}Δ)')
        : _Res(ResultType.bad, "Percival's", 'Fails ✗',
            'Prism needed: ${prism.toStringAsFixed(2)}Δ $dir'));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle(icon: Icons.balance_outlined, text: "Sheard's criterion"),
          InfoBox(child: const Text.rich(TextSpan(children: [
            TextSpan(text: 'Passes if: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
            TextSpan(text: 'comp. vergence ≥ 2 × phoria'),
          ]))),
          NumField(label: 'Phoria (Δ) — + exo, − eso', controller: _shPh, placeholder: 'e.g. 8', step: 0.5),
          const SizedBox(height: 8),
          NumField(label: 'Comp. vergence break (Δ)', controller: _shCv, placeholder: 'e.g. 12'),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _calcSheards, child: const Text("Apply Sheard's")),
          if (_shResult != null)
            ResultCard(type: _shResult!.type, label: _shResult!.label,
                value: _shResult!.value, note: _shResult!.note),
        ])),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle(icon: Icons.horizontal_distribute, text: "Percival's criterion"),
          InfoBox(child: const Text.rich(TextSpan(children: [
            TextSpan(text: 'Passes if: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
            TextSpan(text: 'lesser ≥ ½ × greater vergence'),
          ]))),
          Row(children: [
            Expanded(child: NumField(label: 'BO blur/break (Δ)', controller: _pcBo, placeholder: '17')),
            const SizedBox(width: 8),
            Expanded(child: NumField(label: 'BI blur/break (Δ)', controller: _pcBi, placeholder: '13')),
          ]),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _calcPercivals, child: const Text("Apply Percival's")),
          if (_pcResult != null)
            ResultCard(type: _pcResult!.type, label: _pcResult!.label,
                value: _pcResult!.value, note: _pcResult!.note),
        ])),
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
