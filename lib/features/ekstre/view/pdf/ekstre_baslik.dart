import 'package:pdf/widgets.dart' as pw;

import '../../../../core/metin/metinler.dart';
import '../../../../domain/cari/cari.dart';
import '../../../../domain/ekstre/ekstre.dart';
import '../../../../domain/isletme/isletme.dart';
import 'ekstre_stili.dart';

/// Ekstrenin ilk sayfasındaki başlık bloğu.
///
/// Referans ekstredeki üç sütunlu düzen: solda logo, ortada işletme künyesi,
/// sağda `İLGİLİ FİRMA`. Logo görseli henüz yüklenemediği için sol sütuna
/// işletme adı yazı olarak basılır — sütunu boş bırakmak düzeni bozuyor.
pw.Widget ekstreBasligi(Ekstre ekstre, EkstreStili stil) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Expanded(
            flex: 4,
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(right: 20),
              child: pw.Text(ekstre.isletme.ad, style: stil.logoYazisi),
            ),
          ),
          pw.Expanded(flex: 5, child: _isletmeKunyesi(ekstre.isletme, stil)),
          pw.Expanded(flex: 4, child: _ilgiliFirma(ekstre.cari, stil)),
        ],
      ),
      pw.SizedBox(height: 34),
      pw.Text(Metinler.ekstreBaslik, style: stil.belgeBasligi),
      pw.SizedBox(height: 8),
      pw.Text(ekstre.aralikMetni, style: stil.aralikBasligi),
      pw.SizedBox(height: 18),
    ],
  );
}

/// İkinci ve sonraki sayfaların üstündeki ince şerit.
///
/// Referans ekstre bunu taşımıyor; biz ekliyoruz çünkü çok sayfalı bir ekstre
/// yazdırılıp dağıldığında hangi sayfanın kime ait olduğu okunabilmeli.
pw.Widget ekstreSurdurmeBasligi(Ekstre ekstre, EkstreStili stil) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 6),
    margin: const pw.EdgeInsets.only(bottom: 10),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: EkstreStili.cizgi, width: 0.5),
      ),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: <pw.Widget>[
        pw.Text(ekstre.isletme.tamAd, style: stil.altBilgiKalin),
        pw.Text(ekstre.cari.ad, style: stil.altBilgi),
      ],
    ),
  );
}

pw.Widget _isletmeKunyesi(Isletme isletme, EkstreStili stil) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Text(isletme.ad, style: stil.isletmeAdi),
      if (isletme.unvan.isNotEmpty)
        pw.Text(isletme.unvan, style: stil.isletmeAdi),
      for (final satir in _adresSatirlari(isletme.adres))
        pw.Text(satir, style: stil.isletmeSatiri),
      if (isletme.telefon.isNotEmpty)
        _etiketliSatir(Metinler.ekstreTelefon, isletme.telefon, stil),
      if (isletme.faks != null && isletme.faks!.isNotEmpty)
        _etiketliSatir(Metinler.ekstreFaks, isletme.faks!, stil),
      if (isletme.vergiDairesi.isNotEmpty || isletme.vergiNo.isNotEmpty)
        pw.Row(
          children: <pw.Widget>[
            if (isletme.vergiDairesi.isNotEmpty)
              _etiketliSatir(
                Metinler.ekstreVergiDairesi,
                isletme.vergiDairesi,
                stil,
              ),
            if (isletme.vergiDairesi.isNotEmpty && isletme.vergiNo.isNotEmpty)
              pw.SizedBox(width: 8),
            if (isletme.vergiNo.isNotEmpty)
              _etiketliSatir(Metinler.ekstreVergiNo, isletme.vergiNo, stil),
          ],
        ),
    ],
  );
}

pw.Widget _ilgiliFirma(Cari cari, EkstreStili stil) {
  final ikinciSatir = <String>[
    if (cari.unvan != null && cari.unvan!.isNotEmpty) cari.unvan!,
    if (cari.sehir != null && cari.sehir!.isNotEmpty) cari.sehir!,
  ].join(' ');

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Text(Metinler.ekstreIlgiliFirma, style: stil.isletmeAdi),
      pw.SizedBox(height: 4),
      pw.Text(
        ikinciSatir.isEmpty ? cari.ad : '${cari.ad} $ikinciSatir',
        style: stil.isletmeSatiri,
      ),
    ],
  );
}

pw.Widget _etiketliSatir(String etiket, String deger, EkstreStili stil) {
  return pw.RichText(
    text: pw.TextSpan(
      children: <pw.InlineSpan>[
        pw.TextSpan(text: etiket, style: stil.isletmeEtiketi),
        pw.TextSpan(text: ' $deger', style: stil.isletmeSatiri),
      ],
    ),
  );
}

/// Adres alanı çok satırlı girilebilir; olduğu gibi basılır.
List<String> _adresSatirlari(String adres) => adres
    .split('\n')
    .map((satir) => satir.trim())
    .where((satir) => satir.isNotEmpty)
    .toList(growable: false);
