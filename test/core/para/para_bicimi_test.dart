import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/core/para/para_bicimi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kurusBicimle', () {
    test('referans ekstredeki tutarları birebir üretir', () {
      expect(kurusBicimle(const Kurus(9400000)), '94.000,00 ₺');
      expect(kurusBicimle(const Kurus(22000000)), '220.000,00 ₺');
      expect(kurusBicimle(const Kurus(14203125)), '142.031,25 ₺');
      expect(kurusBicimle(const Kurus(1879)), '18,79 ₺');
    });

    test('negatif bakiye eksi işaretiyle gösterilir', () {
      expect(kurusBicimle(const Kurus(-1203125)), '-12.031,25 ₺');
    });

    test('kuruş her zaman iki hane', () {
      expect(kurusBicimle(const Kurus(500)), '5,00 ₺');
      expect(kurusBicimle(const Kurus(505)), '5,05 ₺');
      expect(kurusBicimle(Kurus.sifir), '0,00 ₺');
    });

    test('binlik ayracı nokta, ondalık ayracı virgül', () {
      expect(kurusBicimle(const Kurus(123456789)), '1.234.567,89 ₺');
    });

    test('simge kapatılabilir', () {
      expect(kurusBicimle(const Kurus(9400000), simgeli: false), '94.000,00');
    });
  });

  group('miktarBicimle', () {
    test('referans ekstredeki miktarları üretir', () {
      expect(miktarBicimle(7000), '7.000');
      expect(miktarBicimle(1650), '1.650');
      expect(miktarBicimle(1), '1');
    });
  });

  group('KurusBicimi uzantısı', () {
    test('bicimli ve bicimliSimgesiz', () {
      expect(const Kurus(9400000).bicimli, '94.000,00 ₺');
      expect(const Kurus(9400000).bicimliSimgesiz, '94.000,00');
    });
  });
}
