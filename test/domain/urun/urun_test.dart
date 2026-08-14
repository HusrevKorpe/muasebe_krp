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

    test('ad üç parçadan türetilir', () {
      const urun = Urun(id: '1', tur: 'Elma', cesit: 'Scarlet', anac: 'M9');

      expect(urun.ad, 'Elma Scarlet M9');
    });

    test('boş bırakılan parça ada girmez', () {
      const urun = Urun(id: '1', tur: 'Çam');

      expect(urun.ad, 'Çam');
    });

    test('anacı olmayan fidanda sarkan boşluk kalmaz', () {
      const urun = Urun(id: '1', tur: 'Kiraz', cesit: '0900');

      expect(urun.ad, 'Kiraz 0900');
    });

    test('arama anahtarı addan türetilir ve normalize edilir', () {
      const urun = Urun(id: '1', tur: 'Elma', cesit: 'Scarlet', anac: 'M9');

      expect(urun.aramaAnahtari, 'elma scarlet m9');
    });

    test('arama anahtarı Türkçe harfleri düzleştirir', () {
      const urun = Urun(id: '1', tur: 'Şeftali', cesit: 'Çıplak Kök');

      expect(urun.aramaAnahtari, 'seftali ciplak kok');
    });

    test('aynı adı taşıyan iki kayıt mükerrer sayılır', () {
      const biri = Urun(id: '1', tur: 'Elma', cesit: 'Scarlet');
      const digeri = Urun(id: '2', tur: 'ELMA ', cesit: ' scarlet');

      expect(biri.ayniUrunMu(digeri), isTrue);
    });

    test('parçaları farklı dağılmış aynı ad mükerrer sayılır', () {
      // Biri katalogdan, biri elle girilmiş olabilir; faturaya aynı metin
      // düşüyorsa aynı üründür.
      const biri = Urun(id: '1', tur: 'Elma', cesit: 'Scarlet', anac: 'M9');
      const digeri = Urun(id: '2', tur: 'Elma Scarlet M9');

      expect(biri.ayniUrunMu(digeri), isTrue);
    });

    test('farklı anaç mükerrer değildir', () {
      const biri = Urun(id: '1', tur: 'Elma', cesit: 'Scarlet', anac: 'M9');
      const digeri = Urun(id: '2', tur: 'Elma', cesit: 'Scarlet', anac: 'MM106');

      expect(biri.ayniUrunMu(digeri), isFalse);
    });
  });

  group('fromMap / toMap', () {
    test('gidiş-dönüşte alan kaybı olmaz', () {
      final urun = Urun(
        id: '1',
        tur: 'Elma',
        cesit: 'Scarlet',
        anac: 'M9',
        fiyat: Kurus.liradan(45),
        olusturmaTarihi: DateTime(2024, 3, 1),
        guncellemeTarihi: DateTime(2024, 3, 2),
      );

      final donen = Urun.fromMap('1', urun.toMap());

      expect(donen, urun);
    });

    test('üç parça belgeye ayrı ayrı yazılır', () {
      const urun = Urun(id: '1', tur: 'Elma', cesit: 'Scarlet', anac: 'M9');
      final alanlar = urun.duzenlenebilirAlanlar();

      expect(alanlar[Urun.alanTur], 'Elma');
      expect(alanlar[Urun.alanCesit], 'Scarlet');
      expect(alanlar[Urun.alanAnac], 'M9');
    });

    test('türetilmiş ad da belgeye yazılır', () {
      // Alan hem konsolda okunurluk için hem göç işareti olarak duruyor
      // (bkz. Urun.alanAd).
      const urun = Urun(id: '1', tur: 'Elma', cesit: 'Scarlet');

      expect(urun.duzenlenebilirAlanlar()[Urun.alanAd], 'Elma Scarlet');
    });

    test('fiyat Firestore\'a int yazılır', () {
      const urun = Urun(id: '1', tur: 'çam', fiyat: Kurus(6000));

      expect(urun.toMap()[Urun.alanFiyatKurus], isA<int>());
      expect(urun.toMap()[Urun.alanFiyatKurus], 6000);
    });

    test('arama anahtarı belgeye yazılır', () {
      const urun = Urun(id: '1', tur: 'Elma', cesit: 'Scarlet');

      expect(
        urun.duzenlenebilirAlanlar()[Urun.alanAramaAnahtari],
        'elma scarlet',
      );
    });

    test('düzenlenebilir alanlar aktiflik ve zaman damgası içermez', () {
      const urun = Urun(id: '1', tur: 'çam');
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

  // Katalog iki kez şema değiştirdi: önce beş alan, sonra tek serbest ad, şimdi
  // yeniden üç alan. Göç scripti çalıştırılmıyor; üçü de okunabilmeli. Bu okuma
  // düşerse kullanıcının katalogu boş görünür.
  group('Eski kayıt uyumu', () {
    test('beş alanlı ilk kayıt okunur, yaş ve kök tipi anaca eklenir', () {
      final donen = Urun.fromMap('1', const <String, Object?>{
        'tur': 'Elma',
        'cesit': 'Scarlet',
        'anac': 'M9',
        'yas': 2,
        'kokTipi': 'tuplu',
        'varsayilanFiyatKurus': 4500,
        'aktif': true,
      });

      expect(donen.tur, 'Elma');
      expect(donen.cesit, 'Scarlet');
      expect(donen.anac, 'M9 2 yaş tüplü');
      expect(donen.ad, 'Elma Scarlet M9 2 yaş tüplü');
      expect(donen.fiyat.deger, 4500);
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

    test('tek adlı ara kayıt olduğu gibi türe düşer', () {
      // Bölmeyi tahminle yapmıyoruz: "asma anacı atasarısı" tek parçadır,
      // boşluktan bölmek onu bozardı.
      final donen = Urun.fromMap('1', const <String, Object?>{
        'ad': 'asma anacı atasarısı',
      });

      expect(donen.tur, 'asma anacı atasarısı');
      expect(donen.cesit, '');
      expect(donen.anac, '');
      expect(donen.ad, 'asma anacı atasarısı');
    });

    test('bugünkü kayıtta parçalar türetilmiş adın önüne geçer', () {
      final donen = Urun.fromMap('1', const <String, Object?>{
        'tur': 'Elma',
        'cesit': 'Scarlet',
        'anac': 'M9',
        'ad': 'Elma Scarlet M9',
      });

      expect(donen.cesit, 'Scarlet');
      expect(donen.ad, 'Elma Scarlet M9');
    });

    test('kaydedilmiş kayıtta yaş eki ikinci kez uygulanmaz', () {
      // Kullanıcı anaçtaki "2 yaş" ekini silip kaydetti; belgede duran eski
      // `yas` alanı onu geri getirmemeli.
      final donen = Urun.fromMap('1', const <String, Object?>{
        'tur': 'Elma',
        'cesit': 'Scarlet',
        'anac': 'M9',
        'ad': 'Elma Scarlet M9',
        'yas': 2,
        'kokTipi': 'tuplu',
      });

      expect(donen.anac, 'M9');
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

    test('eski kayıt kaydedilince bugünkü şemaya geçer', () {
      final okunan = Urun.fromMap('1', const <String, Object?>{
        'tur': 'Elma',
        'cesit': 'Scarlet',
        'varsayilanFiyatKurus': 4500,
      });

      final yazilan = okunan.duzenlenebilirAlanlar();

      expect(yazilan[Urun.alanTur], 'Elma');
      expect(yazilan[Urun.alanAd], 'Elma Scarlet');
      expect(yazilan[Urun.alanFiyatKurus], 4500);
      expect(yazilan.containsKey('varsayilanFiyatKurus'), isFalse);
      expect(yazilan.containsKey('yas'), isFalse);
    });
  });
}
