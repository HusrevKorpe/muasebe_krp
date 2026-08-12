import 'package:fidancari/core/para/kurus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Kurus.liradan', () {
    test('lira ve kuruş parçalarını birleştirir', () {
      expect(Kurus.liradan(94000).deger, 9400000);
      expect(Kurus.liradan(18, 79).deger, 1879);
      expect(Kurus.liradan(0, 5).deger, 5);
    });

    test('negatif lirada kuruş işareti doğru uygulanır', () {
      expect(Kurus.liradan(-12031, 25).deger, -1203125);
    });

    test('geçersiz kuruş reddedilir', () {
      expect(() => Kurus.liradan(1, 100), throwsArgumentError);
      expect(() => Kurus.liradan(1, -1), throwsArgumentError);
    });
  });

  group('parçalar', () {
    test('lira ve kuruş kısımları işaretsiz döner', () {
      const tutar = Kurus(-1203125);
      expect(tutar.liraKismi, 12031);
      expect(tutar.kurusKismi, 25);
    });
  });

  group('aritmetik', () {
    test('toplama ve çıkarma sapma üretmez', () {
      // double ile 0.1 + 0.2 != 0.3 olurdu.
      const on = Kurus(10);
      const yirmi = Kurus(20);
      expect((on + yirmi).deger, 30);
    });

    test('referans ekstrenin ilk faturası kalemlerden tam toplanır', () {
      // zeytin 49.000 + hurma 31.000 + nakliye 14.000 = 94.000,00 ₺
      final toplam = kurusTopla(const [
        Kurus(4900000),
        Kurus(3100000),
        Kurus(1400000),
      ]);
      expect(toplam.deger, 9400000);
    });

    test('miktarla çarpma', () {
      expect((const Kurus(700) * 7000).deger, 4900000);
    });

    test('eksi işleci değeri ters çevirir', () {
      expect((-const Kurus(500)).deger, -500);
    });

    test('boş liste sıfır döner', () {
      expect(kurusTopla(const []), Kurus.sifir);
    });
  });

  group('karşılaştırma', () {
    test('eşitlik değere göredir', () {
      expect(const Kurus(100), const Kurus(100));
      expect(const Kurus(100).hashCode, const Kurus(100).hashCode);
    });

    test('sıralama işleçleri', () {
      expect(const Kurus(100) < const Kurus(200), isTrue);
      expect(const Kurus(200) >= const Kurus(200), isTrue);
      expect(const Kurus(-100) < Kurus.sifir, isTrue);
    });

    test('işaret sorguları', () {
      expect(const Kurus(-1).negatifMi, isTrue);
      expect(const Kurus(1).pozitifMi, isTrue);
      expect(Kurus.sifir.sifirMi, isTrue);
      expect(const Kurus(-500).mutlak.deger, 500);
    });
  });
}
