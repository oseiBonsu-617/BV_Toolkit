import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import 'auth_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await context.read<AuthService>().signIn(
        email: _email.text,
        password: _password.text,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _error = null;
      _googleLoading = true;
    });
    try {
      await context.read<AuthService>().signInWithGoogle();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
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
                title: 'Welcome back',
                subtitle: 'Sign in to your account',
              ),
              const SizedBox(height: 36),
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
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: authFieldDecoration(
                  context,
                  hint: 'Password',
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: const Color(0xFF8E8E93),
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showPasswordReset,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryOf(context),
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                AuthErrorBox(_error!),
              ],
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: 'Sign In',
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
                prompt: "Don't have an account? ",
                action: 'Create one',
                // Replace so that back from Create account returns to Welcome.
                onTap: () => Navigator.pushReplacement(
                  context,
                  appRoute(const RegisterScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasswordReset() {
    final email = TextEditingController(text: _email.text);
    String? error;
    bool sent = false;
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Reset password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your account email and we will send a secure reset link.',
                  style: TextStyle(fontSize: 15, color: Color(0xFF6E6E73)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  decoration: authFieldDecoration(
                    context,
                    hint: 'Email address',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  AuthErrorBox(error!),
                ],
                if (sent) ...[
                  const SizedBox(height: 12),
                  const AuthSuccessBox('Reset link sent. Check your email.'),
                ],
                const SizedBox(height: 18),
                AuthPrimaryButton(
                  label: 'Send Reset Link',
                  loading: loading,
                  onPressed: () async {
                    setSheetState(() {
                      error = null;
                      sent = false;
                      loading = true;
                    });
                    try {
                      await context
                          .read<AuthService>()
                          .sendPasswordReset(email.text);
                      setSheetState(() => sent = true);
                    } on AuthException catch (e) {
                      setSheetState(() => error = e.message);
                    } finally {
                      setSheetState(() => loading = false);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(email.dispose);
  }
}
