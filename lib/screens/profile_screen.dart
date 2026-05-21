import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: const CloseButton(),
      ),
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F2F7),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAvatar(user),
          const SizedBox(height: 24),
          _buildInfoSection(context, user, isDark),
          const SizedBox(height: 12),
          _buildActionsSection(context, isDark),
          const SizedBox(height: 12),
          _buildSignOut(context),
        ],
      ),
    );
  }

  Widget _buildAvatar(AppUser user) {
    return Column(children: [
      CircleAvatar(
        radius: 42,
        backgroundColor: kPrimary,
        child: Text(user.initials,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      const SizedBox(height: 12),
      Text(user.credential,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text(user.email,
          style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          textAlign: TextAlign.center),
      if (user.clinic != null && user.clinic!.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(user.clinic!,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
            textAlign: TextAlign.center),
      ],
    ]);
  }

  Widget _buildInfoSection(BuildContext context, AppUser user, bool isDark) {
    return _card(isDark, [
      _row(context, isDark, 'Full name', user.displayName),
      _divider(isDark),
      _row(context, isDark, 'Title', user.title?.isNotEmpty == true ? user.title! : '—'),
      _divider(isDark),
      _row(context, isDark, 'Clinic', user.clinic?.isNotEmpty == true ? user.clinic! : '—'),
      _divider(isDark),
      _row(context, isDark, 'Email', user.email),
    ]);
  }

  Widget _buildActionsSection(BuildContext context, bool isDark) {
    return _card(isDark, [
      _actionRow(
        context,
        icon: Icons.edit_outlined,
        label: 'Edit profile',
        onTap: () => _showEditProfile(context),
      ),
      _divider(isDark),
      _actionRow(
        context,
        icon: Icons.lock_outline,
        label: 'Change password',
        onTap: () => _showChangePassword(context),
      ),
    ]);
  }

  Widget _buildSignOut(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout, size: 18, color: kBadText),
        label: const Text('Sign Out', style: TextStyle(color: kBadText)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kBadBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => _confirmSignOut(context),
      ),
    );
  }

  Widget _card(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA), width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _row(BuildContext context, bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
          )),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  Widget _actionRow(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 18, color: kPrimary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8E8E93)),
        ]),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: 16,
      color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
    );
  }

  void _showEditProfile(BuildContext context) {
    final auth = context.read<AuthService>();
    final user = auth.currentUser!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: auth,
        child: _EditProfileSheet(user: user),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final auth = context.read<AuthService>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: auth,
        child: const _ChangePasswordSheet(),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final auth = context.read<AuthService>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              auth.signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: kBadText)),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Profile Sheet ───────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final AppUser user;
  const _EditProfileSheet({required this.user});
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _clinic;
  String? _title;
  bool _loading = false;
  String? _error;

  static const _titles = ['OD','Optometrist','Ophthalmologist','Resident','Student','Orthoptist','Other'];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.displayName);
    _clinic = TextEditingController(text: widget.user.clinic ?? '');
    _title = widget.user.title?.isNotEmpty == true ? widget.user.title : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _clinic.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _error = null; _loading = true; });
    try {
      await context.read<AuthService>().updateProfile(
        displayName: _name.text,
        title: _title,
        clinic: _clinic.text.trim().isEmpty ? null : _clinic.text,
      );
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _sheetHandle(),
        const Text('Edit profile', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        _lf('Full name', TextField(controller: _name,
            decoration: const InputDecoration(hintText: 'Dr. Jane Smith'))),
        const SizedBox(height: 12),
        _lf('Clinic (optional)', TextField(controller: _clinic,
            decoration: const InputDecoration(hintText: 'City Eye Centre'))),
        const SizedBox(height: 12),
        Text('Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73))),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _titles.map((t) {
            final sel = _title == t;
            return GestureDetector(
              onTap: () => setState(() => _title = sel ? null : t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? kPrimary : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sel ? kPrimary : (isDark ? const Color(0xFF48484A) : const Color(0xFFE5E5EA))),
                ),
                child: Text(t, style: TextStyle(
                  fontSize: 13, color: sel ? Colors.white : null)),
              ),
            );
          }).toList(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(fontSize: 12, color: kBadText)),
        ],
        const SizedBox(height: 20),
        SizedBox(height: 48,
          child: ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save changes'),
          )),
      ]),
    );
  }

  Widget _lf(String label, Widget field) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      field,
    ]);
  }
}

// ─── Change Password Sheet ────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_next.text != _confirm.text) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }
    setState(() { _error = null; _success = null; _loading = true; });
    try {
      await context.read<AuthService>().changePassword(
        current: _current.text,
        newPassword: _next.text,
      );
      setState(() => _success = 'Password updated successfully.');
      _current.clear(); _next.clear(); _confirm.clear();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _sheetHandle(),
        const Text('Change password', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        _pwField('Current password', _current, TextInputAction.next),
        const SizedBox(height: 12),
        _pwField('New password', _next, TextInputAction.next),
        const SizedBox(height: 12),
        _pwField('Confirm new password', _confirm, TextInputAction.done, onSubmit: (_) => _save()),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(fontSize: 12, color: kBadText)),
        ],
        if (_success != null) ...[
          const SizedBox(height: 10),
          Text(_success!, style: const TextStyle(fontSize: 12, color: kOkText)),
        ],
        const SizedBox(height: 20),
        SizedBox(height: 48,
          child: ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Update password'),
          )),
      ]),
    );
  }

  Widget _pwField(String label, TextEditingController ctrl, TextInputAction action,
      {void Function(String)? onSubmit}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        obscureText: true,
        textInputAction: action,
        onSubmitted: onSubmit,
        decoration: const InputDecoration(hintText: '••••••••'),
      ),
    ]);
  }
}

Widget _sheetHandle() {
  return Center(
    child: Container(
      width: 36, height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFD1D1D6),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
