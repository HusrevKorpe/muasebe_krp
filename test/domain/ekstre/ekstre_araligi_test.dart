import 'package:fidancari/domain/ekstre/ekstre_araligi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final bugun = DateTime(2025, 5, 24, 14, 30);

  group('Hazır aralıklar', () {
    test('bu ay: ayın ilk gününden bugünün sonuna', () {
      final aralik = EkstreAraligi.buAy(bugun);

      expect(aralik.baslangic, DateTime(2025, 5));
      expect(aralik.bitis, DateTime(2025, 5, 24, 23, 59, 59, 999));
      expect(aralik.tip, EkstreAralikTipi.buAy);
    });

    test('bu yıl: yılın ilk gününden bugünün sonuna', () {
      final aralik = EkstreAraligi.buYil(bugun);

      expect(aralik.baslangic, DateTime(2025));
      expect(aralik.bitis, DateTime(2025, 5, 24, 23, 59, 59, 999));
    });

    test('tümü: iki uçta da sınır yok', () {
      const aralik = EkstreAraligi.tumu();

      expect(aralik.baslangic, isNull);
      expect(aralik.bitis, isNull);
      expect(aralik.tumuMu, isTrue);
      expect(aralik.icerirMi(DateTime(1999)), isTrue);
      expect(aralik.oncesindeMi(DateTime(1999)), isFalse);
    });
  });

  group('Özel aralık', () {
    test('bitiş günü sonuna genişler — o gün girilen işlem içeride kalır', () {
      final aralik = EkstreAraligi.ozel(
        baslangic: DateTime(2021, 9, 17, 11),
        bitis: DateTime(2021, 10, 26, 9),
      );

      expect(aralik.baslangic, DateTime(2021, 9, 17));
      expect(aralik.bitis, DateTime(2021, 10, 26, 23, 59, 59, 999));
      expect(aralik.icerirMi(DateTime(2021, 10, 26, 18)), isTrue);
      expect(aralik.icerirMi(DateTime(2021, 9, 17)), isTrue);
    });

    test('ters verilen sınırlar düzeltilir', () {
      final aralik = EkstreAraligi.ozel(
        baslangic: DateTime(2025, 5, 24),
        bitis: DateTime(2021, 9, 17),
      );

      expect(aralik.baslangic, DateTime(2021, 9, 17));
      expect(aralik.bitis, DateTime(2025, 5, 24, 23, 59, 59, 999));
    });

    test('ay sonunda gün sınırı taşmaz', () {
      final aralik = EkstreAraligi.ozel(
        baslangic: DateTime(2024, 12, 31),
        bitis: DateTime(2024, 12, 31),
      );

      expect(aralik.bitis, DateTime(2024, 12, 31, 23, 59, 59, 999));
      expect(aralik.icerirMi(DateTime(2025, 1, 1)), isFalse);
    });
  });

  group('Sınır sorgulari', () {
    final aralik = EkstreAraligi.ozel(
      baslangic: DateTime(2024, 1, 1),
      bitis: DateTime(2024, 12, 31),
    );

    test('aralıktan önceki işlem açılış bakiyesine sayılır', () {
      expect(aralik.oncesindeMi(DateTime(2023, 12, 31)), isTrue);
      expect(aralik.icerirMi(DateTime(2023, 12, 31)), isFalse);
    });

    test('aralıktan sonraki işlem tamamen dışarıda', () {
      expect(aralik.sonrasindaMi(DateTime(2025, 1, 1)), isTrue);
      expect(aralik.icerirMi(DateTime(2025, 1, 1)), isFalse);
    });

    test('eşitlik ve hashCode alanlara dayanır — sağlayıcı anahtarı olur', () {
      final ayni = EkstreAraligi.ozel(
        baslangic: DateTime(2024, 1, 1),
        bitis: DateTime(2024, 12, 31),
      );

      expect(ayni, aralik);
      expect(ayni.hashCode, aralik.hashCode);
      expect(const EkstreAraligi.tumu() == aralik, isFalse);
    });
  });
}
