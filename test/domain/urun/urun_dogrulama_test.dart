import 'package:fidancari/domain/urun/urun_dogrulama.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrunDogrulama.ad', () {
    test('boş ad reddedilir', () {
      expect(UrunDogrulama.ad(''), isNotNull);
      expect(UrunDogrulama.ad('   '), isNotNull);
      expect(UrunDogrulama.ad(null), isNotNull);
    });

    test('tek harflik ad reddedilir', () {
      expect(UrunDogrulama.ad('E'), isNotNull);
    });

    test('geçerli ad kabul edilir', () {
      expect(UrunDogrulama.ad('çam'), isNull);
      expect(UrunDogrulama.ad('Elma Scarlet M9 2 yaş tüplü'), isNull);
      expect(UrunDogrulama.ad('  nakliye  '), isNull);
    });
  });

  group('UrunDogrulama.fiyat', () {
    test('boş fiyat kabul edilir — isteğe bağlı alan', () {
      expect(UrunDogrulama.fiyat(''), isNull);
      expect(UrunDogrulama.fiyat(null), isNull);
    });

    test('geçerli tutar kabul edilir', () {
      expect(UrunDogrulama.fiyat('45'), isNull);
      expect(UrunDogrulama.fiyat('31.000,00'), isNull);
      expect(UrunDogrulama.fiyat('18,79'), isNull);
    });

    test('geçersiz tutar reddedilir', () {
      expect(UrunDogrulama.fiyat('abc'), isNotNull);
      expect(UrunDogrulama.fiyat(','), isNotNull);
    });

    test('negatif fiyat reddedilir', () {
      expect(UrunDogrulama.fiyat('-45'), isNotNull);
    });
  });
}
