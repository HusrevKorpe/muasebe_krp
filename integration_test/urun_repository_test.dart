import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/data/urun/urun_repository.dart';
import 'package:fidancari/domain/isletme/isletme.dart';
import 'package:fidancari/domain/urun/urun.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'emulator_yardimcilari.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore firestore;
  late FirebaseAuth kimlik;
  late UrunRepository repository;
  late CollectionReference<Map<String, dynamic>> koleksiyon;

  setUpAll(emulatoreBaglan);

  setUp(() async {
    firestore = FirebaseFirestore.instance;
    kimlik = FirebaseAuth.instance;

    final isletmeId = await yeniKullaniciAc(kimlik);
    koleksiyon = firestore
        .collection(Isletme.koleksiyon)
        .doc(isletmeId)
        .collection(Urun.koleksiyon);
    repository = UrunRepository(firestore: firestore, isletmeId: isletmeId);
  });

  tearDown(() => kimlik.signOut());

  /// Ürünü ekler ve sunucu onayını bekler; testler yazma sonrası okumaya
  /// güvenebilsin diye. Oluşturma tarihinin dolması, sunucunun yazmayı
  /// gerçekten onayladığının işareti.
  Future<String> urunEkle(String ad, {Kurus fiyat = Kurus.sifir}) async {
    final urunId = await repository.ekle(Urun(id: '', tur: ad, fiyat: fiyat));
    await sunucudaBekle(
      koleksiyon.doc(urunId),
      kosul: (veri) => veri[Urun.alanOlusturmaTarihi] != null,
    );
    return urunId;
  }

  /// Canlı listenin ilk yayınındaki adlar.
  ///
  /// İlk yayın önbellekten gelir; testteki her yazma `sunucudaBekle` ile
  /// onaylandığı ve yerel yazma önbelleğe anında düştüğü için o yayın da tam
  /// sonucu taşır.
  Future<List<String>> adlariListele({
    String arama = '',
    int sinir = UrunRepository.varsayilanSayfaBoyu,
  }) async {
    final sayfa = await repository
        .listeyiIzle(arama: arama, sinir: sinir)
        .first;
    return sayfa.kayitlar
        .map((kayit) => kayit.urun.ad)
        .toList(growable: false);
  }

  group('ekle', () {
    test('yeni ürün sunucuya yazılır ve varsayılanları alır', () async {
      final urunId = await urunEkle(
        'Elma Scarlet M9',
        fiyat: Kurus.liradan(45),
      );
      final veri = (await sunucudaBekle(koleksiyon.doc(urunId))).data()!;

      expect(veri[Urun.alanAd], 'Elma Scarlet M9');
      // Para Firestore'a da int yazılır (KURALLAR.md §3.1).
      expect(veri[Urun.alanFiyatKurus], 4500);
      expect(veri[Urun.alanFiyatKurus], isA<int>());
      expect(veri[Urun.alanAramaAnahtari], 'elma scarlet m9');
      expect(veri[Urun.alanAktif], isTrue);
    });

    test('fiyatsız ürün sıfır fiyatla yazılır', () async {
      final urunId = await urunEkle('nakliye');
      final veri = (await sunucudaBekle(koleksiyon.doc(urunId))).data()!;

      expect(veri[Urun.alanFiyatKurus], 0);
    });
  });

  group('listeyiIzle', () {
    test('yalnızca aktif ürünler döner, kayıt silinmez', () async {
      await urunEkle('Elma Scarlet');
      final pasifId = await urunEkle('Zeytin Gemlik');

      await repository.aktifligiDegistir(pasifId, aktif: false);
      await sunucudaBekle(
        koleksiyon.doc(pasifId),
        kosul: (veri) => veri[Urun.alanAktif] == false,
      );

      expect(await adlariListele(), <String>['Elma Scarlet']);

      final pasif = await koleksiyon.doc(pasifId).get();
      expect(pasif.exists, isTrue, reason: 'kayıt silinmemeli');
    });

    test('liste ada göre alfabetik gelir', () async {
      await urunEkle('Zeytin Gemlik');
      await urunEkle('Elma Starking');
      await urunEkle('Elma Scarlet');

      expect(await adlariListele(), <String>[
        'Elma Scarlet',
        'Elma Starking',
        'Zeytin Gemlik',
      ]);
    });

    test('sınır büyüdükçe kayıt tekrarlamaz ve atlamaz', () async {
      for (final cesit in <String>['Amasya', 'Golden', 'Scarlet', 'Starking']) {
        await urunEkle('Elma $cesit');
      }

      // "Daha yükle" imleci yürütmez, sınırı büyütür: her adımda liste baştan
      // gelir ve öncekini olduğu gibi kapsamalıdır.
      expect(await adlariListele(sinir: 2), <String>[
        'Elma Amasya',
        'Elma Golden',
      ]);
      expect(await adlariListele(sinir: 4), <String>[
        'Elma Amasya',
        'Elma Golden',
        'Elma Scarlet',
        'Elma Starking',
      ]);
    });

    test('aynı adlı kayıtlar sınır büyürken kaybolmaz', () async {
      // Arama anahtarları birebir aynı; sıralama yalnızca anahtara baksaydı
      // sınır büyüdükçe sıra değişir ve kullanıcı satır atlardı.
      for (var sira = 0; sira < 3; sira++) {
        await urunEkle('Elma Scarlet M9');
      }

      final kimlikler = <List<String>>[];
      for (final sinir in <int>[1, 2, 3]) {
        final sayfa = await repository.listeyiIzle(sinir: sinir).first;
        kimlikler.add(
          sayfa.kayitlar.map((kayit) => kayit.urun.id).toList(growable: false),
        );
      }

      expect(kimlikler.last.toSet(), hasLength(3), reason: 'kayıt tekrarlanmamalı');
      for (var sira = 1; sira < kimlikler.length; sira++) {
        expect(
          kimlikler[sira].take(sira),
          kimlikler[sira - 1],
          reason: 'sınır ${sira + 1} olunca önceki sıra bozulmamalı',
        );
      }
    });
  });

  group('arama', () {
    test('Türkçe yazım farkları aynı sonucu verir', () async {
      await urunEkle('Elma Şeker');
      await urunEkle('Zeytin Gemlik');

      for (final yazim in <String>['elma şeker', 'ELMA SEKER', 'Elma Şeker']) {
        expect(
          await adlariListele(arama: yazim),
          <String>['Elma Şeker'],
          reason: '"$yazim" yazımı sonuç vermeli',
        );
      }
    });

    test('öntakı eşleşmesi yapar, ortadan eşleşmez', () async {
      await urunEkle('Elma Scarlet M9');

      expect(await adlariListele(arama: 'elm'), <String>['Elma Scarlet M9']);
      expect(await adlariListele(arama: 'elma sca'), hasLength(1));
      // Firestore'da metin araması öntakıyla sınırlı — bilinen kısıt.
      expect(await adlariListele(arama: 'scarlet'), isEmpty);
    });
  });

  // Sorgu yalnızca yerel önbellekte koşuyor (kaydetme düğmesi ağa bağlanmasın
  // diye). Buradaki ürünleri bu istemci yazdığı için hepsi önbellekte.
  group('benzerleriBul', () {
    test('mükerrer kayıt yakalanır', () async {
      await urunEkle('Elma Scarlet M9');

      // Yazım farkı mükerrerliği gizlememeli.
      const aday = Urun(id: '', tur: 'ELMA  scarlet  m9');
      final benzerler = await repository.benzerleriBul(aday);

      expect(benzerler.any(aday.ayniUrunMu), isTrue);
    });

    test('farklı adlı ürün mükerrer sayılmaz', () async {
      await urunEkle('Elma Scarlet M9 1 yaş');

      const aday = Urun(id: '', tur: 'Elma Scarlet M9 2 yaş');
      final benzerler = await repository.benzerleriBul(aday);

      expect(benzerler, isEmpty);
    });

    test('kaydın kendisi benzer sayılmaz', () async {
      final urunId = await urunEkle('Elma Scarlet');

      final benzerler = await repository.benzerleriBul(
        Urun(id: urunId, tur: 'Elma Scarlet'),
      );

      expect(benzerler, isEmpty, reason: 'düzenleme kendini mükerrer sanmamalı');
    });
  });

  group('guncelle', () {
    test('arama anahtarı tazelenir, oluşturma tarihi korunur', () async {
      final urunId = await urunEkle('Elma Scarlet');
      final oncesi = (await sunucudaBekle(koleksiyon.doc(urunId))).data()!;

      await repository.guncelle(
        Urun(id: urunId, tur: 'Elma Şeker MM106', fiyat: Kurus.liradan(52, 50)),
      );
      final sonrasi = (await sunucudaBekle(
        koleksiyon.doc(urunId),
        kosul: (veri) => veri[Urun.alanAd] == 'Elma Şeker MM106',
      )).data()!;

      expect(sonrasi[Urun.alanAramaAnahtari], 'elma seker mm106');
      expect(sonrasi[Urun.alanFiyatKurus], 5250);
      expect(sonrasi[Urun.alanAktif], isTrue);
      expect(
        sonrasi[Urun.alanOlusturmaTarihi],
        oncesi[Urun.alanOlusturmaTarihi],
      );
    });
  });

  group('eski fidan kaydı', () {
    // Katalogda göç scripti çalıştırılmıyor; eski şemayla yazılmış belgeler
    // okunurken ada dönüşüyor. Bu okuma düşerse kullanıcının katalogu boş
    // görünür (bkz. `eski_fidan_adi.dart`).
    test('eski şemadaki belge ada dönüşerek okunur', () async {
      final belge = koleksiyon.doc();
      await belge.set(<String, Object?>{
        'tur': 'Elma',
        'cesit': 'Scarlet',
        'anac': 'M9',
        'yas': 2,
        'kokTipi': 'tuplu',
        'varsayilanFiyatKurus': 4500,
        'aramaAnahtari': 'elma scarlet m9',
        'aktif': true,
        Urun.alanOlusturmaTarihi: FieldValue.serverTimestamp(),
      });
      await sunucudaBekle(
        belge,
        kosul: (veri) => veri[Urun.alanOlusturmaTarihi] != null,
      );

      final kayit = await repository.izle(belge.id).first;

      expect(kayit?.urun.ad, 'Elma Scarlet M9 2 yaş tüplü');
      expect(kayit?.urun.fiyat.deger, 4500);
    });

    test('eski kayıt listede görünür', () async {
      final belge = koleksiyon.doc();
      await belge.set(<String, Object?>{
        'tur': 'Zeytin',
        'cesit': 'Gemlik',
        'aramaAnahtari': 'zeytin gemlik',
        'aktif': true,
        Urun.alanOlusturmaTarihi: FieldValue.serverTimestamp(),
      });
      await sunucudaBekle(
        belge,
        kosul: (veri) => veri[Urun.alanOlusturmaTarihi] != null,
      );

      expect(await adlariListele(), <String>['Zeytin Gemlik']);
    });
  });

  group('izle', () {
    test('var olmayan ürün için null yayar', () async {
      expect(await repository.izle('olmayan-kimlik').first, isNull);
    });

    test('kayıt okunduğunda adı ve fiyatı gelir', () async {
      final urunId = await urunEkle('çam', fiyat: Kurus.liradan(60));

      final kayit = await repository.izle(urunId).first;

      expect(kayit?.urun.ad, 'çam');
      expect(kayit?.urun.fiyat.deger, 6000);
    });
  });
}
