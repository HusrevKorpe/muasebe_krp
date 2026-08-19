import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/metin/metinler.dart';
import '../../../../core/metin/turkce.dart' as turkce;
import '../../../../core/para/kurus.dart';
import '../../../../core/para/para_bicimi.dart';
import '../../../../core/tarih/tarih_bicimi.dart';
import '../../../../domain/ekstre/ekstre.dart';
import '../../../../domain/islem/islem.dart';
import '../../../../domain/islem/islem_kalemi.dart';
import '../../../../domain/islem/islem_tipi.dart';
import '../../../islem/view/widget/islem_tipi_gorunumu.dart';
import 'ekstre_para_metni.dart';
import 'ekstre_stili.dart';

/// Ekstrenin altı kolonlu tablosu.
///
/// Bir işlemin kalem listesi **kendi satırının içindedir**, ayrı satırlar
/// değil: `pw.Table` bir satırı sayfaya bölmez, böylece fatura ile kalemleri
/// sayfa kırılımında birbirinden kopmaz (`fazlar/faz-4-ekstre.md`, riskler).
///
/// Başlık satırı `repeat: true` ile her sayfada tekrarlanır.
pw.Widget ekstreTablosu(Ekstre ekstre, EkstreStili stil) {
  final satirlar = <pw.TableRow>[
    _baslikSatiri(stil),
    if (ekstre.acilisBakiyesiVarMi) _devirSatiri(ekstre, stil),
    for (final satir in ekstre.satirlar)
      _islemSatiri(
        islem: satir.islem,
        yuruyenBakiye: satir.yuruyenBakiye,
        stil: stil,
      ),
  ];

  return pw.Table(
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
    columnWidths: <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(EkstreStili.simgeKolonu),
      1: const pw.FixedColumnWidth(EkstreStili.tarihKolonu),
      2: pw.FixedColumnWidth(EkstreStili.aciklamaKolonu),
      3: const pw.FixedColumnWidth(EkstreStili.tutarKolonu),
      4: const pw.FixedColumnWidth(EkstreStili.tutarKolonu),
      5: const pw.FixedColumnWidth(EkstreStili.bakiyeKolonu),
    },
    children: satirlar,
  );
}

/// Tablonun son satırını kapatan koyu çizgi.
///
/// Ayrı bir parça olarak duruyor ki çok sayfalı ekstrede tablo nerede biterse
/// çizgi de orada çizilsin.
pw.Widget ekstreTabloKapanisi() => pw.Container(
  height: 1.1,
  color: EkstreStili.koyuCizgi,
  margin: const pw.EdgeInsets.only(top: -0.5),
);

pw.TableRow _baslikSatiri(EkstreStili stil) => pw.TableRow(
  repeat: true,
  children: <pw.Widget>[
    _hucre(pw.SizedBox(), baslikMi: true),
    _hucre(
      pw.Text(Metinler.ekstreKolonIslemTarihi, style: stil.kolonBasligi),
      baslikMi: true,
    ),
    _hucre(
      pw.Text(Metinler.ekstreKolonAciklama, style: stil.kolonBasligi),
      baslikMi: true,
    ),
    _hucre(
      pw.Text(Metinler.ekstreKolonBorc, style: stil.kolonBasligi),
      baslikMi: true,
      hiza: pw.Alignment.topRight,
    ),
    _hucre(
      pw.Text(Metinler.ekstreKolonAlacak, style: stil.kolonBasligi),
      baslikMi: true,
      hiza: pw.Alignment.topRight,
    ),
    _hucre(
      pw.Text(Metinler.ekstreKolonBakiye, style: stil.kolonBasligi),
      baslikMi: true,
      solCizgi: true,
      hiza: pw.Alignment.topRight,
    ),
  ],
);

/// Aralıktan önceki işlemlerin toplamı — tablonun ilk satırı.
pw.TableRow _devirSatiri(Ekstre ekstre, EkstreStili stil) => pw.TableRow(
  children: <pw.Widget>[
    _hucre(pw.SizedBox()),
    _hucre(
      pw.Text(tabloTarihi(ekstre.gosterilenBaslangic), style: stil.satir),
    ),
    _hucre(pw.Text(Metinler.ekstreDevreden, style: stil.satirKalin)),
    _hucre(pw.SizedBox()),
    _hucre(pw.SizedBox()),
    _hucre(
      ekstreParasi(ekstre.acilisBakiyesi, stil, kalin: true),
      solCizgi: true,
      hiza: pw.Alignment.topRight,
    ),
  ],
);

