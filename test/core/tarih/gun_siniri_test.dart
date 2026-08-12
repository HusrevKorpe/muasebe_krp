import 'package:fidancari/core/tarih/gun_siniri.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('gunBasi', () {
    test('saat bilgisini atar', () {
      expect(gunBasi(DateTime(2021, 9, 17, 14, 35, 12)), DateTime(2021, 9, 17));
    });
  });

  group('gunSonu', () {
    test('günün son milisaniyesini verir', () {
      expect(
        gunSonu(DateTime(2021, 9, 17, 8)),
        DateTime(2021, 9, 17, 23, 59, 59, 999),
      );
    });

    test('ay sonunda bir sonraki aya taşmaz', () {
      expect(
        gunSonu(DateTime(2024, 2, 29)),
        DateTime(2024, 2, 29, 23, 59, 59, 999),
      );
      expect(
        gunSonu(DateTime(2024, 12, 31)),
        DateTime(2024, 12, 31, 23, 59, 59, 999),
      );
    });

    test('o gün girilen işlem sınırın içinde kalır', () {
      final sinir = gunSonu(DateTime(2025, 5, 24));

      expect(DateTime(2025, 5, 24, 23, 30).isAfter(sinir), isFalse);
      expect(DateTime(2025, 5, 25).isAfter(sinir), isTrue);
    });
  });
}
