import 'package:fidancari/domain/secenek/secenek_dogrulama.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ad', () {
    test('boş ad reddedilir', () {
      expect(SecenekDogrulama.ad(null), isNotNull);
      expect(SecenekDogrulama.ad(''), isNotNull);
      expect(SecenekDogrulama.ad('   '), isNotNull);
    });

    test('tek harflik ad kabul edilir', () {
      // Ürün türünde iki karakter isteniyor; burada `A` anacı gerçek bir veri.
      expect(SecenekDogrulama.ad('A'), isNull);
      expect(SecenekDogrulama.ad('M9'), isNull);
    });

    test('baştaki ve sondaki boşluk adı geçersiz kılmaz', () {
      expect(SecenekDogrulama.ad('  Scarlet  '), isNull);
    });
  });
}
