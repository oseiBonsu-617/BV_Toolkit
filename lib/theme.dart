import 'package:flutter/material.dart';

const kPrimary = Color(0xFF1D9E75);
const kPrimaryDark = Color(0xFF158060);

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
    colorSchemeSeed: kPrimary,
    useMaterial3: true,
    scaffoldBackgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF2F2F7),
    cardColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
    dividerColor: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      selectedItemColor: kPrimary,
      unselectedItemColor: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
      selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      type: BottomNavigationBarType.fixed,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelStyle: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6E6E73)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
