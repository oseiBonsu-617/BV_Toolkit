import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/patient_service.dart';
import '../../models/patient.dart';
import '../../theme.dart';
import 'patient_form_screen.dart';
import 'patient_detail_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});
  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAdd() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PatientFormScreen()),
  );

  void _openDetail(Patient patient) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PatientDetailScreen(patientId: patient.id)),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = context.watch<PatientService>();
    final list = service.patients;

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by name or MRN…',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: context.read<PatientService>().search,
              )
            : const Text('Patients'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _searching = !_searching);
              if (!_searching) {
                _searchCtrl.clear();
                context.read<PatientService>().search('');
              }
            },
          ),
        ],
        leading: const BackButton(),
      ),
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F2F7),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: kPrimary,
        child: const Icon(Icons.person_add_outlined, color: Colors.white),
      ),
      body: list.isEmpty
          ? _buildEmpty(isDark, service.hasPatients)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 1),
              itemBuilder: (_, i) => _buildRow(list[i], isDark, i, list.length),
            ),
    );
  }

  Widget _buildEmpty(bool isDark, bool hasPatients) {
    final isFiltered = hasPatients;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(isFiltered ? Icons.search_off : Icons.people_outline,
            size: 56, color: const Color(0xFFBCBCC0)),
        const SizedBox(height: 16),
        Text(isFiltered ? 'No patients match your search' : 'No patients yet',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(isFiltered ? 'Try a different name or MRN' : 'Tap + to add your first patient',
            style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
      ]),
    );
  }

  Widget _buildRow(Patient p, bool isDark, int i, int total) {
    final isFirst = i == 0;
    final isLast = i == total - 1;
    return GestureDetector(
      onTap: () => _openDetail(p),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(14) : Radius.zero,
            bottom: isLast ? const Radius.circular(14) : Radius.zero,
          ),
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(
                    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                    width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          _avatar(p),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.fullName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Row(children: [
                if (p.age != null) ...[
                  Text('${p.age} y/o',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                  if (p.gender != null) const Text(' · ',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                ],
                if (p.gender != null) Text(p.gender!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                if (p.mrn != null) ...[
                  const Text(' · ',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                  Text('MRN: ${p.mrn}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                ],
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8E8E93)),
        ]),
      ),
    );
  }

  Widget _avatar(Patient p) => CircleAvatar(
        radius: 22,
        backgroundColor: kPrimary.withAlpha(30),
        child: Text(p.initials,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kPrimary)),
      );
}
