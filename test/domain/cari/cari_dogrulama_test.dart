import 'package:fidancari/domain/cari/cari_dogrulama.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ad', () {
    test('boş ad reddedilir', () {
      expect(CariDogrulama.ad(null), isNotNull);
      expect(CariDogrulama.ad(''), isNotNull);
      expect(CariDogrulama.ad('   '), isNotNull);
    });

    test('tek harflik ad reddedilir', () {
      expect(CariDogrulama.ad('A'), isNotNull);
    });

    test('geçerli ad kabul edilir', () {
      expect(CariDogrulama.ad('Ahmet Koyuncu'), isNull);
      expect(CariDogrulama.ad('  Ali  '), isNull);
    });
  });

  group('vergiNo', () {
    test('boş bırakılabilir', () {
      expect(CariDogrulama.vergiNo(null), isNull);
      expect(CariDogrulama.vergiNo(''), isNull);
    });

    test('geçerli VKN ve TCKN kabul edilir', () {
      expect(CariDogrulama.vergiNo('1234567899'), isNull);
      expect(CariDogrulama.vergiNo('12345678950'), isNull);
    });

    test('hane sayısı tutmuyorsa uzunluk mesajı verilir', () {
      expect(
        CariDogrulama.vergiNo('12345'),
        contains('10, T.C. kimlik no 11'),
      );
    });

    test('hane sayısı doğru ama kontrol hanesi bozuksa reddedilir', () {
      expect(CariDogrulama.vergiNo('1234567890'), isNotNull);
      expect(CariDogrulama.vergiNo('12345678951'), isNotNull);
    });
  });

  group('telefon', () {
    test('boş bırakılabilir', () {
      expect(CariDogrulama.telefon(null), isNull);
      expect(CariDogrulama.telefon(''), isNull);
    });

    test('biçim serbest, yeter ki hane sayısı anlamlı olsun', () {
      expect(CariDogrulama.telefon('0246 000 00 00'), isNull);
      expect(CariDogrulama.telefon('+90 532 000 0000'), isNull);
      expect(CariDogrulama.telefon('5320000000'), isNull);
    });

    test('çok kısa numara reddedilir', () {
      expect(CariDogrulama.telefon('12345'), isNotNull);
    });
  });
}
