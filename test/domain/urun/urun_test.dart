import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/domain/urun/urun.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Urun', () {
    test('kaydedilmemiş ürün yeni sayılır', () {
      const urun = Urun.yeni();

      expect(urun.yeniMi, isTrue);
      expect(urun.ad, '');
      expect(urun.fiyat, Kurus.sifir);
      expect(urun.aktif, isTrue);
    });

    test('arama anahtarı addan türetilir ve normalize edilir', () {
      const urun = Urun(id: '1', ad: 'Elma Scarlet M9');

      expect(urun.aramaAnahtari, 'elma scarlet m9');
    });

    test('arama anahtarı Türkçe harfleri düzleştirir', () {
      const urun = Urun(id: '1', ad: 'Şeftali Çıplak Kök');

      expect(urun.aramaAnahtari, 'seftali ciplak kok');
    });

    test('aynı adı taşıyan iki kayıt mükerrer sayılır', () {
      const biri = Urun(id: '1', ad: 'Elma Scarlet');
      const digeri = Urun(id: '2', ad: 'ELMA  scarlet');

      expect(biri.ayniUrunMu(digeri), isTrue);
    });

    test('farklı ad mükerrer değildir', () {
      const biri = Urun(id: '1', ad: 'Elma Scarlet 1 yaş');
      const digeri = Urun(id: '2', ad: 'Elma Scarlet 2 yaş');

      expect(biri.ayniUrunMu(digeri), isFalse);
    });
  });

  group('fromMap / toMap', () {
    test('gidiş-dönüşte alan kaybı olmaz', () {
      final urun = Urun(
        id: '1',
        ad: 'Elma Scarlet M9',
        fiyat: Kurus.liradan(45),
        olusturmaTarihi: DateTime(2024, 3, 1),
        guncellemeTarihi: DateTime(2024, 3, 2),
      );

      final donen = Urun.fromMap('1', urun.toMap());

      expect(donen, urun);
    });

    test('fiyat Firestore\'a int yazılır', () {
      const urun = Urun(id: '1', ad: 'çam', fiyat: Kurus(6000));

      expect(urun.toMap()[Urun.alanFiyatKurus], isA<int>());
      expect(urun.toMap()[Urun.alanFiyatKurus], 6000);
    });

    test('arama anahtarı belgeye yazılır', () {
      const urun = Urun(id: '1', ad: 'Elma Scarlet');

      expect(urun.duzenlenebilirAlanlar()[Urun.alanAramaAnahtari], 'elma scarlet');
    });

    test('düzenlenebilir alanlar aktiflik ve zaman damgası içermez', () {
      const urun = Urun(id: '1', ad: 'çam');
      final alanlar = urun.duzenlenebilirAlanlar();

      expect(alanlar.containsKey(Urun.alanAktif), isFalse);
      expect(alanlar.containsKey(Urun.alanOlusturmaTarihi), isFalse);
      expect(alanlar.containsKey(Urun.alanGuncellemeTarihi), isFalse);
    });

    test('eksik belge alanları varsayılana düşer, patlamaz', () {
      final donen = Urun.fromMap('bos', const <String, Object?>{});

      expect(donen.ad, '');
      expect(donen.fiyat, Kurus.sifir);
      expect(donen.aktif, isTrue);
    });
  });

  // Katalog önceden tur/cesit/anac/yas/kokTipi alanlarını tutuyordu. Göç
  // scripti çalıştırılmıyor; eski belgeler okunurken ada dönüştürülüyor.
  // Bu okuma düşerse kullanıcının katalogu boş görünür.
  group('Eski fidan kaydı uyumu', () {
    test('beş alanlı eski kayıt tek ada dönüşür', () {
      final donen = Urun.fromMap('1', const <String, Object?>{
        'tur': 'Elma',
        'cesit': 'Scarlet',
        'anac': 'M9',
        'yas': 2,
        'kokTipi': 'tuplu',
        'varsayilanFiyatKurus': 4500,
        'aktif': true,
      });

      expect(donen.ad, 'Elma Scarlet M9 2 yaş tüplü');
      expect(donen.fiyat.deger, 4500);
    });

    test('isteğe bağlı alanları boş eski kayıt sarkan boşluk bırakmaz', () {
      final donen = Urun.fromMap('1', const <String, Object?>{
        'tur': 'Çam',
        'cesit': '',
      });

      expect(donen.ad, 'Çam');
    });

    test('çıplak kök eski kaydı okunur', () {
      final donen = Urun.fromMap('1', const <String, Object?>{
        'tur': 'Kiraz',
        'cesit': '0900',
        'kokTipi': 'ciplakKok',
      });

      expect(donen.ad, 'Kiraz 0900 çıplak kök');
    });

    test('tanınmayan kök tipi ada eklenmez', () {
      final donen = Urun.fromMap('1', const <String, Object?>{
        'tur': 'Kiraz',
        'cesit': '0900',
        'kokTipi': 'gelecektekiTip',
      });

      expect(donen.ad, 'Kiraz 0900');
    });

    test('yeni ad alanı varsa eski alanlara bakılmaz', () {
      final donen = Urun.fromMap('1', const <String, Object?>{
        'ad': 'nakliye',
        'tur': 'Elma',
        'cesit': 'Scarlet',
      });

      expect(donen.ad, 'nakliye');
    });

    test('eski fiyat alanı yeni alan yoksa okunur', () {
      final donen = Urun.fromMap('1', const <String, Object?>{
        'ad': 'çam',
        'varsayilanFiyatKurus': 6000,
      });

      expect(donen.fiyat.deger, 6000);
    });

    test('yeni fiyat alanı eskisinin önüne geçer', () {
      final donen = Urun.fromMap('1', const <String, Object?>{
        'ad': 'çam',
        'fiyatKurus': 7000,
        'varsayilanFiyatKurus': 6000,
      });

      expect(donen.fiyat.deger, 7000);
    });

    test('eski kayıt kaydedilince yeni şemaya geçer', () {
      final okunan = Urun.fromMap('1', const <String, Object?>{
        'tur': 'Elma',
        'cesit': 'Scarlet',
        'varsayilanFiyatKurus': 4500,
      });

      final yazilan = okunan.duzenlenebilirAlanlar();

      expect(yazilan[Urun.alanAd], 'Elma Scarlet');
      expect(yazilan[Urun.alanFiyatKurus], 4500);
      expect(yazilan.containsKey('tur'), isFalse);
      expect(yazilan.containsKey('varsayilanFiyatKurus'), isFalse);
    });
  });
}
