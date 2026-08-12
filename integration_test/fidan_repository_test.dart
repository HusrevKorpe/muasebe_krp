import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/data/fidan/fidan_repository.dart';
import 'package:fidancari/domain/fidan/fidan.dart';
import 'package:fidancari/domain/fidan/fidan_oneri_alani.dart';
import 'package:fidancari/domain/fidan/kok_tipi.dart';
import 'package:fidancari/domain/isletme/isletme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'emulator_yardimcilari.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore firestore;
  late FirebaseAuth kimlik;
  late FidanRepository repository;
  late CollectionReference<Map<String, dynamic>> koleksiyon;

  setUpAll(emulatoreBaglan);

  setUp(() async {
    firestore = FirebaseFirestore.instance;
    kimlik = FirebaseAuth.instance;

    final isletmeId = await yeniKullaniciAc(kimlik);
    koleksiyon = firestore
        .collection(Isletme.koleksiyon)
        .doc(isletmeId)
        .collection(Fidan.koleksiyon);
    repository = FidanRepository(firestore: firestore, isletmeId: isletmeId);
  });

  tearDown(() => kimlik.signOut());

  /// Fidanı ekler ve sunucu onayını bekler; testler yazma sonrası okumaya
  /// güvenebilsin diye. Oluşturma tarihinin dolması, sunucunun yazmayı
  /// gerçekten onayladığının işareti.
  Future<String> fidanEkle({
    required String tur,
    required String cesit,
    String? anac,
    int? yas,
    KokTipi? kokTipi,
    Kurus fiyat = Kurus.sifir,
  }) async {
    final fidanId = await repository.ekle(
      Fidan(
        id: '',
        tur: tur,
        cesit: cesit,
        anac: anac,
        yas: yas,
        kokTipi: kokTipi,
        varsayilanFiyat: fiyat,
      ),
    );
    await sunucudaBekle(
      koleksiyon.doc(fidanId),
      kosul: (veri) => veri[Fidan.alanOlusturmaTarihi] != null,
    );
    return fidanId;
  }

  Future<List<String>> adlariListele({
    String arama = '',
    int sayfaBoyu = FidanRepository.varsayilanSayfaBoyu,
  }) async {
    final sayfa = await repository.listele(arama: arama, sayfaBoyu: sayfaBoyu);
    return sayfa.kayitlar
        .map((kayit) => kayit.fidan.goruntuAdi)
        .toList(growable: false);
  }

  group('ekle', () {
    test('yeni fidan sunucuya yazılır ve varsayılanları alır', () async {
      final fidanId = await fidanEkle(
        tur: 'Elma',
        cesit: 'Scarlet',
        anac: 'M9',
        yas: 2,
        kokTipi: KokTipi.tuplu,
        fiyat: Kurus.liradan(45),
      );
      final veri = (await sunucudaBekle(koleksiyon.doc(fidanId))).data()!;

      expect(veri[Fidan.alanTur], 'Elma');
      expect(veri[Fidan.alanCesit], 'Scarlet');
      expect(veri[Fidan.alanAnac], 'M9');
      expect(veri[Fidan.alanYas], 2);
      expect(veri[Fidan.alanKokTipi], KokTipi.tuplu.anahtar);
      // Para Firestore'a da int yazılır (KURALLAR.md §3.1).
      expect(veri[Fidan.alanVarsayilanFiyatKurus], 4500);
      expect(veri[Fidan.alanVarsayilanFiyatKurus], isA<int>());
      expect(veri[Fidan.alanAramaAnahtari], 'elma scarlet m9');
      expect(veri[Fidan.alanTurAnahtari], 'elma');
      expect(veri[Fidan.alanAnacAnahtari], 'm9');
      expect(veri[Fidan.alanAktif], isTrue);
    });

    test('anaçsız fidanın anaç anahtarı null yazılır', () async {
      final fidanId = await fidanEkle(tur: 'Zeytin', cesit: 'Gemlik');
      final veri = (await sunucudaBekle(koleksiyon.doc(fidanId))).data()!;

      // Alan yazılır ama değeri `null`: öneri sorgusunun aralık süzgeci bu
      // kaydı hiç görmemeli.
      expect(veri.containsKey(Fidan.alanAnacAnahtari), isTrue);
      expect(veri[Fidan.alanAnacAnahtari], isNull);
    });
  });

  group('listele', () {
    test('yalnızca aktif fidanlar döner, kayıt silinmez', () async {
      await fidanEkle(tur: 'Elma', cesit: 'Scarlet');
      final pasifId = await fidanEkle(tur: 'Zeytin', cesit: 'Gemlik');

      await repository.aktifligiDegistir(pasifId, aktif: false);
      await sunucudaBekle(
        koleksiyon.doc(pasifId),
        kosul: (veri) => veri[Fidan.alanAktif] == false,
      );

      expect(await adlariListele(), <String>['Elma / Scarlet']);

      final pasif = await koleksiyon.doc(pasifId).get();
      expect(pasif.exists, isTrue, reason: 'kayıt silinmemeli');
    });

    test('aynı tür yan yana gelir', () async {
      await fidanEkle(tur: 'Zeytin', cesit: 'Gemlik');
      await fidanEkle(tur: 'Elma', cesit: 'Starking');
      await fidanEkle(tur: 'Elma', cesit: 'Scarlet');

      // Sıralama `aramaAnahtari` üzerinden; anahtar türle başladığı için
      // ekran gruplamak adına ayrı sorgu atmıyor.
      expect(await adlariListele(), <String>[
        'Elma / Scarlet',
        'Elma / Starking',
        'Zeytin / Gemlik',
      ]);
    });

    test('sayfalama kayıt tekrarlamaz ve atlamaz', () async {
      for (final cesit in <String>['Amasya', 'Golden', 'Scarlet', 'Starking']) {
        await fidanEkle(tur: 'Elma', cesit: cesit);
      }

      final toplananlar = <String>[];
      var sayfa = await repository.listele(sayfaBoyu: 2);
      toplananlar.addAll(sayfa.kayitlar.map((kayit) => kayit.fidan.cesit));

      while (sayfa.dahaVar) {
        sayfa = await repository.listele(
          sayfaBoyu: 2,
          sonrasindan: sayfa.kayitlar.last,
        );
        toplananlar.addAll(sayfa.kayitlar.map((kayit) => kayit.fidan.cesit));
      }

      expect(toplananlar, <String>[
        'Amasya',
        'Golden',
        'Scarlet',
        'Starking',
      ]);
    });

    test('yalnızca yaşı farklı fidanlar sayfa sınırında kaybolmaz', () async {
      // Arama anahtarları birebir aynı; imleç yalnızca anahtara baksaydı
      // sayfa tam bu üçlünün ortasında bittiğinde kayıt atlanırdı.
      for (var yas = 1; yas <= 3; yas++) {
        await fidanEkle(tur: 'Elma', cesit: 'Scarlet', anac: 'M9', yas: yas);
      }

      final toplananlar = <String>[];
      var sayfa = await repository.listele(sayfaBoyu: 1);
      toplananlar.addAll(sayfa.kayitlar.map((kayit) => kayit.fidan.id));

      while (sayfa.dahaVar) {
        sayfa = await repository.listele(
          sayfaBoyu: 1,
          sonrasindan: sayfa.kayitlar.last,
        );
        toplananlar.addAll(sayfa.kayitlar.map((kayit) => kayit.fidan.id));
      }

      expect(toplananlar, hasLength(3));
      expect(toplananlar.toSet(), hasLength(3), reason: 'kayıt tekrarlanmamalı');
    });
  });

  group('arama', () {
    test('Türkçe yazım farkları aynı sonucu verir', () async {
      await fidanEkle(tur: 'Elma', cesit: 'Şeker');
      await fidanEkle(tur: 'Zeytin', cesit: 'Gemlik');

      for (final yazim in <String>['elma şeker', 'ELMA SEKER', 'Elma Şeker']) {
        expect(
          await adlariListele(arama: yazim),
          <String>['Elma / Şeker'],
          reason: '"$yazim" yazımı sonuç vermeli',
        );
      }
    });

    test('öntakı eşleşmesi yapar, ortadan eşleşmez', () async {
      await fidanEkle(tur: 'Elma', cesit: 'Scarlet', anac: 'M9');

      expect(await adlariListele(arama: 'elm'), <String>['Elma / Scarlet / M9']);
      expect(await adlariListele(arama: 'elma sca'), hasLength(1));
      // Firestore'da metin araması öntakıyla sınırlı — bilinen kısıt.
      expect(await adlariListele(arama: 'scarlet'), isEmpty);
    });
  });

  group('oneriler', () {
    test('tür alanında öntakıyla eşleşen geçmiş girişler döner', () async {
      await fidanEkle(tur: 'Elma', cesit: 'Scarlet');
      await fidanEkle(tur: 'Elma', cesit: 'Starking');
      await fidanEkle(tur: 'Zeytin', cesit: 'Gemlik');

      final oneriler = await repository.oneriler(
        alan: FidanOneriAlani.tur,
        onek: 'El',
      );

      // Aynı tür iki kez girilmiş olsa da öneri listesinde bir kez görünür.
      expect(oneriler, <String>['Elma']);
    });

    test('öntakı boşken tüm türler önerilir', () async {
      await fidanEkle(tur: 'Elma', cesit: 'Scarlet');
      await fidanEkle(tur: 'Zeytin', cesit: 'Gemlik');

      final oneriler = await repository.oneriler(alan: FidanOneriAlani.tur);

      expect(oneriler, <String>['Elma', 'Zeytin']);
    });

    test('anaç önerisinde anaçsız kayıtlar listeye girmez', () async {
      await fidanEkle(tur: 'Elma', cesit: 'Scarlet', anac: 'M9');
      await fidanEkle(tur: 'Elma', cesit: 'Starking', anac: 'MM106');
      await fidanEkle(tur: 'Zeytin', cesit: 'Gemlik');

      expect(
        await repository.oneriler(alan: FidanOneriAlani.anac),
        <String>['M9', 'MM106'],
      );
      expect(
        await repository.oneriler(alan: FidanOneriAlani.anac, onek: 'mm'),
        <String>['MM106'],
      );
    });

    test('pasife alınmış fidanın türü önerilmez', () async {
      final pasifId = await fidanEkle(tur: 'Ceviz', cesit: 'Chandler');
      await repository.aktifligiDegistir(pasifId, aktif: false);
      await sunucudaBekle(
        koleksiyon.doc(pasifId),
        kosul: (veri) => veri[Fidan.alanAktif] == false,
      );

      expect(
        await repository.oneriler(alan: FidanOneriAlani.tur, onek: 'ce'),
        isEmpty,
      );
    });
  });

  group('benzerleriBul', () {
    test('aynı tür/çeşit/anaç üçlüsündeki kayıtları döner', () async {
      await fidanEkle(tur: 'Elma', cesit: 'Scarlet', anac: 'M9', yas: 1);
      await fidanEkle(tur: 'Elma', cesit: 'Starking', anac: 'M9');

      final benzerler = await repository.benzerleriBul(
        const Fidan(id: '', tur: 'Elma', cesit: 'Scarlet', anac: 'M9', yas: 2),
      );

      expect(benzerler, hasLength(1));
      expect(benzerler.single.yas, 1);
      // Yaş farklı: mükerrer değil, ayrı bir kayıt.
      expect(
        benzerler.single.ayniFidanMi(
          const Fidan(id: '', tur: 'Elma', cesit: 'Scarlet', anac: 'M9', yas: 2),
        ),
        isFalse,
      );
    });

    test('mükerrer kayıt yakalanır', () async {
      await fidanEkle(tur: 'Elma', cesit: 'Scarlet', anac: 'M9', yas: 2);

      // Yazım farkı mükerrerliği gizlememeli.
      const aday = Fidan(
        id: '',
        tur: 'ELMA',
        cesit: 'scarlet',
        anac: 'm9',
        yas: 2,
      );
      final benzerler = await repository.benzerleriBul(aday);

      expect(benzerler.any(aday.ayniFidanMi), isTrue);
    });

    test('kaydın kendisi benzer sayılmaz', () async {
      final fidanId = await fidanEkle(tur: 'Elma', cesit: 'Scarlet', yas: 2);

      final benzerler = await repository.benzerleriBul(
        Fidan(id: fidanId, tur: 'Elma', cesit: 'Scarlet', yas: 2),
      );

      expect(benzerler, isEmpty, reason: 'düzenleme kendini mükerrer sanmamalı');
    });
  });

  group('guncelle', () {
    test('arama anahtarları tazelenir, oluşturma tarihi korunur', () async {
      final fidanId = await fidanEkle(tur: 'Elma', cesit: 'Scarlet');
      final oncesi = (await sunucudaBekle(koleksiyon.doc(fidanId))).data()!;

      await repository.guncelle(
        Fidan(
          id: fidanId,
          tur: 'Elma',
          cesit: 'Şeker',
          anac: 'MM106',
          varsayilanFiyat: Kurus.liradan(52, 50),
        ),
      );
      final sonrasi = (await sunucudaBekle(
        koleksiyon.doc(fidanId),
        kosul: (veri) => veri[Fidan.alanCesit] == 'Şeker',
      )).data()!;

      expect(sonrasi[Fidan.alanAramaAnahtari], 'elma seker mm106');
      expect(sonrasi[Fidan.alanAnacAnahtari], 'mm106');
      expect(sonrasi[Fidan.alanVarsayilanFiyatKurus], 5250);
      expect(sonrasi[Fidan.alanAktif], isTrue);
      expect(
        sonrasi[Fidan.alanOlusturmaTarihi],
        oncesi[Fidan.alanOlusturmaTarihi],
      );
    });
  });

  group('izle', () {
    test('var olmayan fidan için null yayar', () async {
      expect(await repository.izle('olmayan-kimlik').first, isNull);
    });

    test('kayıt okunduğunda görünen ad üretilir', () async {
      final fidanId = await fidanEkle(
        tur: 'Elma',
        cesit: 'Scarlet',
        anac: 'M9',
        yas: 2,
        kokTipi: KokTipi.tuplu,
      );

      final kayit = await repository.izle(fidanId).first;

      expect(kayit?.fidan.goruntuAdi, 'Elma / Scarlet / M9 · 2 Yaş · Tüplü');
    });
  });
}
