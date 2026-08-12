import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/core/para/para_bicimi.dart';
import 'package:fidancari/core/para/para_girisi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kurusAyristir', () {
    test('düz tam sayı', () {
      expect(kurusAyristir('94000')?.deger, 9400000);
    });

    test('binlik ayraçlı', () {
      expect(kurusAyristir('94.000')?.deger, 9400000);
      expect(kurusAyristir('1.234.567')?.deger, 123456700);
    });

    test('ondalık virgüllü', () {
      expect(kurusAyristir('18,79')?.deger, 1879);
      expect(kurusAyristir('94000,50')?.deger, 9400050);
    });

    test('binlik ve ondalık birlikte', () {
      expect(kurusAyristir('142.031,25')?.deger, 14203125);
      expect(kurusAyristir('-12.031,25')?.deger, -1203125);
    });

    test('tek haneli ondalık sonda sıfırla tamamlanır', () {
      expect(kurusAyristir('1,5')?.deger, 150);
      expect(kurusAyristir('1,05')?.deger, 105);
    });

    test('nokta ondalık ayracı olarak da kabul edilir', () {
      // Son gruptaki hane sayısı ayracın hangisi olduğunu belirler:
      // `18.79` iki hane → ondalık, `1.234` üç hane → binlik.
      expect(kurusAyristir('18.79')?.deger, 1879);
      expect(kurusAyristir('1.234')?.deger, 123400);
    });

    test('para simgesi ve boşluk göz ardı edilir', () {
      expect(kurusAyristir(' 94.000,00 ₺ ')?.deger, 9400000);
    });

    test('virgülle biten girdi tam sayı sayılır', () {
      expect(kurusAyristir('94,')?.deger, 9400);
    });

    test('ondalıkla başlayan girdi okunur', () {
      expect(kurusAyristir(',50')?.deger, 50);
    });

    test('sıfır geçerli bir tutardır', () {
      expect(kurusAyristir('0')?.deger, 0);
      expect(kurusAyristir('0,00')?.deger, 0);
    });

    test('geçersiz girdide null döner — sessizce sıfırlanmaz', () {
      expect(kurusAyristir(null), isNull);
      expect(kurusAyristir(''), isNull);
      expect(kurusAyristir('   '), isNull);
      expect(kurusAyristir('abc'), isNull);
      expect(kurusAyristir('12a'), isNull);
      expect(kurusAyristir(','), isNull);
      expect(kurusAyristir('.'), isNull);
      expect(kurusAyristir('1,2,3'), isNull);
    });

    test('ikiden fazla ondalık hane reddedilir', () {
      // Kuruş iki hanedir; `18,787878` sessizce kırpılırsa kullanıcı
      // kaydettiğinden farklı bir tutar görür.
      expect(kurusAyristir('18,787878'), isNull);
      expect(kurusAyristir('18,791'), isNull);
    });

    test('biçimlenen değer geri okunduğunda aynı kalır', () {
      for (final deger in <int>[0, 5, 100, 1879, 9400000, -1203125]) {
        final tutar = Kurus(deger);
        expect(
          kurusAyristir(kurusMetni(tutar)),
          tutar,
          reason: '${tutar.bicimliSimgesiz} gidiş-dönüşte değişmemeli',
        );
      }
    });
  });

  group('miktarAyristir', () {
    test('binlik ayraçlı miktar okunur', () {
      expect(miktarAyristir('7.000'), 7000);
      expect(miktarAyristir('1650'), 1650);
    });

    test('ondalıklı miktar reddedilir', () {
      expect(miktarAyristir('1,5'), isNull);
    });

    test('geçersiz girdide null döner', () {
      expect(miktarAyristir(''), isNull);
      expect(miktarAyristir('adet'), isNull);
      expect(miktarAyristir(null), isNull);
    });
  });
}
