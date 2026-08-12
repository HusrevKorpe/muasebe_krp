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
    test('KDV kapalıyken toplam ara toplama eşit', () {
      final hesap = FaturaHesaplayici.hesapla(
        kalemler: <IslemKalemi>[kalem(100), kalem(50)],
      );

      expect(hesap.araToplam.deger, 15000);
      expect(hesap.kdv, Kurus.sifir);
      expect(hesap.toplam, hesap.araToplam);
      expect(hesap.kdvVarMi, isFalse);
    });

    test('%1 KDV: 140.625,00 ₺ → 142.031,25 ₺', () {
      final hesap = FaturaHesaplayici.hesapla(
        kalemler: <IslemKalemi>[kalem(140625)],
        kdvOrani: 1,
      );

      expect(hesap.araToplam.deger, 14062500);
      expect(hesap.kdv.deger, 140625);
      expect(hesap.toplam.deger, 14203125);
    });

    test('KDV kalem kalem değil ara toplam üzerinden hesaplanır', () {
      // Üç kalem tek tek yuvarlansaydı KDV 3 kuruş çıkardı; ara toplamdan
      // hesaplanınca 2 kuruş çıkar. Doğrusu ikincisidir.
      final tekTek = <IslemKalemi>[
        IslemKalemi(
          ad: 'a',
          miktar: 1,
          birimFiyat: const Kurus(50),
          tutar: const Kurus(50),
        ),
        IslemKalemi(
          ad: 'b',
          miktar: 1,
          birimFiyat: const Kurus(50),
          tutar: const Kurus(50),
        ),
        IslemKalemi(
          ad: 'c',
          miktar: 1,
          birimFiyat: const Kurus(50),
          tutar: const Kurus(50),
        ),
      ];

      final hesap = FaturaHesaplayici.hesapla(kalemler: tekTek, kdvOrani: 1);

      expect(hesap.araToplam.deger, 150);
      expect(hesap.kdv.deger, 2, reason: '150 kuruşun %1\'i 1,5 → 2 kuruş');
      expect(hesap.toplam.deger, 152);
    });

    test('KDV en yakın kuruşa yuvarlanır', () {
      final hesap = FaturaHesaplayici.hesapla(
        kalemler: <IslemKalemi>[
          IslemKalemi(
            ad: 'a',
            miktar: 1,
            birimFiyat: const Kurus(1234),
            tutar: const Kurus(1234),
          ),
        ],
        kdvOrani: 1,
      );

      // 1234 kuruşun %1'i 12,34 kuruş → 12 kuruş.
      expect(hesap.kdv.deger, 12);
      expect(hesap.toplam.deger, 1246);
    });

    test('boş kalem listesi sıfır toplam verir', () {
      final hesap = FaturaHesaplayici.hesapla(kalemler: <IslemKalemi>[]);

      expect(hesap.araToplam, Kurus.sifir);
      expect(hesap.toplam, Kurus.sifir);
    });

    test('negatif KDV oranı reddedilir', () {
      expect(
        () => FaturaHesaplayici.hesapla(
          kalemler: <IslemKalemi>[kalem(100)],
          kdvOrani: -1,
        ),
        throwsArgumentError,
      );
    });

    test('varsayılan fidan KDV oranı %1', () {
      expect(FaturaHesaplayici.varsayilanKdvOrani, 1);
    });
  });
}
