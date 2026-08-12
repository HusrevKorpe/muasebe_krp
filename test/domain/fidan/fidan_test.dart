import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/domain/fidan/fidan.dart';
import 'package:fidancari/domain/fidan/kok_tipi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Fidan fidanKur({
    String id = 'fidan-1',
    String tur = 'Elma',
    String cesit = 'Scarlet',
    String? anac,
    int? yas,
    KokTipi? kokTipi,
    Kurus varsayilanFiyat = Kurus.sifir,
  }) => Fidan(
    id: id,
    tur: tur,
    cesit: cesit,
    anac: anac,
    yas: yas,
    kokTipi: kokTipi,
    varsayilanFiyat: varsayilanFiyat,
  );

  group('goruntuAdi', () {
    test('opsiyonel alanlar boşken ayraç sarkmaz', () {
      expect(fidanKur().goruntuAdi, 'Elma / Scarlet');
    });

    test('anaç varsa üçüncü bölüm olarak eklenir', () {
      expect(fidanKur(anac: 'M9').goruntuAdi, 'Elma / Scarlet / M9');
    });

    test('tüm alanlar dolu', () {
      final fidan = fidanKur(anac: 'M9', yas: 2, kokTipi: KokTipi.tuplu);

      expect(fidan.goruntuAdi, 'Elma / Scarlet / M9 · 2 Yaş · Tüplü');
    });

    test('anaç yokken yaş ve kök tipi yine de eklenir', () {
      final fidan = fidanKur(yas: 1, kokTipi: KokTipi.ciplakKok);

      expect(fidan.goruntuAdi, 'Elma / Scarlet · 1 Yaş · Çıplak Kök');
    });

    test('yalnızca yaş girilmişse tek ek görünür', () {
      expect(fidanKur(yas: 2).goruntuAdi, 'Elma / Scarlet · 2 Yaş');
    });

    test('boş anaç metni bölüm açmaz', () {
      expect(fidanKur(anac: '  ').goruntuAdi, 'Elma / Scarlet');
    });
  });

  group('aramaAnahtari', () {
    test('tür, çeşit ve anaçtan üretilir', () {
      expect(fidanKur(anac: 'M9').aramaAnahtari, 'elma scarlet m9');
    });

    test('anaç yokken sonda boşluk kalmaz', () {
      expect(fidanKur().aramaAnahtari, 'elma scarlet');
    });

    test('Türkçe yazım farkları aynı anahtarı verir', () {
      // "Şeker" ve "seker" aynı fidanı bulmalı (KURALLAR.md §6.1).
      expect(
        fidanKur(cesit: 'Şeker').aramaAnahtari,
        fidanKur(cesit: 'seker').aramaAnahtari,
      );
      expect(fidanKur(cesit: 'Şeker').aramaAnahtari, 'elma seker');
    });

    test('noktasız I ve noktalı İ ayrımı korunur', () {
      expect(fidanKur(tur: 'IĞDIR').aramaAnahtari, 'igdir scarlet');
    });

    test('yaş ve kök tipi anahtara girmez', () {
      // "elma scarlet" araması iki yaşlısını da bulmalı.
      expect(
        fidanKur(yas: 2, kokTipi: KokTipi.tuplu).aramaAnahtari,
        fidanKur().aramaAnahtari,
      );
    });

    test('tür ve anaç anahtarları öneri sorgusu için ayrı üretilir', () {
      final fidan = fidanKur(tur: 'Elma', anac: 'MM106');

      expect(fidan.turAnahtari, 'elma');
      expect(fidan.anacAnahtari, 'mm106');
    });

    test('anaç yokken anaç anahtarı null kalır', () {
      // Alan `null` olunca kayıt öneri sorgusunun aralık süzgecine hiç girmez.
      expect(fidanKur().anacAnahtari, isNull);
      expect(fidanKur(anac: '   ').anacAnahtari, isNull);
    });
  });

  group('ayniFidanMi', () {
    test('aynı tür/çeşit/anaç/yaş/kök tipi mükerrer sayılır', () {
      final ilk = fidanKur(id: 'a', anac: 'M9', yas: 2);
      final ikinci = fidanKur(id: 'b', anac: 'M9', yas: 2);

      expect(ilk.ayniFidanMi(ikinci), isTrue);
    });

    test('yalnızca yaşı farklı olan ayrı fidandır', () {
      final birYas = fidanKur(id: 'a', anac: 'M9', yas: 1);
      final ikiYas = fidanKur(id: 'b', anac: 'M9', yas: 2);

      expect(birYas.ayniFidanMi(ikiYas), isFalse);
    });

    test('yalnızca kök tipi farklı olan ayrı fidandır', () {
      final tuplu = fidanKur(id: 'a', kokTipi: KokTipi.tuplu);
      final ciplak = fidanKur(id: 'b', kokTipi: KokTipi.ciplakKok);

      expect(tuplu.ayniFidanMi(ciplak), isFalse);
    });

    test('yazım farkı mükerrerliği gizlemez', () {
      final ilk = fidanKur(id: 'a', tur: 'ELMA', cesit: 'Şeker');
      final ikinci = fidanKur(id: 'b', tur: 'elma', cesit: 'seker');

      expect(ilk.ayniFidanMi(ikinci), isTrue);
    });
  });

  group('fromMap / toMap', () {
    test('gidiş-dönüşte alan kaybı olmaz', () {
      final fidan = fidanKur(
        anac: 'M9',
        yas: 2,
        kokTipi: KokTipi.tuplu,
        varsayilanFiyat: Kurus.liradan(18, 79),
      );

      final donen = Fidan.fromMap(fidan.id, fidan.toMap());

      expect(donen, fidan);
      expect(donen.goruntuAdi, fidan.goruntuAdi);
    });

    test('fiyat Firestore\'a da int yazılır', () {
      final veri = fidanKur(varsayilanFiyat: Kurus.liradan(45)).toMap();

      expect(veri[Fidan.alanVarsayilanFiyatKurus], 4500);
      expect(veri[Fidan.alanVarsayilanFiyatKurus], isA<int>());
    });

    test('arama anahtarları yazılan alanlar arasında', () {
      final veri = fidanKur(anac: 'M9').duzenlenebilirAlanlar();

      expect(veri[Fidan.alanAramaAnahtari], 'elma scarlet m9');
      expect(veri[Fidan.alanTurAnahtari], 'elma');
      expect(veri[Fidan.alanAnacAnahtari], 'm9');
    });

    test('eksik alanlar varsayılana düşer, patlamaz', () {
      final fidan = Fidan.fromMap('bos', const <String, Object?>{});

      expect(fidan.tur, '');
      expect(fidan.cesit, '');
      expect(fidan.anac, isNull);
      expect(fidan.yas, isNull);
      expect(fidan.kokTipi, isNull);
      expect(fidan.varsayilanFiyat, Kurus.sifir);
      expect(fidan.aktif, isTrue);
    });

    test('tanınmayan kök tipi null okunur', () {
      final fidan = Fidan.fromMap('a', const <String, Object?>{
        Fidan.alanTur: 'Elma',
        Fidan.alanCesit: 'Scarlet',
        Fidan.alanKokTipi: 'bilinmeyen',
      });

      expect(fidan.kokTipi, isNull);
      expect(fidan.goruntuAdi, 'Elma / Scarlet');
    });

    test('eski kayıtta double yazılmış fiyat yuvarlanarak okunur', () {
      final fidan = Fidan.fromMap('a', const <String, Object?>{
        Fidan.alanVarsayilanFiyatKurus: 1879.4,
      });

      expect(fidan.varsayilanFiyat.deger, 1879);
    });

    test('yaş sıfır ile yaş yok birbirine karışmaz', () {
      final sifirYas = Fidan.fromMap('a', const <String, Object?>{
        Fidan.alanTur: 'Elma',
        Fidan.alanCesit: 'Scarlet',
        Fidan.alanYas: 0,
      });

      expect(sifirYas.yas, 0);
      expect(sifirYas.goruntuAdi, 'Elma / Scarlet · 0 Yaş');
    });
  });

  group('yeniMi', () {
    test('kaydedilmemiş fidanın kimliği boştur', () {
      expect(const Fidan.yeni().yeniMi, isTrue);
      expect(fidanKur().yeniMi, isFalse);
    });
  });
}
