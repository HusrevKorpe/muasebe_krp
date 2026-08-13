import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'ekstre_fontlari.dart';

/// Ekstre PDF'inin ölçüleri, renkleri ve yazı biçimleri.
///
/// Sayısal değerler referans ekstreden ölçülerek alındı; kolon genişlikleri
/// A4 genişliğinden kenar boşlukları düşülerek dağıtıldı ve toplamları
/// [kullanilabilirGenislik]'e eşittir.
class EkstreStili {
  const EkstreStili(this.fontlar);

  final EkstreFontlari fontlar;

  static const PdfPageFormat sayfaBicimi = PdfPageFormat.a4;
  static const double kenarBosluk = 28;
  static double get kullanilabilirGenislik =>
      sayfaBicimi.width - kenarBosluk * 2;

  // ─── Renkler ─────────────────────────────────────────────────────────────
  static const PdfColor metin = PdfColor.fromInt(0xFF1F1F1F);
  static const PdfColor soluk = PdfColor.fromInt(0xFF8C8C8C);
  static const PdfColor cizgi = PdfColor.fromInt(0xFFDDDDDD);
  static const PdfColor koyuCizgi = PdfColor.fromInt(0xFF6E6E6E);

  /// Uygulamanın fidan yeşili — başlıktaki işletme adında kullanılır.
  static const PdfColor vurgu = PdfColor.fromInt(0xFF2E7D32);

  // ─── Kolon genişlikleri ──────────────────────────────────────────────────
  /// Satır başındaki işlem tipi simgesinin kolonu ve o kolonun dar boşluğu.
  ///
  /// Simge 10×12 punto çiziliyor; normal [kolonBoslugu] uygulanırsa kolonda
  /// çizime iki punto yer kalır ve simge ezilir.
  static const double simgeKolonu = 18;
  static const double simgeBoslugu = 3;

  /// Tarih kolonu `28 Ağustos 2024` gibi en uzun tarihi tek satıra sığdıracak
  /// genişlikte: sarkan tarih satır yüksekliğini büyütüyor ve tablo tırtıklı
  /// görünüyor.
  static const double tarihKolonu = 72;

  /// BORÇ ve ALACAK kolonlarının ortak genişliği.
  ///
  /// `142.031,25 ₺` rahat sığacak kadar geniş tutuldu: para kolonu taşarsa
  /// rakam yan kolona sarkar ve hangi tarafa yazıldığı okunamaz hâle gelir.
  static const double tutarKolonu = 68;
  static const double bakiyeKolonu = 72;

  /// Açıklama kolonu kalan genişliği alır.
  static double get aciklamaKolonu =>
      kullanilabilirGenislik -
      simgeKolonu -
      tarihKolonu -
      tutarKolonu * 2 -
      bakiyeKolonu;

  /// Kuruş kısmı lira kısmından bu oranda küçük basılır — referans ekstredeki
  /// `94.000,00 ₺` görünümü.
  static const double kurusOrani = 0.82;

  static const double satirBosluguDikey = 7;
  static const double kolonBoslugu = 6;

  // ─── Yazı biçimleri ──────────────────────────────────────────────────────
  pw.TextStyle get belgeBasligi => pw.TextStyle(
    font: fontlar.kalin,
    fontSize: 21,
    color: metin,
    letterSpacing: -0.2,
  );

  pw.TextStyle get aralikBasligi =>
      pw.TextStyle(font: fontlar.kalin, fontSize: 8, color: metin);

  pw.TextStyle get isletmeAdi =>
      pw.TextStyle(font: fontlar.kalin, fontSize: 8.5, color: metin);

  pw.TextStyle get isletmeSatiri =>
      pw.TextStyle(font: fontlar.normal, fontSize: 8, color: metin);

  pw.TextStyle get isletmeEtiketi =>
      pw.TextStyle(font: fontlar.kalin, fontSize: 8, color: metin);

  /// Sol üstteki logo yerine basılan işletme adı. Uzun ad alt satıra kayar ve
  /// iki satırlı bir logo gibi durur — referans ekstredeki logo da öyle.
  pw.TextStyle get logoYazisi =>
      pw.TextStyle(font: fontlar.kalin, fontSize: 16, color: vurgu);

  pw.TextStyle get kolonBasligi => pw.TextStyle(
    font: fontlar.kalin,
    fontSize: 7,
    color: metin,
    letterSpacing: 0.4,
  );

  pw.TextStyle get satir =>
      pw.TextStyle(font: fontlar.normal, fontSize: 8.5, color: metin);

  pw.TextStyle get satirKalin =>
      pw.TextStyle(font: fontlar.kalin, fontSize: 8.5, color: metin);

  pw.TextStyle get kalemSatiri =>
      pw.TextStyle(font: fontlar.normal, fontSize: 7, color: metin);

  pw.TextStyle get kalemSoluk =>
      pw.TextStyle(font: fontlar.normal, fontSize: 7, color: soluk);

  pw.TextStyle get toplamEtiketi =>
      pw.TextStyle(font: fontlar.kalin, fontSize: 8.5, color: metin);

  pw.TextStyle get bolumBasligi =>
      pw.TextStyle(font: fontlar.kalin, fontSize: 10, color: metin);

  pw.TextStyle get bankaAdi =>
      pw.TextStyle(font: fontlar.kalin, fontSize: 8, color: metin);

  pw.TextStyle get bankaEtiketi =>
      pw.TextStyle(font: fontlar.kalin, fontSize: 6.5, color: metin);

  pw.TextStyle get bankaDegeri =>
      pw.TextStyle(font: fontlar.normal, fontSize: 7.5, color: metin);

  pw.TextStyle get altBilgi =>
      pw.TextStyle(font: fontlar.normal, fontSize: 7.5, color: soluk);

  pw.TextStyle get altBilgiKalin =>
      pw.TextStyle(font: fontlar.kalin, fontSize: 7.5, color: soluk);
}
