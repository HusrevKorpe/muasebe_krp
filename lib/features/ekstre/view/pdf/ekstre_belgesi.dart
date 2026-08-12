import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../../../core/hata/hatalar.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../core/metin/turkce.dart' as turkce;
import '../../../../core/tarih/tarih_bicimi.dart';
import '../../../../domain/ekstre/ekstre.dart';
import 'ekstre_altligi.dart';
import 'ekstre_baslik.dart';
import 'ekstre_fontlari.dart';
import 'ekstre_stili.dart';
import 'ekstre_tablosu.dart';

/// [Ekstre]'yi PDF baytlarına çevirir.
abstract final class EkstreBelgesi {
  /// Belgeyi üretir.
  ///
  /// Tablo ile toplamlar tutmuyorsa [DogrulamaHatasi] fırlatır ve **hiçbir
  /// çıktı üretmez**. Referans yazılım bu kontrolü yapmadığı için müşteriye
  /// kendi içinde çelişen bir ekstre göndermiş (bkz. `fazlar/faz-4-ekstre.md`);
  /// son kapı burasıdır.
  static Future<Uint8List> uret({
    required Ekstre ekstre,
    required EkstreFontlari fontlar,
  }) {
    if (!ekstre.tutarliMi) {
      throw const DogrulamaHatasi(Metinler.ekstreTutarsiz);
    }

    final stil = EkstreStili(fontlar);
    final belge = pw.Document(
      title: '${Metinler.ekstre} — ${ekstre.cari.ad}',
      author: ekstre.isletme.tamAd,
      creator: Metinler.uygulamaAdi,
      subject: ekstre.aralikMetni,
    );

    belge.addPage(
      pw.MultiPage(
        pageFormat: EkstreStili.sayfaBicimi,
        margin: const pw.EdgeInsets.all(EkstreStili.kenarBosluk),
        theme: pw.ThemeData.withFont(
          base: fontlar.normal,
          bold: fontlar.kalin,
        ),
        // İlk sayfanın başlığı içerikle birlikte akar; sonraki sayfalara
        // yalnızca ince bir kimlik şeridi konur.
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : ekstreSurdurmeBasligi(ekstre, stil),
        footer: (context) => ekstreSayfaDibi(context, ekstre, stil),
        build: (context) => <pw.Widget>[
          ekstreBasligi(ekstre, stil),
          ekstreTablosu(ekstre, stil),
          ekstreTabloKapanisi(),
          if (ekstre.bosMu) _bosNot(stil),
          pw.SizedBox(height: 28),
          ekstreAltligi(ekstre, stil),
        ],
      ),
    );

    return belge.save();
  }

  /// Paylaşılan dosyanın adı: `ekstre-ahmet-koyuncu-24-05-2025.pdf`
  ///
  /// Ad ASCII'ye indirgenir; Türkçe karakterli dosya adları paylaşım
  /// hedeflerinde (WhatsApp, e-posta ekleri) bozuk görünebiliyor.
  static String dosyaAdi(Ekstre ekstre) {
    final ad = turkce
        .aramaAnahtari(ekstre.cari.ad)
        .replaceAll(RegExp('[^a-z0-9]+'), '-');
    final tarih = kisaTarih(ekstre.hazirlanmaTarihi).replaceAll('.', '-');
    return 'ekstre-${ad.isEmpty ? 'cari' : ad}-$tarih.pdf';
  }
}

pw.Widget _bosNot(EkstreStili stil) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 16),
  child: pw.Center(
    child: pw.Text(Metinler.ekstreBosBaslik, style: stil.kalemSoluk),
  ),
);
