import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/domain/cari/acik_hesap_ozeti.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AcikHesapOzeti ozet(List<int> kuruslar) =>
      AcikHesapOzeti.hesapla(kuruslar.map(Kurus.new));

  group('hesapla', () {
    test('boş listede sıfır özet döner', () {
      expect(ozet(<int>[]), AcikHesapOzeti.bos);
      expect(ozet(<int>[]).bosMu, isTrue);
    });

    test('pozitif bakiyeler alacakta toplanır', () {
      expect(
        ozet(<int>[1250000, 320000]),
        const AcikHesapOzeti(
          adet: 2,
          alacak: Kurus(1570000),
          borc: Kurus.sifir,
        ),
      );
    });

    test('negatif bakiyeler borçta işaretsiz toplanır', () {
      expect(
        ozet(<int>[-180000, -20000]),
        const AcikHesapOzeti(
          adet: 2,
          alacak: Kurus.sifir,
          borc: Kurus(200000),
        ),
      );
    });

    test('alacak ve borç netleştirilmez', () {
      // İki kişiyle iki ayrı açık hesap var; net sıfır çıkması "hesap kapandı"
      // demek değil. Kullanıcının göreceği şey iki ayrı tutar olmalı.
      final sonuc = ozet(<int>[1000000, -1000000]);

      expect(sonuc.adet, 2);
      expect(sonuc.alacak, const Kurus(1000000));
      expect(sonuc.borc, const Kurus(1000000));
    });

    test('sıfır bakiye ne sayıma ne toplama girer', () {
      final sonuc = ozet(<int>[0, 500000, 0]);

      expect(sonuc.adet, 1);
      expect(sonuc.alacak, const Kurus(500000));
      expect(sonuc.borc, Kurus.sifir);
    });

    test('yalnızca sıfır bakiyeli liste boş sayılır', () {
      expect(ozet(<int>[0, 0]).bosMu, isTrue);
    });

    test('kuruş düzeyinde sapma bırakmaz', () {
      // Para tam sayı; üç kuruşluk üç bakiye tam dokuz kuruş etmeli
      // (bkz. KURALLAR.md §3.1).
      expect(ozet(<int>[3, 3, 3]).alacak, const Kurus(9));
    });
  });
}
