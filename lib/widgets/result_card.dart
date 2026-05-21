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
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 10, letterSpacing: 0.5, color: labelColor)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: textColor)),
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(note!, style: TextStyle(fontSize: 11, height: 1.5, color: noteColor)),
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
          Text(text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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

  factory Pill.normal(String text) =>
      Pill(text, bg: kOkBg, fg: kOkText);
  factory Pill.warn(String text) =>
      Pill(text, bg: kWarnBg, fg: kWarnTextDark);
  factory Pill.fail(String text) =>
      Pill(text, bg: kBadBg, fg: kBadTextDark);
  factory Pill.info(String text) =>
      Pill(text, bg: kBadgeBlueBg, fg: kBadgeBlueText);
  factory Pill.purple(String text) =>
      Pill(text, bg: kBadgePurpleBg, fg: kBadgePurpleText);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: fg)),
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
                          width: 0.5)
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6E6E73),
            )),
        const SizedBox(height: 3),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: InputDecoration(hintText: placeholder, hintStyle: const TextStyle(fontSize: 13)),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
