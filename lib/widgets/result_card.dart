import 'package:flutter/material.dart';
import '../theme.dart';

enum ResultType { ok, bad, warn, info }

class ResultCard extends StatelessWidget {
  final ResultType type;
  final String label;
  final String value;
  final String? note;

  const ResultCard({
    super.key,
    required this.type,
    required this.label,
    required this.value,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, border, textColor, noteColor) = switch (type) {
      ResultType.ok => (kOkBg, kOkBorder, kOkText, kOkText),
      ResultType.bad => (kBadBg, kBadBorder, kBadTextDark, kBadText),
      ResultType.warn => (kWarnBg, kWarnBorder, kWarnTextDark, kWarnText),
      ResultType.info => (
        Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF2F2F7),
        Theme.of(context).dividerColor,
        Theme.of(context).textTheme.bodyLarge!.color!,
        Theme.of(context).textTheme.bodySmall!.color!,
      ),
    };

    final labelColor = switch (type) {
      ResultType.ok => kOkText.withAlpha(180),
      ResultType.bad => kBadText.withAlpha(200),
      ResultType.warn => kWarnText.withAlpha(200),
      ResultType.info => Theme.of(context).textTheme.bodySmall!.color!,
    };

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.5,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              note!,
              style: TextStyle(fontSize: 11, height: 1.5, color: noteColor),
            ),
          ],
        ],
      ),
    );
  }
}

class InfoBox extends StatelessWidget {
  final Widget child;
  const InfoBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 11,
          height: 1.55,
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
        ),
        child: child,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.6,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF8E8E93)
              : const Color(0xFF6E6E73),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  const AppCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class CardTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  const CardTitle({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kPrimary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const Pill(this.text, {super.key, required this.bg, required this.fg});

  factory Pill.normal(String text) => Pill(text, bg: kOkBg, fg: kOkText);
  factory Pill.warn(String text) => Pill(text, bg: kWarnBg, fg: kWarnTextDark);
  factory Pill.fail(String text) => Pill(text, bg: kBadBg, fg: kBadTextDark);
  factory Pill.info(String text) =>
      Pill(text, bg: kBadgeBlueBg, fg: kBadgeBlueText);
  factory Pill.purple(String text) =>
      Pill(text, bg: kBadgePurpleBg, fg: kBadgePurpleText);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class SegmentedControl extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const SegmentedControl({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isOn = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isOn
                      ? (isDark ? const Color(0xFF3A3A3C) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: isOn
                      ? Border.all(
                          color: isDark
                              ? const Color(0xFF48484A)
                              : const Color(0xFFE5E5EA),
                          width: 0.5,
                        )
                      : null,
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isOn ? FontWeight.w500 : FontWeight.normal,
                    color: isOn
                        ? kPrimary
                        : (isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6E6E73)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class NumField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final double step;

  const NumField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final text = controller.text.trim();
        final parsed = double.tryParse(text);
        final isInvalid =
            text.isNotEmpty && (parsed == null || !parsed.isFinite);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6E6E73),
              ),
            ),
            const SizedBox(height: 3),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF636366)
                      : const Color(0xFFC7C7CC),
                ),
                errorText: isInvalid ? 'Enter a valid number' : null,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        );
      },
    );
  }
}

class PhoriaField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String direction;
  final ValueChanged<String> onDirectionChanged;
  final String? placeholder;
  final double step;

  const PhoriaField({
    super.key,
    required this.label,
    required this.controller,
    required this.direction,
    required this.onDirectionChanged,
    this.placeholder,
    this.step = 1,
  });

  static const directions = ['Exo', 'Eso', 'Ortho'];

  static double? signedValue(
    TextEditingController controller,
    String direction,
  ) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || !value.isFinite) return null;
    if (direction == 'Ortho') return 0;
    final magnitude = value.abs();
    return direction == 'Eso' ? -magnitude : magnitude;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: NumField(
            label: label,
            controller: controller,
            placeholder: placeholder,
            step: step,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 96,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Direction',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6E6E73),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: direction,
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    dropdownColor: isDark
                        ? const Color(0xFF2C2C2E)
                        : Colors.white,
                    items: directions
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              d,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) onDirectionChanged(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Animation helpers ──────────────────────────────────────────────────────

class FadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const FadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
  });

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _opacity = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curved);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

// ─── Skeleton / Shimmer ─────────────────────────────────────────────────────

class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final shine = isDark ? const Color(0xFF48484A) : Colors.white;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: const Alignment(-2, 0),
            end: const Alignment(2, 0),
            colors: [base, shine, base],
            stops: [
              (_ctrl.value - 0.35).clamp(0.0, 1.0),
              _ctrl.value.clamp(0.0, 1.0),
              (_ctrl.value + 0.35).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: const Color(0xFFBCBCC0)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
