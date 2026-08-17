import 'package:fidancari/domain/tema/tema_tercihi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('koddan', () {
    test('her tercih kendi kodundan geri okunur', () {
      for (final tercih in TemaTercihi.values) {
        expect(TemaTercihi.koddan(tercih.kod), tercih);
      }
    });

    test('eksik ya da tanınmayan kod varsayılana düşer', () {
      // Cihazda hiç tercih yoksa `null` okunur; eski bir sürümden kalmış
      // değer de tanınmayabilir. İkisinde de uygulama açılmalı.
      expect(TemaTercihi.koddan(null), TemaTercihi.varsayilan);
      expect(TemaTercihi.koddan(''), TemaTercihi.varsayilan);
      expect(TemaTercihi.koddan('sistem'), TemaTercihi.varsayilan);
    });

    test('varsayılan açık tema', () {
      expect(TemaTercihi.varsayilan, TemaTercihi.acik);
      expect(TemaTercihi.varsayilan.koyuMu, isFalse);
    });
  });

  group('kod', () {
    test('kodlar ASCII ve birbirinden ayrı', () {
      final kodlar = TemaTercihi.values.map((tercih) => tercih.kod).toSet();

      expect(kodlar, hasLength(TemaTercihi.values.length));
      for (final kod in kodlar) {
        expect(kod, matches(RegExp(r'^[a-z]+$')));
      }
    });
  });
}
