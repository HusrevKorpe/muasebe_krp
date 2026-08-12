import 'package:pdf/widgets.dart' as pw;

import '../../../../core/metin/metinler.dart';
import '../../../../core/para/kurus.dart';
import '../../../../core/tarih/tarih_bicimi.dart';
import '../../../../domain/ekstre/ekstre.dart';
import '../../../../domain/isletme/banka_hesabi.dart';
import 'ekstre_para_metni.dart';
import 'ekstre_stili.dart';

/// Ekstrenin son bloğu: solda banka hesapları, sağda toplamlar.
pw.Widget ekstreAltligi(Ekstre ekstre, EkstreStili stil) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Expanded(child: _bankaBolumu(ekstre, stil)),
      pw.SizedBox(width: 24),
      pw.SizedBox(width: _toplamGenisligi, child: _toplamlar(ekstre, stil)),
    ],
  );
}

/// Sayfa dibi: solda hazırlanma notu, sağda sayfa numarası.
pw.Widget ekstreSayfaDibi(
  pw.Context context,
  Ekstre ekstre,
  EkstreStili stil,
) {
  // `hazirlanmaNotu` metni kısa tarihle başlar; tarih kısmını koyu basmak için
  // baştaki o parça ayrılıyor (bkz. `core/tarih/tarih_bicimi.dart`).
  final tarih = kisaTarih(ekstre.hazirlanmaTarihi);
  final not = hazirlanmaNotu(ekstre.hazirlanmaTarihi);

  return pw.Container(
    padding: const pw.EdgeInsets.only(top: 8),
    margin: const pw.EdgeInsets.only(top: 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(color: EkstreStili.cizgi, width: 0.5),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.RichText(
          text: pw.TextSpan(
            style: stil.altBilgi,
            children: <pw.InlineSpan>[
              pw.TextSpan(text: tarih, style: stil.altBilgiKalin),
              pw.TextSpan(text: not.substring(tarih.length)),
            ],
          ),
        ),
        pw.RichText(
          text: pw.TextSpan(
            style: stil.altBilgi,
            children: <pw.InlineSpan>[
              pw.TextSpan(
                text: Metinler.ekstreSayfa(context.pageNumber),
                style: stil.altBilgiKalin,
              ),
              pw.TextSpan(
                text: Metinler.ekstreSayfaToplami(context.pagesCount),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Toplam bloğunun genişliği — etiket ve tutar yan yana sığmalı.
const double _toplamGenisligi = 200;

pw.Widget _bankaBolumu(Ekstre ekstre, EkstreStili stil) {
  final hesaplar = ekstre.isletme.bankaHesaplari;
  if (hesaplar.isEmpty) return pw.SizedBox();

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Text(Metinler.ekstreBankaBilgileri, style: stil.bolumBasligi),
      pw.SizedBox(height: 8),
      for (final hesap in hesaplar) _bankaHesabi(hesap, stil),
    ],
  );
}

pw.Widget _bankaHesabi(BankaHesabi hesap, EkstreStili stil) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text('${hesap.banka} (${hesap.paraBirimi})', style: stil.bankaAdi),
        if (hesap.hesapNo != null && hesap.hesapNo!.isNotEmpty)
          _etiketliDeger(Metinler.ekstreHesapNo, hesap.hesapNo!, stil),
        if (hesap.iban.isNotEmpty)
          _etiketliDeger(Metinler.ekstreIban, hesap.ibanBicimli, stil),
      ],
    ),
  );
}

pw.Widget _etiketliDeger(String etiket, String deger, EkstreStili stil) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 2),
    child: pw.RichText(
      text: pw.TextSpan(
        children: <pw.InlineSpan>[
          pw.TextSpan(text: etiket, style: stil.bankaEtiketi),
          pw.TextSpan(text: '  $deger', style: stil.bankaDegeri),
        ],
      ),
    ),
  );
}

/// `TOPLAM ALACAK`, `TOPLAM BORÇ`, `BAKİYE` — her biri altı çizili.
///
/// Sıra referans ekstredeki sıradır. Rakamlar tablodaki satırlarla tutar;
/// tutmazsa PDF hiç üretilmez (bkz. `ekstre_belgesi.dart`).
pw.Widget _toplamlar(Ekstre ekstre, EkstreStili stil) {
  return pw.Column(
    children: <pw.Widget>[
      _toplamSatiri(Metinler.ekstreToplamAlacak, ekstre.toplamAlacak, stil),
      _toplamSatiri(Metinler.ekstreToplamBorc, ekstre.toplamBorc, stil),
      _toplamSatiri(Metinler.ekstreBakiye, ekstre.kapanisBakiyesi, stil),
    ],
  );
}

pw.Widget _toplamSatiri(String etiket, Kurus tutar, EkstreStili stil) {
  return pw.Column(
    children: <pw.Widget>[
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: <pw.Widget>[
          pw.Text(etiket, style: stil.toplamEtiketi),
          pw.SizedBox(width: 16),
          pw.SizedBox(
            width: 86,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: ekstreParasi(tutar, stil, kalin: true),
            ),
          ),
        ],
      ),
      pw.Divider(
        height: 14,
        thickness: 0.7,
        color: EkstreStili.koyuCizgi,
      ),
    ],
  );
}
