import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/tools.dart';
import '../data/clinical_pearls.dart';
import '../data/home_feed.dart';
import '../data/reference_data.dart';
import '../services/auth_service.dart';
import '../services/patient_service.dart';
import '../services/preferences_service.dart';
import '../services/session_service.dart';
import '../theme.dart';
import '../widgets/home_shortcuts_picker.dart';
import '../widgets/profile_avatar_button.dart';
import '../widgets/result_card.dart';
import 'patients/patient_form_screen.dart';
import 'shell/shell_scope.dart';

typedef WeekSummary = ({int sessions, int patients});

/// Line height of a tool tile's label, as a multiple of its font size.
const _labelHeight = 1.25;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.now, this.weekSummary});

  /// The clock. Defaults to [DateTime.now]; tests fix it.
  final DateTime Function()? now;

  /// Counts the sessions since a time. Defaults to
  /// [SessionService.weekSummary]; tests pass their own.
  final Future<WeekSummary> Function(DateTime since)? weekSummary;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  SessionService? _sessions;
  Future<WeekSummary>? _summary;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Home can sit in the background across hours or days: on return, redo
  /// the greeting, date and picks (by rebuilding) and this week's count.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reloadSummary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sessions = Provider.of<SessionService?>(context, listen: false);
    if (!identical(sessions, _sessions)) {
      _sessions?.removeListener(_reloadSummary);
      _sessions = sessions;
      _sessions?.addListener(_reloadSummary);
      _summary = null;
    }
    _summary ??= _loadSummary();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessions?.removeListener(_reloadSummary);
    super.dispose();
  }

  Future<WeekSummary>? _loadSummary() {
    final load = widget.weekSummary ?? _sessions?.weekSummary;
    return load?.call(weekStart(_now()));
  }

  void _reloadSummary() {
    if (!mounted) return;
    setState(() {
      _summary = _loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0xFFE5E5EA);
    final now = _now();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [ProfileAvatarButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        children: [
          _greeting(context, now),
          const SizedBox(height: 16),
          _PearlCard(pearl: pearlFor(now)),
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
          _ConditionCard(entry: conditionFor(now)),
          _NormCard(entry: normFor(now)),
        ],
      ),
    );
  }

  Widget _greeting(BuildContext context, DateTime now) {
    final name = firstNameOf(
      context.watch<AuthService?>()?.currentUser?.displayName ?? '',
    );
    final greeting = greetingFor(now);
    final muted = _muted(context);
    final mutedStyle = TextStyle(fontSize: 15, color: muted);
    return Padding(
      key: const Key('home-greeting'),
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? greeting : '$greeting, $name',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(DateFormat('EEEE, d MMMM').format(now), style: mutedStyle),
          const SizedBox(height: 2),
          FutureBuilder<WeekSummary>(
            future: _summary,
            builder: (context, snap) {
              final s =
                  snap.connectionState == ConnectionState.done && snap.hasData
                  ? snap.data!
                  : null;
              // Empty while loading (or if the count failed); an empty Text
              // still takes a line, so nothing jumps when it arrives.
              return Text(
                s == null
                    ? ''
                    : weekSummaryText(
                        sessions: s.sessions,
                        patients: s.patients,
                      ),
                key: const Key('home-week-summary'),
                style: mutedStyle,
              );
            },
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
    // Room for the padding, icon and two label lines at the current text
    // size: about 94 pt at the default size.
    final labelLine = MediaQuery.textScalerOf(context).scale(16) * _labelHeight;
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 12 + 20 + 6 + 2 * labelLine + 12 + 4,
      ),
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
    final muted = _muted(context);
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
                  style: TextStyle(fontSize: 14, color: primaryOf(context)),
                ),
              ),
              title: Text(p.fullName, style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                [
                  if (p.age != null) '${p.age} yrs',
                  if (p.mrn != null && p.mrn!.isNotEmpty) 'MRN ${p.mrn}',
                ].join(' · '),
                style: TextStyle(fontSize: 13, color: muted),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => ShellScope.of(context).openPatient(p.id),
            ),
        ],
      ),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                height: _labelHeight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _muted(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF8E8E93)
    : const Color(0xFF6E6E73);

