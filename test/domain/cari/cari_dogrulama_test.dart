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
