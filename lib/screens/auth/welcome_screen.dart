import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// First screen for signed-out users: a white panel with the app mark over a
/// brand-blue panel holding the Sign In / Create account buttons.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.openSignInOnStart = false});

  /// Push the Sign In screen once after the first frame, so onboarding's
  /// "Log In" lands on Sign In with Welcome underneath.
  final bool openSignInOnStart;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _tagline = 'Binocular vision assessment, made simple';

  @override
  void initState() {
    super.initState();
    if (widget.openSignInOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openSignIn();
      });
    }
  }

  void _openSignIn() => Navigator.push(context, appRoute(const LoginScreen()));

  void _openCreateAccount() =>
      Navigator.push(context, appRoute(const RegisterScreen()));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        // The blue shows around the top panel's rounded bottom edge.
        backgroundColor: kPrimary,
        body: Column(
          children: [
            Expanded(child: _TopPanel(isDark: isDark)),
            ConstrainedBox(
              // ~45% on tall phones; shrinks to its content on short ones so
              // the top panel keeps room for the mark.
              constraints: BoxConstraints(minHeight: media.size.height * 0.45),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  28,
                  24,
                  media.padding.bottom + 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      _tagline,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _PillButton(
                      key: const Key('welcome-sign-in'),
                      label: 'Sign In',
                      filled: true,
                      onPressed: _openSignIn,
                    ),
                    const SizedBox(height: 16),
                    _PillButton(
                      key: const Key('welcome-create-account'),
                      label: 'Create account',
                      filled: false,
                      onPressed: _openCreateAccount,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopPanel extends StatelessWidget {
  const _TopPanel({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(48),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.remove_red_eye_outlined,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'BV Toolkit',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 20),
              // The illustration scales down to whatever height is left.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: _Illustration(isDark: isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon-only illustration echoing onboarding's hero: an eye in a soft blue
/// circle with a small chart badge.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const size = 200.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? kPrimaryOnDark : kPrimary).withValues(
                alpha: isDark ? 0.16 : 0.10,
              ),
            ),
            child: Icon(
              Icons.visibility_outlined,
              size: 96,
              color: isDark ? kPrimaryOnDark : kPrimary,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 16,
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.stacked_line_chart,
                color: kPrimary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    super.key,
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );
    const textStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: filled
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: kPrimary,
                minimumSize: const Size.fromHeight(54),
                elevation: 0,
                shape: shape,
                textStyle: textStyle,
              ),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                minimumSize: const Size.fromHeight(54),
                shape: shape,
                textStyle: textStyle,
              ),
              child: Text(label),
            ),
    );
  }
}
