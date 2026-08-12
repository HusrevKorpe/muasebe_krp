import 'package:fidancari/core/tarih/tarih_bicimi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('uzunTarih', () {
    test('referans ekstredeki tarihleri birebir üretir', () {
      expect(uzunTarih(DateTime(2021, 9, 17)), '17 Eylül 2021');
      expect(uzunTarih(DateTime(2025, 5, 24)), '24 Mayıs 2025');
      expect(uzunTarih(DateTime(2024, 12, 5)), '5 Aralık 2024');
      expect(uzunTarih(DateTime(2022, 1, 28)), '28 Ocak 2022');
    });

    test('tüm aylar doğru adlandırılır', () {
      const beklenen = [
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
      ];
      for (var ay = 1; ay <= 12; ay++) {
        expect(uzunTarih(DateTime(2025, ay, 1)), '1 ${beklenen[ay - 1]} 2025');
      }
    });
  });

  group('kisaTarih', () {
    test('gün ve ay iki haneye tamamlanır', () {
      expect(kisaTarih(DateTime(2021, 9, 17)), '17.09.2021');
      expect(kisaTarih(DateTime(2025, 1, 5)), '05.01.2025');
      expect(kisaTarih(DateTime(2025, 12, 31)), '31.12.2025');
    });
  });

  group('gunAdiylaTarih', () {
    test('gün adı doğru hesaplanır', () {
      // 17 Eylül 2021 bir Cuma günü.
      expect(gunAdiylaTarih(DateTime(2021, 9, 17)), 'Cuma, 17 Eylül 2021');
      // 24 Mayıs 2025 bir Cumartesi.
      expect(gunAdiylaTarih(DateTime(2025, 5, 24)), 'Cumartesi, 24 Mayıs 2025');
    });
  });

  group('hazirlanmaNotu', () {
    test('ekstre alt bilgisini üretir', () {
      expect(
        hazirlanmaNotu(DateTime(2025, 5, 24)),
        '24.05.2025 tarihinde hazırlanmıştır.',
      );
    });
  });

  group('tarihAraligi', () {
    test('referans ekstrenin başlık aralığını üretir', () {
      expect(
        tarihAraligi(DateTime(2021, 9, 17), DateTime(2025, 5, 24)),
        '17 Eylül 2021 — 24 Mayıs 2025',
      );
    });
  });
}
