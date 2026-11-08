import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/tools.dart';
import '../services/patient_service.dart';
import '../services/preferences_service.dart';
import '../theme.dart';
import '../widgets/home_shortcuts_picker.dart';
import '../widgets/profile_avatar_button.dart';
import '../widgets/result_card.dart';
import 'patients/patient_form_screen.dart';
import 'shell/shell_scope.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0xFFE5E5EA);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BV Toolkit'),
            Text(
              'Clinical suite',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6E6E73),
              ),
            ),
          ],
        ),
        actions: const [ProfileAvatarButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _sectionHeader(
            context,
            'Your tools',
            TextButton(
              key: const Key('home-edit-shortcuts'),
              onPressed: () => _edit(context),
              child: const Text('Edit'),
            ),
          ),
          _shortcutGrid(context),
          const SizedBox(height: 16),
          _sectionHeader(
            context,
            'Recent patients',
            TextButton(
              key: const Key('home-see-all'),
              onPressed: () =>
                  ShellScope.of(context).openTabAtRoot(ShellTab.patients),
              child: const Text('See all'),
            ),
          ),
          _recentPatients(context, isDark, borderColor),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardTitle(
                  icon: Icons.table_chart_outlined,
                  text: "Morgan's norms",
                ),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.5),
                  },
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: borderColor,
                      width: 0.5,
                    ),
                    bottom: BorderSide(color: borderColor, width: 0.5),
                  ),
                  children: [
                    _headerRow(['Test', 'Dist', 'Near'], context),
                    _dataRow(
                      ['Phoria', '1Δ exo', '3Δ exo'],
                      context,
                      highlight: true,
                    ),
                    _dataRow(['BI break', '7Δ', '21Δ'], context),
                    _dataRow(['BO break', '19Δ', '21Δ'], context),
                    _dataRow(
                      ['NPC break', '≤ 5 cm', ''],
                      context,
                      highlight: true,
                      colSpan2: true,
                    ),
                    _dataRow(
                      ['Acc. amp.', 'Hofstetter', ''],
                      context,
                      colSpan2: true,
                    ),
                    _dataRow([
                      'Acc. facility',
                      'OD/OS ≥13',
                      'Bin ≥11',
                    ], context),
                    _dataRow(['MEM lag', '+0.25D', '+0.75D'], context),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final prefs = context.read<PreferencesService>();
    final r = await showHomeShortcutsPicker(
      context,
      initial: prefs.homeShortcuts,
    );
    if (r != null) await prefs.setHomeShortcuts(r);
  }

  Widget _sectionHeader(BuildContext context, String title, Widget action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          action,
        ],
      ),
    );
  }

  Widget _shortcutGrid(BuildContext context) {
    final ids = context.watch<PreferencesService>().homeShortcuts;
    final defs = [
      for (final id in ids)
        for (final s in kShortcuts)
          if (s.id == id) s,
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.5,
      children: [for (final s in defs) _tile(context, s)],
    );
  }

  Widget _recentPatients(BuildContext context, bool isDark, Color borderColor) {
    final recent = context.watch<PatientService>().recent;
    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: FilledButton(
          key: const Key('home-add-first-patient'),
          onPressed: () => Navigator.of(
            context,
            rootNavigator: true,
          ).push(appRoute(const PatientFormScreen())),
          child: const Text('Add your first patient'),
        ),
      );
    }
    final muted = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border.all(color: borderColor, width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (final p in recent)
            ListTile(
              key: Key('home-patient-${p.id}'),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: kPrimary.withValues(alpha: 0.12),
                child: Text(
                  p.initials,
                  style: TextStyle(fontSize: 12, color: primaryOf(context)),
                ),
              ),
              title: Text(p.fullName, style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                [
                  if (p.age != null) '${p.age} yrs',
                  if (p.mrn != null && p.mrn!.isNotEmpty) 'MRN ${p.mrn}',
                ].join(' · '),
                style: TextStyle(fontSize: 11, color: muted),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => ShellScope.of(context).openPatient(p.id),
            ),
        ],
      ),
    );
  }

  TableRow _headerRow(List<String> cells, BuildContext context) {
    return TableRow(
      children: cells
          .map(
            (c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              child: Text(
                c,
                style: TextStyle(
                  fontSize: 10,
                  textBaseline: TextBaseline.alphabetic,
                  letterSpacing: 0.4,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6E6E73),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  TableRow _dataRow(
    List<String> cells,
    BuildContext context, {
    bool highlight = false,
    bool colSpan2 = false,
  }) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: highlight ? FontWeight.w500 : FontWeight.normal,
      color: highlight ? primaryOf(context) : null,
    );
    if (colSpan2) {
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            child: Text(cells[0], style: const TextStyle(fontSize: 11)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            child: Text(cells[1], style: style),
          ),
          const SizedBox.shrink(),
        ],
      );
    }
    return TableRow(
      children: cells
          .map(
            (c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              child: Text(c, style: style),
            ),
          )
          .toList(),
    );
  }

  Widget _tile(BuildContext context, ShortcutDef s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      key: Key('home-shortcut-${s.id}'),
      onTap: () => ShellScope.of(context).openShortcut(s.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(s.icon, size: 20, color: primaryOf(context)),
            const SizedBox(height: 6),
            Text(
              s.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
