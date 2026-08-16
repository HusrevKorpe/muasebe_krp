import 'package:flutter/material.dart';

import 'renkler.dart';

/// Paletin Material karşılığı: açık ve koyu [ColorScheme].
///
/// Şemalar `ColorScheme.fromSeed` ile **üretilmiyor**, elle yazılıyor. Tohumdan
/// üretilen şema kremi griye çeviriyor ve kartla zemin arasındaki farkı
/// silikleştiriyordu; paletteki sıcaklık ancak yüzey tonları elle verilince
/// duruyor (bkz. [Renkler]).
abstract final class RenkSemasi {
  static const ColorScheme acik = ColorScheme(
    brightness: Brightness.light,

    primary: Renkler.zeytin,
    onPrimary: Renkler.kagit,
    primaryContainer: Renkler.yaprakSolgun,
    onPrimaryContainer: Renkler.zeytinKoyu,

    secondary: Renkler.sage,
    onSecondary: Renkler.kagit,
    secondaryContainer: Renkler.sageZemin,
    onSecondaryContainer: Renkler.sageKoyu,

    tertiary: Renkler.kiremit,
    onTertiary: Renkler.kagit,
    tertiaryContainer: Renkler.kiremitZemin,
    onTertiaryContainer: Renkler.kiremitKoyu,

    error: Renkler.hata,
    onError: Renkler.kagit,
    errorContainer: Renkler.hataZemin,
    onErrorContainer: Renkler.hataKoyu,

    surface: Renkler.krem,
    onSurface: Renkler.kurum,
    onSurfaceVariant: Renkler.kurumSolgun,
    surfaceContainerLowest: Renkler.kagit,
    surfaceContainerLow: Renkler.kremKoyu,
    surfaceContainer: Renkler.kum,
    surfaceContainerHigh: Renkler.kumKoyu,
    surfaceContainerHighest: Renkler.kumEnKoyu,
    surfaceDim: Renkler.kumKoyu,
    surfaceBright: Renkler.kagit,
    surfaceTint: Renkler.zeytin,

    outline: Renkler.kenar,
    outlineVariant: Renkler.cizgi,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    inverseSurface: Renkler.kurum,
    onInverseSurface: Renkler.krem,
    inversePrimary: Renkler.yaprak,
  );

  static const ColorScheme koyu = ColorScheme(
    brightness: Brightness.dark,

    primary: Renkler.yaprak,
    onPrimary: Renkler.zeytinKoyu,
    primaryContainer: Renkler.zeytinGece,
    onPrimaryContainer: Renkler.yaprakGece,

    secondary: Renkler.sageAcik,
    onSecondary: Renkler.sageKoyu,
    secondaryContainer: Renkler.sageGece,
    onSecondaryContainer: Renkler.sageZemin,

    tertiary: Renkler.kiremitAcik,
    onTertiary: Renkler.kiremitKoyu,
    tertiaryContainer: Renkler.kiremitGece,
    onTertiaryContainer: Renkler.kiremitZemin,

    error: Renkler.hataGeceMetin,
    onError: Renkler.hataGeceKoyu,
    errorContainer: Renkler.hataGeceZemin,
    onErrorContainer: Renkler.hataZemin,

    surface: Renkler.geceZemin,
    onSurface: Renkler.geceMetin,
    onSurfaceVariant: Renkler.geceMetinSolgun,
    surfaceContainerLowest: Renkler.geceEnAlt,
    surfaceContainerLow: Renkler.geceKart,
    surfaceContainer: Renkler.geceKart,
    surfaceContainerHigh: Renkler.geceKartUst,
    surfaceContainerHighest: Renkler.geceKartTepe,
    surfaceDim: Renkler.geceEnAlt,
    surfaceBright: Renkler.geceKartTepe,
    surfaceTint: Renkler.yaprak,

    outline: Renkler.geceKenar,
    outlineVariant: Renkler.geceCizgi,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),

    inverseSurface: Renkler.geceMetin,
    onInverseSurface: Renkler.kurum,
    inversePrimary: Renkler.zeytin,
  );
}
