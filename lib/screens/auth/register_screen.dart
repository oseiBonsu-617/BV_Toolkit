import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _clinic = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  String? _title;
  bool _obscurePw = true;
  bool _obscureCf = true;
  bool _loading = false;
  String? _error;
  String? _success;

  static const _titles = [
    'OD',
    'Optometrist',
    'Ophthalmologist',
    'Resident',
    'Student',
    'Orthoptist',
    'Other',
  ];

  @override
  void dispose() {
    for (final c in [_name, _clinic, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _error = null;
      _success = null;
      _loading = true;
    });
    try {
      final result = await context.read<AuthService>().register(
        email: _email.text,
        password: _password.text,
        displayName: _name.text,
        title: _title,
        clinic: _clinic.text.trim().isEmpty ? null : _clinic.text,
      );
      if (result.needsEmailConfirmation) {
        setState(() {
          _success =
              'Check ${result.email} to verify your account, then sign in.';
        });
      } else if (mounted) {
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Create account'),
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section(isDark, 'Personal', [
                _field(
                  controller: _name,
                  label: 'Full name',
                  hint: 'Dr. Jane Smith',
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _titlePicker(isDark),
                const SizedBox(height: 12),
                _field(
                  controller: _clinic,
                  label: 'Clinic / Practice (optional)',
                  hint: 'City Eye Centre',
                  action: TextInputAction.next,
                ),
              ]),
              const SizedBox(height: 12),
              _section(isDark, 'Account', [
                _field(
                  controller: _email,
                  label: 'Email',
                  hint: 'you@clinic.com',
                  keyboard: TextInputType.emailAddress,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _password,
                  label: 'Password',
                  hint: '••••••••',
                  obscure: _obscurePw,
                  action: TextInputAction.next,
                  suffix: _eyeButton(
                    _obscurePw,
                    () => setState(() => _obscurePw = !_obscurePw),
                  ),
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _confirm,
                  label: 'Confirm password',
                  hint: '••••••••',
                  obscure: _obscureCf,
                  action: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  suffix: _eyeButton(
                    _obscureCf,
                    () => setState(() => _obscureCf = !_obscureCf),
                  ),
                ),
              ]),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _errorBox(_error!),
              ],
              if (_success != null) ...[
                const SizedBox(height: 12),
                _successBox(_success!),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(bool isDark, String heading, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            heading.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _titlePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Title',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _titles.map((t) {
            final selected = _title == t;
            return GestureDetector(
              onTap: () => setState(() => _title = selected ? null : t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? kPrimary
                      : (isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? kPrimary
                        : (isDark
                              ? const Color(0xFF48484A)
                              : const Color(0xFFE5E5EA)),
                    width: 1,
                  ),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: selected ? Colors.white : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboard = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    bool obscure = false,
    Widget? suffix,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          textInputAction: action,
          obscureText: obscure,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
        ),
      ],
    );
  }

  Widget _eyeButton(bool obscure, VoidCallback onTap) => IconButton(
    icon: Icon(
      obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      size: 20,
      color: const Color(0xFF8E8E93),
    ),
    onPressed: onTap,
  );

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kBadBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBadBorder, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: kBadText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(fontSize: 13, color: kBadText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successBox(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kOkBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kOkBorder, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 16, color: kOkText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(fontSize: 13, color: kOkText),
            ),
          ),
        ],
      ),
    );
  }
}
