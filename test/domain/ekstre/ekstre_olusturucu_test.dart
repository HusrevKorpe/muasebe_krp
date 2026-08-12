import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/core/para/para_bicimi.dart';
import 'package:fidancari/domain/ekstre/ekstre.dart';
import 'package:fidancari/domain/ekstre/ekstre_araligi.dart';
import 'package:fidancari/domain/ekstre/ekstre_olusturucu.dart';
import 'package:fidancari/domain/islem/islem.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ornek/ornek_isletme.dart';
import '../../ornek/referans_ekstre.dart';

/// Fazın ana doğruluk ölçütü: referans ekstredeki dokuz işlem, aynı tarih
/// aralığıyla ekstreye dönüştürüldüğünde tablo satırları ve bakiye kolonu
/// PDF'tekiyle birebir aynı olmalı (`fazlar/faz-4-ekstre.md`, kabul kriteri 2).
void main() {
  final hazirlanma = DateTime(2025, 5, 24);

  Ekstre ekstreUret({
    required EkstreAraligi aralik,
    List<Islem>? islemler,
  }) => EkstreOlusturucu.olustur(
    isletme: ornekIsletme,
    cari: ornekCari,
    aralik: aralik,
    islemler: islemler ?? referansIslemleri,
    hazirlanmaTarihi: hazirlanma,
  );

  group('Referans ekstre — tüm geçmiş', () {
    test('bakiye kolonu PDF ile kuruşu kuruşuna aynı', () {
      final ekstre = ekstreUret(aralik: const EkstreAraligi.tumu());

      expect(ekstre.satirlar, hasLength(9));
      expect(
        ekstre.satirlar.map((satir) => satir.yuruyenBakiye.deger),
        beklenenBakiyeler,
      );
    });

    test('satırlar eskiden yeniye dizilir', () {
      final ekstre = ekstreUret(
        aralik: const EkstreAraligi.tumu(),
        islemler: referansIslemleri.reversed.toList(),
      );

      expect(
        ekstre.satirlar.map((satir) => satir.islem.id),
        <String>['01', '02', '03', '04', '05', '06', '07', '08', '09'],
      );
    });

    test('toplamlar ekstrenin son sayfasıyla aynı', () {
      final ekstre = ekstreUret(aralik: const EkstreAraligi.tumu());

      expect(ekstre.toplamBorc.deger, beklenenToplamBorc);
      expect(ekstre.toplamAlacak.deger, beklenenToplamAlacak);
      expect(ekstre.kapanisBakiyesi.deger, beklenenBakiye);
      expect(ekstre.kapanisBakiyesi.bicimli, '-12.031,25 ₺');
    });

    test('tüm geçmiş dökülüyorsa açılış bakiyesi sıfırdır', () {
      final ekstre = ekstreUret(aralik: const EkstreAraligi.tumu());

      expect(ekstre.acilisBakiyesi, Kurus.sifir);
      expect(ekstre.acilisBakiyesiVarMi, isFalse);
    });

    test('başlıktaki aralık ilk işlemden hazırlanma tarihine uzanır', () {
      final ekstre = ekstreUret(aralik: const EkstreAraligi.tumu());

      expect(ekstre.aralikMetni, '17 Eylül 2021 — 24 Mayıs 2025');
    });
  });

  group('Tutarlılık — referans yazılımın düştüğü hata', () {
    test('açılış + toplam borç − toplam alacak == kapanış bakiyesi', () {
      for (final aralik in <EkstreAraligi>[
        const EkstreAraligi.tumu(),
        EkstreAraligi.ozel(
          baslangic: DateTime(2024, 12, 1),
          bitis: DateTime(2025, 1, 31),
        ),
        EkstreAraligi.ozel(
          baslangic: DateTime(2021, 11, 14),
          bitis: DateTime(2022, 2, 1),
        ),
      ]) {
        final ekstre = ekstreUret(aralik: aralik);

        expect(
          ekstre.acilisBakiyesi + ekstre.toplamBorc - ekstre.toplamAlacak,
          ekstre.kapanisBakiyesi,
          reason: 'aralık: $aralik',
        );
        expect(ekstre.tutarliMi, isTrue, reason: 'aralık: $aralik');
      }
    });

    test('kapanış bakiyesi, tablodaki son satırın bakiyesine eşit', () {
      final ekstre = ekstreUret(aralik: const EkstreAraligi.tumu());

      expect(
        ekstre.satirlar.last.yuruyenBakiye,
        ekstre.kapanisBakiyesi,
        reason: 'referans PDF bu eşitliği tutturamamıştı',
      );
    });
  });

  group('Açılış bakiyesi — aralık ortasından başlayan ekstre', () {
    test('aralıktan önceki işlemler devir olarak taşınır', () {
      // 2024 sonundan itibaren: öncesindeki dört tahsilat ve ilk fatura
      // bakiyeyi sıfırlamıştı, 05 Aralık faturası da devre girer.
      final ekstre = ekstreUret(
        aralik: EkstreAraligi.ozel(
          baslangic: DateTime(2024, 12, 6),
          bitis: DateTime(2025, 5, 24),
        ),
      );

      expect(ekstre.acilisBakiyesi.deger, 22000000, reason: '220.000,00 ₺');
      expect(ekstre.acilisBakiyesiVarMi, isTrue);
      expect(
        ekstre.satirlar.map((satir) => satir.islem.id),
        <String>['07', '08', '09'],
      );
      expect(
        ekstre.satirlar.map((satir) => satir.yuruyenBakiye.deger),
        <int>[17000000, 13000000, -1203125],
      );
    });

    test('devir yalnızca aralıktan önceki işlemlerden toplanır', () {
      final ekstre = ekstreUret(
        aralik: EkstreAraligi.ozel(
          baslangic: DateTime(2021, 11, 13),
          bitis: DateTime(2021, 11, 15),
        ),
      );

      // 17 Eylül'deki fatura (94.000) ve tahsilat (10.000) devre girer.
      expect(ekstre.acilisBakiyesi.deger, 8400000);
      expect(ekstre.toplamBorc, Kurus.sifir);
      expect(ekstre.toplamAlacak.deger, 8000000);
      expect(ekstre.kapanisBakiyesi.deger, 400000);
    });

    test('aralıktan sonraki işlemler ne tabloya ne bakiyeye girer', () {
      final ekstre = ekstreUret(
        aralik: EkstreAraligi.ozel(
          baslangic: DateTime(2021, 1, 1),
          bitis: DateTime(2021, 12, 31),
        ),
      );

      expect(
        ekstre.satirlar.map((satir) => satir.islem.id),
        <String>['01', '02', '03', '04'],
      );
      expect(
        ekstre.kapanisBakiyesi.deger,
        400000,
        reason: '2022 ve sonrasındaki işlemler o günkü bakiyeyi etkilemez',
      );
    });
  });

  group('Boş aralık', () {
    test('hiç işlem yoksa ekstre yine üretilir ve tutarlıdır', () {
      final ekstre = ekstreUret(
        aralik: EkstreAraligi.ozel(
          baslangic: DateTime(2023, 1, 1),
          bitis: DateTime(2023, 12, 31),
        ),
      );

      expect(ekstre.bosMu, isTrue);
      expect(ekstre.satirlar, isEmpty);
      expect(ekstre.toplamBorc, Kurus.sifir);
      expect(ekstre.toplamAlacak, Kurus.sifir);
      expect(ekstre.tutarliMi, isTrue);
    });

    test('boş aralıkta bile açılış bakiyesi taşınır', () {
      final ekstre = ekstreUret(
        aralik: EkstreAraligi.ozel(
          baslangic: DateTime(2023, 1, 1),
          bitis: DateTime(2023, 12, 31),
        ),
      );

      expect(ekstre.acilisBakiyesi, Kurus.sifir, reason: '2022 sonu sıfırdı');
      expect(ekstre.kapanisBakiyesi, ekstre.acilisBakiyesi);
    });

    test('hiç işlemi olmayan cari — başlık tarihleri çökmeden üretilir', () {
      final ekstre = ekstreUret(
        aralik: const EkstreAraligi.tumu(),
        islemler: <Islem>[],
      );

      expect(ekstre.bosMu, isTrue);
      expect(ekstre.gosterilenBaslangic, hazirlanma);
      expect(ekstre.aralikMetni, '24 Mayıs 2025 — 24 Mayıs 2025');
    });
  });

  group('İptal edilmiş işlem', () {
    test('tabloda kalır, bakiyeye ve toplamlara katılmaz', () {
      final iptalli = tahsilatlar[0].kopyala(iptal: true);
      final ekstre = ekstreUret(
        aralik: const EkstreAraligi.tumu(),
        islemler: <Islem>[zeytinHurmaFaturasi, iptalli],
      );

      expect(ekstre.satirlar, hasLength(2));
      expect(ekstre.toplamAlacak, Kurus.sifir);
      expect(ekstre.toplamBorc.deger, 9400000);
      expect(ekstre.kapanisBakiyesi.deger, 9400000);
      expect(ekstre.tutarliMi, isTrue);
    });

    test('açılış bakiyesine de katılmaz', () {
      final iptalli = zeytinHurmaFaturasi.kopyala(iptal: true);
      final ekstre = ekstreUret(
        aralik: EkstreAraligi.ozel(
          baslangic: DateTime(2021, 10, 1),
          bitis: DateTime(2021, 12, 31),
        ),
        islemler: <Islem>[iptalli, tahsilatlar[1]],
      );

      expect(ekstre.acilisBakiyesi, Kurus.sifir);
      expect(ekstre.kapanisBakiyesi.deger, -5000000);
    });
  });
}
