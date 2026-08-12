import 'package:fidancari/core/metin/turkce.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dart yerleşik davranışı — bu testler sorunun varlığını sabitler', () {
    test('toLowerCase noktasız ı harfini üretmez', () {
      // Türkçe'de 'I' harfinin küçüğü 'ı'dır. Dart 'i' verir.
      expect('I'.toLowerCase(), 'i');
      expect('I'.toLowerCase(), isNot('ı'));
      // Gerçek sonuç: şehir araması tutmaz.
      expect('ISPARTA'.toLowerCase(), isNot('ısparta'));
    });

    test('toUpperCase noktalı İ harfini üretmez', () {
      // Türkçe'de 'i' harfinin büyüğü 'İ'dir. Dart 'I' verir.
      expect('i'.toUpperCase(), 'I');
      expect('i'.toUpperCase(), isNot('İ'));
      expect('izmir'.toUpperCase(), 'IZMIR');
    });

    test('bu modülün fonksiyonları doğru sonucu verir', () {
      expect(turkceKucuk('ISPARTA'), 'ısparta');
      expect(turkceBuyuk('izmir'), 'İZMİR');
    });
  });

  group('turkceKucuk', () {
    test('I ve İ doğru karşılıklarına iner', () {
      expect(turkceKucuk('IĞDIR'), 'ığdır');
      expect(turkceKucuk('İZMİR'), 'izmir');
    });

    test('tek karakterlik sonuç üretir', () {
      expect(turkceKucuk('İ').length, 1);
    });

    test('diğer Türkçe harfler korunur', () {
      expect(turkceKucuk('ŞEFTALİ ÇEŞİDİ'), 'şeftali çeşidi');
      expect(turkceKucuk('ÖĞÜT'), 'öğüt');
    });
  });

  group('turkceBuyuk', () {
    test('i ve ı doğru karşılıklarına çıkar', () {
      expect(turkceBuyuk('ığdır'), 'IĞDIR');
      expect(turkceBuyuk('izmir'), 'İZMİR');
    });
  });

  group('aramaAnahtari', () {
    test('İstanbul yazımlarının hepsi aynı anahtarı üretir', () {
      const beklenen = 'istanbul';
      expect(aramaAnahtari('İstanbul'), beklenen);
      expect(aramaAnahtari('istanbul'), beklenen);
      expect(aramaAnahtari('ISTANBUL'), beklenen);
      expect(aramaAnahtari('İSTANBUL'), beklenen);
      expect(aramaAnahtari('ıstanbul'), beklenen);
    });

    test('Türkçe harfler ASCII karşılıklarına katlanır', () {
      expect(aramaAnahtari('Çiğdem'), 'cigdem');
      expect(aramaAnahtari('ŞEKER'), 'seker');
      expect(aramaAnahtari('Öğünç'), 'ogunc');
      expect(aramaAnahtari('Ünlü'), 'unlu');
    });

    test('şapkalı harfler de katlanır', () {
      expect(aramaAnahtari('Kâmil'), 'kamil');
    });

    test('baştaki sondaki boşluk atılır, çoklu boşluk teke iner', () {
      expect(aramaAnahtari('  İSTANBUL   Fidancılık '), 'istanbul fidancilik');
    });

    test('gerçek cari adı — referans ekstreden', () {
      expect(aramaAnahtari('Ahmet Koyuncu'), 'ahmet koyuncu');
      expect(aramaAnahtari('Favori Fidancılık'), 'favori fidancilik');
    });

    test('boş metin boş anahtar üretir', () {
      expect(aramaAnahtari(''), '');
      expect(aramaAnahtari('   '), '');
    });
  });

  group('turkceKarsilastir — Türk alfabesi sırası', () {
    test('ç harfi c ile d arasında sıralanır', () {
      final liste = ['dut', 'çam', 'ceviz'];
      liste.sort(turkceKarsilastir);
      expect(liste, ['ceviz', 'çam', 'dut']);
    });

    test('ğ harfi g ile h arasında sıralanır', () {
      final liste = ['halka', 'ğ', 'gül'];
      liste.sort(turkceKarsilastir);
      expect(liste, ['gül', 'ğ', 'halka']);
    });

    test('ı harfi i harfinden önce gelir', () {
      final liste = ['incir', 'ıhlamur'];
      liste.sort(turkceKarsilastir);
      expect(liste, ['ıhlamur', 'incir']);
    });

    test('ö harfi o ile p arasında, ü harfi u ile v arasında', () {
      final liste = ['portakal', 'öksüz', 'ova'];
      liste.sort(turkceKarsilastir);
      expect(liste, ['ova', 'öksüz', 'portakal']);

      final liste2 = ['vişne', 'üzüm', 'urfa'];
      liste2.sort(turkceKarsilastir);
      expect(liste2, ['urfa', 'üzüm', 'vişne']);
    });

    test('ş harfi s ile t arasında sıralanır', () {
      final liste = ['turp', 'şeftali', 'sedir'];
      liste.sort(turkceKarsilastir);
      expect(liste, ['sedir', 'şeftali', 'turp']);
    });

    test('büyük-küçük harf sıralamayı etkilemez', () {
      final liste = ['çam', 'CEVİZ'];
      liste.sort(turkceKarsilastir);
      expect(liste, ['CEVİZ', 'çam']);
    });

    test('fidan türleri doğru sırada', () {
      final turler = ['Zeytin', 'Elma', 'Şeftali', 'Ceviz', 'Çam', 'Armut'];
      turler.sort(turkceKarsilastir);
      expect(turler, ['Armut', 'Ceviz', 'Çam', 'Elma', 'Şeftali', 'Zeytin']);
    });
  });

  group('ilkHarfBuyuk', () {
    test('ilk harfi Türkçe kurallarına göre büyütür', () {
      expect(ilkHarfBuyuk('adet'), 'Adet');
      expect(ilkHarfBuyuk('ışık'), 'Işık');
      expect(ilkHarfBuyuk('istanbul'), 'İstanbul');
    });

    test('kalan harflere dokunmaz', () {
      expect(ilkHarfBuyuk('şEFTALİ'), 'ŞEFTALİ');
      expect(ilkHarfBuyuk(''), '');
    });
  });
}
