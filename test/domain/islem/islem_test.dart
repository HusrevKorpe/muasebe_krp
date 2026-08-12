import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/domain/islem/islem.dart';
import 'package:fidancari/domain/islem/islem_durumu.dart';
import 'package:fidancari/domain/islem/islem_kalemi.dart';
import 'package:fidancari/domain/islem/islem_tipi.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ornek/referans_ekstre.dart';

void main() {
  group('Islem.fatura', () {
    test('toplamı kalemlerden hesaplar', () {
      final fatura = Islem.fatura(
        tip: IslemTipi.satisFaturasi,
        baslik: 'Zeytin',
        islemTarihi: DateTime(2024, 3, 1),
        kalemler: <IslemKalemi>[
          IslemKalemi.birimFiyattan(
            ad: 'zeytin',
            miktar: 100,
            birimFiyat: Kurus.liradan(7),
          ),
        ],
      );

      expect(fatura.araToplam.deger, 70000);
      expect(fatura.toplam.deger, 70000);
      expect(fatura.yeniMi, isTrue);
    });

    test('kalem listesi sonradan değiştirilemez', () {
      final fatura = Islem.fatura(
        tip: IslemTipi.satisFaturasi,
        baslik: 'Zeytin',
        islemTarihi: DateTime(2024, 3, 1),
        kalemler: <IslemKalemi>[
          IslemKalemi.birimFiyattan(
            ad: 'zeytin',
            miktar: 1,
            birimFiyat: Kurus.liradan(7),
          ),
        ],
      );

      expect(
        () => fatura.kalemler.add(
          IslemKalemi.birimFiyattan(
            ad: 'ek',
            miktar: 1,
            birimFiyat: Kurus.liradan(1),
          ),
        ),
        throwsUnsupportedError,
        reason: 'saklanan toplam ile kalemler ayrışmamalı',
      );
    });
  });

  group('Islem.odeme', () {
    test('kalemsiz, KDV\'siz ve vadesiz kurulur', () {
      final tahsilat = Islem.odeme(
        tip: IslemTipi.tahsilat,
        baslik: 'Müşteriden Tahsilat',
        islemTarihi: DateTime(2024, 3, 1),
        tutar: Kurus.liradan(10000),
      );

      expect(tahsilat.kalemler, isEmpty);
      expect(tahsilat.kdvOrani, 0);
      expect(tahsilat.kdv, Kurus.sifir);
      expect(tahsilat.vadeTarihi, isNull);
      expect(tahsilat.toplam.deger, 1000000);
      expect(tahsilat.araToplam.deger, 1000000);
    });
  });

  group('fromMap / toMap', () {
    test('faturada gidiş-dönüşte alan kaybı olmaz', () {
      final veri = zeytinHurmaFaturasi.toMap();

      final donen = Islem.fromMap('01', veri);

      expect(donen.tip, IslemTipi.satisFaturasi);
      expect(donen.baslik, 'Zeytin-Hurma');
      expect(donen.islemTarihi, DateTime(2021, 9, 17));
      expect(donen.vadeTarihi, DateTime(2021, 10, 26));
      expect(donen.durum, IslemDurumu.teslimEdildi);
      expect(donen.kalemler, hasLength(3));
      expect(donen.kalemler[1].tutar.deger, 3100000);
      expect(donen.kalemler[1].birimFiyat.deger, 1879);
      expect(donen.araToplam.deger, 9400000);
      expect(donen.toplam.deger, 9400000);
      expect(donen.iptalMi, isFalse);
    });

    test('KDV\'li faturada oran ve tutar birlikte saklanır', () {
      final donen = Islem.fromMap('09', sertCekirdekliFaturasi.toMap());

      expect(donen.kdvOrani, 1);
      expect(donen.kdv.deger, 140625);
      expect(donen.toplam.deger, 14203125);
    });

    test('saklanan toplam okunurken yeniden hesaplanmaz', () {
      // Kalemlerle toplamı kasten tutarsız bir kayıt: geçmiş fatura ne
      // yazıldıysa onu göstermeli (bkz. KURALLAR.md §3.2).
      final veri = <String, Object?>{
        ...zeytinHurmaFaturasi.toMap(),
        Islem.alanToplamKurus: 9999999,
      };

      final donen = Islem.fromMap('01', veri);

      expect(donen.toplam.deger, 9999999);
    });

    test('para alanları Firestore\'a int yazılır', () {
      final veri = sertCekirdekliFaturasi.toMap();

      expect(veri[Islem.alanAraToplamKurus], isA<int>());
      expect(veri[Islem.alanKdvKurus], isA<int>());
      expect(veri[Islem.alanToplamKurus], isA<int>());
    });

    test('yazılabilir alanlar iptal ve oluşturma tarihini içermez', () {
      final veri = zeytinHurmaFaturasi.yazilabilirAlanlar();

      expect(veri.containsKey(Islem.alanIptal), isFalse);
      expect(veri.containsKey(Islem.alanIptalNedeni), isFalse);
      expect(veri.containsKey(Islem.alanOlusturmaTarihi), isFalse);
      expect(veri[Islem.alanTip], 'satisFaturasi');
      expect(veri[Islem.alanDurum], 'teslimEdildi');
    });

    test('eksik belge alanları varsayılana düşer, patlamaz', () {
      final donen = Islem.fromMap('bos', const <String, Object?>{});

      expect(donen.baslik, '');
      expect(donen.toplam, Kurus.sifir);
      expect(donen.kalemler, isEmpty);
      expect(donen.durum, IslemDurumu.beklemede);
    });

    test('tanınmayan tip kaydı düşürmez', () {
      final donen = Islem.fromMap('1', const <String, Object?>{
        Islem.alanTip: 'gelecektekiTip',
        Islem.alanToplamKurus: 5000,
      });

      expect(donen.tip, IslemTipi.satisFaturasi);
      expect(donen.toplam.deger, 5000);
    });
  });

  group('IslemTipi', () {
    test('anahtarlar Firestore değerleriyle eşleşir', () {
      expect(IslemTipi.satisFaturasi.anahtar, 'satisFaturasi');
      expect(IslemTipi.alisFaturasi.anahtar, 'alisFaturasi');
      expect(IslemTipi.tahsilat.anahtar, 'tahsilat');
      expect(IslemTipi.odeme.anahtar, 'odeme');
    });

    test('anahtardan tipe çevirir', () {
      expect(IslemTipi.anahtardan('tahsilat'), IslemTipi.tahsilat);
      expect(IslemTipi.anahtardan('yok'), isNull);
      expect(IslemTipi.anahtardan(null), isNull);
    });

    test('yalnızca faturalar kalem ve vade taşır', () {
      expect(IslemTipi.satisFaturasi.faturaMi, isTrue);
      expect(IslemTipi.alisFaturasi.faturaMi, isTrue);
      expect(IslemTipi.tahsilat.faturaMi, isFalse);
      expect(IslemTipi.odeme.faturaMi, isFalse);
    });

    test('işaret yönü tabloyla aynı', () {
      expect(IslemTipi.satisFaturasi.isaret, 1);
      expect(IslemTipi.odeme.isaret, 1);
      expect(IslemTipi.tahsilat.isaret, -1);
      expect(IslemTipi.alisFaturasi.isaret, -1);
    });
  });

  group('IslemDurumu', () {
    test('bilinmeyen değer beklemede sayılır', () {
      expect(IslemDurumu.anahtardan('yok'), IslemDurumu.beklemede);
      expect(IslemDurumu.anahtardan(null), IslemDurumu.beklemede);
      expect(
        IslemDurumu.anahtardan('teslimEdildi'),
        IslemDurumu.teslimEdildi,
      );
    });
  });
}
