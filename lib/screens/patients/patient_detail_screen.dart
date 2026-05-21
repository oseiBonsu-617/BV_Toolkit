import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/patient.dart';
import '../../models/test_session.dart';
import '../assessment/assessment_screen.dart';
import '../../services/patient_service.dart';
import '../../services/session_service.dart';
import '../../theme.dart';
import '../../widgets/result_card.dart';
import 'patient_form_screen.dart';
import 'session_record_screen.dart';
import 'session_detail_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});
  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late Future<List<TestSession>> _sessionsFuture;
  bool _sessionsInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sessionsInit) {
      _sessionsInit = true;
      _sessionsFuture = context.read<SessionService>().forPatient(widget.patientId);
    }
  }

  void _reload() {
    setState(() {
      _sessionsFuture = context.read<SessionService>().forPatient(widget.patientId);
    });
  }

  void _newSession() {
    Navigator.push(
      context,
      appRoute(SessionRecordScreen(patientId: widget.patientId)),
    ).then((_) => _reload());
  }

  void _showSessionOptions() {
    final patient = context.read<PatientService>().getById(widget.patientId);
    if (patient == null) return;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            _sheetTile(ctx,
              icon: Icons.track_changes_outlined,
              title: 'Clinical assessment',
              subtitle: 'Guide which tests to run based on symptoms & cover test',
              onTap: () { Navigator.pop(ctx); _startAssessment(patient); },
            ),
            const SizedBox(height: 4),
            _sheetTile(ctx,
              icon: Icons.edit_note_outlined,
              title: 'Direct entry',
              subtitle: 'Open session form with all test sections',
              onTap: () { Navigator.pop(ctx); _newSession(); },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _sheetTile(BuildContext ctx, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: kPrimary.withAlpha(20), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: kPrimary),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 18),
    );
  }

  void _startAssessment(Patient patient) {
    Navigator.push(
      context,
      appRoute(AssessmentScreen(patient: patient)),
    ).then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<PatientService>().getById(widget.patientId);
    if (patient == null) {
      return const Scaffold(body: Center(child: Text('Patient not found.')));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(patient.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              appRoute(PatientFormScreen(patient: patient)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kBadText),
            onPressed: () => _confirmDelete(context, patient),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSessionOptions,
        icon: const Icon(Icons.add),
        label: const Text('New session'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(patient),
          const SizedBox(height: 20),
          _buildDemographics(patient, isDark),
          const SizedBox(height: 12),
          if (_hasContact(patient)) ...[
            _buildContact(patient, isDark),
            const SizedBox(height: 12),
          ],
          if (_hasClinical(patient)) ...[
            _buildClinical(patient, isDark),
            const SizedBox(height: 12),
          ],
          _buildSessions(isDark),
          const SizedBox(height: 12),
          _buildMeta(patient, isDark),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  // ─── Sessions section ──────────────────────────────────────────────────────

  Widget _buildSessions(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text('SESSIONS', style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.6,
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
        )),
      ),
      FutureBuilder<List<TestSession>>(
        future: _sessionsFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return _buildSessionSkeleton(isDark);
          }
          final sessions = snap.data ?? [];
          if (sessions.isEmpty) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: _cardDecor(isDark),
              child: Text(
                'No sessions recorded yet. Tap + New session to start.',
                style: TextStyle(fontSize: 13,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73)),
              ),
            );
          }
          return Container(
            decoration: _cardDecor(isDark),
            child: Column(
              children: sessions.asMap().entries.map((e) {
                return _sessionRow(e.value, isDark, e.key == sessions.length - 1, sessions);
              }).toList(),
            ),
          );
        },
      ),
    ]);
  }

  Widget _buildSessionSkeleton(bool isDark) {
    return Container(
      decoration: _cardDecor(isDark),
      child: Column(
        children: List.generate(3, (i) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: i < 2 ? Border(bottom: BorderSide(
                color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                width: 0.5,
              )) : null,
            ),
            child: Row(children: [
              SkeletonBox(width: 36, height: 36, radius: 18),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SkeletonBox(width: 110, height: 13),
                const SizedBox(height: 6),
                SkeletonBox(width: 160, height: 11),
              ])),
            ]),
          );
        }),
      ),
    );
  }

  Widget _sessionRow(TestSession s, bool isDark, bool isLast, List<TestSession> all) {
    final sectionCount = [
      s.hasSection('ph_'),
      s.hasSection('npc_'),
      s.hasSection('bi_') || s.hasSection('bo_'),
      s.hasSection('sh_') || s.hasSection('pc_'),
      s.hasSection('dx_'),
    ].where((v) => v).length;

    return Dismissible(
      key: ValueKey(s.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete session?'),
          content: Text('Remove the session from ${DateFormat('d MMM yyyy').format(s.date)}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: kBadText)),
            ),
          ],
        ),
      ),
      onDismissed: (_) async {
        await context.read<SessionService>().delete(s);
        _reload();
        if (mounted) showAppSnackBar(context, 'Session removed');
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: kBadBg,
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(14))
              : BorderRadius.zero,
        ),
        child: const Icon(Icons.delete_outline, color: kBadText, size: 22),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.push(
          context,
          appRoute(SessionDetailScreen(session: s)),
        ).then((_) => _reload()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: isLast ? null : Border(bottom: BorderSide(
              color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
              width: 0.5,
            )),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: kPrimary.withAlpha(25), shape: BoxShape.circle),
              child: const Icon(Icons.assignment_outlined, size: 18, color: kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateFormat('d MMM yyyy').format(s.date),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                s.visitNote?.isNotEmpty == true
                    ? s.visitNote!
                    : '$sectionCount test section${sectionCount == 1 ? '' : 's'} recorded',
                style: TextStyle(fontSize: 12,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ])),
            Icon(Icons.chevron_right, size: 18,
                color: isDark ? const Color(0xFF48484A) : const Color(0xFFCECED2)),
          ]),
        ),
      ),
    );
  }

  BoxDecoration _cardDecor(bool isDark) => BoxDecoration(
    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
      width: 0.5,
    ),
  );

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(Patient p) {
    return Column(children: [
      CircleAvatar(
        radius: 40,
        backgroundColor: kPrimary.withAlpha(30),
        child: Text(p.initials,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: kPrimary)),
      ),
      const SizedBox(height: 12),
      Text(p.fullName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (p.age != null) _chip('${p.age} y/o'),
        if (p.age != null && p.gender != null) const SizedBox(width: 6),
        if (p.gender != null) _chip(p.gender!),
        if (p.mrn != null) ...[const SizedBox(width: 6), _chip('MRN: ${p.mrn}')],
      ]),
    ]);
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: kPrimary.withAlpha(25),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(text,
        style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w500)),
  );

  // ─── Info sections ─────────────────────────────────────────────────────────

  Widget _buildDemographics(Patient p, bool isDark) {
    return _card(isDark, 'Demographics', [
      if (p.dateOfBirth != null) ...[
        _infoRow(isDark, 'Date of birth', DateFormat('d MMM yyyy').format(p.dateOfBirth!)),
        _divider(isDark),
      ],
      if (p.gender != null) ...[
        _infoRow(isDark, 'Gender', p.gender!),
        _divider(isDark),
      ],
      if (p.mrn != null) ...[
        _infoRow(isDark, 'MRN', p.mrn!),
        _divider(isDark),
      ],
      _infoRow(isDark, 'Patient since', DateFormat('d MMM yyyy').format(p.createdAt)),
    ]);
  }

  Widget _buildContact(Patient p, bool isDark) {
    return _card(isDark, 'Contact', [
      if (p.phone != null) ...[
        _infoRow(isDark, 'Phone', p.phone!),
        if (p.email != null) _divider(isDark),
      ],
      if (p.email != null) _infoRow(isDark, 'Email', p.email!),
    ]);
  }

  Widget _buildClinical(Patient p, bool isDark) {
    return _card(isDark, 'Clinical', [
      if (p.chiefComplaint != null) ...[
        _infoRow(isDark, 'Chief complaint', p.chiefComplaint!, multiLine: true),
        if (p.notes != null) _divider(isDark),
      ],
      if (p.notes != null) _infoRow(isDark, 'Notes', p.notes!, multiLine: true),
    ]);
  }

  Widget _buildMeta(Patient p, bool isDark) {
    final fmt = DateFormat('d MMM yyyy, h:mm a');
    return _card(isDark, 'Record', [
      _infoRow(isDark, 'Created', fmt.format(p.createdAt)),
      _divider(isDark),
      _infoRow(isDark, 'Updated', fmt.format(p.updatedAt)),
    ]);
  }

  Widget _card(bool isDark, String heading, List<Widget> rows) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(heading.toUpperCase(), style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.6,
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
        )),
      ),
      Container(
        decoration: _cardDecor(isDark),
        child: Column(children: rows),
      ),
    ]);
  }

  Widget _infoRow(bool isDark, String label, String value, {bool multiLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: multiLine
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
              )),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14, height: 1.5)),
            ])
          : Row(children: [
              SizedBox(
                width: 110,
                child: Text(label, style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
                )),
              ),
              Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
            ]),
    );
  }

  Widget _divider(bool isDark) => Divider(
    height: 0.5, thickness: 0.5, indent: 16,
    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
  );

  bool _hasContact(Patient p) => p.phone != null || p.email != null;
  bool _hasClinical(Patient p) => p.chiefComplaint != null || p.notes != null;

  void _confirmDelete(BuildContext context, Patient p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete patient?'),
        content: Text(
            'This will permanently remove ${p.fullName} and all their sessions. Cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<PatientService>().delete(p.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: kBadText)),
          ),
        ],
      ),
    );
  }
}
