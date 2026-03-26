// lib/core/theme/app_theme.dart
// CU Branded Theme — Navy Blue + Gold

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Brand Colours ─────────────────────────────────────────
  static const Color cuNavy     = Color(0xFF0A2342);
  static const Color cuNavyLight= Color(0xFF1A3C6E);
  static const Color cuGold     = Color(0xFFD4AF37);
  static const Color cuGoldLight= Color(0xFFF0CE5E);
  static const Color navGreen   = Color(0xFF00C896);
  static const Color errorRed   = Color(0xFFE53935);
  static const Color warningAmber= Color(0xFFFFB300);

  // ── Light surfaces ────────────────────────────────────────
  static const Color lightBg      = Color(0xFFF4F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard    = Color(0xFFFFFFFF);
  static const Color lightText    = Color(0xFF0D1B2A);
  static const Color lightSubText = Color(0xFF6B7A8D);
  static const Color lightBorder  = Color(0xFFE2E8F0);

  // ── Dark surfaces ─────────────────────────────────────────
  static const Color darkBg      = Color(0xFF070E1A);
  static const Color darkSurface = Color(0xFF0F1C2E);
  static const Color darkCard    = Color(0xFF162035);
  static const Color darkText    = Color(0xFFE8EDF5);
  static const Color darkSubText = Color(0xFF7A8BA0);
  static const Color darkBorder  = Color(0xFF1E3050);

  // ── Voice states ──────────────────────────────────────────
  static const Color voiceIdle      = cuNavy;
  static const Color voiceListening = Color(0xFFE53935);
  static const Color voiceSpeaking  = navGreen;
  static const Color voiceProcessing= cuGold;

  // ── Text theme helper ─────────────────────────────────────
  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
    displayLarge:  GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: primary),
    displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: primary),
    headlineLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: primary),
    headlineMedium:GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
    headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
    titleLarge:    GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
    titleMedium:   GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: primary),
    titleSmall:    GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
    bodyLarge:     GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
    bodyMedium:    GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: primary),
    bodySmall:     GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
    labelLarge:    GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
    labelMedium:   GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
    labelSmall:    GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: secondary),
  );

  // ── Light Theme ───────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: cuNavy, onPrimary: Colors.white,
      secondary: cuGold, onSecondary: Colors.white,
      error: errorRed, onError: Colors.white,
      surface: lightSurface, onSurface: lightText,
    ),
    scaffoldBackgroundColor: lightBg,
    textTheme: _textTheme(lightText, lightSubText),
    appBarTheme: AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: lightText,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700, color: lightText),
    ),
    // ✅ Changed to CardThemeData and added const to BorderSide
    cardTheme: CardThemeData(
      color: lightCard, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: lightBorder),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cuNavy, foregroundColor: Colors.white,
        elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: lightBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: lightBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: cuNavy, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: lightSubText),
    ),
    dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
  );

  // ── Dark Theme ────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: cuGold, onPrimary: cuNavy,
      secondary: cuGoldLight, onSecondary: cuNavy,
      error: errorRed, onError: Colors.white,
      surface: darkSurface, onSurface: darkText,
    ),
    scaffoldBackgroundColor: darkBg,
    textTheme: _textTheme(darkText, darkSubText),
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkText,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700, color: darkText),
    ),
    // ✅ Changed to CardThemeData and added const to BorderSide
    cardTheme: CardThemeData(
      color: darkCard, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cuGold, foregroundColor: cuNavy,
        elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: darkCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: darkBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: cuGold, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: darkSubText),
    ),
    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
  );
}