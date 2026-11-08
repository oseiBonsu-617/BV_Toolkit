import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import 'auth_widgets.dart';
import 'login_screen.dart';

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
  bool _googleLoading = false;
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _error = null;
      _success = null;
      _googleLoading = true;
    });
    try {
      await context.read<AuthService>().signInWithGoogle(
        displayName: _name.text.trim().isEmpty ? null : _name.text,
        title: _title,
        clinic: _clinic.text.trim().isEmpty ? null : _clinic.text,
      );
      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _googleLoading;

    return Scaffold(
      backgroundColor: authBackgroundOf(context),
      appBar: authAppBar(context),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(
                title: "Let's get started!",
                subtitle: 'Create your new account',
              ),
              const SizedBox(height: 32),
              const AuthSectionLabel('About you'),
              TextField(
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: authFieldDecoration(context, hint: 'Full name'),
              ),
              const SizedBox(height: 14),
              _titlePicker(),
              const SizedBox(height: 14),
              TextField(
                controller: _clinic,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: authFieldDecoration(
                  context,
                  hint: 'Clinic / practice (optional)',
                ),
              ),
              const SizedBox(height: 26),
              const AuthSectionLabel('Account'),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: authFieldDecoration(
                  context,
                  hint: 'Email address',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                obscureText: _obscurePw,
                textInputAction: TextInputAction.next,
                decoration: authFieldDecoration(
                  context,
                  hint: 'Password',
                  suffix: _eyeButton(
                    _obscurePw,
                    () => setState(() => _obscurePw = !_obscurePw),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirm,
                obscureText: _obscureCf,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: authFieldDecoration(
                  context,
                  hint: 'Confirm password',
                  suffix: _eyeButton(
                    _obscureCf,
                    () => setState(() => _obscureCf = !_obscureCf),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                AuthErrorBox(_error!),
              ],
              if (_success != null) ...[
                const SizedBox(height: 16),
                AuthSuccessBox(_success!),
              ],
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'Create account',
                loading: _loading,
                onPressed: busy ? null : _submit,
              ),
              const SizedBox(height: 22),
              const AuthOrDivider(),
              const SizedBox(height: 22),
              AuthGoogleButton(
                loading: _googleLoading,
                onPressed: busy ? null : _signInWithGoogle,
              ),
              const SizedBox(height: 20),
              AuthFooterLink(
                key: const Key('auth-footer-link'),
                prompt: 'Already have an account? ',
                action: 'Sign in',
                // Replace so that back from Sign In returns to Welcome.
                onTap: () => Navigator.pushReplacement(
                  context,
                  appRoute(const LoginScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titlePicker() {
    final outline = authOutlineOf(context);
    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _titles.map((t) {
        final selected = _title == t;
        return Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: () => setState(() => _title = selected ? null : t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? kPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? kPrimary : outline,
                  width: 1,
                ),
              ),
              child: Text(
                t,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : null,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            'Title',
            style: TextStyle(
              fontSize: 13,
              color: authSecondaryTextOf(context),
            ),
          ),
        ),
        chips,
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
}
