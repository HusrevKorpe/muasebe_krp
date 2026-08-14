import 'package:fidancari/domain/secenek/secenek.dart';
import 'package:fidancari/domain/secenek/secenek_tipi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fromMap', () {
    test('adı ve zaman damgalarını okur, tipi koleksiyondan alır', () {
      final olusturma = DateTime.utc(2026, 3, 14);

      final secenek = Secenek.fromMap('kimlik', SecenekTipi.anac, {
        Secenek.alanAd: 'M9',
        Secenek.alanAramaAnahtari: 'm9',
        Secenek.alanOlusturmaTarihi: olusturma,
      });

      expect(secenek.id, 'kimlik');
      expect(secenek.tip, SecenekTipi.anac);
      expect(secenek.ad, 'M9');
      expect(secenek.olusturmaTarihi, olusturma);
      expect(secenek.guncellemeTarihi, isNull);
    });

    test('eksik alanlı belge patlamaz', () {
      // Firestore belgesi şemasız; alan hiç olmayabilir ya da başka tipte
      // gelebilir (bkz. `harita.dart`).
      final secenek = Secenek.fromMap('kimlik', SecenekTipi.tur, const {
        Secenek.alanAd: 42,
      });

      expect(secenek.ad, '');
      expect(secenek.gecerliMi, isFalse);
    });
  });

  group('aramaAnahtari', () {
    test('Türkçe harfler katlanır', () {
      const secenek = Secenek(id: '', tip: SecenekTipi.cesit, ad: 'Şeker');

      expect(secenek.aramaAnahtari, 'seker');
    });

    test('baştaki ve aradaki fazla boşluk atılır', () {
      const secenek = Secenek(
        id: '',
        tip: SecenekTipi.cesit,
        ad: '  0900  Ziraat ',
      );

      expect(secenek.aramaAnahtari, '0900 ziraat');
    });
  });

  group('gecerliMi', () {
    test('yalnızca boşluktan oluşan ad geçersiz', () {
      const secenek = Secenek(id: '', tip: SecenekTipi.anac, ad: '   ');

      expect(secenek.gecerliMi, isFalse);
    });

    test('dolu ad geçerli', () {
      const secenek = Secenek(id: '', tip: SecenekTipi.anac, ad: 'MM106');

      expect(secenek.gecerliMi, isTrue);
    });
  });

  group('ayniMi', () {
    test('yazım farkı mükerrerliği gizlemez', () {
      const kayitli = Secenek(id: 'a', tip: SecenekTipi.anac, ad: 'M9');
      const aday = Secenek(id: '', tip: SecenekTipi.anac, ad: '  m9 ');

      expect(aday.ayniMi(kayitli), isTrue);
    });

    test('farklı listelerdeki aynı ad mükerrer sayılmaz', () {
      // `Gemlik` hem çeşit hem — başka bir işletmede — tür olabilir; listeler
      // birbirinden bağımsız.
      const cesit = Secenek(id: 'a', tip: SecenekTipi.cesit, ad: 'Gemlik');
      const tur = Secenek(id: '', tip: SecenekTipi.tur, ad: 'Gemlik');

      expect(tur.ayniMi(cesit), isFalse);
    });

    test('farklı ad mükerrer sayılmaz', () {
      const kayitli = Secenek(id: 'a', tip: SecenekTipi.anac, ad: 'M9');
      const aday = Secenek(id: '', tip: SecenekTipi.anac, ad: 'MM106');

      expect(aday.ayniMi(kayitli), isFalse);
    });
  });

  group('duzenlenebilirAlanlar', () {
    test('ad ve arama anahtarı yazılır, zaman damgası yazılmaz', () {
      const secenek = Secenek(id: 'a', tip: SecenekTipi.cesit, ad: 'Şeker');

      final alanlar = secenek.duzenlenebilirAlanlar();

      expect(alanlar, <String, Object?>{
        Secenek.alanAd: 'Şeker',
        Secenek.alanAramaAnahtari: 'seker',
      });
    });
  });

  group('kopyala', () {
    test('ad değişir, tip ve zaman damgaları korunur', () {
      final olusturma = DateTime.utc(2026, 3, 14);
      final secenek = Secenek(
        id: 'a',
        tip: SecenekTipi.anac,
        ad: 'M9',
        olusturmaTarihi: olusturma,
      );

      final yenisi = secenek.kopyala(ad: 'MM106');

      expect(yenisi.id, 'a');
      expect(yenisi.tip, SecenekTipi.anac);
      expect(yenisi.ad, 'MM106');
      expect(yenisi.olusturmaTarihi, olusturma);
    });
  });

  group('yeni', () {
    test('kimliği boş, tipi verilen tip', () {
      const secenek = Secenek.yeni(SecenekTipi.cesit);

      expect(secenek.yeniMi, isTrue);
      expect(secenek.tip, SecenekTipi.cesit);
      expect(secenek.ad, '');
    });
  });
}
