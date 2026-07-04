import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/graphical_analysis.dart';
import '../theme.dart';

/// Interactive Zone of Clear Single Binocular Vision (ZCSBV) plot.
///
/// Renders the demand line, phoria line, PFV/NFV blur & break lines, the ZCSBV
/// zone and the NRA/PRA range from a computed [GAGeometry]. Layers can be
/// toggled and a drag reveals the vergence/accommodation read-out.
class ZcsbvGraph extends StatefulWidget {
  final GAGeometry geometry;
  const ZcsbvGraph({super.key, required this.geometry});

  @override
  State<ZcsbvGraph> createState() => _ZcsbvGraphState();
}

class _Layer {
  final String key;
  final String label;
  final Color color;
  const _Layer(this.key, this.label, this.color);
}

class _ZcsbvGraphState extends State<ZcsbvGraph> {
  final _on = <String>{'zone', 'dem', 'ph', 'bo', 'bi', 'nr'};
  Offset? _probe;

  static const _layers = [
    _Layer('zone', 'ZCSBV zone', Color(0xFF7FA9DE)),
    _Layer('dem', 'Demand line', GAColors.demand),
    _Layer('ph', 'Phoria line', GAColors.phoria),
    _Layer('bo', 'PFV / BO', GAColors.boBreak),
    _Layer('bi', 'NFV / BI', GAColors.biBreak),
    _Layer('nr', 'NRA / PRA', GAColors.nrpra),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _layers.map((l) {
            final active = _on.contains(l.key);
            return GestureDetector(
              onTap: () => setState(() {
                active ? _on.remove(l.key) : _on.add(l.key);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: active
                      ? kPrimary.withAlpha(isDark ? 40 : 26)
                      : (isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7)),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active
                        ? kPrimary.withAlpha(150)
                        : Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? l.color : l.color.withAlpha(90),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: active
                            ? (isDark ? Colors.white : const Color(0xFF1C1C1E))
                            : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = w / 1.5;
            return GestureDetector(
              onPanStart: (d) => setState(() => _probe = d.localPosition),
              onPanUpdate: (d) => setState(() => _probe = d.localPosition),
              onPanEnd: (_) => setState(() => _probe = null),
              child: CustomPaint(
                size: Size(w, h),
                painter: _ZcsbvPainter(
                  g: widget.geometry,
                  layers: _on,
                  isDark: isDark,
                  probe: _probe,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Palette for the ZCSBV plot (referenced by both the graph and its legend).
class GAColors {
  static const demand = Color(0xFF2A78D6);
  static const phoria = Color(0xFF1BAF7A);
  static const boBlur = Color(0xFF9085E9);
  static const boBreak = Color(0xFF4A3AA7);
  static const biBlur = Color(0xFFE66767);
  static const biBreak = Color(0xFFE34948);
  static const nrpra = Color(0xFFC98500);
}

const _vMin = -25.0, _vMax = 45.0;
const _aMin = -0.5, _aMax = 4.5;

class _ZcsbvPainter extends CustomPainter {
  final GAGeometry g;
  final Set<String> layers;
  final bool isDark;
  final Offset? probe;

  _ZcsbvPainter({
    required this.g,
    required this.layers,
    required this.isDark,
    required this.probe,
  });

  static const _padL = 40.0, _padR = 12.0, _padT = 18.0, _padB = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      _padL,
      _padT,
      size.width - _padR,
      size.height - _padB,
    );
    final bg = isDark ? const Color(0xFF1A1A19) : const Color(0xFFFCFCFB);
    final gridC = isDark
        ? Colors.white.withAlpha(14)
        : Colors.black.withAlpha(14);
    final axisC = isDark
        ? Colors.white.withAlpha(46)
        : Colors.black.withAlpha(36);
    final tickC = isDark ? const Color(0xFF898781) : const Color(0xFF73726C);
    final titleC = isDark ? const Color(0xFFC3C2B7) : const Color(0xFF2C2C2A);
    final refC = isDark
        ? Colors.white.withAlpha(18)
        : Colors.black.withAlpha(15);

    double vx(double v) =>
        plot.left + (v - _vMin) / (_vMax - _vMin) * plot.width;
    double ay(double a) =>
        plot.bottom - (a - _aMin) / (_aMax - _aMin) * plot.height;
    Offset p(GAPoint pt) => Offset(vx(pt.v), ay(pt.a));

    // Background
    final bgPaint = Paint()..color = bg;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    canvas.save();
    canvas.clipRect(plot);

    // Grid
    final grid = Paint()
      ..color = gridC
      ..strokeWidth = 0.5;
    for (double v = -20; v <= 40; v += 5) {
      canvas.drawLine(Offset(vx(v), plot.top), Offset(vx(v), plot.bottom), grid);
    }
    for (double a = 0; a <= 4; a += 0.5) {
      canvas.drawLine(Offset(plot.left, ay(a)), Offset(plot.right, ay(a)), grid);
    }

    // Distance / near reference lines
    final ref = Paint()
      ..color = refC
      ..strokeWidth = 1;
    _dashed(canvas, Offset(plot.left, ay(0)), Offset(plot.right, ay(0)), ref);
    _dashed(
      canvas,
      Offset(plot.left, ay(g.accNear)),
      Offset(plot.right, ay(g.accNear)),
      ref,
    );

    // Zone
    if (layers.contains('zone') && g.zone != null) {
      final path = Path()..moveTo(p(g.zone![0]).dx, p(g.zone![0]).dy);
      for (final pt in g.zone!.skip(1)) {
        path.lineTo(p(pt).dx, p(pt).dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = GAColors.demand.withAlpha(isDark ? 26 : 20),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = GAColors.demand.withAlpha(64)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.75,
      );
    }

    // NFV / BI
    if (layers.contains('bi')) {
      _line(canvas, g.biBreak, p, GAColors.biBreak, 2, bg);
      _line(canvas, g.biBlur, p, GAColors.biBlur, 1.5, bg, dashed: true);
    }
    // PFV / BO
    if (layers.contains('bo')) {
      _line(canvas, g.boBreak, p, GAColors.boBreak, 2, bg);
      _line(canvas, g.boBlur, p, GAColors.boBlur, 1.5, bg, dashed: true);
    }

    // Demand line
    if (layers.contains('dem')) {
      final paint = Paint()
        ..color = GAColors.demand
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p(g.demandLine.distance), p(g.demandLine.near), paint);
      _dot(canvas, p(g.demandLine.distance), 5, GAColors.demand, bg);
      _dot(canvas, p(g.demandLine.near), 5, GAColors.demand, bg);
    }

    // Phoria line
    if (layers.contains('ph')) {
      _dashed(
        canvas,
        p(g.phoriaLine.distance),
        p(g.phoriaLine.near),
        Paint()
          ..color = GAColors.phoria
          ..strokeWidth = 1.5,
        dash: 6,
        gap: 4,
      );
      _dot(canvas, p(g.phoriaLine.distance), 4.5, GAColors.phoria, bg);
      _dot(canvas, p(g.phoriaLine.near), 4.5, GAColors.phoria, bg);
    }

    // NRA / PRA
    if (layers.contains('nr') && g.nraA != null && g.praA != null) {
      final x = vx(g.nrPraV);
      final paint = Paint()
        ..color = GAColors.nrpra
        ..strokeWidth = 1.5;
      _dashed(canvas, Offset(x, ay(g.accNear)), Offset(x, ay(g.nraA!)), paint,
          dash: 3, gap: 3);
      _dashed(canvas, Offset(x, ay(g.accNear)), Offset(x, ay(g.praA!)), paint,
          dash: 3, gap: 3);
      _arrow(canvas, Offset(x, ay(g.nraA!)), up: true, color: GAColors.nrpra);
      _arrow(canvas, Offset(x, ay(g.praA!)), up: false, color: GAColors.nrpra);
      _dot(canvas, Offset(x, ay(g.accNear)), 3.5, GAColors.nrpra, bg);
    }

    // Probe crosshair
    if (probe != null && plot.contains(probe!)) {
      final crossC = isDark
          ? Colors.white.withAlpha(120)
          : Colors.black.withAlpha(110);
      final cp = Paint()
        ..color = crossC
        ..strokeWidth = 0.75;
      canvas.drawLine(
        Offset(probe!.dx, plot.top),
        Offset(probe!.dx, plot.bottom),
        cp,
      );
      canvas.drawLine(
        Offset(plot.left, probe!.dy),
        Offset(plot.right, probe!.dy),
        cp,
      );
    }

    canvas.restore();

    // Axes
    final axis = Paint()
      ..color = axisC
      ..strokeWidth = 1;
    canvas.drawLine(Offset(plot.left, ay(0)), Offset(plot.right, ay(0)), axis);
    canvas.drawLine(Offset(vx(0), plot.top), Offset(vx(0), plot.bottom), axis);
    canvas.drawRect(
      plot,
      Paint()
        ..color = isDark ? Colors.white.withAlpha(23) : Colors.black.withAlpha(23)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // Tick labels
    for (double v = -20; v <= 40; v += 10) {
      _text(canvas, '${v.toInt()}', Offset(vx(v), plot.bottom + 4), tickC, 9,
          align: TextAlign.center);
    }
    for (int a = 0; a <= 4; a++) {
      _text(canvas, '${a}D', Offset(plot.left - 5, ay(a.toDouble()) - 5), tickC,
          9,
          align: TextAlign.right);
    }

    // Reference labels
    _text(canvas, '6 m', Offset(plot.left + 3, ay(0) - 12), tickC, 8);
    _text(canvas, '${g.input.nearDistCm.toStringAsFixed(0)} cm',
        Offset(plot.left + 3, ay(g.accNear) - 12), tickC, 8);

    // Axis titles
    _text(canvas, 'Vergence (Δ)  ·  BI ← 0 → BO',
        Offset(plot.center.dx, size.height - 12), titleC, 10,
        align: TextAlign.center, weight: FontWeight.w500);

    // Probe read-out
    if (probe != null && plot.contains(probe!)) {
      final v = _vMin + (probe!.dx - plot.left) / plot.width * (_vMax - _vMin);
      final a = _aMin + (plot.bottom - probe!.dy) / plot.height * (_aMax - _aMin);
      final label =
          '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}Δ · ${a.toStringAsFixed(2)}D';
      _readout(canvas, probe!, label, plot, isDark);
    }
  }

  void _line(Canvas canvas, GALine? line, Offset Function(GAPoint) p,
      Color color, double width, Color dotBg,
      {bool dashed = false}) {
    if (line == null) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    if (dashed) {
      _dashed(canvas, p(line.distance), p(line.near), paint, dash: 5, gap: 4);
    } else {
      canvas.drawLine(p(line.distance), p(line.near), paint);
    }
    _dot(canvas, p(line.distance), dashed ? 3.5 : 4.5, color, dotBg);
    _dot(canvas, p(line.near), dashed ? 3.5 : 4.5, color, dotBg);
  }

  void _dot(Canvas canvas, Offset o, double r, Color fill, Color stroke) {
    canvas.drawCircle(o, r, Paint()..color = fill);
    canvas.drawCircle(
      o,
      r,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint,
      {double dash = 5, double gap = 7}) {
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    double covered = 0;
    while (covered < total) {
      final start = a + dir * covered;
      final end = a + dir * math.min(covered + dash, total);
      canvas.drawLine(start, end, paint);
      covered += dash + gap;
    }
  }

  void _arrow(Canvas canvas, Offset tip, {required bool up, required Color color}) {
    final dy = up ? 1.0 : -1.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy + dy * 3)
      ..lineTo(tip.dx - 5, tip.dy - dy * 5)
      ..lineTo(tip.dx + 5, tip.dy - dy * 5)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _text(Canvas canvas, String s, Offset o, Color color, double size,
      {TextAlign align = TextAlign.left, FontWeight weight = FontWeight.w400}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    var dx = o.dx;
    if (align == TextAlign.center) dx -= tp.width / 2;
    if (align == TextAlign.right) dx -= tp.width;
    tp.paint(canvas, Offset(dx, o.dy));
  }

  void _readout(
      Canvas canvas, Offset at, String text, Rect plot, bool isDark) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    const pad = 6.0;
    var x = at.dx + 12;
    var y = at.dy - tp.height - 12;
    if (x + tp.width + pad * 2 > plot.right) x = at.dx - tp.width - pad * 2 - 12;
    if (y < plot.top) y = at.dy + 12;
    final box = Rect.fromLTWH(
        x, y, tp.width + pad * 2, tp.height + pad);
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(6)),
      Paint()
        ..color = isDark ? const Color(0xFF2C2C2E) : Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(6)),
      Paint()
        ..color = isDark ? Colors.white.withAlpha(40) : Colors.black.withAlpha(30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
    tp.paint(canvas, Offset(x + pad, y + pad / 2));
  }

  @override
  bool shouldRepaint(covariant _ZcsbvPainter old) =>
      old.g != g ||
      old.isDark != isDark ||
      old.probe != probe ||
      !_setEq(old.layers, layers);

  static bool _setEq(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
