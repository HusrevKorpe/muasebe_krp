import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/domain/cari/cari.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ornek = Cari(
    id: 'cari-1',
    ad: 'Ahmet Koyuncu',
    unvan: 'Koyuncu Tarım Ltd.Şti',
    sehir: 'Isparta',
    telefon: '0246 000 00 00',
    adres: 'Merkez Mah. No:1',
    notlar: 'Toptan alıyor',
    bakiye: const Kurus(9400000),
    sonIslemTarihi: DateTime.utc(2021, 9, 17),
    olusturmaTarihi: DateTime.utc(2021, 1, 1),
    guncellemeTarihi: DateTime.utc(2025, 5, 24),
  );

  group('gidiş-dönüş dönüşümü', () {
    test('toMap → fromMap tüm alanları korur', () {
      expect(Cari.fromMap(ornek.id, ornek.toMap()), ornek);
    });

    test('yalnızca zorunlu alanı olan kayıt da bozulmadan döner', () {
      const yalin = Cari(id: 'cari-2', ad: 'Veli Demir');
      expect(Cari.fromMap(yalin.id, yalin.toMap()), yalin);
    });

    test('eksik alanlı belge varsayılanlarla okunur', () {
      // Firestore şemasızdır: eski sürümde yazılmış bir belgede alan hiç
      // olmayabilir. Model bu durumda patlamamalı.
      final cari = Cari.fromMap('cari-3', const <String, Object?>{
        'ad': 'Yeni Cari',
      });

      expect(cari.ad, 'Yeni Cari');
      expect(cari.bakiye, Kurus.sifir);
      expect(cari.aktif, isTrue, reason: 'aktif alanı yoksa aktif sayılır');
      expect(cari.unvan, isNull);
      expect(cari.sonIslemTarihi, isNull);
    });

    test('bakiye double yazılmış olsa bile tam sayıya çevrilir', () {
      // KURALLAR.md §3.1 — para asla double değil. Eski/bozuk bir belge
      // gelirse değer sessizce sıfırlanmamalı.
      final cari = Cari.fromMap('cari-4', const <String, Object?>{
        'ad': 'Test',
        'bakiyeKurus': 9400000.0,
      });

      expect(cari.bakiye, const Kurus(9400000));
    });

    test('boş metin alanları null olarak okunur', () {
      final cari = Cari.fromMap('cari-5', const <String, Object?>{
        'ad': 'Test',
        'unvan': '   ',
      });

      expect(cari.unvan, isNull);
    });
  });

  group('aramaAnahtari', () {
    test('addan türetilir ve Türkçe harfleri katlar', () {
      const cari = Cari(id: 'x', ad: 'İstanbul Fidancılık');
      expect(cari.aramaAnahtari, 'istanbul fidancilik');
    });

    test('aynı adın farklı yazımları tek anahtar üretir', () {
      // Kabul kriteri: "İstanbul" araması istanbul / İSTANBUL / ıstanbul
      // yazımlarıyla da sonuç vermeli.
      const yazimlar = <String>[
        'İstanbul',
        'istanbul',
        'ISTANBUL',
        'ıstanbul',
        'İSTANBUL',
      ];

      final anahtarlar = yazimlar
          .map((yazim) => Cari(id: 'x', ad: yazim).aramaAnahtari)
          .toSet();

      expect(anahtarlar, <String>{'istanbul'});
    });

    test('saklanan eski anahtar değil, güncel ad esas alınır', () {
      // Ad değişip anahtar eski kalırsa arama sessizce yanlış sonuç verir.
      final cari = Cari.fromMap('x', const <String, Object?>{
        'ad': 'Yeni Ad',
        'aramaAnahtari': 'eski ad',
      });

      expect(cari.aramaAnahtari, 'yeni ad');
      expect(cari.toMap()['aramaAnahtari'], 'yeni ad');
    });

    test('baştaki ve aradaki fazla boşluklar temizlenir', () {
      const cari = Cari(id: 'x', ad: '  Ahmet   Koyuncu ');
      expect(cari.aramaAnahtari, 'ahmet koyuncu');
    });
  });

  group('duzenlenebilirAlanlar', () {
    test('bakiye, aktiflik ve tarihleri içermez', () {
      // Cari düzenlenirken bu harita olduğu gibi gönderiliyor. Bakiye buraya
      // sızarsa Faz 2'de bir işlemin güncellediği bakiye form kaydıyla ezilir.
      final alanlar = ornek.duzenlenebilirAlanlar();

      expect(alanlar.containsKey('bakiyeKurus'), isFalse);
      expect(alanlar.containsKey('aktif'), isFalse);
      expect(alanlar.containsKey('sonIslemTarihi'), isFalse);
      expect(alanlar.containsKey('olusturmaTarihi'), isFalse);
      expect(alanlar.containsKey('guncellemeTarihi'), isFalse);
    });

    test('kullanıcı alanlarını ve arama anahtarını içerir', () {
      final alanlar = ornek.duzenlenebilirAlanlar();

      expect(alanlar['ad'], 'Ahmet Koyuncu');
      expect(alanlar['sehir'], 'Isparta');
      expect(alanlar['aramaAnahtari'], 'ahmet koyuncu');
    });
  });

  group('türetilmiş alanlar', () {
    test('yeniMi kimliksiz kayıtta doğrudur', () {
      expect(const Cari.yeni().yeniMi, isTrue);
      expect(ornek.yeniMi, isFalse);
    });

    test('altBaslik ünvanı, yoksa şehri verir', () {
      expect(ornek.altBaslik, 'Koyuncu Tarım Ltd.Şti');
      expect(
        const Cari(id: 'x', ad: 'A', sehir: 'Adana').altBaslik,
        'Adana',
      );
      expect(const Cari(id: 'x', ad: 'A').altBaslik, isNull);
    });
  });
}