pw.TableRow _islemSatiri({
  required Islem islem,
  required Kurus yuruyenBakiye,
  required EkstreStili stil,
}) {
  return pw.TableRow(
    decoration: _satirZemini(islem),
    children: <pw.Widget>[
      // Simge kolonu dar; normal kolon boşluğu uygulanırsa çizime yer kalmıyor.
      _hucre(_tipSimgesi(islem.tip), yatayBosluk: EkstreStili.simgeBoslugu),
      _hucre(pw.Text(tabloTarihi(islem.islemTarihi), style: stil.satir)),
      _hucre(_aciklamaHucresi(islem, stil)),
      _hucre(
        islem.borc.sifirMi ? pw.SizedBox() : ekstreParasi(islem.borc, stil),
        hiza: pw.Alignment.topRight,
      ),
      _hucre(
        islem.alacak.sifirMi ? pw.SizedBox() : ekstreParasi(islem.alacak, stil),
        hiza: pw.Alignment.topRight,
      ),
      _hucre(
        ekstreParasi(yuruyenBakiye, stil, kalin: true),
        solCizgi: true,
        hiza: pw.Alignment.topRight,
      ),
    ],
  );
}

/// Satır açık zeminde mi basılacak?
///
/// Kullanıcının isteği: "para aldığım ve fidan aldığım" satırlar ayrışsın —
/// yani tahsilat ve alış faturası. İkisi de ekstrenin alacak tarafıdır, bu
/// yüzden ölçüt tip listesi değil **alacak kolonundaki tutardır**.
///
/// [Islem.alacak] iptalli kayıtta sıfır döner; iptalli bir tahsilat da bu
/// yüzden zeminsiz kalır. Tutarları boş basılan bir satırı boyamak "para girdi"
/// derdi.
bool ekstreAlacakSatiriMi(Islem islem) => !islem.alacak.sifirMi;

/// Zemin satırın tamamına çizilir ve hücre çizgileri üstüne biner; `pw.Table`
/// satır dekorasyonunu hücrelerden önce boyar.
pw.BoxDecoration? _satirZemini(Islem islem) => ekstreAlacakSatiriMi(islem)
    ? const pw.BoxDecoration(color: EkstreStili.alacakZemini)
    : null;

pw.Widget _aciklamaHucresi(Islem islem, EkstreStili stil) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Text(ekstreAciklamasi(islem), style: stil.satir),
      if (islem.kalemler.isNotEmpty) ...<pw.Widget>[
        pw.SizedBox(height: 4),
        for (final kalem in islem.kalemler) _kalemSatiri(kalem, stil),
      ],
    ],
  );
}

/// `Satış Faturası — Zeytin-Hurma`
///
/// Faturalarda tip adı başlığın önüne eklenir; tahsilat ve ödemede başlık
/// zaten "Müşteriden Tahsilat" gibi kendi kendini anlatır ve tekrarlanmaz —
/// referans ekstredeki yazım budur. İptalli kayıt `(İPTAL EDİLDİ)` ekiyle
/// basılır: satır ekstreden düşmez, tutarları boş görünür.
String ekstreAciklamasi(Islem islem) {
  final govde = islem.baslik.isEmpty
      ? islem.tip.belgeAdi
      : (islem.tip.faturaMi
            ? '${islem.tip.belgeAdi} — ${islem.baslik}'
            : islem.baslik);

  if (!islem.iptalMi) return govde;
  return '$govde (${turkce.turkceBuyuk(Metinler.iptalEdildi)})';
}

