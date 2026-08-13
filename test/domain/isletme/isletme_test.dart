import 'package:fidancari/domain/isletme/banka_hesabi.dart';
import 'package:fidancari/domain/isletme/isletme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ornek = Isletme(
    id: 'uid-1',
    ad: 'Favori Fidancılık',
    unvan: 'Tar.Taş.Hay.Ltd.Şti',
    adres: 'Sarıçam / ADANA',
    telefon: '0322 000 00 00',
    bankaHesaplari: const <BankaHesabi>[
      BankaHesabi(
        banka: 'Ziraat Bankası',
        iban: 'TR330006100519786457841326',
        hesapNo: '12345678',
      ),
      BankaHesabi(
        banka: 'Yapı Kredi',
        iban: 'TR110001000111222233334444',
        paraBirimi: 'EUR',
      ),
    ],
    olusturmaTarihi: DateTime.utc(2024, 3, 1),
    guncellemeTarihi: DateTime.utc(2026, 8, 12),
  );

  group('gidiş-dönüş dönüşümü', () {
    test('toMap → fromMap tüm alanları korur', () {
      expect(Isletme.fromMap(ornek.id, ornek.toMap()), ornek);
    });

    test('banka hesapları dizisi sırasıyla korunur', () {
      final geri = Isletme.fromMap(ornek.id, ornek.toMap());

      expect(geri.bankaHesaplari, hasLength(2));
      expect(geri.bankaHesaplari.first.banka, 'Ziraat Bankası');
      expect(geri.bankaHesaplari.last.paraBirimi, 'EUR');
    });

    test('hesabı olmayan işletme boş dizi ile okunur', () {
      const yalin = Isletme(id: 'uid-2', ad: 'Tek Kişi');
      expect(Isletme.fromMap(yalin.id, yalin.toMap()), yalin);
      expect(Isletme.fromMap(yalin.id, yalin.toMap()).bankaHesaplari, isEmpty);
    });

    test('bozuk banka hesabı öğeleri atlanır', () {
      // Diziye elle müdahale edilmiş bir belge uygulamayı çökertmemeli.
      final isletme = Isletme.fromMap('uid-3', const <String, Object?>{
        'ad': 'Test',
        'bankaHesaplari': <Object?>[
          <String, Object?>{'banka': 'Ziraat', 'iban': 'TR33'},
          'bozuk kayıt',
          null,
        ],
      });

      expect(isletme.bankaHesaplari, hasLength(1));
      expect(isletme.bankaHesaplari.single.banka, 'Ziraat');
    });
  });

  group('tamAd', () {
    test('ünvan varsa ada eklenir', () {
      expect(ornek.tamAd, 'Favori Fidancılık Tar.Taş.Hay.Ltd.Şti');
    });

    test('ünvan yoksa yalnızca ad döner', () {
      expect(const Isletme(id: 'x', ad: 'Tek Kişi').tamAd, 'Tek Kişi');
    });
  });

  group('duzenlenebilirAlanlar', () {
    test('zaman damgalarını içermez', () {
      // Zaman damgalarını yalnızca repository yazar (KURALLAR.md §4.2).
      final alanlar = ornek.duzenlenebilirAlanlar();

      expect(alanlar.containsKey('olusturmaTarihi'), isFalse);
      expect(alanlar.containsKey('guncellemeTarihi'), isFalse);
      expect(alanlar['ad'], 'Favori Fidancılık');
    });
  });

  group('kopyala', () {
    test('verilmeyen alanlar korunur', () {
      final guncel = ornek.kopyala(ad: 'Yeni Ad');

      expect(guncel.ad, 'Yeni Ad');
      expect(guncel.id, ornek.id);
      expect(guncel.adres, ornek.adres);
      expect(guncel.bankaHesaplari, ornek.bankaHesaplari);
      expect(guncel.olusturmaTarihi, ornek.olusturmaTarihi);
    });
  });

  group('BankaHesabi', () {
    test('IBAN dörderli gruplanmış olarak gösterilir', () {
      expect(
        ornek.bankaHesaplari.first.ibanBicimli,
        'TR33 0006 1005 1978 6457 8413 26',
      );
    });

    test('geçerlilik IBAN üzerinden okunur', () {
      expect(ornek.bankaHesaplari.first.ibanGecerliMi, isTrue);
      expect(
        const BankaHesabi(banka: 'X', iban: 'TR00').ibanGecerliMi,
        isFalse,
      );
    });

    test('fromMap IBAN’ı normalize eder', () {
      final hesap = BankaHesabi.fromMap(const <String, Object?>{
        'banka': 'Ziraat',
        'iban': 'tr33 0006 1005 1978 6457 8413 26',
      });

      expect(hesap.iban, 'TR330006100519786457841326');
      expect(hesap.paraBirimi, BankaHesabi.varsayilanParaBirimi);
    });
  });
}
