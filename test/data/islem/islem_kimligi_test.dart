import 'package:fidancari/data/islem/islem_kimligi.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kimlik sıralaması, aynı güne düşen işlemlerin ekstredeki sırasını belirler
/// (bkz. `domain/islem/islem_siralamasi.dart`).
void main() {
  group('yeniIslemKimligi', () {
    test('sonra üretilen kimlik metin sırasında da sonra gelir', () {
      final onceki = yeniIslemKimligi(an: DateTime(2021, 9, 17, 10));
      final sonraki = yeniIslemKimligi(an: DateTime(2021, 9, 17, 10, 0, 0, 0, 1));

      expect(onceki.compareTo(sonraki), isNegative);
    });

    test('yıllar boyunca hane sayısı sabit kalır — sıralama bozulmaz', () {
      final kimlikler = <String>[
        for (final yil in <int>[2021, 2025, 2030, 2099])
          yeniIslemKimligi(an: DateTime(yil)),
      ];

      expect(kimlikler.map((kimlik) => kimlik.length).toSet(), hasLength(1));
      expect(kimlikler, orderedEquals(kimlikler.toList()..sort()));
    });

    test('aynı mikrosaniyede üretilen kimlikler çakışmaz', () {
      final an = DateTime(2024, 12, 5);

      final kimlikler = <String>{
        for (var sayac = 0; sayac < 500; sayac++) yeniIslemKimligi(an: an),
      };

      expect(kimlikler, hasLength(500));
    });

    test('yalnızca Firestore belge kimliğinde geçerli karakterler kullanılır',
        () {
      final kimlik = yeniIslemKimligi();

      expect(RegExp(r'^[0-9a-z]+$').hasMatch(kimlik), isTrue);
    });
  });
}
