import 'package:flutter/material.dart';
import '../config/tools.dart';

/// Grid of every available Home shortcut; selected ones are filled dark.
class ShortcutGrid extends StatelessWidget {
  const ShortcutGrid({
    super.key,
    required this.selected,
    required this.onToggle,
    this.crossAxisCount = 2,
  });

  final List<String> selected;
  final ValueChanged<String> onToggle;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.builder(
      itemCount: kShortcuts.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: crossAxisCount >= 3 ? 0.95 : 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, i) {
        final s = kShortcuts[i];
        final isSelected = selected.contains(s.id);
        final fg = isSelected
            ? (isDark ? const Color(0xFFEAF8F2) : Colors.white)
            : (isDark ? Colors.white : const Color(0xFF303538));
        return Material(
          key: Key('shortcut-tile-${s.id}'),
          color: isSelected
              ? const Color(0xFF303538)
              : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onToggle(s.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF303538)
                      : (isDark
                            ? const Color(0xFF38383A)
                            : const Color(0xFFE5E5EA)),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(s.icon, size: 28, color: fg),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      s.name,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
