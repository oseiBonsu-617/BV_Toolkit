import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Brand: clinical blue on white.
const kPrimary = Color(0xFF1F5FAF);
const kPrimaryDark = Color(0xFF174A8A);
/// Lighter brand blue for text and icons sitting on dark surfaces.
const kPrimaryOnDark = Color(0xFF5B8FD6);

/// The brand blue to use for links and icons on the current background:
/// [kPrimaryOnDark] in dark mode, [kPrimary] otherwise.
Color primaryOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? kPrimaryOnDark : kPrimary;

// Result colours
const kOkBg = Color(0xFFE1F5EE);
const kOkBorder = Color(0xFF5DCAA5);
const kOkText = Color(0xFF085041);

const kBadBg = Color(0xFFFCEBEB);
const kBadBorder = Color(0xFFF09595);
const kBadText = Color(0xFFA32D2D);
const kBadTextDark = Color(0xFF791F1F);

const kWarnBg = Color(0xFFFAEEDA);
const kWarnBorder = Color(0xFFFAC775);
const kWarnText = Color(0xFF854F0B);
const kWarnTextDark = Color(0xFF633806);

// Badge colours
const kBadgeBlueBg = Color(0xFFE6F1FB);
const kBadgeBlueText = Color(0xFF0C447C);
const kBadgePurpleBg = Color(0xFFEEEDFE);
const kBadgePurpleText = Color(0xFF3C3489);

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? kPrimaryOnDark : kPrimary,
      onPrimary: Colors.white,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F2F7),
    cardColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
    dividerColor: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: isDark ? Colors.black26 : Colors.black12,
      elevation: 8,
      indicatorColor: kPrimary.withAlpha(30),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: kPrimary, size: 22);
        }
        return IconThemeData(
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73),
          size: 22,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kPrimary);
        }
        return const TextStyle(fontSize: 10, color: Color(0xFF8E8E93));
      }),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBadText, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBadText, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelStyle: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73)),
      errorStyle: const TextStyle(fontSize: 10, color: kBadText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        elevation: 0,
      ),
    ),
  );
}

// ─── Page route with slide + fade transition ────────────────────────────────
// On iOS a CupertinoPageRoute is used instead so the edge back-swipe works.
// [settings] lets the shell recognise a route on a tab's stack.

Route<T> appRoute<T>(Widget page, {RouteSettings? settings}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPageRoute<T>(builder: (_) => page, settings: settings);
  }
  return _slideFadeRoute<T>(page, settings);
}

Route<T> _slideFadeRoute<T>(Widget page, RouteSettings? settings) => PageRouteBuilder<T>(
  settings: settings,
  pageBuilder: (context, animation, secondaryAnimation) => page,
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
        child: child,
      ),
    );
  },
  transitionDuration: const Duration(milliseconds: 260),
  reverseTransitionDuration: const Duration(milliseconds: 220),
);

// ─── Styled SnackBar helper ─────────────────────────────────────────────────

void showAppSnackBar(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontSize: 13)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? kBadText : const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      duration: const Duration(seconds: 2),
    ));
}
