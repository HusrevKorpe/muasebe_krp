import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/domain/islem/islem.dart';
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
            tur: 'zeytin',
            miktar: 100,
            birimFiyat: Kurus.liradan(7),
          ),
        ],
      );

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
            tur: 'zeytin',
            miktar: 1,
            birimFiyat: Kurus.liradan(7),
          ),
        ],
      );

      expect(
        () => fatura.kalemler.add(
          IslemKalemi.birimFiyattan(
            tur: 'ek',
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
    test('kalemsiz kurulur', () {
      final tahsilat = Islem.odeme(
        tip: IslemTipi.tahsilat,
        baslik: 'Müşteriden Tahsilat',
        islemTarihi: DateTime(2024, 3, 1),
        tutar: Kurus.liradan(10000),
      );

      expect(tahsilat.kalemler, isEmpty);
      expect(tahsilat.toplam.deger, 1000000);
    });
  });

  group('Islem.hesapGorme', () {
    // Kullanıcının deyişiyle "hesap görme": pazarlıkla silinen kalan bakiye.
    // Kayıt bakiyeyi tam sıfıra indirmeli, yönü de bakiyenin işaretinden
    // gelmeli (bkz. `fazlar/faz-2-islemler.md` → Hesap görme).
    test('cari bize borçluyken alacak yazılır ve bakiyeyi sıfırlar', () {
      final bakiye = Kurus.liradan(5000);
      final kayit = Islem.hesapGorme(
        bakiye: bakiye,
        baslik: 'Hesap görüldü',
        islemTarihi: DateTime(2026, 8, 19),
      );

      expect(kayit.tip, IslemTipi.hesapGorulduAlacak);
      expect(kayit.toplam, bakiye);
      expect(kayit.bakiyeEtkisi.deger, -bakiye.deger);
      expect((bakiye + kayit.bakiyeEtkisi).sifirMi, isTrue);
    });

    test('biz cariye borçluyken borç yazılır ve bakiyeyi sıfırlar', () {
      final bakiye = -Kurus.liradan(5000);
      final kayit = Islem.hesapGorme(
        bakiye: bakiye,
        baslik: 'Hesap görüldü',
        islemTarihi: DateTime(2026, 8, 19),
      );

      expect(kayit.tip, IslemTipi.hesapGorulduBorc);
      expect(kayit.toplam, bakiye.mutlak, reason: 'tutar işaretsiz saklanır');
      expect((bakiye + kayit.bakiyeEtkisi).sifirMi, isTrue);
    });

    test('kalemi yoktur ve kaydedilmemiş kurulur', () {
      final kayit = Islem.hesapGorme(
        bakiye: Kurus.liradan(100),
        baslik: 'Hesap görüldü',
        islemTarihi: DateTime(2026, 8, 19),
      );

      expect(kayit.kalemler, isEmpty);
      expect(kayit.yeniMi, isTrue);
      expect(kayit.iptalMi, isFalse);
    });

    test('iptal edilince bakiyeye katkısı kalmaz', () {
      // "Geri alınabilsin" isteğinin karşılığı: kayıt silinmez, iptal edilir ve
      // kapatılan bakiye eski hâline döner.
      final kayit = Islem.hesapGorme(
        bakiye: Kurus.liradan(5000),
        baslik: 'Hesap görüldü',
        islemTarihi: DateTime(2026, 8, 19),
      );

      expect(kayit.kopyala(iptal: true).bakiyeEtkisi, Kurus.sifir);
    });

    test('kapanacak bakiye yoksa kurulamaz', () {
      expect(
        () => Islem.hesapGorme(
          bakiye: Kurus.sifir,
          baslik: 'Hesap görüldü',
          islemTarihi: DateTime(2026, 8, 19),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('gidiş-dönüşte tipi korunur', () {
      final kayit = Islem.hesapGorme(
        bakiye: Kurus.liradan(5000),
        baslik: 'Hesap görüldü',
        islemTarihi: DateTime(2026, 8, 19),
      );
      final okunan = Islem.fromMap('x', kayit.toMap());

      expect(okunan.tip, IslemTipi.hesapGorulduAlacak);
      expect(okunan.toplam, kayit.toplam);
      expect(okunan.baslik, 'Hesap görüldü');
    });
  });

  group('fromMap / toMap', () {
    test('faturada gidiş-dönüşte alan kaybı olmaz', () {
      final veri = zeytinHurmaFaturasi.toMap();

      final donen = Islem.fromMap('01', veri);

      expect(donen.tip, IslemTipi.satisFaturasi);
      expect(donen.baslik, 'Zeytin-Hurma');
      expect(donen.islemTarihi, DateTime(2021, 9, 17));
      expect(donen.kalemler, hasLength(3));
      expect(donen.kalemler[1].tutar.deger, 3100000);
      expect(donen.kalemler[1].birimFiyat.deger, 1879);
      expect(donen.toplam.deger, 9400000);
      expect(donen.iptalMi, isFalse);
    });

    test('kalemleriyle birlikte tam tur atar', () {
      final donen = Islem.fromMap('09', sertCekirdekliFaturasi.toMap());

      expect(donen.kalemler, hasLength(6));
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

      expect(veri[Islem.alanToplamKurus], isA<int>());
      final kalem = (veri[Islem.alanKalemler]! as List).first as Map;
      expect(kalem[IslemKalemi.alanTutarKurus], isA<int>());
      expect(kalem[IslemKalemi.alanBirimFiyatKurus], isA<int>());
    });

    test('yazılabilir alanlar iptal ve oluşturma tarihini içermez', () {
      final veri = zeytinHurmaFaturasi.yazilabilirAlanlar();

      expect(veri.containsKey(Islem.alanIptal), isFalse);
      expect(veri.containsKey(Islem.alanIptalNedeni), isFalse);
      expect(veri.containsKey(Islem.alanOlusturmaTarihi), isFalse);
      expect(veri[Islem.alanTip], 'satisFaturasi');
    });

    test('güncelleme tarihini de repository yazar, model değil', () {
      // Sunucu saatiyle yazılan alanlar `yazilabilirAlanlar` dışında kalır;
      // aksi hâlde düzenleme cihaz saatini yazardı (bkz. KURALLAR.md §4.2).
      final veri = zeytinHurmaFaturasi.yazilabilirAlanlar();

      expect(veri.containsKey(Islem.alanGuncellemeTarihi), isFalse);
    });

    test('düzenlenmiş kaydın güncelleme tarihi okunur', () {
      final veri = <String, Object?>{
        ...zeytinHurmaFaturasi.toMap(),
        Islem.alanGuncellemeTarihi: DateTime(2024, 5, 6, 14, 30),
      };

      final donen = Islem.fromMap('01', veri);

      expect(donen.guncellemeTarihi, DateTime(2024, 5, 6, 14, 30));
      expect(donen.duzenlenmisMi, isTrue);
    });

    test('hiç düzenlenmemiş kayıt düzenlenmiş görünmez', () {
      final donen = Islem.fromMap('01', zeytinHurmaFaturasi.toMap());

      expect(donen.guncellemeTarihi, isNull);
      expect(donen.duzenlenmisMi, isFalse);
    });

    test('vade ve durum alanları artık yazılmaz', () {
      final veri = zeytinHurmaFaturasi.toMap();

      expect(veri.containsKey('vadeTarihi'), isFalse);
      expect(veri.containsKey(Islem.alanEskiDurum), isFalse);
    });

    test('eksik belge alanları varsayılana düşer, patlamaz', () {
      final donen = Islem.fromMap('bos', const <String, Object?>{});

      expect(donen.baslik, '');
      expect(donen.toplam, Kurus.sifir);
      expect(donen.kalemler, isEmpty);
      expect(donen.iptalMi, isFalse);
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
      expect(IslemTipi.hesapGorulduAlacak.anahtar, 'hesapGorulduAlacak');
      expect(IslemTipi.hesapGorulduBorc.anahtar, 'hesapGorulduBorc');
    });

    test('anahtardan tipe çevirir', () {
      expect(IslemTipi.anahtardan('tahsilat'), IslemTipi.tahsilat);
      expect(IslemTipi.anahtardan('yok'), isNull);
      expect(IslemTipi.anahtardan(null), isNull);
    });

    test('yalnızca faturalar kalem taşır', () {
      expect(IslemTipi.satisFaturasi.faturaMi, isTrue);
      expect(IslemTipi.alisFaturasi.faturaMi, isTrue);
      expect(IslemTipi.tahsilat.faturaMi, isFalse);
      expect(IslemTipi.odeme.faturaMi, isFalse);
    });

    test('işaret yönü tabloyla aynı', () {
      expect(IslemTipi.satisFaturasi.isaret, 1);
      expect(IslemTipi.odeme.isaret, 1);
      expect(IslemTipi.hesapGorulduBorc.isaret, 1);
      expect(IslemTipi.tahsilat.isaret, -1);
      expect(IslemTipi.alisFaturasi.isaret, -1);
      expect(IslemTipi.hesapGorulduAlacak.isaret, -1);
    });

    test('hesapGormeMi yalnızca kapanış kayıtlarında doğru', () {
      expect(IslemTipi.hesapGorulduAlacak.hesapGormeMi, isTrue);
      expect(IslemTipi.hesapGorulduBorc.hesapGormeMi, isTrue);
      for (final tip in IslemTipi.girisTipleri) {
        expect(tip.hesapGormeMi, isFalse);
      }
    });

    test('hesap görme kaydı düzenlenemez, diğerleri düzenlenebilir', () {
      // Tutarı o günkü bakiyeden türetildi; elle değişirse bakiye sıfırda
      // kalmaz. Geri alma yolu iptal.
      expect(IslemTipi.hesapGorulduAlacak.duzenlenebilirMi, isFalse);
      expect(IslemTipi.hesapGorulduBorc.duzenlenebilirMi, isFalse);
      for (final tip in IslemTipi.girisTipleri) {
        expect(tip.duzenlenebilirMi, isTrue);
      }
    });

    test('giriş düğmeleri yalnızca dört tipi gösterir', () {
      // Hesap görme kullanıcının doğrudan girdiği bir tip değil; tutarı
      // bakiyeden geliyor ve kişi sayfasının menüsünden kaydediliyor.
      expect(IslemTipi.girisTipleri, <IslemTipi>[
        IslemTipi.satisFaturasi,
        IslemTipi.alisFaturasi,
        IslemTipi.tahsilat,
        IslemTipi.odeme,
      ]);
    });
  });

  group('Eski kayıt uyumu', () {
    // Vade ve durum alanları modelden kalktı, ama Firestore'daki geçmiş
    // kayıtlarda duruyorlar. İptal bilgisi eskiden yalnızca `durum` alanına
    // yazılıyordu; okuması düşerse iptalli kayıt bakiyeye geri sızar.
    test('durum alanına yazılmış iptal okunmaya devam eder', () {
      final donen = Islem.fromMap('1', const <String, Object?>{
        Islem.alanTip: 'satisFaturasi',
        Islem.alanToplamKurus: 5000,
        Islem.alanEskiDurum: 'iptal',
      });

      expect(donen.iptalMi, isTrue);
      expect(donen.bakiyeEtkisi, Kurus.sifir);
    });

    test('iptal bayrağı tek başına da yeter', () {
      final donen = Islem.fromMap('1', const <String, Object?>{
        Islem.alanTip: 'satisFaturasi',
        Islem.alanToplamKurus: 5000,
        Islem.alanIptal: true,
      });

      expect(donen.iptalMi, isTrue);
    });

    test('teslimEdildi durumu kaydı iptal saymaz', () {
      final donen = Islem.fromMap('1', const <String, Object?>{
        Islem.alanTip: 'satisFaturasi',
        Islem.alanToplamKurus: 5000,
        Islem.alanEskiDurum: 'teslimEdildi',
      });

      expect(donen.iptalMi, isFalse);
      expect(donen.bakiyeEtkisi.deger, 5000);
    });

    test('artık kullanılmayan vade alanı okumayı bozmaz', () {
      final donen = Islem.fromMap('1', <String, Object?>{
        Islem.alanTip: 'satisFaturasi',
        Islem.alanToplamKurus: 5000,
        'vadeTarihi': DateTime(2024, 5, 1),
      });

      expect(donen.toplam.deger, 5000);
    });
  });
}
