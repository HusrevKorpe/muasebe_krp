import 'package:fidancari/domain/secenek/secenek_tipi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('anahtardan', () {
    test('her tip kendi anahtarından geri okunur', () {
      for (final tip in SecenekTipi.values) {
        expect(SecenekTipi.anahtardan(tip.anahtar), tip);
      }
    });

    test('tanınmayan anahtar null döner', () {
      // Gezinme yolundan gelen değer eski bir sürümden kalmış olabilir;
      // çağıran taraf ne yapacağına kendi karar verir.
      expect(SecenekTipi.anahtardan('kokTipi'), isNull);
      expect(SecenekTipi.anahtardan(null), isNull);
      expect(SecenekTipi.anahtardan(''), isNull);
    });
  });

  group('koleksiyon', () {
    test('üç tip ayrı koleksiyonda durur', () {
      final koleksiyonlar = SecenekTipi.values
          .map((tip) => tip.koleksiyon)
          .toSet();

      // Çakışan iki ad, iki listenin birbirinin kayıtlarını göstermesi demek.
      expect(koleksiyonlar, hasLength(SecenekTipi.values.length));
    });

    test('koleksiyon adları var olan koleksiyonlarla çakışmaz', () {
      // `fidanlar`, `cariler`, `islemler` kullanımda; bir çakışma iki ayrı
      // veriyi aynı yola yazardı.
      const kullanimda = <String>{'fidanlar', 'cariler', 'islemler'};

      for (final tip in SecenekTipi.values) {
        expect(kullanimda.contains(tip.koleksiyon), isFalse);
      }
    });
  });
}
