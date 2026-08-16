import 'package:flutter/material.dart';

import 'olculer.dart';
import 'renk_semasi.dart';
import 'tema_dugmeleri.dart';

/// Uygulama teması.
///
/// Tasarımın üç kuralı burada kodlanıyor:
///
/// 1. **Zemin krem, kart beyaz.** Liste satırları kâğıt gibi zeminden ayrılıyor;
///    gölge yerine ince kenar kullanılıyor — gölge küçük ekranda bulanık bir
///    gri hâleye dönüşüyor.
/// 2. **Yükseklik yok, kenar var.** `elevation` her yerde 0; ayrım rengin
///    tonuyla ve `outlineVariant` çizgisiyle yapılıyor.
/// 3. **Köşeler tek aileden.** Kart, kutu ve düğme aynı yarıçap ailesini
///    paylaşıyor (bkz. [Olculer]).
///
/// Renkler `ColorScheme.fromSeed` ile üretilmiyor; elle yazılmış iki şema var
/// (bkz. `RenkSemasi`).
abstract final class Tema {
  static ThemeData acik() => _olustur(RenkSemasi.acik);

  static ThemeData koyu() => _olustur(RenkSemasi.koyu);

  static ThemeData _olustur(ColorScheme sema) {
    final temel = ThemeData(colorScheme: sema, useMaterial3: true);

    return temel.copyWith(
      scaffoldBackgroundColor: sema.surface,
      canvasColor: sema.surface,
      textTheme: _metinTemasi(temel.textTheme, sema),
      appBarTheme: _ustCubuk(sema),
      cardTheme: _kart(sema),
      inputDecorationTheme: _metinKutusu(sema),
      filledButtonTheme: TemaDugmeleri.dolu(sema),
      outlinedButtonTheme: TemaDugmeleri.cerceveli(sema),
      textButtonTheme: TemaDugmeleri.sade(sema),
      iconButtonTheme: TemaDugmeleri.simge(sema),
      floatingActionButtonTheme: TemaDugmeleri.yuzen(sema),
      segmentedButtonTheme: TemaDugmeleri.bolumlu(sema),
      navigationBarTheme: _altGezinme(sema),
      tabBarTheme: _sekmeler(sema),
      listTileTheme: _satir(sema),
      dividerTheme: _ayirac(sema),
      chipTheme: _cip(sema),
      dialogTheme: _kutu(sema),
      snackBarTheme: _serit(sema),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: sema.primary,
        circularTrackColor: sema.primary.withValues(alpha: 0.12),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sema.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Olculer.yaricapBuyuk),
          ),
        ),
      ),
    );
  }

  /// Başlıklar sıkı ve kalın, gövde metni rahat.
  ///
  /// Rakamlar bu uygulamanın asıl içeriği: para satırları `titleMedium` ve
  /// üstünde w700 ile basılıyor, gövde metni onların yanında geri çekiliyor.
  static TextTheme _metinTemasi(TextTheme temel, ColorScheme sema) {
    return temel
        .copyWith(
          headlineSmall: temel.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          headlineMedium: temel.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          titleLarge: temel.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: temel.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          titleSmall: temel.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: temel.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          bodyMedium: temel.bodyMedium?.copyWith(height: 1.35),
          bodySmall: temel.bodySmall?.copyWith(height: 1.35),
        )
        .apply(bodyColor: sema.onSurface, displayColor: sema.onSurface);
  }

  static AppBarTheme _ustCubuk(ColorScheme sema) => AppBarTheme(
    centerTitle: false,
    backgroundColor: sema.surface,
    foregroundColor: sema.onSurface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleSpacing: Olculer.sayfaKenari,
    titleTextStyle: TextStyle(
      color: sema.onSurface,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    iconTheme: IconThemeData(color: sema.onSurfaceVariant),
    actionsIconTheme: IconThemeData(color: sema.onSurfaceVariant),
  );

  static CardThemeData _kart(ColorScheme sema) => CardThemeData(
    color: sema.surfaceContainerLowest,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: Olculer.koseBuyuk,
      side: BorderSide(color: sema.outlineVariant),
    ),
  );

  /// Metin kutuları: dolu, kenarlıksız duruyor; odaklanınca ana renkle
  /// çerçeveleniyor. Krem zeminde beyaz kutu, kart mantığının devamı.
  static InputDecorationTheme _metinKutusu(ColorScheme sema) =>
      InputDecorationTheme(
        filled: true,
        fillColor: sema.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Olculer.bosluk16,
          vertical: Olculer.bosluk16,
        ),
        border: OutlineInputBorder(
          borderRadius: Olculer.koseOrta,
          borderSide: BorderSide(color: sema.outlineVariant, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Olculer.koseOrta,
          borderSide: BorderSide(color: sema.outlineVariant, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Olculer.koseOrta,
          borderSide: BorderSide(color: sema.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Olculer.koseOrta,
          borderSide: BorderSide(color: sema.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Olculer.koseOrta,
          borderSide: BorderSide(color: sema.error, width: 1.8),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: Olculer.koseOrta,
          borderSide: BorderSide(color: sema.outlineVariant.withValues(alpha: 0.6)),
        ),
        prefixIconColor: sema.onSurfaceVariant,
        suffixIconColor: sema.onSurfaceVariant,
        labelStyle: TextStyle(color: sema.onSurfaceVariant),
        floatingLabelStyle: TextStyle(
          color: sema.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: sema.onSurfaceVariant.withValues(alpha: 0.7)),
        helperStyle: TextStyle(color: sema.onSurfaceVariant, fontSize: 12),
        helperMaxLines: 3,
        errorMaxLines: 2,
      );

  static NavigationBarThemeData _altGezinme(ColorScheme sema) =>
      NavigationBarThemeData(
        height: Olculer.gezinmeYuksekligi,
        backgroundColor: sema.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: sema.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: Olculer.koseTam,
        ),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (durumlar) => TextStyle(
            fontSize: 12,
            fontWeight: durumlar.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: durumlar.contains(WidgetState.selected)
                ? sema.onSurface
                : sema.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (durumlar) => IconThemeData(
            size: 24,
            color: durumlar.contains(WidgetState.selected)
                ? sema.onPrimaryContainer
                : sema.onSurfaceVariant,
          ),
        ),
      );

  static TabBarThemeData _sekmeler(ColorScheme sema) => TabBarThemeData(
    labelColor: sema.onSurface,
    unselectedLabelColor: sema.onSurfaceVariant,
    labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    unselectedLabelStyle: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
    indicatorSize: TabBarIndicatorSize.label,
    dividerColor: sema.outlineVariant,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: sema.primary, width: 3),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
    ),
    overlayColor: WidgetStatePropertyAll<Color>(
      sema.primary.withValues(alpha: 0.06),
    ),
  );

  static ListTileThemeData _satir(ColorScheme sema) => ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: Olculer.sayfaKenari,
      vertical: Olculer.bosluk8,
    ),
    iconColor: sema.onSurfaceVariant,
    titleTextStyle: TextStyle(
      color: sema.onSurface,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    subtitleTextStyle: TextStyle(color: sema.onSurfaceVariant, fontSize: 13),
    shape: const RoundedRectangleBorder(borderRadius: Olculer.koseOrta),
  );

  static DividerThemeData _ayirac(ColorScheme sema) => DividerThemeData(
    color: sema.outlineVariant,
    thickness: 1,
    space: 1,
  );

  static ChipThemeData _cip(ColorScheme sema) => ChipThemeData(
    backgroundColor: sema.surfaceContainerLowest,
    selectedColor: sema.primaryContainer,
    checkmarkColor: sema.onPrimaryContainer,
    surfaceTintColor: Colors.transparent,
    side: BorderSide(color: sema.outlineVariant, width: 1.4),
    labelStyle: TextStyle(
      color: sema.onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    secondaryLabelStyle: TextStyle(
      color: sema.onPrimaryContainer,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: Olculer.bosluk12,
      vertical: Olculer.bosluk8,
    ),
    shape: const RoundedRectangleBorder(borderRadius: Olculer.koseTam),
  );

  static DialogThemeData _kutu(ColorScheme sema) => DialogThemeData(
    backgroundColor: sema.surfaceContainerLowest,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(borderRadius: Olculer.koseBuyuk),
    titleTextStyle: TextStyle(
      color: sema.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    contentTextStyle: TextStyle(
      color: sema.onSurfaceVariant,
      fontSize: 15,
      height: 1.4,
    ),
  );

  static SnackBarThemeData _serit(ColorScheme sema) => SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: sema.inverseSurface,
    contentTextStyle: TextStyle(
      color: sema.onInverseSurface,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    elevation: 0,
    insetPadding: const EdgeInsets.all(Olculer.sayfaKenari),
    shape: const RoundedRectangleBorder(borderRadius: Olculer.koseOrta),
  );
}
