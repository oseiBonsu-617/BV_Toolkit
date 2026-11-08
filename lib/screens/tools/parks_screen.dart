import 'package:flutter/material.dart';
import '../../models/parks_test.dart';
import '../../theme.dart';
import '../../widgets/result_card.dart';

/// Park's three-step test: three cover-test findings narrow eight
/// cyclovertical muscles to one.
class ParksScreen extends StatefulWidget {
  const ParksScreen({super.key});
  @override
  State<ParksScreen> createState() => _ParksScreenState();
}

class _ParksScreenState extends State<ParksScreen> {
  Side? _hyper, _gaze, _tilt;

  ParksAnalysis get _analysis =>
      ParksAnalysis(hyper: _hyper, gaze: _gaze, tilt: _tilt);

  void _setHyper(Side s) => setState(() {
    _hyper = s;
    _gaze = null;
    _tilt = null;
  });

  void _setGaze(Side s) => setState(() {
    _gaze = s;
    _tilt = null;
  });

  void _setTilt(Side s) => setState(() => _tilt = s);

  void _reset() => setState(() {
    _hyper = null;
    _gaze = null;
    _tilt = null;
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73);
    final a = _analysis;
    final answered = [_hyper, _gaze, _tilt].where((s) => s != null).length;
    // The set the latest answered step started from; what that step
    // eliminated is shown struck through.
    final parent = switch (answered) {
      0 || 1 => ParksMuscle.values,
      2 => ParksAnalysis(hyper: _hyper).candidates,
      _ => ParksAnalysis(hyper: _hyper, gaze: _gaze).candidates,
    };
    final remaining = a.candidates.toSet();
    final result = a.result;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const InfoBox(
          child: Text(
            'Use for a vertical deviation. Answer each step from your cover '
            'test findings.',
          ),
        ),
        _step(
          1,
          'Which eye is higher in primary gaze?',
          const ['Right hyper', 'Left hyper'],
          _hyper,
          enabled: true,
          onPick: _setHyper,
        ),
        _step(
          2,
          'The hypertropia is greater on gaze to the…',
          const ['Right', 'Left'],
          _gaze,
          enabled: _hyper != null,
          onPick: _setGaze,
        ),
        _step(
          3,
          'The hypertropia is greater on head tilt to the…',
          const ['Right', 'Left'],
          _tilt,
          enabled: _hyper != null && _gaze != null,
          onPick: _setTilt,
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardTitle(
                icon: Icons.filter_list,
                text: 'Candidate muscles',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in parent)
                    _chip(m, struck: !remaining.contains(m), muted: muted),
                ],
              ),
            ],
          ),
        ),
        if (result != null)
          Container(
            key: const Key('parks-result'),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: isDark ? 0.18 : 0.08),
              border: Border.all(color: primaryOf(context), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIKELY PARETIC MUSCLE',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.5,
                    color: primaryOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: primaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(result.nerve, style: TextStyle(fontSize: 15, color: muted)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            "Assumes a single paretic cyclovertical muscle. If the findings "
            "don't fit or the deviation is small, consider skew deviation "
            "(upright–supine test), a restrictive cause or more than one "
            "muscle.",
            style: TextStyle(fontSize: 13, height: 1.5, color: muted),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('parks-reset'),
            onPressed: _reset,
            child: const Text('Reset', style: TextStyle(fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _step(
    int n,
    String question,
    List<String> labels,
    Side? value, {
    required bool enabled,
    required ValueChanged<Side> onPick,
  }) {
    return AppCard(
      key: Key('parks-step-$n'),
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Step $n. $question',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SegmentedControl(
                labels: labels,
                selected: value == null ? -1 : value.index,
                onChanged: (i) => onPick(Side.values[i]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(ParksMuscle m, {required bool struck, required Color muted}) {
    return Container(
      key: Key('parks-candidate-${(m as Enum).name}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: struck
            ? Colors.transparent
            : kPrimary.withValues(alpha: 0.12),
        border: Border.all(
          color: struck ? muted.withValues(alpha: 0.4) : primaryOf(context),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        m.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: struck ? FontWeight.normal : FontWeight.w600,
          color: struck ? muted : primaryOf(context),
          decoration: struck ? TextDecoration.lineThrough : null,
          decorationColor: muted,
        ),
      ),
    );
  }
}
