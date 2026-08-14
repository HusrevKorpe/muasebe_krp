import 'package:fidancari/domain/urun/urun_adi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('urunAdi', () {
    test('üç parça boşlukla birleşir', () {
      expect(
        urunAdi(tur: 'Elma', cesit: 'Scarlet', anac: 'M9'),
        'Elma Scarlet M9',
      );
    });

    test('yalnızca tür girilirse ad odur', () {
      expect(urunAdi(tur: 'nakliye'), 'nakliye');
    });

    test('boş parça sarkan boşluk bırakmaz', () {
      expect(urunAdi(tur: 'Kiraz', anac: 'Idris'), 'Kiraz Idris');
      expect(urunAdi(tur: 'Çam', cesit: '', anac: ''), 'Çam');
    });

    test('parçaların baş ve son boşlukları kırpılır', () {
      expect(
        urunAdi(tur: '  Elma ', cesit: ' Scarlet  ', anac: ' M9 '),
        'Elma Scarlet M9',
      );
    });

    test('yalnızca boşluktan oluşan parça atlanır', () {
      expect(urunAdi(tur: 'Elma', cesit: '   ', anac: 'M9'), 'Elma M9');
    });

    test('üçü de boşsa ad boştur', () {
      expect(urunAdi(tur: ''), '');
    });
  });
}
