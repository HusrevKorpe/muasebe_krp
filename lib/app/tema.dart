import 'package:flutter/material.dart';

/// Uygulama teması. Fidancılık işine uygun yeşil tonlu Material 3 paleti.
abstract final class Tema {
  /// Çekirdek renk — fidan yeşili.
  static const Color _cekirdekRenk = Color(0xFF2E7D32);

  /// Borç ve negatif değerler için.
  static const Color borcRengi = Color(0xFFC62828);

  /// Alacak ve tahsilat için.
  static const Color alacakRengi = Color(0xFF2E7D32);

  static ThemeData acik() => _olustur(Brightness.light);

  static ThemeData koyu() => _olustur(Brightness.dark);

  static ThemeData _olustur(Brightness parlaklik) {
    final renkSemasi = ColorScheme.fromSeed(
      seedColor: _cekirdekRenk,
      brightness: parlaklik,
    );

    return ThemeData(
      colorScheme: renkSemasi,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: renkSemasi.surface,
        foregroundColor: renkSemasi.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
