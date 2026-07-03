import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/result_card.dart';

class AccommodationScreen extends StatefulWidget {
  const AccommodationScreen({super.key});

  @override
  State<AccommodationScreen> createState() => _AccommodationScreenState();
}

class _AccommodationScreenState extends State<AccommodationScreen> {
  final _scroll = ScrollController();
  final _age = TextEditingController();
  final _amp = TextEditingController();
  final _facOd = TextEditingController();
  final _facOs = TextEditingController();
  final _facBin = TextEditingController();
  final _mem = TextEditingController();
  final _nra = TextEditingController();
  final _pra = TextEditingController();

  List<_NormRow> _ampRows = [];
  List<_NormRow> _rangeRows = [];
  _Result? _ampSummary;
  int _ampCalcCount = 0;
  int _rangeCalcCount = 0;

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [_age, _amp, _facOd, _facOs, _facBin, _mem, _nra, _pra]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _v(TextEditingController c) => double.tryParse(c.text.trim());
  bool _isFinite(double? v) => v != null && v.isFinite;
  bool _isPositiveFinite(double? v) => _isFinite(v) && v! > 0;

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

  void _calcAmplitude() {
    HapticFeedback.lightImpact();
    final age = _v(_age);
    final amp = _v(_amp);
    if (!_isPositiveFinite(age) || !_isPositiveFinite(amp)) {
      setState(() {
        _ampRows = [];
        _ampSummary = _Result(
          ResultType.warn,
          'Input required',
          'Enter age and amplitude',
          '',
        );
        _ampCalcCount++;
      });
      _scrollToBottom();
      return;
    }

    final minimum = 15 - (0.25 * age!);
    final expected = 18.5 - (0.30 * age);
    final maximum = 25 - (0.40 * age);
    final nearPointCm = 100 / amp!;

    final type = amp < minimum
        ? ResultType.bad
        : amp > maximum
        ? ResultType.warn
        : ResultType.ok;
    final value = amp < minimum
        ? 'Below age minimum'
        : amp > maximum
        ? 'Above expected maximum'
        : 'Within age range';
    final note = amp < minimum
        ? 'Pattern supports accommodative insufficiency when symptoms match.'
        : amp > maximum
        ? 'Check for over-minusing, spasm, or measurement artefact.'
        : 'Compare with facility, MEM, NRA/PRA for the full pattern.';

    setState(() {
      _ampSummary = _Result(type, 'Amplitude status', value, note);
      _ampRows = [
        _NormRow(
          'Measured amplitude',
          '${amp.toStringAsFixed(2)}D',
          '',
          BadgeStatus.info,
        ),
        _NormRow(
          'Hofstetter minimum',
          '${minimum.toStringAsFixed(2)}D',
          _ampBadge(amp, minimum),
          _ampStatus(amp, minimum),
        ),
        _NormRow(
          'Expected',
          '${expected.toStringAsFixed(2)}D',
          '',
          BadgeStatus.info,
        ),
        _NormRow(
          'Maximum',
          '${maximum.toStringAsFixed(2)}D',
          '',
          BadgeStatus.info,
        ),
        _NormRow(
          'Near point',
          '${nearPointCm.toStringAsFixed(1)} cm',
          '',
          BadgeStatus.info,
        ),
      ];
      _ampCalcCount++;
    });
    _scrollToBottom();
  }

  void _calcRanges() {
    HapticFeedback.lightImpact();
    final rows = <_NormRow>[];
    final od = _v(_facOd);
    final os = _v(_facOs);
    final bin = _v(_facBin);
    final mem = _v(_mem);
    final nra = _v(_nra);
    final pra = _v(_pra);

    if (_isFinite(od)) {
      rows.add(_minRow('OD facility', od!, 13, 'cpm'));
    }
    if (_isFinite(os)) {
      rows.add(_minRow('OS facility', os!, 13, 'cpm'));
    }
    if (_isFinite(bin)) {
      rows.add(_minRow('Binocular facility', bin!, 11, 'cpm'));
    }
    if (_isFinite(mem)) {
      rows.add(_rangeRow('MEM lag', mem!, 0.25, 0.75, 'D'));
    }
    if (_isFinite(nra)) {
      rows.add(_rangeRow('NRA', nra!, 2.00, 2.50, 'D'));
    }
    if (_isFinite(pra)) {
      rows.add(_rangeRow('PRA', pra!.abs(), 2.00, 2.75, 'D'));
    }

    if (rows.isEmpty) {
      rows.add(
        _NormRow(
          'Input required',
          'Enter at least one value',
          '',
          BadgeStatus.warn,
        ),
      );
    }

    setState(() {
      _rangeRows = rows;
      _rangeCalcCount++;
    });
    _scrollToBottom();
  }

