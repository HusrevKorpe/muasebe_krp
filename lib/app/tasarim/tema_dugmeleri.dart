import 'package:flutter/material.dart';

import 'olculer.dart';

/// Düğme ailelerinin tema tanımları.
///
/// `Tema`'dan ayrı bir dosyada duruyorlar çünkü altı ayrı düğme türü var ve
/// hepsi aynı ölçü ailesini paylaşıyor: aynı yarıçap, aynı yazı ağırlığı, aynı
/// dokunma yüksekliği. Bir yerde değişen bir ölçü hepsinde değişmeli.
///
/// Ekranlar bu temaları doğrudan çağırmaz — `Dugme` bileşenini kullanır.
abstract final class TemaDugmeleri {
  /// Yazı tipi: düğme metni gövde metninden bir tık kalın, harf aralığı sıfıra
  /// yakın. Türkçe düğme adları uzun ("Bakiyeyi yeniden hesapla"), aralık
  /// açıldığında satır taşıyor.
  static const TextStyle _buyukYazi = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle _kucukYazi = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static FilledButtonThemeData dolu(ColorScheme sema) => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(Olculer.dugmeYuksekligi),
      padding: const EdgeInsets.symmetric(horizontal: Olculer.bosluk24),
      textStyle: _buyukYazi,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: Olculer.koseOrta),
      // Pasif düğme "kapalı" değil "şimdilik olmaz" demeli: zemin kaybolmasın,
      // yalnızca soluklaşsın.
      disabledBackgroundColor: sema.onSurface.withValues(alpha: 0.10),
      disabledForegroundColor: sema.onSurface.withValues(alpha: 0.38),
    ),
  );

  static OutlinedButtonThemeData cerceveli(ColorScheme sema) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(Olculer.kucukDugmeYuksekligi),
          padding: const EdgeInsets.symmetric(horizontal: Olculer.bosluk20),
          textStyle: _kucukYazi,
          foregroundColor: sema.primary,
          side: BorderSide(color: sema.outlineVariant, width: 1.4),
          shape: const RoundedRectangleBorder(borderRadius: Olculer.koseOrta),
        ),
      );

  static TextButtonThemeData sade(ColorScheme sema) => TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: const Size(0, Olculer.kucukDugmeYuksekligi),
      padding: const EdgeInsets.symmetric(
        horizontal: Olculer.bosluk16,
        vertical: Olculer.bosluk8,
      ),
      textStyle: _kucukYazi,
      foregroundColor: sema.primary,
      shape: const RoundedRectangleBorder(borderRadius: Olculer.koseKucuk),
    ),
  );

  static IconButtonThemeData simge(ColorScheme sema) => IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: sema.onSurfaceVariant,
      highlightColor: sema.primary.withValues(alpha: 0.10),
      shape: const RoundedRectangleBorder(borderRadius: Olculer.koseKucuk),
    ),
  );

  static FloatingActionButtonThemeData yuzen(ColorScheme sema) =>
      FloatingActionButtonThemeData(
        backgroundColor: sema.primary,
        foregroundColor: sema.onPrimary,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 4,
        extendedTextStyle: _kucukYazi,
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: Olculer.bosluk20,
        ),
        shape: const RoundedRectangleBorder(borderRadius: Olculer.koseBuyuk),
      );

  static SegmentedButtonThemeData bolumlu(ColorScheme sema) =>
      SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: sema.surfaceContainerLowest,
          foregroundColor: sema.onSurfaceVariant,
          selectedBackgroundColor: sema.primaryContainer,
          selectedForegroundColor: sema.onPrimaryContainer,
          side: BorderSide(color: sema.outlineVariant, width: 1.4),
          textStyle: _kucukYazi,
          padding: const EdgeInsets.symmetric(vertical: Olculer.bosluk12),
          shape: const RoundedRectangleBorder(borderRadius: Olculer.koseOrta),
        ),
      );
}
