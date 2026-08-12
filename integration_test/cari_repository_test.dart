import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidancari/data/cari/cari_repository.dart';
import 'package:fidancari/domain/cari/cari.dart';
import 'package:fidancari/domain/cari/cari_siralamasi.dart';
import 'package:fidancari/domain/isletme/isletme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'emulator_yardimcilari.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore firestore;
  late FirebaseAuth kimlik;
  late CariRepository repository;
  late CollectionReference<Map<String, dynamic>> koleksiyon;

  setUpAll(emulatoreBaglan);

  setUp(() async {
    firestore = FirebaseFirestore.instance;
    kimlik = FirebaseAuth.instance;

    final isletmeId = await yeniKullaniciAc(kimlik);
    koleksiyon = firestore
        .collection(Isletme.koleksiyon)
        .doc(isletmeId)
        .collection(Cari.koleksiyon);
    repository = CariRepository(firestore: firestore, isletmeId: isletmeId);
  });

  tearDown(() => kimlik.signOut());

  /// Cariyi ekler ve sunucu onayını bekler; testler yazma sonrası okumaya
  /// güvenebilsin diye.
  ///
  /// Belgenin var olması yetmiyor: yazma yerel önbellekte beklerken belge
  /// görünür ama `serverTimestamp` henüz `null`'dur. Oluşturma tarihinin
  /// dolması, sunucunun yazmayı gerçekten onayladığının işareti.
  Future<String> cariEkle(String ad) async {
    final cariId = await repository.ekle(Cari(id: '', ad: ad));
    await sunucudaBekle(
      koleksiyon.doc(cariId),
      kosul: (veri) => veri[Cari.alanOlusturmaTarihi] != null,
    );
    return cariId;
  }

  Future<List<String>> adlariListele({
    CariSiralamasi siralama = CariSiralamasi.ad,
    String arama = '',
    int sayfaBoyu = CariRepository.varsayilanSayfaBoyu,
  }) async {
    final sayfa = await repository.listele(
      siralama: siralama,
      arama: arama,
      sayfaBoyu: sayfaBoyu,
    );
    return sayfa.kayitlar.map((kayit) => kayit.cari.ad).toList();
  }

  group('ekle', () {
    test('yeni cari sunucuya yazılır ve varsayılanları alır', () async {
      final cariId = await cariEkle('Ahmet Koyuncu');
      final veri = (await sunucudaBekle(koleksiyon.doc(cariId))).data()!;

      expect(veri[Cari.alanAd], 'Ahmet Koyuncu');
      expect(veri[Cari.alanAramaAnahtari], 'ahmet koyuncu');
      expect(veri[Cari.alanBakiyeKurus], 0);
      expect(veri[Cari.alanAktif], isTrue);
      // Alan `null` da olsa yazılmalı; yoksa son işleme göre sıralayan sorgu
      // bu cariyi hiç görmez.
      expect(veri.containsKey(Cari.alanSonIslemTarihi), isTrue);
      expect(veri[Cari.alanOlusturmaTarihi], isA<Timestamp>());
    });
  });

  group('listele', () {
    test('yalnızca aktif cariler döner', () async {
      await cariEkle('Aktif Cari');
      final pasifId = await cariEkle('Pasif Cari');

      await repository.aktifligiDegistir(pasifId, aktif: false);
      await sunucudaBekle(
        koleksiyon.doc(pasifId),
        kosul: (veri) => veri[Cari.alanAktif] == false,
      );

      expect(await adlariListele(), <String>['Aktif Cari']);

      // Muhasebe kaydı silinmez; belge yerinde durmalı (KURALLAR.md §4.2).
      final pasif = await koleksiyon.doc(pasifId).get();
      expect(pasif.exists, isTrue);
      expect(pasif.data()![Cari.alanAd], 'Pasif Cari');
    });

    test('ada göre Türkçe katlanmış anahtar sırasıyla döner', () async {
      await cariEkle('Zeynep Ak');
      await cariEkle('Ahmet Koyuncu');
      await cariEkle('Mehmet Öz');

      expect(await adlariListele(), <String>[
        'Ahmet Koyuncu',
        'Mehmet Öz',
        'Zeynep Ak',
      ]);
    });

    test('sayfalama kayıt tekrarlamaz ve atlamaz', () async {
      for (final ad in <String>['A Cari', 'B Cari', 'C Cari', 'D Cari']) {
        await cariEkle(ad);
      }

      final toplananlar = <String>[];
      var sayfa = await repository.listele(sayfaBoyu: 2);
      toplananlar.addAll(sayfa.kayitlar.map((kayit) => kayit.cari.ad));

      while (sayfa.dahaVar) {
        sayfa = await repository.listele(
          sayfaBoyu: 2,
          sonrasindan: sayfa.kayitlar.last,
        );
        toplananlar.addAll(sayfa.kayitlar.map((kayit) => kayit.cari.ad));
      }

      expect(toplananlar, <String>['A Cari', 'B Cari', 'C Cari', 'D Cari']);
    });

    test('aynı adlı cariler sayfa sınırında kaybolmaz', () async {
      // İmleç yalnızca ada baksaydı, sayfa tam bu ikilinin ortasında bittiğinde
      // ikinci kayıt atlanırdı. Belge kimliği ikinci sıralama ölçütü.
      for (var sira = 0; sira < 4; sira++) {
        await cariEkle('Ayni Ad');
      }

      final toplananlar = <String>[];
      var sayfa = await repository.listele(sayfaBoyu: 1);
      toplananlar.addAll(sayfa.kayitlar.map((kayit) => kayit.cari.id));

      while (sayfa.dahaVar) {
        sayfa = await repository.listele(
          sayfaBoyu: 1,
          sonrasindan: sayfa.kayitlar.last,
        );
        toplananlar.addAll(sayfa.kayitlar.map((kayit) => kayit.cari.id));
      }

      expect(toplananlar, hasLength(4));
      expect(toplananlar.toSet(), hasLength(4), reason: 'kayıt tekrarlanmamalı');
    });

    test('bakiyeye göre sıralamada en borçlu başta gelir', () async {
      final dusuk = await cariEkle('Düşük Bakiye');
      final yuksek = await cariEkle('Yüksek Bakiye');

      // Bakiye Faz 2'de transaction ile dolacak; burada sıralamayı sınamak için
      // doğrudan yazılıyor.
      await koleksiyon.doc(dusuk).update(<String, Object?>{
        Cari.alanBakiyeKurus: 100000,
      });
      await koleksiyon.doc(yuksek).update(<String, Object?>{
        Cari.alanBakiyeKurus: 9400000,
      });
      await sunucudaBekle(
        koleksiyon.doc(yuksek),
        kosul: (veri) => veri[Cari.alanBakiyeKurus] == 9400000,
      );

      expect(
        await adlariListele(siralama: CariSiralamasi.bakiye),
        <String>['Yüksek Bakiye', 'Düşük Bakiye'],
      );
    });

    test('son işleme göre sıralamada tarihsiz cariler de listede kalır',
        () async {
      final eski = await cariEkle('İşlem Görmüş');
      await cariEkle('Hiç İşlem Yok');

      await koleksiyon.doc(eski).update(<String, Object?>{
        Cari.alanSonIslemTarihi: Timestamp.fromDate(DateTime.utc(2025, 5, 24)),
      });
      await sunucudaBekle(
        koleksiyon.doc(eski),
        kosul: (veri) => veri[Cari.alanSonIslemTarihi] != null,
      );

      final adlar = await adlariListele(siralama: CariSiralamasi.sonIslem);
      expect(adlar.first, 'İşlem Görmüş');
      expect(adlar, hasLength(2));
    });
  });

  group('arama', () {
    test('Türkçe yazım farkları aynı sonucu verir', () async {
      await cariEkle('İstanbul Fidancılık');
      await cariEkle('Ahmet Koyuncu');

      for (final yazim in <String>[
        'istanbul',
        'İstanbul',
        'ISTANBUL',
        'ıstanbul',
        'İSTANBUL',
      ]) {
        expect(
          await adlariListele(arama: yazim),
          <String>['İstanbul Fidancılık'],
          reason: '"$yazim" yazımı sonuç vermeli',
        );
      }
    });

    test('öntakı eşleşmesi yapar, ortadan eşleşmez', () async {
      await cariEkle('Ahmet Koyuncu');

      expect(await adlariListele(arama: 'ahm'), <String>['Ahmet Koyuncu']);
      // Firestore'da metin araması öntakıyla sınırlı — bilinen kısıt.
      expect(await adlariListele(arama: 'koyuncu'), isEmpty);
    });

    test('arama sıralama seçiminden bağımsız çalışır', () async {
      await cariEkle('İstanbul Fidancılık');

      // Aralık süzgeci uygulanan alan ilk sıralama alanı olmak zorunda;
      // repository bunu kendisi zorluyor, sorgu hata vermemeli.
      expect(
        await adlariListele(arama: 'istanbul', siralama: CariSiralamasi.bakiye),
        <String>['İstanbul Fidancılık'],
      );
    });
  });

  group('guncelle', () {
    test('bakiye ve oluşturma tarihine dokunmaz', () async {
      final cariId = await cariEkle('Ahmet Koyuncu');
      await koleksiyon.doc(cariId).update(<String, Object?>{
        Cari.alanBakiyeKurus: 9400000,
      });
      final oncesi = await sunucudaBekle(
        koleksiyon.doc(cariId),
        kosul: (veri) => veri[Cari.alanBakiyeKurus] == 9400000,
      );

      await repository.guncelle(
        Cari(id: cariId, ad: 'Ahmet Koyuncu Tarım', sehir: 'Isparta'),
      );
      final sonrasi = (await sunucudaBekle(
        koleksiyon.doc(cariId),
        kosul: (veri) => veri[Cari.alanAd] == 'Ahmet Koyuncu Tarım',
      )).data()!;

      expect(sonrasi[Cari.alanAd], 'Ahmet Koyuncu Tarım');
      expect(sonrasi[Cari.alanSehir], 'Isparta');
      expect(sonrasi[Cari.alanAramaAnahtari], 'ahmet koyuncu tarim');
      // Faz 2'de bir işlemin güncellediği bakiye, form kaydıyla ezilmemeli.
      expect(sonrasi[Cari.alanBakiyeKurus], 9400000);
      expect(
        sonrasi[Cari.alanOlusturmaTarihi],
        oncesi.data()![Cari.alanOlusturmaTarihi],
      );
    });
  });

  group('izle', () {
    test('var olmayan cari için null yayar', () async {
      expect(await repository.izle('olmayan-kimlik').first, isNull);
    });

    test('kayıt değişince yeni değer yayılır', () async {
      final cariId = await cariEkle('Ahmet Koyuncu');

      expect((await repository.izle(cariId).first)?.cari.ad, 'Ahmet Koyuncu');
    });
  });
}
