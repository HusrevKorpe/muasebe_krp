import 'package:flutter/material.dart';

/// Uygulamanın renk paleti: **Toprak Yeşili + Krem**.
///
/// Ham renkler burada, Material'ın beklediği [ColorScheme] karşılıkları
/// `renk_semasi.dart` içinde durur. Ekranlar bu sınıftan yalnızca *anlam taşıyan*
/// renkleri okur ([borc], [alacak] ve zeminleri); geri kalan her şey temadan
/// gelir — bir ekranda `Color(0xFF...)` görünüyorsa orası kural ihlalidir.
///
/// Palet iki eksende kuruldu: yeşil işin kendisi (fidan), krem/kum kâğıdın
/// yerini tutuyor (defter). Kiremit yalnızca vurgu — uyarı değil, dikkat çeken
/// ama alarm vermeyen ikinci ses.
abstract final class Renkler {
  // ─── Yeşiller ────────────────────────────────────────────────────────────
  static const Color zeytinKoyu = Color(0xFF1E4028);
  static const Color zeytin = Color(0xFF2F5D3A);
  static const Color zeytinAcik = Color(0xFF4C7F58);
  static const Color yaprak = Color(0xFF8FC79A);
  static const Color yaprakSolgun = Color(0xFFD5E7D6);
  static const Color zeytinGece = Color(0xFF244B31);
  static const Color yaprakGece = Color(0xFFC8EACC);

  // ─── Toprak / vurgu ──────────────────────────────────────────────────────
  static const Color kiremit = Color(0xFFC2703D);
  static const Color kiremitAcik = Color(0xFFE9A178);
  static const Color kiremitZemin = Color(0xFFF6DFCE);
  static const Color kiremitGece = Color(0xFF6A3A1D);
  static const Color kiremitKoyu = Color(0xFF4A2411);

  // ─── Nötrler — açık tema ─────────────────────────────────────────────────
  /// Ekranın zemini. Beyaz değil: kart beyazı zeminden ayrılabilsin diye.
  static const Color krem = Color(0xFFFBF8F3);
  static const Color kagit = Color(0xFFFFFFFF);
  static const Color kremKoyu = Color(0xFFF7F3EB);
  static const Color kum = Color(0xFFF1ECE1);
  static const Color kumKoyu = Color(0xFFE9E3D6);
  static const Color kumEnKoyu = Color(0xFFE1DACB);
  static const Color cizgi = Color(0xFFE7E0D3);
  static const Color kenar = Color(0xFFB6AE9C);
  static const Color kurum = Color(0xFF1C2620);
  static const Color kurumSolgun = Color(0xFF5C6157);

  // ─── Nötrler — koyu tema ─────────────────────────────────────────────────
  static const Color geceZemin = Color(0xFF11150F);
  static const Color geceEnAlt = Color(0xFF0B0E0A);
  static const Color geceKart = Color(0xFF1A201A);
  static const Color geceKartUst = Color(0xFF232A22);
  static const Color geceKartTepe = Color(0xFF2C342B);
  static const Color geceCizgi = Color(0xFF333A32);
  static const Color geceKenar = Color(0xFF6E7369);
  static const Color geceMetin = Color(0xFFE5E6E0);
  static const Color geceMetinSolgun = Color(0xFFA8AC9F);

  // ─── Sage (ikincil) ──────────────────────────────────────────────────────
  static const Color sage = Color(0xFF5C6B52);
  static const Color sageZemin = Color(0xFFE2E7D8);
  static const Color sageKoyu = Color(0xFF1B2416);
  static const Color sageAcik = Color(0xFFB9C5AC);
  static const Color sageGece = Color(0xFF3A4732);

  // ─── Hata ────────────────────────────────────────────────────────────────
  static const Color hata = Color(0xFFB3261E);
  static const Color hataZemin = Color(0xFFF9DEDC);
  static const Color hataKoyu = Color(0xFF410E0B);
  static const Color hataGeceMetin = Color(0xFFFFB4AB);
  static const Color hataGeceZemin = Color(0xFF8C1D18);
  static const Color hataGeceKoyu = Color(0xFF601410);

  // ─── Borç / alacak ───────────────────────────────────────────────────────
  //
  // Bu iki renk temanın `ColorScheme`'i dışında elle tutuluyor: borç-alacak
  // ayrımı bir marka tercihi değil, muhasebe anlamı. Palet değişse de kırmızı
  // borç, yeşil alacak kalır (bkz. KURALLAR.md §3.4).
  static const Color _borcAcik = Color(0xFFB3261E);
  static const Color _borcKoyu = Color(0xFFFFB4AB);
  static const Color _borcZeminAcik = Color(0xFFFBEAE7);
  static const Color _borcZeminKoyu = Color(0xFF3A211E);
  static const Color _alacakZeminAcik = Color(0xFFE6F0E6);
  static const Color _alacakZeminKoyu = Color(0xFF1D2E22);

  /// Carinin işletmeye borçlu olduğu (pozitif) bakiyenin rengi.
  ///
  /// Koyu temada koyu kırmızı okunmuyor; iki ton ayrı tutuluyor.
  static Color borc(Brightness parlaklik) =>
      parlaklik == Brightness.dark ? _borcKoyu : _borcAcik;

  /// İşletmenin cariye borçlu olduğu (negatif) bakiyenin rengi.
  static Color alacak(Brightness parlaklik) =>
      parlaklik == Brightness.dark ? yaprak : zeytin;

  /// Borç vurgusunun soluk zemini — bakiye kartı ve rozetler için.
  static Color borcZemini(Brightness parlaklik) =>
      parlaklik == Brightness.dark ? _borcZeminKoyu : _borcZeminAcik;

  /// Alacak vurgusunun soluk zemini.
  static Color alacakZemini(Brightness parlaklik) =>
      parlaklik == Brightness.dark ? _alacakZeminKoyu : _alacakZeminAcik;
}
