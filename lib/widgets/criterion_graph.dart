import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

class SheardsGraph extends StatelessWidget {
  final double phoria;
  final double compensatingVergence;

  const SheardsGraph({
    super.key,
    required this.phoria,
    required this.compensatingVergence,
  });

  @override
  Widget build(BuildContext context) {
    final demand = phoria.abs();
    final required = demand * 2;
    final pass = compensatingVergence >= required;
    final direction = phoria >= 0 ? 'BI' : 'BO';

    return _GraphShell(
      title: "Sheard's graphical method",
      subtitle:
          'Compensating reserve should reach at least twice the phoria demand.',
      child: CustomPaint(
        painter: _SheardsPainter(
          demand: demand,
          required: required,
          actual: compensatingVergence,
          pass: pass,
          direction: direction,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }
}

class PercivalsGraph extends StatelessWidget {
  final double bo;
  final double bi;

  const PercivalsGraph({super.key, required this.bo, required this.bi});

  @override
  Widget build(BuildContext context) {
    final greater = math.max(bo, bi);
    final lesser = math.min(bo, bi);
    final pass = lesser >= greater / 2;

    return _GraphShell(
      title: "Percival's graphical method",
      subtitle: 'The fixation demand should sit within the middle third.',
      child: CustomPaint(
        painter: _PercivalsPainter(
          bo: bo,
          bi: bi,
          pass: pass,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }
}

class _GraphShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _GraphShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.35,
              color: isDark ? const Color(0xFFB0B0B6) : const Color(0xFF6E6E73),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 126, width: double.infinity, child: child),
        ],
      ),
    );
  }
}

class _SheardsPainter extends CustomPainter {
  final double demand;
  final double required;
  final double actual;
  final bool pass;
  final String direction;
  final bool isDark;

  _SheardsPainter({
    required this.demand,
    required this.required,
    required this.actual,
    required this.pass,
    required this.direction,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fg = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final muted = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73);
    final axis = isDark ? const Color(0xFF636366) : const Color(0xFFC7C7CC);
    final maxValue = math.max(math.max(required, actual), demand) * 1.18;
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    const left = 6.0;
    final right = size.width - 6;
    final width = right - left;
    final y = size.height * 0.5;
    final actualY = y - 22;
    final reqY = y + 22;

    double x(double value) => left + width * (value / safeMax).clamp(0.0, 1.0);

    final axisPaint = Paint()
      ..color = axis
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, y), Offset(right, y), axisPaint);

    final reqPaint = Paint()
      ..color = kWarnText
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, reqY), Offset(x(required), reqY), reqPaint);

    final actualPaint = Paint()
      ..color = pass ? kOkText : kBadText
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(left, actualY),
      Offset(x(actual), actualY),
      actualPaint,
    );

    final demandPaint = Paint()
      ..color = kPrimary
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(x(demand), y - 34),
      Offset(x(demand), y + 34),
      demandPaint,
    );

    final requiredPaint = Paint()
      ..color = kWarnTextDark
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(x(required), y - 36),
      Offset(x(required), y + 36),
      requiredPaint,
    );

    _label(
      canvas,
      Offset(left, actualY - 22),
      'Actual CV ${actual.toStringAsFixed(0)}Δ',
      fg,
    );
    _label(
      canvas,
      Offset(left, reqY + 8),
      'Required ${required.toStringAsFixed(0)}Δ',
      muted,
    );
    _label(
      canvas,
      Offset(x(demand), y - 52),
      'Phoria ${demand.toStringAsFixed(1)}Δ',
      kPrimary,
      center: true,
    );
    _label(
      canvas,
      Offset(x(required), y + 40),
      '2x',
      kWarnTextDark,
      center: true,
    );
    _label(canvas, Offset(right, y - 2), direction, muted, right: true);
  }

  @override
  bool shouldRepaint(covariant _SheardsPainter oldDelegate) =>
      oldDelegate.demand != demand ||
      oldDelegate.required != required ||
      oldDelegate.actual != actual ||
      oldDelegate.pass != pass ||
      oldDelegate.direction != direction ||
      oldDelegate.isDark != isDark;
}

class _PercivalsPainter extends CustomPainter {
  final double bo;
  final double bi;
  final bool pass;
  final bool isDark;

  _PercivalsPainter({
    required this.bo,
    required this.bi,
    required this.pass,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fg = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final muted = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73);
    final axis = isDark ? const Color(0xFF636366) : const Color(0xFFC7C7CC);
    final safeBi = math.max(0.0, bi);
    final safeBo = math.max(0.0, bo);
    final total = math.max(safeBi + safeBo, 1.0);
    const left = 10.0;
    final right = size.width - 10;
    final width = right - left;
    final y = size.height * 0.52;
    final zero = left + width * (safeBi / total);
    final middleLeft = left + width / 3;
    final middleRight = left + 2 * width / 3;

    final axisPaint = Paint()
      ..color = axis
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, y), Offset(right, y), axisPaint);

    final zonePaint = Paint()
      ..color = (pass ? kOkText : kWarnText).withAlpha(isDark ? 70 : 55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(middleLeft, y - 18, middleRight, y + 18),
        const Radius.circular(8),
      ),
      zonePaint,
    );

    final biPaint = Paint()
      ..color = kBadgeBlueText
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final boPaint = Paint()
      ..color = kBadgePurpleText
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, y), Offset(zero, y), biPaint);
    canvas.drawLine(Offset(zero, y), Offset(right, y), boPaint);

    final demandPaint = Paint()
      ..color = pass ? kOkText : kBadText
      ..strokeWidth = 2.4;
    canvas.drawLine(Offset(zero, y - 36), Offset(zero, y + 36), demandPaint);

    _label(
      canvas,
      Offset(left, y - 48),
      'BI ${safeBi.toStringAsFixed(0)}Δ',
      kBadgeBlueText,
    );
    _label(
      canvas,
      Offset(right, y - 48),
      'BO ${safeBo.toStringAsFixed(0)}Δ',
      kBadgePurpleText,
      right: true,
    );
    _label(
      canvas,
      Offset((middleLeft + middleRight) / 2, y + 28),
      'middle third',
      muted,
      center: true,
    );
    _label(
      canvas,
      Offset(zero, y - 60),
      'Demand',
      pass ? kOkText : kBadText,
      center: true,
    );
    _label(
      canvas,
      Offset(size.width / 2, size.height - 16),
      pass ? 'Demand is balanced' : 'Demand is outside the middle third',
      fg,
      center: true,
    );
  }

  @override
  bool shouldRepaint(covariant _PercivalsPainter oldDelegate) =>
      oldDelegate.bo != bo ||
      oldDelegate.bi != bi ||
      oldDelegate.pass != pass ||
      oldDelegate.isDark != isDark;
}

void _label(
  Canvas canvas,
  Offset offset,
  String text,
  Color color, {
  bool center = false,
  bool right = false,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = center
      ? offset.dx - painter.width / 2
      : right
      ? offset.dx - painter.width
      : offset.dx;
  painter.paint(
    canvas,
    Offset(
      dx.clamp(0.0, canvas.getLocalClipBounds().width - painter.width),
      offset.dy,
    ),
  );
}