  _NormRow _minRow(String label, double value, double minimum, String unit) {
    final diff = value - minimum;
    if (diff >= 0) {
      return _NormRow(
        label,
        '${value.toStringAsFixed(0)} $unit',
        'Norm',
        BadgeStatus.ok,
      );
    }
    return _NormRow(
      label,
      '${value.toStringAsFixed(0)} $unit',
      '${diff.abs().toStringAsFixed(0)} low',
      BadgeStatus.bad,
    );
  }

  _NormRow _rangeRow(
    String label,
    double value,
    double low,
    double high,
    String unit,
  ) {
    final display = '$value'.endsWith('.0')
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    if (value < low) {
      return _NormRow(label, '$display $unit', 'Low', BadgeStatus.bad);
    }
    if (value > high) {
      return _NormRow(label, '$display $unit', 'High', BadgeStatus.warn);
    }
    return _NormRow(label, '$display $unit', 'Norm', BadgeStatus.ok);
  }

  String _ampBadge(double amp, double minimum) {
    final diff = amp - minimum;
    if (diff >= 0) return 'Pass';
    return '${diff.abs().toStringAsFixed(1)}D low';
  }

  BadgeStatus _ampStatus(double amp, double minimum) {
    return amp >= minimum ? BadgeStatus.ok : BadgeStatus.bad;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardTitle(
                icon: Icons.zoom_in,
                text: 'Amplitude of accommodation',
              ),
              InfoBox(
                child: const Text(
                  'Hofstetter: minimum 15 − 0.25 × age, expected 18.5 − 0.30 × age, maximum 25 − 0.40 × age.',
                ),
              ),
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
                      placeholder: '10',
                      step: 0.25,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _calcAmplitude,
                child: const Text('Compare amplitude'),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _ampSummary == null
                    ? const SizedBox.shrink()
                    : FadeIn(
                        key: ValueKey(_ampCalcCount),
                        child: Column(
                          children: [
                            ResultCard(
                              type: _ampSummary!.type,
                              label: _ampSummary!.label,
                              value: _ampSummary!.value,
                              note: _ampSummary!.note,
                            ),
                            if (_ampRows.isNotEmpty)
                              _RowsPanel(rows: _ampRows, isDark: isDark),
                          ],
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
                icon: Icons.tune_outlined,
                text: 'Facility, MEM, NRA/PRA',
              ),
              InfoBox(
                child: const Text(
                  'Adult comparison ranges: OD/OS facility ≥13 cpm, binocular facility ≥11 cpm, MEM +0.25 to +0.75D, NRA +2.00 to +2.50D, PRA about −2.00 to −2.75D.',
                ),
              ),
              const SectionLabel('Facility'),
              Row(
                children: [
                  Expanded(
                    child: NumField(
                      label: 'OD (cpm)',
                      controller: _facOd,
                      placeholder: '≥13',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumField(
                      label: 'OS (cpm)',
                      controller: _facOs,
                      placeholder: '≥13',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              NumField(
                label: 'Binocular (cpm)',
                controller: _facBin,
                placeholder: '≥11',
              ),
              const SectionLabel('Response and relative accommodation'),
              Row(
                children: [
                  Expanded(
                    child: NumField(
                      label: 'MEM lag (D)',
                      controller: _mem,
                      placeholder: '0.50',
                      step: 0.25,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumField(
                      label: 'NRA (D)',
                      controller: _nra,
                      placeholder: '+2.25',
                      step: 0.25,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              NumField(
                label: 'PRA (D)',
                controller: _pra,
                placeholder: '-2.25',
                step: 0.25,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _calcRanges,
                child: const Text('Compare ranges'),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _rangeRows.isEmpty
                    ? const SizedBox.shrink()
                    : FadeIn(
                        key: ValueKey(_rangeCalcCount),
                        child: _RowsPanel(rows: _rangeRows, isDark: isDark),
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

class _RowsPanel extends StatelessWidget {
  final List<_NormRow> rows;
  final bool isDark;

  const _RowsPanel({required this.rows, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: rows.map((r) {
          final isLast = rows.last == r;
          final border = isDark
              ? const Color(0xFF38383A)
              : const Color(0xFFE5E5EA);
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: border, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    r.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6E6E73),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      r.value,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (r.badge.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      _badge(r),
                    ],
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _badge(_NormRow row) {
    return switch (row.status) {
      BadgeStatus.ok => Pill.normal(row.badge),
      BadgeStatus.bad => Pill.fail(row.badge),
      BadgeStatus.warn => Pill.warn(row.badge),
      BadgeStatus.info => Pill.info(row.badge),
    };
  }
}

class _Result {
  final ResultType type;
  final String label, value;
  final String? note;

  _Result(this.type, this.label, this.value, this.note);
}

class _NormRow {
  final String label, value, badge;
  final BadgeStatus status;

  _NormRow(this.label, this.value, this.badge, this.status);
}

enum BadgeStatus { ok, bad, warn, info }
