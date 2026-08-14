import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/domain/islem/islem_kalemi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IslemKalemi.birimFiyattan', () {
    test('tutar = miktar × birim fiyat, yuvarlama yok', () {
      final kalem = IslemKalemi.birimFiyattan(
        tur: 'zeytin',
        miktar: 7000,
        birimFiyat: Kurus.liradan(7),
      );

      expect(kalem.tutar.deger, 4900000);
      expect(kalem.birimFiyat.deger, 700);
      expect(kalem.birimFiyatYuvarlanmisMi, isFalse);
    });

    test('kuruşlu birim fiyat tam çarpılır', () {
      final kalem = IslemKalemi.birimFiyattan(
        tur: 'fidan',
        miktar: 3,
        birimFiyat: Kurus.liradan(18, 79),
      );

      expect(kalem.tutar.deger, 5637);
    });
  });

  group('IslemKalemi.toplamdan — birim fiyat geri hesabı', () {
    test('31.000 ₺ ÷ 1.650 adet → 18,79 ₺ gösterilir, toplam korunur', () {
      final kalem = IslemKalemi.toplamdan(
        tur: 'Hurma',
        miktar: 1650,
        toplam: Kurus.liradan(31000),
      );

      expect(kalem.tutar.deger, 3100000);
      expect(kalem.birimFiyat.deger, 1879);
      expect(kalem.birimFiyatYuvarlanmisMi, isTrue);
    });

    test('tam bölünen toplamda yuvarlama izi kalmaz', () {
      final kalem = IslemKalemi.toplamdan(
        tur: 'elma',
        miktar: 600,
        toplam: Kurus.liradan(27000),
      );

      expect(kalem.birimFiyat.deger, 4500);
      expect(kalem.birimFiyatYuvarlanmisMi, isFalse);
    });

    test('yarım kuruş yukarı yuvarlanır', () {
      // 100 kuruş ÷ 8 = 12,5 kuruş → 13 kuruş.
      final kalem = IslemKalemi.toplamdan(
        tur: 'fidan',
        miktar: 8,
        toplam: const Kurus(100),
      );

      expect(kalem.birimFiyat.deger, 13);
      expect(kalem.tutar.deger, 100, reason: 'girilen toplam değişmez');
    });

    test('sıfır miktar reddedilir', () {
      expect(
        () => IslemKalemi.toplamdan(
          tur: 'fidan',
          miktar: 0,
          toplam: Kurus.liradan(100),
        ),
        throwsArgumentError,
      );
    });
  });

  group('fidan kimliği', () {
    test('ad üç parçadan türetilir', () {
      final kalem = IslemKalemi.birimFiyattan(
        tur: 'Elma',
        cesit: 'Scarlet',
        anac: 'M9',
        miktar: 600,
        birimFiyat: Kurus.liradan(45),
      );

      expect(kalem.ad, 'Elma Scarlet M9');
    });

    test('serbest kalemde yalnızca tür dolar', () {
      final kalem = IslemKalemi.birimFiyattan(
        tur: 'nakliye',
        miktar: 1,
        birimFiyat: Kurus.liradan(2500),
      );

      expect(kalem.ad, 'nakliye');
      expect(kalem.cesit, '');
      expect(kalem.anac, '');
    });

    test('parçalar belgeye ayrı ayrı yazılır', () {
      final kalem = IslemKalemi.birimFiyattan(
        tur: 'Elma',
        cesit: 'Scarlet',
        anac: 'M9',
        miktar: 600,
        birimFiyat: Kurus.liradan(45),
      );

      final veri = kalem.toMap();

      expect(veri[IslemKalemi.alanTur], 'Elma');
      expect(veri[IslemKalemi.alanCesit], 'Scarlet');
      expect(veri[IslemKalemi.alanAnac], 'M9');
      expect(veri[IslemKalemi.alanAd], 'Elma Scarlet M9');
    });

    test('anacı farklı iki kalem eşit değildir', () {
      IslemKalemi kalem(String anac) => IslemKalemi.birimFiyattan(
        tur: 'Elma',
        cesit: 'Scarlet',
        anac: anac,
        miktar: 600,
        birimFiyat: Kurus.liradan(45),
      );

      expect(kalem('M9'), isNot(kalem('MM106')));
    });
  });

  group('katalog bağı', () {
    test('katalogdan seçilen kalem fidanId taşır', () {
      final kalem = IslemKalemi.birimFiyattan(
        tur: 'Elma',
        cesit: 'Scarlet',
        anac: 'M9',
        miktar: 600,
        birimFiyat: Kurus.liradan(45),
        urunId: 'fidan-1',
      );

      expect(kalem.urunId, 'fidan-1');
      expect(kalem.toMap()[IslemKalemi.alanUrunId], 'fidan-1');
    });

    test('serbest metin kalemde fidanId boş kalır', () {
      // "nakliye" katalogda yok; katalog zorunlu olmamalı (Faz 3 kriteri 5).
      final kalem = IslemKalemi.birimFiyattan(
        tur: 'nakliye',
        miktar: 1,
        birimFiyat: Kurus.liradan(2500),
      );

      expect(kalem.urunId, isNull);
      expect(kalem.toMap()[IslemKalemi.alanUrunId], isNull);
    });

    test('Faz 2\'de fidanId olmadan yazılmış kalem bozulmadan okunur', () {
      final kalem = IslemKalemi.fromMap(const <String, Object?>{
        IslemKalemi.alanAd: 'zeytin',
        IslemKalemi.alanMiktar: 7000,
        IslemKalemi.alanBirimFiyatKurus: 700,
        IslemKalemi.alanTutarKurus: 4900000,
      });

      expect(kalem.urunId, isNull);
      expect(kalem.ad, 'zeytin');
      expect(kalem.tutar.deger, 4900000);
    });
  });

  group('fromMap / toMap', () {
    test('gidiş-dönüşte alan kaybı olmaz', () {
      final kalem = IslemKalemi.toplamdan(
        tur: 'Hurma',
        cesit: 'Karışık',
        miktar: 1650,
        toplam: Kurus.liradan(31000),
        urunId: 'fidan-1',
        birim: 'adet',
      );

      final donen = IslemKalemi.fromMap(kalem.toMap());

      expect(donen, kalem);
      expect(donen.tutar.deger, 3100000);
      expect(donen.birimFiyat.deger, 1879);
      expect(donen.urunId, 'fidan-1');
    });

    test('tutar ve birim fiyat ayrı ayrı saklanır', () {
      final kalem = IslemKalemi.toplamdan(
        tur: 'Hurma',
        miktar: 1650,
        toplam: Kurus.liradan(31000),
      );

      final veri = kalem.toMap();

      expect(veri[IslemKalemi.alanTutarKurus], 3100000);
      expect(veri[IslemKalemi.alanBirimFiyatKurus], 1879);
      expect(
        veri[IslemKalemi.alanTutarKurus],
        isA<int>(),
        reason: 'para Firestore\'a da int yazılır',
      );
    });

    test('eksik alanlar varsayılana düşer, patlamaz', () {
      final kalem = IslemKalemi.fromMap(const <String, Object?>{});

      expect(kalem.ad, '');
      expect(kalem.miktar, 0);
      expect(kalem.tutar, Kurus.sifir);
      expect(kalem.birim, IslemKalemi.varsayilanBirim);
    });

    test('eski kayıtta double yazılmış tutar yuvarlanarak okunur', () {
      final kalem = IslemKalemi.fromMap(const <String, Object?>{
        IslemKalemi.alanAd: 'fidan',
        IslemKalemi.alanTutarKurus: 3100000.4,
      });

      expect(kalem.tutar.deger, 3100000);
    });
  });

  // Kalem üçe bölünmeden önce girilmiş faturalar yalnızca `ad` taşıyor. Geçmiş
  // fatura yeniden yazılmıyor; okuma düşerse eski ekstreler adsız çıkar.
  group('Bölünmeden önceki kalem uyumu', () {
    test('tek adlı eski kalem olduğu gibi türe düşer', () {
      final kalem = IslemKalemi.fromMap(const <String, Object?>{
        IslemKalemi.alanAd: 'Elma Scarlet M9',
        IslemKalemi.alanMiktar: 600,
        IslemKalemi.alanTutarKurus: 2700000,
      });

      expect(kalem.tur, 'Elma Scarlet M9');
      expect(kalem.cesit, '');
      expect(kalem.anac, '');
      expect(kalem.ad, 'Elma Scarlet M9');
    });

    test('parçalar varsa türetilmiş adın önüne geçer', () {
      final kalem = IslemKalemi.fromMap(const <String, Object?>{
        IslemKalemi.alanTur: 'Elma',
        IslemKalemi.alanCesit: 'Scarlet',
        IslemKalemi.alanAnac: 'M9',
        IslemKalemi.alanAd: 'Elma Scarlet M9',
        IslemKalemi.alanMiktar: 600,
      });

      expect(kalem.cesit, 'Scarlet');
      expect(kalem.ad, 'Elma Scarlet M9');
    });
  });
}
