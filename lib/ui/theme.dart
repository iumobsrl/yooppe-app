import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colori presi dalle variabili CSS della web app.
class K {
  static const indigo = Color(0xFF2E3192);
  static const navy = Color(0xFF000479);
  static const peri = Color(0xFF6368FC);
  static const lav = Color(0xFFF0F0FF);
  static const green = Color(0xFF18A12B);
  static const greenD = Color(0xFF118A22);
  static const pink = Color(0xFFED1E79);
  static const berry = Color(0xFFC2185B);
  static const berryD = Color(0xFF5C0A2E);
  static const wine = Color(0xFFA0144F);
  static const red = Color(0xFFE30613);
  static const gold = Color(0xFFE9A825);
  static const ink = Color(0xFF222222);
  static const ink2 = Color(0xFF444444);
  static const muted = Color(0xFF777777);
  static const line = Color(0xFFE3E3E8);
  static const soft = Color(0xFFF6F6F8);
  static const card = Color(0xFFF6F6F6);
  static const bubbleHer = Color(0xFFEFEFEF);
  static const pendBg = Color(0xFF7F2B2B);
  static const online = Color(0xFF19C22B);
  static const placeholder = Color(0xFFE6E6EA);
  static const shadow = Color(0x1F1E1E50);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: K.indigo, primary: K.indigo, secondary: K.pink),
    scaffoldBackgroundColor: Colors.white,
    splashFactory: InkRipple.splashFactory,
  );
  return base.copyWith(
    textTheme: GoogleFonts.montserratTextTheme(base.textTheme).apply(bodyColor: K.ink, displayColor: K.ink),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCFCFD6))),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFCFCFD6))),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: K.peri, width: 2)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: Color(0xF0222233)),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? const Color(0xFF2D7FF9) : null),
    ),
  );
}
