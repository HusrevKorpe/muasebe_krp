import 'package:fidancari/domain/urun/urun_dogrulama.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrunDogrulama.tur', () {
    test('boş tür reddedilir', () {
      expect(UrunDogrulama.tur(''), isNotNull);
      expect(UrunDogrulama.tur('   '), isNotNull);
      expect(UrunDogrulama.tur(null), isNotNull);
    });

    test('tek harflik tür reddedilir', () {
      expect(UrunDogrulama.tur('E'), isNotNull);
    });

    test('geçerli tür kabul edilir', () {
      expect(UrunDogrulama.tur('çam'), isNull);
      expect(UrunDogrulama.tur('Elma'), isNull);
      // Serbest kalemin tamamı türe yazılır; çeşit ve anaç boş kalır.
      expect(UrunDogrulama.tur('  nakliye  '), isNull);
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
