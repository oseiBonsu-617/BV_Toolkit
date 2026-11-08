import 'package:flutter/material.dart';
import '../../theme.dart';

// Shared building blocks for the Welcome, Sign In and Create account screens:
// clean white (or dark) pages with rounded "pill" fields and buttons.

const _kPillRadius = 28.0;
const _kGreyLight = Color(0xFF6E6E73);
const _kGreyDark = Color(0xFF8E8E93);

bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

/// Page background for the auth screens: pure white in light mode, the app's
/// dark scaffold colour in dark mode.
Color authBackgroundOf(BuildContext context) =>
    _isDark(context) ? const Color(0xFF0F0F0F) : Colors.white;

/// Thin outline colour used by pill fields, chips and the Google button.
Color authOutlineOf(BuildContext context) =>
    _isDark(context) ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6);

/// Secondary (grey) text colour for subtitles and section labels.
Color authSecondaryTextOf(BuildContext context) =>
    _isDark(context) ? _kGreyDark : _kGreyLight;

/// Transparent app bar with an iOS-style back arrow, shown only when there is
/// somewhere to go back to. No title — the screen's [AuthHeader] carries it.
PreferredSizeWidget authAppBar(BuildContext context) {
  final canPop = Navigator.of(context).canPop();
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: false,
    leading: canPop
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
          )
        : null,
  );
}

/// The single pill-shaped field decoration shared by both auth screens.
InputDecoration authFieldDecoration(
  BuildContext context, {
  required String hint,
  Widget? suffix,
}) {
  OutlineInputBorder pill(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(_kPillRadius),
    borderSide: BorderSide(color: color, width: width),
  );

  final outline = authOutlineOf(context);
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 15, color: authSecondaryTextOf(context)),
    filled: false,
    fillColor: Colors.transparent,
    contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
    border: pill(outline, 1),
    enabledBorder: pill(outline, 1),
    focusedBorder: pill(primaryOf(context), 1.5),
    errorBorder: pill(kBadText, 1),
    focusedErrorBorder: pill(kBadText, 1.5),
    suffixIcon: suffix == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(right: 6),
            child: suffix,
          ),
  );
}

/// Centred screen title with a grey subtitle underneath.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: authSecondaryTextOf(context)),
        ),
      ],
    );
  }
}

/// Full-width filled pill button in the brand blue.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          // Keep the fill solid while loading so the spinner reads clearly;
          // fade it when the button is disabled for another reason.
          disabledBackgroundColor: loading
              ? kPrimary
              : kPrimary.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kPillRadius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Full-width outlined pill button for Google sign-in.
class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final textColor = _isDark(context) ? Colors.white : const Color(0xFF1C1C1E);
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: authOutlineOf(context), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kPillRadius),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        icon: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryOf(context),
                ),
              )
            : Icon(Icons.g_mobiledata, size: 30, color: primaryOf(context)),
        label: const Text('Continue with Google'),
      ),
    );
  }
}

/// "or" between two thin lines.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final color = _isDark(context)
        ? const Color(0xFF38383A)
        : const Color(0xFFE5E5EA);
    return Row(
      children: [
        Expanded(child: Divider(height: 1, color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: TextStyle(fontSize: 15, color: authSecondaryTextOf(context)),
          ),
        ),
        Expanded(child: Divider(height: 1, color: color)),
      ],
    );
  }
}

/// Footer line such as "Don't have an account? Create one".
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: prompt,
                style: TextStyle(color: authSecondaryTextOf(context)),
              ),
              TextSpan(
                text: action,
                style: TextStyle(
                  color: primaryOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

/// Small grey section label, e.g. "About you".
class AuthSectionLabel extends StatelessWidget {
  const AuthSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: authSecondaryTextOf(context),
        ),
      ),
    );
  }
}

/// Red error message box (unchanged styling from the previous auth screens).
class AuthErrorBox extends StatelessWidget {
  const AuthErrorBox(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => _MessageBox(
    message: message,
    icon: Icons.error_outline,
    background: kBadBg,
    border: kBadBorder,
    foreground: kBadText,
  );
}

/// Green success message box (unchanged styling from the previous auth screens).
class AuthSuccessBox extends StatelessWidget {
  const AuthSuccessBox(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => _MessageBox(
    message: message,
    icon: Icons.mark_email_read_outlined,
    background: kOkBg,
    border: kOkBorder,
    foreground: kOkText,
  );
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.message,
    required this.icon,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final String message;
  final IconData icon;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 15, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
