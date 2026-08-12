import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/core/para/yuvarlama.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bolVeYuvarla', () {
    test('tam bölünen değerler olduğu gibi döner', () {
      expect(bolVeYuvarla(100, 4), 25);
      expect(bolVeYuvarla(0, 7), 0);
    });

    test('yarım sıfırdan uzağa yuvarlanır', () {
      expect(bolVeYuvarla(5, 2), 3);
      expect(bolVeYuvarla(-5, 2), -3);
    });

    test('yarımın altı aşağı, üstü yukarı yuvarlanır', () {
      expect(bolVeYuvarla(4, 3), 1); // 1,33
      expect(bolVeYuvarla(5, 3), 2); // 1,67
    });

    test('negatif payda işareti doğru taşır', () {
      expect(bolVeYuvarla(10, -4), -3);
      expect(bolVeYuvarla(-10, -4), 3);
    });

    test('sıfıra bölme reddedilir', () {
      expect(() => bolVeYuvarla(1, 0), throwsArgumentError);
    });
  });

  group('yuzdesi — KDV hesabı', () {
    test('referans ekstredeki %1 KDV birebir tutar', () {
      // Kalemler toplamı 140.625,00 ₺ -> KDV 1.406,25 ₺ -> toplam 142.031,25 ₺
      const araToplam = Kurus(14062500);
      final kdv = yuzdesi(araToplam, 1);

      expect(kdv.deger, 140625);
      expect((araToplam + kdv).deger, 14203125);
    });

    test('sıfır oran sıfır KDV üretir', () {
      expect(yuzdesi(const Kurus(9400000), 0), Kurus.sifir);
    });

    test('yuvarlama gerektiren oran en yakın kuruşa iner', () {
      // 33,33 ₺ -> %1 = 0,3333 ₺ -> 0,33 ₺
      expect(yuzdesi(const Kurus(3333), 1).deger, 33);
    });
  });

  group('birimFiyatHesapla — toplamdan geriye hesap', () {
    test('referans ekstredeki Hurma kalemini üretir', () {
      // 1.650 adet, toplam 31.000,00 ₺ -> birim fiyat 18,79 ₺
      // Gerçek değer 18,787878... — ekstrede 18,79 olarak basılmış.
      final birimFiyat = birimFiyatHesapla(
        toplam: const Kurus(3100000),
        miktar: 1650,
      );
      expect(birimFiyat.deger, 1879);
    });

    test('yuvarlanmış birim fiyattan yeniden çarpım toplamı bozar', () {
      // Bu test, KURALLAR.md §3.2'deki kuralın neden var olduğunu sabitler:
      // girilen toplam esastır, birim fiyattan yeniden hesaplanmaz.
      const girilenToplam = Kurus(3100000);
      final birimFiyat = birimFiyatHesapla(toplam: girilenToplam, miktar: 1650);
      final yenidenHesap = kalemTutari(miktar: 1650, birimFiyat: birimFiyat);

      expect(yenidenHesap.deger, 3100350); // 31.003,50 ₺ — yanlış
      expect(girilenToplam.deger, 3100000); // 31.000,00 ₺ — doğru olan bu
      expect(yenidenHesap, isNot(girilenToplam));
    });

    test('tam bölünen kalem sapma üretmez', () {
      // zeytin: 7.000 adet, toplam 49.000,00 ₺ -> 7,00 ₺
      final birimFiyat = birimFiyatHesapla(
        toplam: const Kurus(4900000),
        miktar: 7000,
      );
      expect(birimFiyat.deger, 700);
      expect(kalemTutari(miktar: 7000, birimFiyat: birimFiyat).deger, 4900000);
    });

    test('sıfır veya negatif miktar reddedilir', () {
      expect(
        () => birimFiyatHesapla(toplam: const Kurus(100), miktar: 0),
        throwsArgumentError,
      );
      expect(
        () => birimFiyatHesapla(toplam: const Kurus(100), miktar: -5),
        throwsArgumentError,
      );
    });
  });

  group('kalemTutari', () {
    test('referans ekstrenin ikinci faturası tam toplanır', () {
      // hachiya 3.000 x 60,00 + çam 250 x 60,00 + zeytin 250 x 100,00
      final hachiya = kalemTutari(miktar: 3000, birimFiyat: const Kurus(6000));
      final cam = kalemTutari(miktar: 250, birimFiyat: const Kurus(6000));
      final zeytin = kalemTutari(miktar: 250, birimFiyat: const Kurus(10000));

      expect(kurusTopla([hachiya, cam, zeytin]).deger, 22000000); // 220.000,00 ₺
    });

    test('negatif miktar reddedilir', () {
      expect(
        () => kalemTutari(miktar: -1, birimFiyat: const Kurus(100)),
        throwsArgumentError,
      );
    });
  });
}
