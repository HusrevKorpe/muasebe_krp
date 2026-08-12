import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/core/para/para_bicimi.dart';
import 'package:fidancari/domain/islem/bakiye_hesaplayici.dart';
import 'package:fidancari/domain/islem/islem.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ornek/referans_ekstre.dart';

/// Fazın ana doğruluk ölçütü: referans ekstredeki dokuz işlem girildiğinde
/// ürettiğimiz bakiye kolonu, PDF'teki kolonla kuruşu kuruşuna aynı olmalı
/// (bkz. `fazlar/faz-2-islemler.md`, kabul kriteri 2).
void main() {
  group('Referans ekstre — dokuz işlem', () {
    test('yürüyen bakiye kolonu PDF ile birebir aynı', () {
      final dokum = BakiyeHesaplayici.ileri(islemler: referansIslemleri);

      expect(dokum.satirlar, hasLength(referansIslemleri.length));
      for (var sira = 0; sira < beklenenBakiyeler.length; sira++) {
        final satir = dokum.satirlar[sira];
        expect(
          satir.yuruyenBakiye.deger,
          beklenenBakiyeler[sira],
          reason:
              '${sira + 1}. satır (${satir.islem.baslik}) beklenen '
              '${Kurus(beklenenBakiyeler[sira]).bicimli}, '
              'çıkan ${satir.yuruyenBakiye.bicimli}',
        );
      }
    });

    test('satırlar ekstredeki sırayla dizilir', () {
      final dokum = BakiyeHesaplayici.ileri(islemler: referansIslemleri);

      expect(
        dokum.satirlar.map((satir) => satir.islem.id),
        <String>['01', '02', '03', '04', '05', '06', '07', '08', '09'],
      );
    });

    test('karışık sırada verilse de aynı kolonu üretir', () {
      final karisik = referansIslemleri.reversed.toList();

      final dokum = BakiyeHesaplayici.ileri(islemler: karisik);

      expect(
        dokum.satirlar.map((satir) => satir.yuruyenBakiye.deger),
        beklenenBakiyeler,
      );
    });

    test('toplam borç, toplam alacak ve bakiye ekstrenin son sayfasıyla aynı',
        () {
      final dokum = BakiyeHesaplayici.ileri(islemler: referansIslemleri);

      expect(dokum.toplamBorc.deger, beklenenToplamBorc);
      expect(dokum.toplamAlacak.deger, beklenenToplamAlacak);
      expect(dokum.bakiye.deger, beklenenBakiye);
      expect(dokum.bakiye.bicimli, '-12.031,25 ₺');
    });

    test('bakiye = toplam borç − toplam alacak', () {
      final dokum = BakiyeHesaplayici.ileri(islemler: referansIslemleri);

      expect(dokum.bakiye, dokum.toplamBorc - dokum.toplamAlacak);
    });

    test('son bakiye negatif — cari hem müşteri hem tedarikçi', () {
      final bakiye = BakiyeHesaplayici.bakiye(referansIslemleri);

      expect(bakiye.negatifMi, isTrue, reason: 'işletme cariye borçlu kalır');
      expect(bakiye.deger, beklenenBakiye);
    });
  });

  group('Zeytin-Hurma faturası — kabul kriteri 4', () {
    test('fatura toplamı 94.000,00 ₺ — 94.003,50 değil', () {
      expect(zeytinHurmaFaturasi.toplam.deger, 9400000);
      expect(zeytinHurmaFaturasi.toplam.bicimli, '94.000,00 ₺');
    });

    test('Hurma kalemi: toplam 31.000 ₺ girilir, birim fiyat 18,79 ₺ görünür',
        () {
      final hurma = zeytinHurmaFaturasi.kalemler[1];

      expect(hurma.tutar.deger, 3100000, reason: 'girilen toplam esastır');
      expect(hurma.birimFiyat.bicimli, '18,79 ₺');
      expect(hurma.miktar, 1650);
    });

    test('yuvarlanmış birim fiyattan çarpım tutarı vermez — ekranda işaretlenir',
        () {
      final hurma = zeytinHurmaFaturasi.kalemler[1];

      expect(hurma.birimFiyatYuvarlanmisMi, isTrue);
      expect(
        (hurma.birimFiyat * hurma.miktar).deger,
        3100350,
        reason: 'çarpım 31.003,50 çıkar; bu yüzden tutar ayrıca saklanıyor',
      );
    });

    test('birim fiyattan girilen kalemlerde yuvarlama yok', () {
      final zeytin = zeytinHurmaFaturasi.kalemler.first;
      final nakliye = zeytinHurmaFaturasi.kalemler.last;

      expect(zeytin.tutar.deger, 4900000);
      expect(zeytin.birimFiyatYuvarlanmisMi, isFalse);
      expect(nakliye.tutar.deger, 1400000);
      expect(nakliye.birimFiyatYuvarlanmisMi, isFalse);
    });

    test('KDV uygulanmadı — toplam ara toplama eşit', () {
      expect(zeytinHurmaFaturasi.kdvOrani, 0);
      expect(zeytinHurmaFaturasi.kdv, Kurus.sifir);
      expect(zeytinHurmaFaturasi.toplam, zeytinHurmaFaturasi.araToplam);
    });
  });

  group('Sert Çekirdekli faturası — kabul kriteri 3', () {
    test('%1 KDV: 140.625,00 ₺ → 142.031,25 ₺', () {
      expect(sertCekirdekliFaturasi.araToplam.deger, 14062500);
      expect(sertCekirdekliFaturasi.kdvOrani, 1);
      expect(sertCekirdekliFaturasi.kdv.deger, 140625);
      expect(sertCekirdekliFaturasi.toplam.deger, 14203125);
      expect(sertCekirdekliFaturasi.toplam.bicimli, '142.031,25 ₺');
    });

    test('alış faturası alacak kolonuna yazılır, bakiyeyi düşürür', () {
      expect(sertCekirdekliFaturasi.borc, Kurus.sifir);
      expect(sertCekirdekliFaturasi.alacak.deger, 14203125);
      expect(sertCekirdekliFaturasi.bakiyeEtkisi.deger, -14203125);
    });
  });

  group('Hachiya faturası', () {
    test('üç kalem toplamı 220.000,00 ₺', () {
      expect(hachiyaFaturasi.toplam.deger, 22000000);
      expect(hachiyaFaturasi.kalemler, hasLength(3));
    });
  });

  group('Yeniden hesaplama — kabul kriteri 6', () {
    test('geriye yürüyen hesap, ileri hesapla aynı kolonu verir', () {
      final ileri = BakiyeHesaplayici.ileri(islemler: referansIslemleri);
      final geriye = BakiyeHesaplayici.geriye(
        islemler: referansIslemleri,
        sonBakiye: ileri.bakiye,
      );

      // Geriye hesap ekranın sırasını kullanır: en yeni işlem en üstte.
      expect(
        geriye.satirlar.map((satir) => satir.yuruyenBakiye.deger).toList(),
        ileri.satirlar.reversed
            .map((satir) => satir.yuruyenBakiye.deger)
            .toList(),
      );
      expect(geriye.devir, Kurus.sifir);
    });

    test('sayfa sayfa okunsa da bakiye kaymaz', () {
      final tumu = BakiyeHesaplayici.ileri(islemler: referansIslemleri);
      // Ekranın ilk sayfası: en yeni dört işlem.
      final ilkSayfa = <Islem>[
        sertCekirdekliFaturasi,
        tahsilatlar[5],
        tahsilatlar[4],
        hachiyaFaturasi,
      ];

      final dokum = BakiyeHesaplayici.geriye(
        islemler: ilkSayfa,
        sonBakiye: tumu.bakiye,
      );

      expect(
        dokum.satirlar.map((satir) => satir.yuruyenBakiye.deger),
        <int>[-1203125, 13000000, 17000000, 22000000],
      );
      expect(
        dokum.devir.deger,
        0,
        reason: 'dördüncü satırdan önceki bakiye sıfırdı',
      );
    });
  });
}
