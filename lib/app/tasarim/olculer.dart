import 'package:flutter/material.dart';

/// Boşluk, yarıçap ve yükseklik ölçüleri.
///
/// Ekranlarda çıplak sayı yazılmaz. Bir kartın 12, yanındakinin 14 yarıçapta
/// olması tek tek bakınca fark edilmiyor ama liste boyunca göz onu düzensizlik
/// olarak okuyor; ölçüler tek yerden geldiğinde bu kendiliğinden çözülüyor.
///
/// Boşluklar 4'ün katları: 4 · 8 · 12 · 16 · 20 · 24 · 32.
abstract final class Olculer {
  // ─── Boşluklar ───────────────────────────────────────────────────────────
  static const double bosluk4 = 4;
  static const double bosluk8 = 8;
  static const double bosluk12 = 12;
  static const double bosluk16 = 16;
  static const double bosluk20 = 20;
  static const double bosluk24 = 24;
  static const double bosluk32 = 32;

  /// Ekran kenarlarının standart iç boşluğu.
  static const double sayfaKenari = 16;

  /// Yüzen düğmenin listenin son satırını örtmemesi için gereken alt boşluk.
  static const double yuzenDugmeBoslugu = 96;

  // ─── Yarıçaplar ──────────────────────────────────────────────────────────
  /// Rozet, çip, küçük etiket.
  static const double yaricapKucuk = 10;

  /// Metin kutusu, düğme.
  static const double yaricapOrta = 14;

  /// Kart, kutu, bölüm.
  static const double yaricapBuyuk = 20;

  /// Tam yuvarlak — avatar ve hap biçimli rozetler.
  static const double yaricapTam = 999;

  static const BorderRadius koseKucuk = BorderRadius.all(
    Radius.circular(yaricapKucuk),
  );
  static const BorderRadius koseOrta = BorderRadius.all(
    Radius.circular(yaricapOrta),
  );
  static const BorderRadius koseBuyuk = BorderRadius.all(
    Radius.circular(yaricapBuyuk),
  );
  static const BorderRadius koseTam = BorderRadius.all(
    Radius.circular(yaricapTam),
  );

  // ─── Yükseklikler ────────────────────────────────────────────────────────
  /// Birincil düğmenin yüksekliği. Parmakla, tarlada, eldivenle basılıyor.
  static const double dugmeYuksekligi = 52;

  /// İkincil ve sade düğmelerin yüksekliği.
  static const double kucukDugmeYuksekligi = 44;

  /// Alt gezinme çubuğunun yüksekliği.
  static const double gezinmeYuksekligi = 68;
}
