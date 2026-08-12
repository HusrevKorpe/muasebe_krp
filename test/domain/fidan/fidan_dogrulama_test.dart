import 'package:fidancari/domain/fidan/fidan_dogrulama.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tur', () {
    test('boş bırakılamaz', () {
      expect(FidanDogrulama.tur(null), isNotNull);
      expect(FidanDogrulama.tur(''), isNotNull);
      expect(FidanDogrulama.tur('   '), isNotNull);
    });

    test('tek harf kabul edilmez', () {
      expect(FidanDogrulama.tur('E'), isNotNull);
    });

    test('geçerli tür null döner', () {
      expect(FidanDogrulama.tur('Elma'), isNull);
      expect(FidanDogrulama.tur('  Zeytin  '), isNull);
    });
  });

  group('cesit', () {
    test('boş bırakılamaz', () {
      expect(FidanDogrulama.cesit(''), isNotNull);
    });

    test('geçerli çeşit null döner', () {
      expect(FidanDogrulama.cesit('Şeker'), isNull);
    });

    test('hata mesajı alan adını söyler', () {
      expect(FidanDogrulama.cesit(''), contains('Çeşit'));
      expect(FidanDogrulama.tur(''), contains('Tür'));
    });
  });

  group('yas', () {
    test('isteğe bağlıdır', () {
      expect(FidanDogrulama.yas(null), isNull);
      expect(FidanDogrulama.yas(''), isNull);
    });

    test('makul aralıktaki tam sayı kabul edilir', () {
      expect(FidanDogrulama.yas('0'), isNull);
      expect(FidanDogrulama.yas('2'), isNull);
      expect(FidanDogrulama.yas('${FidanDogrulama.enBuyukYas}'), isNull);
    });

    test('sayı olmayan ve aralık dışı değer reddedilir', () {
      expect(FidanDogrulama.yas('iki'), isNotNull);
      expect(FidanDogrulama.yas('-1'), isNotNull);
      expect(FidanDogrulama.yas('${FidanDogrulama.enBuyukYas + 1}'), isNotNull);
      // Yaş alanına yanlışlıkla yazılmış fiyat buraya düşer.
      expect(FidanDogrulama.yas('4500'), isNotNull);
    });
  });

  group('varsayilanFiyat', () {
    test('isteğe bağlıdır', () {
      expect(FidanDogrulama.varsayilanFiyat(null), isNull);
      expect(FidanDogrulama.varsayilanFiyat('  '), isNull);
    });

    test('Türkçe yazımlı tutar kabul edilir', () {
      expect(FidanDogrulama.varsayilanFiyat('45'), isNull);
      expect(FidanDogrulama.varsayilanFiyat('18,79'), isNull);
      expect(FidanDogrulama.varsayilanFiyat('1.234,50'), isNull);
    });

    test('geçersiz ve negatif tutar reddedilir', () {
      expect(FidanDogrulama.varsayilanFiyat('abc'), isNotNull);
      expect(FidanDogrulama.varsayilanFiyat('18,795'), isNotNull);
      expect(FidanDogrulama.varsayilanFiyat('-5'), isNotNull);
    });
  });
}
