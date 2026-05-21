import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/result_card.dart';

class VergenceScreen extends StatefulWidget {
  const VergenceScreen({super.key});
  @override
  State<VergenceScreen> createState() => _VergenceScreenState();
}

class _VergenceScreenState extends State<VergenceScreen> {
  final _scroll = ScrollController();
  final _nbrk = TextEditingController();
  final _nrec = TextEditingController();
  final _biBlur = TextEditingController();
  final _biBrk = TextEditingController();
  final _biRec = TextEditingController();
  final _boBlur = TextEditingController();
  final _boBrk = TextEditingController();
  final _boRec = TextEditingController();

  int _vergSeg = 0;
  _NpcResult? _npcResult;
  List<_VergRow> _vergRows = [];
  int _npcCalcCount = 0;
  int _vergCalcCount = 0;

  static const _norms = [
    {
      'dist': {'bi_blur': null, 'bi_brk': 7.0, 'bi_rec': 4.0, 'bo_blur': 9.0, 'bo_brk': 19.0, 'bo_rec': 10.0},
      'near': {'bi_blur': 13.0, 'bi_brk': 21.0, 'bi_rec': 13.0, 'bo_blur': 17.0, 'bo_brk': 21.0, 'bo_rec': 11.0},
    }
  ];

  Map<String, double?> get _currentNorms {
    final key = _vergSeg == 0 ? 'dist' : 'near';
    return Map<String, double?>.from(_norms[0][key]!);
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [_nbrk, _nrec, _biBlur, _biBrk, _biRec, _boBlur, _boBrk, _boRec]) {
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

  void _calcNPC() {
    HapticFeedback.lightImpact();
    final b = _v(_nbrk), r = _v(_nrec);
    if (b == null || r == null) {
      setState(() {
        _npcResult = _NpcResult(ResultType.warn, 'Input required', 'Enter break and recovery', '');
        _npcCalcCount++;
      });
      return;
    }
    final bOk = b <= 5, rOk = r <= 7;
    final cls = (bOk && rOk)
        ? ResultType.ok
        : (!bOk && !rOk)
            ? ResultType.bad
            : ResultType.warn;
    final lbl = (bOk && rOk)
        ? 'Normal NPC'
        : (!bOk && !rOk)
            ? 'Receded NPC'
            : 'Borderline NPC';
    setState(() {
      _npcResult = _NpcResult(
          cls, 'NPC status', lbl, 'Break ${b.toStringAsFixed(1)} cm / Recovery ${r.toStringAsFixed(1)} cm');
      _npcCalcCount++;
    });
    _scrollToBottom();
  }

  void _calcVerg() {
    HapticFeedback.lightImpact();
    final norms = _currentNorms;
    final fields = [
      _Field(_biBlur, norms['bi_blur'], 'BI blur'),
      _Field(_biBrk, norms['bi_brk'], 'BI break'),
      _Field(_biRec, norms['bi_rec'], 'BI recovery'),
      _Field(_boBlur, norms['bo_blur'], 'BO blur'),
      _Field(_boBrk, norms['bo_brk'], 'BO break'),
      _Field(_boRec, norms['bo_rec'], 'BO recovery'),
    ];

    final rows = <_VergRow>[];
    for (final f in fields) {
      final val = _v(f.ctrl);
      if (val == null) continue;
      final norm = f.norm;
      String badge = '';
      BadgeStatus status = BadgeStatus.info;
      if (norm != null) {
        final diff = val - norm;
        if (diff.abs() <= 2) {
          badge = 'Norm';
          status = BadgeStatus.ok;
        } else if (diff < 0) {
          badge = '${diff.abs().toStringAsFixed(0)}Δ low';
          status = BadgeStatus.bad;
        } else {
          badge = '${diff.toStringAsFixed(0)}Δ high';
          status = BadgeStatus.warn;
        }
      }
      rows.add(_VergRow(f.label, '${val.toStringAsFixed(0)}Δ', badge, status));
    }
    setState(() {
      _vergRows = rows;
      _vergCalcCount++;
    });
    _scrollToBottom();
  }

  String _placeholder(String key) {
    final n = _currentNorms[key];
    return n == null ? '—' : n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      children: [
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle(icon: Icons.open_with, text: 'NPC'),
          InfoBox(child: const Text('Norms: break ≤ 5 cm, recovery ≤ 7 cm')),
          Row(children: [
            Expanded(child: NumField(label: 'Break (cm)', controller: _nbrk, placeholder: '5', step: 0.5)),
            const SizedBox(width: 8),
            Expanded(child: NumField(label: 'Recovery (cm)', controller: _nrec, placeholder: '7', step: 0.5)),
          ]),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calcNPC, child: const Text('Assess NPC')),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _npcResult == null
                ? const SizedBox.shrink()
                : FadeIn(
                    key: ValueKey(_npcCalcCount),
                    child: ResultCard(
                      type: _npcResult!.type, label: _npcResult!.label,
                      value: _npcResult!.value, note: _npcResult!.note,
                    ),
                  ),
          ),
        ])),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const CardTitle(icon: Icons.compare_arrows, text: 'Vergence ranges'),
          SegmentedControl(
            labels: const ['Distance', 'Near'],
            selected: _vergSeg,
            onChanged: (i) {
              setState(() {
                _vergSeg = i;
                _vergRows = [];
                for (final c in [_biBlur, _biBrk, _biRec, _boBlur, _boBrk, _boRec]) {
                  c.clear();
                }
              });
            },
          ),
          const SectionLabel('Base-In'),
          Row(children: [
            Expanded(child: NumField(label: 'Blur (Δ)', controller: _biBlur, placeholder: _placeholder('bi_blur'))),
            const SizedBox(width: 8),
            Expanded(child: NumField(label: 'Break (Δ)', controller: _biBrk, placeholder: _placeholder('bi_brk'))),
          ]),
          const SizedBox(height: 8),
          NumField(label: 'Recovery (Δ)', controller: _biRec, placeholder: _placeholder('bi_rec')),
          const SectionLabel('Base-Out'),
          Row(children: [
            Expanded(child: NumField(label: 'Blur (Δ)', controller: _boBlur, placeholder: _placeholder('bo_blur'))),
            const SizedBox(width: 8),
            Expanded(child: NumField(label: 'Break (Δ)', controller: _boBrk, placeholder: _placeholder('bo_brk'))),
          ]),
          const SizedBox(height: 8),
          NumField(label: 'Recovery (Δ)', controller: _boRec, placeholder: _placeholder('bo_rec')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _calcVerg, child: const Text('Compare to norms')),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _vergRows.isEmpty
                ? const SizedBox.shrink()
                : FadeIn(
                    key: ValueKey(_vergCalcCount),
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: _vergRows.map((r) => _buildVergRow(r, isDark)).toList(),
                      ),
                    ),
                  ),
          ),
        ])),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildVergRow(_VergRow r, bool isDark) {
    final border = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);
    final isLast = _vergRows.last == r;

    Widget badge;
    if (r.badge.isEmpty) {
      badge = const SizedBox.shrink();
    } else {
      badge = switch (r.status) {
        BadgeStatus.ok => Pill.normal(r.badge),
        BadgeStatus.bad => Pill.fail(r.badge),
        BadgeStatus.warn => Pill.warn(r.badge),
        BadgeStatus.info => Pill.info(r.badge),
      };
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(r.label, style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
          )),
          Row(children: [
            Text(r.value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            if (r.badge.isNotEmpty) ...[const SizedBox(width: 5), badge],
          ]),
        ],
      ),
    );
  }
}

class _NpcResult {
  final ResultType type;
  final String label, value;
  final String? note;
  _NpcResult(this.type, this.label, this.value, this.note);
}

class _Field {
  final TextEditingController ctrl;
  final double? norm;
  final String label;
  _Field(this.ctrl, this.norm, this.label);
}

class _VergRow {
  final String label, value, badge;
  final BadgeStatus status;
  _VergRow(this.label, this.value, this.badge, this.status);
}

enum BadgeStatus { ok, bad, warn, info }
