import 'package:fidancari/domain/ortak/vergi_kimlik.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalize', () {
    test('rakam dışındaki karakterleri atar', () {
      expect(VergiKimlik.normalize('123 456 78 99'), '1234567899');
      expect(VergiKimlik.normalize('123-456-7899'), '1234567899');
    });
  });

  group('VKN (10 hane)', () {
    test('kontrol hanesi doğru olan numaraları kabul eder', () {
      expect(VergiKimlik.gecerliMi('1234567899'), isTrue);
      expect(VergiKimlik.gecerliMi('9876543218'), isTrue);
      expect(VergiKimlik.gecerliMi('1111111115'), isTrue);
    });

    test('son hanesi bozuk numarayı reddeder', () {
      // Yazım hatasının yakalanması bu doğrulamanın tek varlık sebebi:
      // yanlış vergi numarası basılmış ekstre muhasebede sorun çıkarır.
      expect(VergiKimlik.gecerliMi('1234567890'), isFalse);
    });

    test('boşluklu yazımda da çalışır', () {
      expect(VergiKimlik.gecerliMi('123 456 78 99'), isTrue);
    });
  });

  group('TCKN (11 hane)', () {
    test('geçerli numaraları kabul eder', () {
      expect(VergiKimlik.gecerliMi('12345678950'), isTrue);
      expect(VergiKimlik.gecerliMi('10101010150'), isTrue);
    });

    test('son hanesi bozuk numarayı reddeder', () {
      expect(VergiKimlik.gecerliMi('12345678951'), isFalse);
    });

    test('sıfırla başlayan numarayı reddeder', () {
      expect(VergiKimlik.tcknGecerliMi('01234567890'), isFalse);
    });
  });

  group('uzunluk', () {
    test('10 ve 11 dışındaki uzunlukları reddeder', () {
      expect(VergiKimlik.gecerliMi(''), isFalse);
      expect(VergiKimlik.gecerliMi('123456789'), isFalse);
      expect(VergiKimlik.gecerliMi('123456789990'), isFalse);
    });

    test('harf içeren girdi rakama indirgendiği için uzunluktan düşer', () {
      expect(VergiKimlik.gecerliMi('12345678a9'), isFalse);
    });
  });
}
