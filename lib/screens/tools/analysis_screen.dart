import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/result_card.dart';

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

  _Res? _shResult, _pcResult;
  int _shCalcCount = 0;
  int _pcCalcCount = 0;

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [_shPh, _shCv, _pcBo, _pcBi]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _v(TextEditingController c) => double.tryParse(c.text.trim());

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
    final ph = _v(_shPh), cv = _v(_shCv);
    if (ph == null || cv == null) {
      setState(() {
        _shResult = _Res(ResultType.warn, "Sheard's", 'Input required', 'Enter phoria and comp. vergence');
        _shCalcCount++;
      });
      return;
    }
    final a = ph.abs();
    final pass = cv >= 2 * a;
    final prism = ((2 * a - cv) / 3).clamp(0, double.infinity);
    final dir = ph >= 0 ? 'BI' : 'BO';
    setState(() {
      _shResult = pass
          ? _Res(ResultType.ok, "Sheard's", 'Passes ✓',
              'CV (${cv.toStringAsFixed(0)}Δ) ≥ 2 × phoria (${a.toStringAsFixed(1)}Δ)')
          : _Res(ResultType.bad, "Sheard's", 'Fails ✗',
              'Prism needed: ${prism.toStringAsFixed(2)}Δ $dir');
      _shCalcCount++;
    });
    _scrollToBottom();
  }

  void _calcPercivals() {
    HapticFeedback.lightImpact();
    final bo = _v(_pcBo), bi = _v(_pcBi);
    if (bo == null || bi == null) {
      setState(() {
        _pcResult = _Res(ResultType.warn, "Percival's", 'Input required', 'Enter BO and BI values');
        _pcCalcCount++;
      });
      return;
    }
    final G = bo > bi ? bo : bi;
    final L = bo < bi ? bo : bi;
    final pass = L >= G / 2;
    final prism = (G / 3 - (2 * L) / 3).clamp(0, double.infinity);
    final dir = bo < bi ? 'BI' : 'BO';
    setState(() {
      _pcResult = pass
          ? _Res(ResultType.ok, "Percival's", 'Passes ✓',
              'Lesser (${L.toStringAsFixed(0)}Δ) ≥ half of greater (${G.toStringAsFixed(0)}Δ)')
          : _Res(ResultType.bad, "Percival's", 'Fails ✗',
              'Prism needed: ${prism.toStringAsFixed(2)}Δ $dir');
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
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle(icon: Icons.balance_outlined, text: "Sheard's criterion"),
          InfoBox(child: const Text.rich(TextSpan(children: [
            TextSpan(text: 'Passes if: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
            TextSpan(text: 'comp. vergence ≥ 2 × phoria'),
          ]))),
          NumField(label: 'Phoria (Δ) — + exo, − eso', controller: _shPh, placeholder: 'e.g. 8', step: 0.5),
          const SizedBox(height: 8),
          NumField(label: 'Comp. vergence break (Δ)', controller: _shCv, placeholder: 'e.g. 12'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calcSheards, child: const Text("Apply Sheard's")),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _shResult == null
                ? const SizedBox.shrink()
                : FadeIn(
                    key: ValueKey(_shCalcCount),
                    child: ResultCard(
                      type: _shResult!.type, label: _shResult!.label,
                      value: _shResult!.value, note: _shResult!.note,
                    ),
                  ),
          ),
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
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calcPercivals, child: const Text("Apply Percival's")),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _pcResult == null
                ? const SizedBox.shrink()
                : FadeIn(
                    key: ValueKey(_pcCalcCount),
                    child: ResultCard(
                      type: _pcResult!.type, label: _pcResult!.label,
                      value: _pcResult!.value, note: _pcResult!.note,
                    ),
                  ),
          ),
        ])),
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