/// `zeytin   7.000 Adet  ×  7,00 ₺`
///
/// Tek bir [pw.RichText] olarak kuruluyor, [pw.Row] olarak değil: uzun kalem
/// adı geldiğinde satır taşmak yerine kendiliğinden kayar.
pw.Widget _kalemSatiri(IslemKalemi kalem, EkstreStili stil) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 3),
    child: pw.RichText(
      text: pw.TextSpan(
        style: stil.kalemSatiri,
        children: <pw.InlineSpan>[
          pw.TextSpan(text: kalem.ad),
          pw.TextSpan(
            text: '     ${miktarBicimle(kalem.miktar)} '
                '${turkce.ilkHarfBuyuk(kalem.birim)}',
          ),
          pw.TextSpan(text: '  ×  ', style: stil.kalemSoluk),
          pw.TextSpan(text: liraKismiMetni(kalem.birimFiyat)),
          pw.TextSpan(
            text: kurusKismiMetni(kalem.birimFiyat),
            style: stil.kalemSatiri.copyWith(
              fontSize:
                  (stil.kalemSatiri.fontSize ?? 7) * EkstreStili.kurusOrani,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Satırın solundaki işlem tipi simgesi.
///
/// Material simgeleri PDF'e gömülemez (ayrı bir simge fontu gerekirdi); üç
/// basit vektör çizim yeterli: fatura için köşesi kıvrık sayfa, tahsilat ve
/// ödeme için madenî para, hesap görme için onay imi.
///
/// Hesap görme kaydı madenî parayla çizilmiyor: o satırda para el değiştirmedi,
/// kalan bakiyeden vazgeçildi (bkz. `IslemTipi.hesapGormeMi`).
pw.Widget _tipSimgesi(IslemTipi tip) {
  return pw.SizedBox(
    width: 10,
    height: 12,
    child: pw.CustomPaint(
      size: const PdfPoint(10, 12),
      painter: (canvas, size) {
        canvas
          ..setStrokeColor(EkstreStili.soluk)
          ..setLineWidth(0.6);

        if (tip.hesapGormeMi) {
          // Onay imi: sol üstten aşağı, oradan sağ yukarı. PDF'te y ekseni
          // yukarı doğru büyür.
          canvas
            ..moveTo(1.6, size.y / 2)
            ..lineTo(size.x / 2 - 0.8, size.y / 2 - 2.6)
            ..lineTo(size.x - 1.4, size.y / 2 + 2.8)
            ..strokePath();
        } else if (tip.faturaMi) {
          const kivrim = 2.4;
          canvas
            ..moveTo(0.5, 0.5)
            ..lineTo(0.5, size.y - 0.5)
            ..lineTo(size.x - kivrim, size.y - 0.5)
            ..lineTo(size.x - 0.5, size.y - kivrim)
            ..lineTo(size.x - 0.5, 0.5)
            ..closePath()
            ..strokePath();

          canvas.setLineWidth(0.5);
          for (var sira = 0; sira < 2; sira++) {
            final y = 4 + sira * 2.8;
            canvas
              ..moveTo(2.8, y)
              ..lineTo(size.x - 2.8, y);
          }
          canvas.strokePath();
        } else {
          canvas
            ..drawEllipse(size.x / 2, size.y / 2, 3.6, 3.6)
            ..strokePath()
            ..moveTo(size.x / 2 - 1.8, size.y / 2)
            ..lineTo(size.x / 2 + 1.8, size.y / 2)
            ..strokePath();
        }
      },
    ),
  );
}

/// Tablo hücresi: alt çizgi, gerekiyorsa BAKİYE kolonunun sol ayracı.
///
/// Dikey ayraç hücrenin kenarlığıdır; `TableCellVerticalAlignment.full` ile
/// hücre satır yüksekliğini kapladığı için çizgi satırlar boyunca kesintisiz
/// iner.
pw.Widget _hucre(
  pw.Widget cocuk, {
  bool baslikMi = false,
  bool solCizgi = false,
  pw.Alignment hiza = pw.Alignment.topLeft,
  double yatayBosluk = EkstreStili.kolonBoslugu,
}) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(
          color: baslikMi ? EkstreStili.koyuCizgi : EkstreStili.cizgi,
          width: baslikMi ? 0.8 : 0.5,
        ),
        left: solCizgi
            ? const pw.BorderSide(color: EkstreStili.koyuCizgi, width: 0.8)
            : pw.BorderSide.none,
      ),
    ),
    padding: pw.EdgeInsets.symmetric(
      vertical: EkstreStili.satirBosluguDikey,
      horizontal: yatayBosluk,
    ),
    child: pw.Align(alignment: hiza, child: cocuk),
  );
}
