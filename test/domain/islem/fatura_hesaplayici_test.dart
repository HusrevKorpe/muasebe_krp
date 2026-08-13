import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/domain/islem/fatura_hesaplayici.dart';
import 'package:fidancari/domain/islem/islem_kalemi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IslemKalemi kalem(int lira) => IslemKalemi.birimFiyattan(
    ad: 'fidan',
    miktar: 1,
    birimFiyat: Kurus.liradan(lira),
  );

  group('FaturaHesaplayici', () {
    test('toplam, kalem tutarlarının toplamıdır', () {
      final toplam = FaturaHesaplayici.hesapla(
        kalemler: <IslemKalemi>[kalem(100), kalem(50)],
      );

      expect(toplam.deger, 15000);
    });

    test('kalem tutarlarına hiçbir ek binmez', () {
      final toplam = FaturaHesaplayici.hesapla(
        kalemler: <IslemKalemi>[kalem(140625)],
      );

      expect(toplam.deger, 14062500, reason: 'toplam üzerine vergi eklenmez');
    });

    test('kuruşlu kalemler yuvarlama sapması bırakmaz', () {
      // Üç kalemin toplamı tam sayı toplamasıdır; hiçbir adımda bölme yok.
      final tekTek = <IslemKalemi>[
        for (final ad in <String>['a', 'b', 'c'])
          IslemKalemi(
            ad: ad,
            miktar: 1,
            birimFiyat: const Kurus(50),
            tutar: const Kurus(50),
          ),
      ];

      final toplam = FaturaHesaplayici.hesapla(kalemler: tekTek);

      expect(toplam.deger, 150);
    });

    test('boş kalem listesi sıfır toplam verir', () {
      final toplam = FaturaHesaplayici.hesapla(kalemler: <IslemKalemi>[]);

      expect(toplam, Kurus.sifir);
    });
  });
}