/// A small grey heading above a Home card's title.
class _CardLabel extends StatelessWidget {
  const _CardLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: _muted(context),
    ),
  );
}

/// A Reference-style bullet line.
class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: kPrimary.withAlpha(180),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PearlCard extends StatelessWidget {
  const _PearlCard({required this.pearl});
  final ClinicalPearl pearl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = primaryOf(context);
    return Container(
      key: const Key('home-pearl'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: isDark ? .18 : .08),
        border: Border.all(color: kPrimary.withValues(alpha: .3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 20, color: primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Clinical pearl of the day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(pearl.text, style: const TextStyle(fontSize: 16, height: 1.4)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('home-pearl-learn-more'),
              style: TextButton.styleFrom(
                foregroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 0),
              ),
              onPressed: () =>
                  ShellScope.of(context).openReference(pearl.refTitle),
              child: const Text('Learn more'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({required this.entry});
  final ReferenceEntry entry;

  @override
  Widget build(BuildContext context) {
    final bullets = entry.bullets ?? const <String>[];
    return AppCard(
      key: const Key('home-condition'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel('Condition of the week'),
          const SizedBox(height: 4),
          Text(
            entry.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [for (final t in entry.tags.take(3)) Pill.info(t)],
            ),
          ],
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final b in bullets.take(3)) _Bullet(b),
          ],
          if (entry.management != null) ...[
            const SizedBox(height: 8),
            const Text(
              'First-line management',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              entry.management!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('home-condition-read-more'),
              style: TextButton.styleFrom(
                foregroundColor: primaryOf(context),
                padding: const EdgeInsets.symmetric(horizontal: 0),
              ),
              onPressed: () =>
                  ShellScope.of(context).openReference(entry.title),
              child: const Text('Read more'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NormCard extends StatelessWidget {
  const _NormCard({required this.entry});
  final ReferenceEntry entry;

  @override
  Widget build(BuildContext context) {
    final bullets = entry.bullets ?? const <String>[];
    return AppCard(
      key: const Key('home-norm'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel('Norm spotlight'),
          const SizedBox(height: 4),
          Text(
            entry.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              bullets.first,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: primaryOf(context),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            entry.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, height: 1.4, color: _muted(context)),
          ),
          if (bullets.length > 1) ...[
            const SizedBox(height: 8),
            for (final b in bullets.skip(1).take(2)) _Bullet(b),
          ],
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('home-see-all-norms'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryOf(context),
            ),
            onPressed: () => _showMorgansNorms(context),
            child: const Text('See all norms'),
          ),
        ],
      ),
    );
  }

  void _showMorgansNorms(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Morgan's norms",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              MorgansNormsTable(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Morgan's norms at distance and near (formerly inline on Home).
class MorgansNormsTable extends StatelessWidget {
  const MorgansNormsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0xFFE5E5EA);
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: borderColor, width: 0.5),
        bottom: BorderSide(color: borderColor, width: 0.5),
      ),
      children: [
        _headerRow(['Test', 'Dist', 'Near'], context),
        _dataRow(['Phoria', '1Δ exo', '3Δ exo'], context, highlight: true),
        _dataRow(['BI break', '7Δ', '21Δ'], context),
        _dataRow(['BO break', '19Δ', '21Δ'], context),
        _dataRow(
          ['NPC break', '≤ 5 cm', ''],
          context,
          highlight: true,
          colSpan2: true,
        ),
        _dataRow(['Acc. amp.', 'Hofstetter', ''], context, colSpan2: true),
        _dataRow(['Acc. facility', 'OD/OS ≥13', 'Bin ≥11'], context),
        _dataRow(['MEM lag', '+0.25D', '+0.75D'], context),
      ],
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
                  fontSize: 12,
                  textBaseline: TextBaseline.alphabetic,
                  letterSpacing: 0.4,
                  color: _muted(context),
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
      fontSize: 13,
      fontWeight: highlight ? FontWeight.w500 : FontWeight.normal,
      color: highlight ? primaryOf(context) : null,
    );
    if (colSpan2) {
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            child: Text(cells[0], style: const TextStyle(fontSize: 13)),
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
}
