import 'package:fidancari/domain/isletme/iban.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gecerli = 'TR330006100519786457841326';

  group('gecerliMi', () {
    test('mod-97 kontrolünü geçen IBAN kabul edilir', () {
      expect(Iban.gecerliMi(gecerli), isTrue);
      expect(Iban.gecerliMi('TR110001000111222233334444'), isTrue);
    });

    test('boşluklu ve küçük harfli yazım kabul edilir', () {
      expect(Iban.gecerliMi('tr33 0006 1005 1978 6457 8413 26'), isTrue);
      expect(Iban.gecerliMi('TR33-0006-1005-1978-6457-8413-26'), isTrue);
    });

    test('tek hanesi değişmiş IBAN reddedilir', () {
      // IBAN ekstreye basılıyor; tek hanelik hata parayı başka hesaba yollar.
      expect(Iban.gecerliMi('TR330006100519786457841327'), isFalse);
    });

    test('eksik veya fazla haneli IBAN reddedilir', () {
      expect(Iban.gecerliMi('TR33000610051978645784132'), isFalse);
      expect(Iban.gecerliMi('TR3300061005197864578413266'), isFalse);
      expect(Iban.gecerliMi(''), isFalse);
    });

    test('TR dışındaki ülke kodu reddedilir', () {
      expect(Iban.gecerliMi('DE89370400440532013000'), isFalse);
    });

    test('rakam yerine harf içeren gövde reddedilir', () {
      expect(Iban.gecerliMi('TR33000610051978645784132A'), isFalse);
    });
  });

  group('bicimle', () {
    test('dörderli gruplara ayırır', () {
      expect(Iban.bicimle(gecerli), 'TR33 0006 1005 1978 6457 8413 26');
    });

    test('zaten biçimlenmiş IBAN yeniden biçimlendiğinde bozulmaz', () {
      expect(
        Iban.bicimle('TR33 0006 1005 1978 6457 8413 26'),
        'TR33 0006 1005 1978 6457 8413 26',
      );
    });
  });

  group('normalize', () {
    test('boşluk ve tireleri atıp büyütür', () {
      expect(Iban.normalize('tr33 0006-1005 1978 6457 8413 26'), gecerli);
    });
  });
}
