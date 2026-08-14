import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidancari/data/secenek/secenek_repository.dart';
import 'package:fidancari/domain/isletme/isletme.dart';
import 'package:fidancari/domain/secenek/secenek.dart';
import 'package:fidancari/domain/secenek/secenek_tipi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'emulator_yardimcilari.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore firestore;
  late FirebaseAuth kimlik;
  late SecenekRepository repository;
  late String isletmeId;

  setUpAll(emulatoreBaglan);

  setUp(() async {
    firestore = FirebaseFirestore.instance;
    kimlik = FirebaseAuth.instance;
    isletmeId = await yeniKullaniciAc(kimlik);
    repository = SecenekRepository(firestore: firestore, isletmeId: isletmeId);
  });

  tearDown(() => kimlik.signOut());

  CollectionReference<Map<String, dynamic>> koleksiyon(SecenekTipi tip) =>
      firestore
          .collection(Isletme.koleksiyon)
          .doc(isletmeId)
          .collection(tip.koleksiyon);

  /// Satırı ekler ve sunucu onayını bekler; testler yazma sonrası okumaya
  /// güvenebilsin diye (bkz. `urun_repository_test.dart`).
  Future<String> ekle(SecenekTipi tip, String ad) async {
    final id = await repository.ekle(Secenek(id: '', tip: tip, ad: ad));
    await sunucudaBekle(
      koleksiyon(tip).doc(id),
      kosul: (veri) => veri[Secenek.alanOlusturmaTarihi] != null,
    );
    return id;
  }

  /// Canlı listenin ilk yayınındaki adlar.
  Future<List<String>> adlariListele(
    SecenekTipi tip, {
    String arama = '',
    int sinir = SecenekRepository.varsayilanSayfaBoyu,
  }) async {
    final sayfa = await repository
        .listeyiIzle(tip, arama: arama, sinir: sinir)
        .first;
    return sayfa.kayitlar
        .map((kayit) => kayit.secenek.ad)
        .toList(growable: false);
  }

  group('ekle', () {
    test('satır adı ve arama anahtarıyla yazılır', () async {
      final id = await ekle(SecenekTipi.cesit, 'Şeker');
      final veri = (await sunucudaBekle(
        koleksiyon(SecenekTipi.cesit).doc(id),
      )).data()!;

      expect(veri[Secenek.alanAd], 'Şeker');
      expect(veri[Secenek.alanAramaAnahtari], 'seker');
      // Tip belgeye yazılmaz; koleksiyon adı taşır (bkz. SecenekTipi).
      expect(veri.containsKey('tip'), isFalse);
    });
  });

  group('listeyiIzle', () {
    test('üç liste birbirinin kaydını göstermez', () async {
      await ekle(SecenekTipi.tur, 'Elma');
      await ekle(SecenekTipi.anac, 'M9');

      expect(await adlariListele(SecenekTipi.tur), <String>['Elma']);
      expect(await adlariListele(SecenekTipi.anac), <String>['M9']);
      expect(await adlariListele(SecenekTipi.cesit), isEmpty);
    });

    test('liste ada göre alfabetik gelir', () async {
      await ekle(SecenekTipi.anac, 'MM106');
      await ekle(SecenekTipi.anac, 'Gisela 5');
      await ekle(SecenekTipi.anac, 'M9');

      expect(await adlariListele(SecenekTipi.anac), <String>[
        'Gisela 5',
        'M9',
        'MM106',
      ]);
    });

    test('sınır büyüdükçe kayıt tekrarlamaz ve atlamaz', () async {
      for (final ad in <String>['Armut', 'Ceviz', 'Elma', 'Kiraz']) {
        await ekle(SecenekTipi.tur, ad);
      }

      // "Daha yükle" imleci yürütmez, sınırı büyütür: her adımda liste baştan
      // gelir ve öncekini olduğu gibi kapsamalıdır.
      expect(await adlariListele(SecenekTipi.tur, sinir: 2), <String>[
        'Armut',
        'Ceviz',
      ]);
      expect(await adlariListele(SecenekTipi.tur, sinir: 4), <String>[
        'Armut',
        'Ceviz',
        'Elma',
        'Kiraz',
      ]);
    });
  });

  group('arama', () {
    test('Türkçe yazım farkları aynı sonucu verir', () async {
      await ekle(SecenekTipi.cesit, 'Şeker');
      await ekle(SecenekTipi.cesit, 'Scarlet');

      for (final yazim in <String>['şeker', 'SEKER', 'Şeker']) {
        expect(
          await adlariListele(SecenekTipi.cesit, arama: yazim),
          <String>['Şeker'],
          reason: '"$yazim" yazımı sonuç vermeli',
        );
      }
    });

    test('öntakı eşleşmesi yapar, ortadan eşleşmez', () async {
      await ekle(SecenekTipi.cesit, '0900 Ziraat');

      expect(
        await adlariListele(SecenekTipi.cesit, arama: '0900'),
        <String>['0900 Ziraat'],
      );
      // Firestore'da metin araması öntakıyla sınırlı — bilinen kısıt.
      expect(await adlariListele(SecenekTipi.cesit, arama: 'ziraat'), isEmpty);
    });
  });

  group('guncelle', () {
    test('arama anahtarı tazelenir, oluşturma tarihi korunur', () async {
      final id = await ekle(SecenekTipi.anac, 'M9');
      final belge = koleksiyon(SecenekTipi.anac).doc(id);
      final oncesi = (await sunucudaBekle(belge)).data()!;

      await repository.guncelle(
        Secenek(id: id, tip: SecenekTipi.anac, ad: 'MM106'),
      );
      final sonrasi = (await sunucudaBekle(
        belge,
        kosul: (veri) => veri[Secenek.alanAd] == 'MM106',
      )).data()!;

      expect(sonrasi[Secenek.alanAramaAnahtari], 'mm106');
      expect(
        sonrasi[Secenek.alanOlusturmaTarihi],
        oncesi[Secenek.alanOlusturmaTarihi],
      );
    });
  });

  group('sil', () {
    // Burada pasife alma yok, gerçek silme var: satıra kimlikle bağlı geçmiş
    // kayıt bulunmuyor (bkz. `SecenekRepository.sil`).
    test('satır belgeden ve listeden kalkar', () async {
      final id = await ekle(SecenekTipi.anac, 'M9');
      await ekle(SecenekTipi.anac, 'MM106');

      await repository.sil(
        Secenek(id: id, tip: SecenekTipi.anac, ad: 'M9'),
      );
      await sunucudanSilinmeyiBekle(koleksiyon(SecenekTipi.anac).doc(id));

      expect(await adlariListele(SecenekTipi.anac), <String>['MM106']);
    });

    test('kaydedilmemiş satır sessizce geçilir', () async {
      await ekle(SecenekTipi.anac, 'M9');

      await repository.sil(const Secenek(id: '', tip: SecenekTipi.anac, ad: ''));

      expect(await adlariListele(SecenekTipi.anac), <String>['M9']);
    });
  });

  // Sorgu yalnızca yerel önbellekte koşuyor (kaydetme düğmesi ağa bağlanmasın
  // diye). Buradaki satırları bu istemci yazdığı için hepsi önbellekte.
  group('benzerleriBul', () {
    test('yazım farkı mükerrerliği gizlemez', () async {
      await ekle(SecenekTipi.anac, 'M9');

      const aday = Secenek(id: '', tip: SecenekTipi.anac, ad: '  m9 ');
      final benzerler = await repository.benzerleriBul(aday);

      expect(benzerler.any(aday.ayniMi), isTrue);
    });

    test('başka listedeki aynı ad mükerrer sayılmaz', () async {
      await ekle(SecenekTipi.tur, 'Gemlik');

      const aday = Secenek(id: '', tip: SecenekTipi.cesit, ad: 'Gemlik');

      expect(await repository.benzerleriBul(aday), isEmpty);
    });

    test('kaydın kendisi benzer sayılmaz', () async {
      final id = await ekle(SecenekTipi.cesit, 'Scarlet');

      final benzerler = await repository.benzerleriBul(
        Secenek(id: id, tip: SecenekTipi.cesit, ad: 'Scarlet'),
      );

      expect(benzerler, isEmpty, reason: 'düzenleme kendini mükerrer sanmamalı');
    });
  });
}
