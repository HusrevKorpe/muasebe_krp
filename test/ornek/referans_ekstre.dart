/// Referans ekstrenin dokuz işlemi — fazın ana doğruluk ölçütü.
///
/// Tutarlar, tarihler ve kalemler `~/Desktop/Favori_Fidancılık_Ekstresi.pdf`
/// dosyasındaki gerçek ekstreden birebir alınmıştır — tek istisna
/// [sertCekirdekliFaturasi]'ndaki vergi satırıdır, orada anlatılıyor.
/// Ürettiğimiz bakiye kolonunun PDF ile kuruşu kuruşuna tutması gerekir.
/// Cari adı ve IBAN gibi
/// kişisel bilgiler bilerek alınmamıştır — gerçek müşteri verisi
/// repoya commit edilmez (bkz. KURALLAR.md §7).
///
/// Belge kimlikleri sıra numarasıdır: aynı güne düşen iki işlemin (17 Eylül
/// 2021'deki fatura ve tahsilat) sırası kimliğe göre belirlenir; uygulamada da
/// kimlikler zaman sıralı üretilir (bkz. `islem_siralamasi.dart`).
library;

import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/domain/islem/islem.dart';
import 'package:fidancari/domain/islem/islem_kalemi.dart';
import 'package:fidancari/domain/islem/islem_tipi.dart';

/// `17 Eylül 2021` — Satış Faturası, Zeytin-Hurma.
///
/// Hurma kalemi fazın en kritik satırı: ekstrede `1.650 Adet × 18,79 ₺` yazar,
/// ama `1.650 × 18,79 = 31.003,50`. Gerçek tutar `31.000,00 ₺` ve birim fiyat
/// oradan geri hesaplanmıştır.
final Islem zeytinHurmaFaturasi = Islem.fatura(
  id: '01',
  tip: IslemTipi.satisFaturasi,
  baslik: 'Zeytin-Hurma',
  islemTarihi: DateTime(2021, 9, 17),
  kalemler: <IslemKalemi>[
    IslemKalemi.birimFiyattan(
      ad: 'zeytin',
      miktar: 7000,
      birimFiyat: Kurus.liradan(7),
    ),
    IslemKalemi.toplamdan(
      ad: 'Hurma',
      miktar: 1650,
      toplam: Kurus.liradan(31000),
    ),
    IslemKalemi.birimFiyattan(
      ad: 'nakliye',
      miktar: 1,
      birimFiyat: Kurus.liradan(14000),
    ),
  ],
);

/// `05 Aralık 2024` — Satış Faturası, Hachiya Tüplü-Çam-Gemlik 2 Yaş.
final Islem hachiyaFaturasi = Islem.fatura(
  id: '06',
  tip: IslemTipi.satisFaturasi,
  baslik: 'Hachiya Tüplü-Çam-Gemlik 2 Yaş',
  islemTarihi: DateTime(2024, 12, 5),
  kalemler: <IslemKalemi>[
    IslemKalemi.birimFiyattan(
      ad: 'hachiya',
      miktar: 3000,
      birimFiyat: Kurus.liradan(60),
    ),
    IslemKalemi.birimFiyattan(
      ad: 'çam',
      miktar: 250,
      birimFiyat: Kurus.liradan(60),
    ),
    IslemKalemi.birimFiyattan(
      ad: 'zeytin gemlik 2 yaş',
      miktar: 250,
      birimFiyat: Kurus.liradan(100),
    ),
  ],
);

/// `20 Ocak 2025` — Alış Faturası, Sert Çekirdekli Meyve Fidanı.
///
/// Toplamı `142.031,25 ₺`. Alış faturası olduğu için bakiyeyi negatife
/// düşürür — bir cari hem müşteri hem tedarikçi olabilir.
///
/// Ekstrede bu faturaya %1 vergi işlenmiştir: fidan kalemleri `140.625,00 ₺`,
/// üzerine `1.406,25 ₺`. Uygulamada vergi diye ayrı bir alan yok; böyle bir
/// tutar "nakliye" gibi serbest metin kalemi olarak girilir. Fatura toplamı ve
/// dolayısıyla ekstrenin bakiye kolonu PDF ile birebir aynı kalır.
final Islem sertCekirdekliFaturasi = Islem.fatura(
  id: '09',
  tip: IslemTipi.alisFaturasi,
  baslik: 'Sert Çekirdekli Meyve Fidanı',
  islemTarihi: DateTime(2025, 1, 20),
  kalemler: <IslemKalemi>[
    for (final ad in <String>['elma', 'armut', 'kiraz', 'ayva'])
      IslemKalemi.birimFiyattan(
        ad: ad,
        miktar: 600,
        birimFiyat: Kurus.liradan(45),
      ),
    IslemKalemi.birimFiyattan(
      ad: 'asma anacı atasarısı',
      miktar: 725,
      birimFiyat: Kurus.liradan(45),
    ),
    IslemKalemi.birimFiyattan(
      ad: 'vergi',
      miktar: 1,
      birimFiyat: Kurus.liradan(1406, 25),
    ),
  ],
);

/// Ekstredeki altı tahsilat, ekstredeki sırayla.
final List<Islem> tahsilatlar = <Islem>[
  _tahsilat('02', DateTime(2021, 9, 17), 10000),
  _tahsilat('03', DateTime(2021, 11, 13), 50000),
  _tahsilat('04', DateTime(2021, 11, 15), 30000),
  _tahsilat('05', DateTime(2022, 1, 28), 4000),
  _tahsilat('07', DateTime(2024, 12, 6), 50000),
  _tahsilat('08', DateTime(2024, 12, 31), 40000),
];

/// Dokuz işlemin tamamı, ekstredeki sırayla.
final List<Islem> referansIslemleri = <Islem>[
  zeytinHurmaFaturasi,
  tahsilatlar[0],
  tahsilatlar[1],
  tahsilatlar[2],
  tahsilatlar[3],
  hachiyaFaturasi,
  tahsilatlar[4],
  tahsilatlar[5],
  sertCekirdekliFaturasi,
];

/// Ekstrenin BAKİYE kolonu, kuruş cinsinden — satır satır beklenen değer.
const List<int> beklenenBakiyeler = <int>[
  9400000, //     94.000,00 ₺
  8400000, //     84.000,00 ₺
  3400000, //     34.000,00 ₺
  400000, //       4.000,00 ₺
  0, //                0,00 ₺
  22000000, //   220.000,00 ₺
  17000000, //   170.000,00 ₺
  13000000, //   130.000,00 ₺
  -1203125, //   -12.031,25 ₺
];

/// Ekstrenin son sayfasındaki toplamlar.
const int beklenenToplamBorc = 31400000; //  314.000,00 ₺
const int beklenenToplamAlacak = 32603125; // 326.031,25 ₺
const int beklenenBakiye = -1203125; //       -12.031,25 ₺

Islem _tahsilat(String id, DateTime tarih, int lira) => Islem.odeme(
  id: id,
  tip: IslemTipi.tahsilat,
  baslik: 'Müşteriden Tahsilat',
  islemTarihi: tarih,
  tutar: Kurus.liradan(lira),
);
