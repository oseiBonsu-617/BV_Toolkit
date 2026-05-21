import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/patient.dart';
import '../../services/patient_service.dart';
import '../../theme.dart';

class PatientFormScreen extends StatefulWidget {
  final Patient? patient; // null = create, non-null = edit
  const PatientFormScreen({super.key, this.patient});
  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _mrn = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _complaint = TextEditingController();
  final _notes = TextEditingController();

  DateTime? _dob;
  String? _gender;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.patient != null;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    if (p != null) {
      _firstName.text = p.firstName;
      _lastName.text = p.lastName;
      _mrn.text = p.mrn ?? '';
      _phone.text = p.phone ?? '';
      _email.text = p.email ?? '';
      _complaint.text = p.chiefComplaint ?? '';
      _notes.text = p.notes ?? '';
      _dob = p.dateOfBirth;
      _gender = p.gender;
    }
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _mrn, _phone, _email, _complaint, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(DateTime.now().year - 30),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
      setState(() => _error = 'First and last name are required.');
      return;
    }
    setState(() { _error = null; _loading = true; });
    try {
      final service = context.read<PatientService>();
      if (_isEdit) {
        await service.update(widget.patient!.copyWith(
          firstName: _firstName.text,
          lastName: _lastName.text,
          dateOfBirth: _dob,
          clearDob: _dob == null,
          gender: _gender,
          mrn: _mrn.text,
          phone: _phone.text,
          email: _email.text,
          chiefComplaint: _complaint.text,
          notes: _notes.text,
        ));
      } else {
        await service.add(
          firstName: _firstName.text,
          lastName: _lastName.text,
          dateOfBirth: _dob,
          gender: _gender,
          mrn: _mrn.text,
          phone: _phone.text,
          email: _email.text,
          chiefComplaint: _complaint.text,
          notes: _notes.text,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit patient' : 'New patient'),
        leading: const CloseButton(),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))
                : Text(_isEdit ? 'Save' : 'Add',
                    style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(isDark, 'Identity', [
            _row(Row(children: [
              Expanded(child: _lf('First name *', _firstName, hint: 'Jane', action: TextInputAction.next)),
              const SizedBox(width: 12),
              Expanded(child: _lf('Last name *', _lastName, hint: 'Smith', action: TextInputAction.next)),
            ])),
            _divider(isDark),
            _row(_genderPicker(isDark)),
            _divider(isDark),
            _row(_dobPicker(isDark)),
            _divider(isDark),
            _row(_lf('MRN', _mrn, hint: 'Optional', action: TextInputAction.next)),
          ]),
          const SizedBox(height: 12),
          _section(isDark, 'Contact', [
            _row(_lf('Phone', _phone, hint: '—', keyboard: TextInputType.phone,
                action: TextInputAction.next)),
            _divider(isDark),
            _row(_lf('Email', _email, hint: '—', keyboard: TextInputType.emailAddress,
                action: TextInputAction.next)),
          ]),
          const SizedBox(height: 12),
          _section(isDark, 'Clinical', [
            _row(_lf('Chief complaint', _complaint, hint: 'e.g. Headaches with near work',
                action: TextInputAction.next)),
            _divider(isDark),
            _row(_lf('Notes', _notes, hint: 'Additional clinical notes',
                action: TextInputAction.done, maxLines: 4)),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kBadBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBadBorder, width: 0.5),
              ),
              child: Text(_error!, style: const TextStyle(fontSize: 13, color: kBadText)),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(bool isDark, String title, List<Widget> rows) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(title.toUpperCase(), style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.6,
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
        )),
      ),
      Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA), width: 0.5),
        ),
        child: Column(children: rows),
      ),
    ]);
  }

  Widget _row(Widget child) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: child);

  Widget _divider(bool isDark) => Divider(
    height: 0.5, thickness: 0.5, indent: 14,
    color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
  );

  Widget _lf(String label, TextEditingController ctrl, {
    String? hint,
    TextInputType keyboard = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    int maxLines = 1,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
          color: Color(0xFF8E8E93))),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        textInputAction: action,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
      ),
    ]);
  }

  Widget _genderPicker(bool isDark) {
    const options = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Gender', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
          color: Color(0xFF8E8E93))),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8,
        children: options.map((g) {
          final sel = _gender == g;
          return GestureDetector(
            onTap: () => setState(() => _gender = sel ? null : g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? kPrimary : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: sel ? kPrimary : (isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA))),
              ),
              child: Text(g, style: TextStyle(fontSize: 13, color: sel ? Colors.white : null)),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _dobPicker(bool isDark) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Date of birth', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93))),
          const SizedBox(height: 4),
          Text(
            _dob != null ? DateFormat('d MMM yyyy').format(_dob!) : 'Not set',
            style: TextStyle(fontSize: 14,
              color: _dob != null ? null : const Color(0xFF8E8E93)),
          ),
        ]),
      ),
      Row(children: [
        if (_dob != null)
          TextButton(
            onPressed: () => setState(() => _dob = null),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('Clear', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
          ),
        TextButton(
          onPressed: _pickDob,
          child: Text(_dob != null ? 'Change' : 'Set', style: const TextStyle(color: kPrimary)),
        ),
      ]),
    ]);
  }
}
