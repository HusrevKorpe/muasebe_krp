import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/domain/islem/bakiye_hesaplayici.dart';
import 'package:fidancari/domain/islem/islem.dart';
import 'package:fidancari/domain/islem/islem_tipi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Islem islem(
    String id,
    IslemTipi tip,
    int lira, {
    DateTime? tarih,
    bool iptal = false,
  }) => Islem(
    id: id,
    tip: tip,
    baslik: tip.anahtar,
    islemTarihi: tarih ?? DateTime(2024, 1, int.parse(id)),
    toplam: Kurus.liradan(lira),
    iptal: iptal,
  );

  group('İşaret yönü', () {
    test('satış faturası borç yazar, bakiyeyi artırır', () {
      final kayit = islem('1', IslemTipi.satisFaturasi, 1000);

      expect(kayit.borc.deger, 100000);
      expect(kayit.alacak, Kurus.sifir);
      expect(kayit.bakiyeEtkisi.deger, 100000);
    });

    test('tahsilat alacak yazar, bakiyeyi azaltır', () {
      final kayit = islem('1', IslemTipi.tahsilat, 1000);

      expect(kayit.alacak.deger, 100000);
      expect(kayit.bakiyeEtkisi.deger, -100000);
    });

    test('alış faturası alacak yazar — biz cariye borçlanırız', () {
      final kayit = islem('1', IslemTipi.alisFaturasi, 1000);

      expect(kayit.alacak.deger, 100000);
      expect(kayit.bakiyeEtkisi.deger, -100000);
    });

    test('ödeme borç yazar — biz cariye öderiz', () {
      final kayit = islem('1', IslemTipi.odeme, 1000);

      expect(kayit.borc.deger, 100000);
      expect(kayit.bakiyeEtkisi.deger, 100000);
    });
  });

  group('BakiyeHesaplayici.ileri', () {
    test('alış faturası bakiyeyi negatife düşürür', () {
      final dokum = BakiyeHesaplayici.ileri(
        islemler: <Islem>[
          islem('1', IslemTipi.satisFaturasi, 1000),
          islem('2', IslemTipi.alisFaturasi, 3000),
        ],
      );

      expect(dokum.bakiye.deger, -200000);
      expect(dokum.bakiye.negatifMi, isTrue);
    });

    test('devir bakiyesi ilk satıra eklenir', () {
      final dokum = BakiyeHesaplayici.ileri(
        islemler: <Islem>[islem('1', IslemTipi.satisFaturasi, 1000)],
        devir: Kurus.liradan(500),
      );

      expect(dokum.satirlar.single.yuruyenBakiye.deger, 150000);
      expect(dokum.devir.deger, 50000);
      expect(dokum.bakiye.deger, 150000);
      expect(
        dokum.toplamBorc.deger,
        100000,
        reason: 'devir toplam borca karışmaz',
      );
    });

    test('boş liste sıfır bakiye verir', () {
      final dokum = BakiyeHesaplayici.ileri(islemler: <Islem>[]);

      expect(dokum.bosMu, isTrue);
      expect(dokum.bakiye, Kurus.sifir);
    });

    test('aynı güne düşen işlemler kimlik sırasıyla dizilir', () {
      final ayniGun = DateTime(2024, 5, 1);
      final dokum = BakiyeHesaplayici.ileri(
        islemler: <Islem>[
          islem('2', IslemTipi.tahsilat, 400, tarih: ayniGun),
          islem('1', IslemTipi.satisFaturasi, 1000, tarih: ayniGun),
        ],
      );

      expect(dokum.satirlar.map((satir) => satir.islem.id), <String>['1', '2']);
      expect(
        dokum.satirlar.map((satir) => satir.yuruyenBakiye.deger),
        <int>[100000, 60000],
      );
    });
  });

  group('İptal edilmiş işlem', () {
    test('bakiyeye katılmaz', () {
      final dokum = BakiyeHesaplayici.ileri(
        islemler: <Islem>[
          islem('1', IslemTipi.satisFaturasi, 1000),
          islem('2', IslemTipi.tahsilat, 400, iptal: true),
        ],
      );

      expect(dokum.bakiye.deger, 100000);
      expect(dokum.satirlar.last.yuruyenBakiye.deger, 100000);
    });

    test('borç ve alacak kolonlarında da görünmez', () {
      final iptalli = islem('1', IslemTipi.satisFaturasi, 1000, iptal: true);

      expect(iptalli.borc, Kurus.sifir);
      expect(iptalli.alacak, Kurus.sifir);
      expect(iptalli.bakiyeEtkisi, Kurus.sifir);
      expect(iptalli.iptalMi, isTrue);
    });

    test('listeden düşmez — üstü çizili göstermek için satırı durur', () {
      final dokum = BakiyeHesaplayici.ileri(
        islemler: <Islem>[islem('1', IslemTipi.tahsilat, 400, iptal: true)],
      );

      expect(dokum.satirlar, hasLength(1));
      expect(dokum.toplamAlacak, Kurus.sifir);
    });

    test('eski kayıttaki durum:iptal de bakiyeye girmez', () {
      final eski = Islem.fromMap('1', const <String, Object?>{
        Islem.alanTip: 'satisFaturasi',
        Islem.alanToplamKurus: 10000,
        Islem.alanEskiDurum: 'iptal',
      });

      expect(eski.iptalMi, isTrue);
      expect(eski.bakiyeEtkisi, Kurus.sifir);
    });
  });

  group('BakiyeHesaplayici.geriye', () {
    test('önbelleklenmiş bakiyeden geriye sayar', () {
      final islemler = <Islem>[
        islem('1', IslemTipi.satisFaturasi, 1000),
        islem('2', IslemTipi.tahsilat, 400),
        islem('3', IslemTipi.tahsilat, 100),
      ];
      final sonBakiye = BakiyeHesaplayici.bakiye(islemler);

      final dokum = BakiyeHesaplayici.geriye(
        islemler: islemler,
        sonBakiye: sonBakiye,
      );

      expect(dokum.satirlar.map((satir) => satir.islem.id), <String>[
        '3',
        '2',
        '1',
      ]);
      expect(
        dokum.satirlar.map((satir) => satir.yuruyenBakiye.deger),
        <int>[50000, 60000, 100000],
      );
      expect(dokum.devir, Kurus.sifir);
    });

    test('eksik sayfada devir, sayfadan önceki bakiyeyi verir', () {
      final dokum = BakiyeHesaplayici.geriye(
        islemler: <Islem>[islem('3', IslemTipi.tahsilat, 100)],
        sonBakiye: Kurus.liradan(500),
      );

      expect(dokum.satirlar.single.yuruyenBakiye.deger, 50000);
      expect(dokum.devir.deger, 60000);
    });
  });

  group('BakiyeHesaplayici.bakiye', () {
    test('yeniden hesaplama, yürüyen bakiyenin son değerine eşit', () {
      final islemler = <Islem>[
        islem('1', IslemTipi.satisFaturasi, 1000),
        islem('2', IslemTipi.tahsilat, 400),
        islem('3', IslemTipi.alisFaturasi, 200),
        islem('4', IslemTipi.odeme, 50),
      ];

      final dokum = BakiyeHesaplayici.ileri(islemler: islemler);

      expect(BakiyeHesaplayici.bakiye(islemler), dokum.bakiye);
      expect(dokum.bakiye.deger, 45000);
    });
  });
}
