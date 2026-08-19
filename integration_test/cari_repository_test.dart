import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidancari/data/cari/cari_repository.dart';
import 'package:fidancari/domain/cari/cari.dart';
import 'package:fidancari/domain/cari/cari_grubu.dart';
import 'package:fidancari/domain/cari/cari_siralamasi.dart';
import 'package:fidancari/domain/cari/cari_suzgeci.dart';
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

  /// Canlı listenin ilk yayınındaki adlar.
  ///
  /// İlk yayın önbellekten gelir; testteki her yazma `sunucudaBekle` ile
  /// onaylandığı ve yerel yazma önbelleğe anında düştüğü için o yayın da tam
  /// sonucu taşır.
  Future<List<String>> adlariListele({
    CariSuzgeci suzgec = CariSuzgeci.musteriler,
    CariSiralamasi siralama = CariSiralamasi.ad,
    String arama = '',
    int sinir = CariRepository.varsayilanSayfaBoyu,
  }) async {
    final sayfa = await repository
        .listeyiIzle(
          suzgec: suzgec,
          siralama: siralama,
          arama: arama,
          sinir: sinir,
        )
        .first;
    return sayfa.kayitlar.map((kayit) => kayit.cari.ad).toList();
  }

  /// Bakiyeyi doğrudan yazar ve sunucu onayını bekler.
  ///
  /// Bakiye normalde işlem kaydıyla birlikte transaction içinde dolar; burada
  /// sınanan şey sorgu, işlem akışı değil.
  Future<void> bakiyeYaz(String cariId, int kurus) async {
    await koleksiyon.doc(cariId).update(<String, Object?>{
      Cari.alanBakiyeKurus: kurus,
    });
    await sunucudaBekle(
      koleksiyon.doc(cariId),
      kosul: (veri) => veri[Cari.alanBakiyeKurus] == kurus,
    );
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

  group('listeyiIzle', () {
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

    test('sınır büyüdükçe kayıt tekrarlamaz ve atlamaz', () async {
      for (final ad in <String>['A Cari', 'B Cari', 'C Cari', 'D Cari']) {
        await cariEkle(ad);
      }

      // "Daha yükle" imleci yürütmez, sınırı büyütür: her adımda liste baştan
      // gelir ve öncekini olduğu gibi kapsamalıdır.
      expect(await adlariListele(sinir: 2), <String>['A Cari', 'B Cari']);
      expect(await adlariListele(sinir: 4), <String>[
        'A Cari',
        'B Cari',
        'C Cari',
        'D Cari',
      ]);
    });

    test('aynı adlı cariler sınır büyürken kaybolmaz', () async {
      // Sıralama yalnızca ada baksaydı iki kayıt aynı yere düşer, sınır
      // büyüdükçe sıra değişir ve kullanıcı satır atlardı. Belge kimliği ikinci
      // sıralama ölçütü.
      for (var sira = 0; sira < 4; sira++) {
        await cariEkle('Ayni Ad');
      }

      final kimlikler = <List<String>>[];
      for (final sinir in <int>[1, 2, 3, 4]) {
        final sayfa = await repository.listeyiIzle(sinir: sinir).first;
        kimlikler.add(
          sayfa.kayitlar.map((kayit) => kayit.cari.id).toList(growable: false),
        );
      }

      expect(kimlikler.last.toSet(), hasLength(4), reason: 'kayıt tekrarlanmamalı');
      for (var sira = 1; sira < kimlikler.length; sira++) {
        expect(
          kimlikler[sira].take(sira),
          kimlikler[sira - 1],
          reason: 'sınır ${sira + 1} olunca önceki sıra bozulmamalı',
        );
      }
    });

    test('bakiyeye göre sıralamada en borçlu başta gelir', () async {
      final dusuk = await cariEkle('Düşük Bakiye');
      final yuksek = await cariEkle('Yüksek Bakiye');

      await bakiyeYaz(dusuk, 100000);
      await bakiyeYaz(yuksek, 9400000);

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

  /// Cariyi fidancı olarak işaretler ve sunucu onayını bekler.
  Future<void> grubuYaz(String cariId, CariGrubu grup) async {
    await koleksiyon.doc(cariId).update(<String, Object?>{
      Cari.alanGrup: grup.anahtar,
    });
    await sunucudaBekle(
      koleksiyon.doc(cariId),
      kosul: (veri) => veri[Cari.alanGrup] == grup.anahtar,
    );
  }

  /// Belgeden `grup` alanını siler — bu özellikten önce yazılmış bir kaydı
  /// taklit eder. Göç scripti yazılmadığı için o kayıtlar veritabanında böyle
  /// duruyor (bkz. `CariSuzgeci.sunucuGrubu`).
  Future<void> grubuSil(String cariId) async {
    await koleksiyon.doc(cariId).update(<String, Object?>{
      Cari.alanGrup: FieldValue.delete(),
    });
    await sunucudaBekle(
      koleksiyon.doc(cariId),
      kosul: (veri) => !veri.containsKey(Cari.alanGrup),
    );
  }

  group('grup süzgeci', () {
    test('fidancı listesi yalnızca fidancıları döner', () async {
      final fidanciId = await cariEkle('Fidancı Meslektaş');
      await cariEkle('Sıradan Müşteri');
      await grubuYaz(fidanciId, CariGrubu.fidanci);

      expect(await adlariListele(suzgec: CariSuzgeci.fidancilar), <String>[
        'Fidancı Meslektaş',
      ]);
    });

    test('müşteri listesi fidancıları göstermez', () async {
      final fidanciId = await cariEkle('Fidancı Meslektaş');
      await cariEkle('Sıradan Müşteri');
      await grubuYaz(fidanciId, CariGrubu.fidanci);

      expect(await adlariListele(suzgec: CariSuzgeci.musteriler), <String>[
        'Sıradan Müşteri',
      ]);
    });

    test('grup alanı hiç olmayan eski kayıt müşteri listesinde kalır', () async {
      // Bu davranış özelliğin can damarı: `grup == 'musteri'` sunucu süzgeci
      // yazılsaydı, alanı olmayan belgeler Firestore tarafından eşleştirilmez
      // ve bu özellikten önce kaydedilmiş herkes listeden düşerdi.
      final eskiId = await cariEkle('Eski Kayıt');
      await grubuSil(eskiId);

      expect(await adlariListele(suzgec: CariSuzgeci.musteriler), <String>[
        'Eski Kayıt',
      ]);
    });

    test('grup alanı hiç olmayan eski kayıt fidancı listesine girmez', () async {
      final eskiId = await cariEkle('Eski Kayıt');
      await grubuSil(eskiId);

      expect(await adlariListele(suzgec: CariSuzgeci.fidancilar), isEmpty);
    });

    test('açık hesap listesi iki gruptan da besleniyor', () async {
      final fidanciId = await cariEkle('Borçlu Fidancı');
      final musteriId = await cariEkle('Borçlu Müşteri');
      await grubuYaz(fidanciId, CariGrubu.fidanci);
      await bakiyeYaz(fidanciId, 5000000);
      await bakiyeYaz(musteriId, 9400000);

      expect(
        (await adlariListele(suzgec: CariSuzgeci.acikHesap)).toSet(),
        <String>{'Borçlu Fidancı', 'Borçlu Müşteri'},
      );
    });

    test('grup değişince kişi öteki sekmeye geçer', () async {
      final cariId = await cariEkle('Ahmet Koyuncu');
      expect(await adlariListele(suzgec: CariSuzgeci.musteriler), <String>[
        'Ahmet Koyuncu',
      ]);

      await grubuYaz(cariId, CariGrubu.fidanci);

      expect(await adlariListele(suzgec: CariSuzgeci.musteriler), isEmpty);
      expect(await adlariListele(suzgec: CariSuzgeci.fidancilar), <String>[
        'Ahmet Koyuncu',
      ]);
    });

    test('fidancı listesinde arama çalışır', () async {
      final birId = await cariEkle('Ahmet Fidancılık');
      final ikiId = await cariEkle('Veli Fidancılık');
      await grubuYaz(birId, CariGrubu.fidanci);
      await grubuYaz(ikiId, CariGrubu.fidanci);

      expect(
        await adlariListele(suzgec: CariSuzgeci.fidancilar, arama: 'ahmet'),
        <String>['Ahmet Fidancılık'],
      );
    });
  });

  group('açık hesap süzgeci', () {
    test('bakiyesi sıfır olanlar listeye girmez', () async {
      final borclu = await cariEkle('Borçlu Cari');
      final alacakli = await cariEkle('Alacaklı Cari');
      await cariEkle('Kapalı Hesap');

      await bakiyeYaz(borclu, 9400000);
      await bakiyeYaz(alacakli, -180000);

      // Hesabın açık olması için yön önemli değil: iki taraf da listede.
      expect(
        (await adlariListele(suzgec: CariSuzgeci.acikHesap)).toSet(),
        <String>{'Borçlu Cari', 'Alacaklı Cari'},
      );
    });

    test('en borçlu başta, borçlu olduğumuz sonda gelir', () async {
      final az = await cariEkle('Az Borçlu');
      final cok = await cariEkle('Çok Borçlu');
      final bizimBorc = await cariEkle('Bize Alacaklı');

      await bakiyeYaz(az, 100000);
      await bakiyeYaz(cok, 9400000);
      await bakiyeYaz(bizimBorc, -500000);

      expect(await adlariListele(suzgec: CariSuzgeci.acikHesap), <String>[
        'Çok Borçlu',
        'Az Borçlu',
        'Bize Alacaklı',
      ]);
    });

    test('pasif cari açık bakiyesiyle de listede görünmez', () async {
      final pasif = await cariEkle('Pasif Borçlu');
      await bakiyeYaz(pasif, 9400000);

      await repository.aktifligiDegistir(pasif, aktif: false);
      await sunucudaBekle(
        koleksiyon.doc(pasif),
        kosul: (veri) => veri[Cari.alanAktif] == false,
      );

      expect(await adlariListele(suzgec: CariSuzgeci.acikHesap), isEmpty);
    });

    test('hesap kapanınca kayıt listeden düşer', () async {
      final cariId = await cariEkle('Ödeyen Cari');
      await bakiyeYaz(cariId, 9400000);

      expect(await adlariListele(suzgec: CariSuzgeci.acikHesap), <String>[
        'Ödeyen Cari',
      ]);

      // Tahsilat bakiyeyi sıfırladığında satır kendiliğinden kaybolmalı.
      await bakiyeYaz(cariId, 0);

      expect(await adlariListele(suzgec: CariSuzgeci.acikHesap), isEmpty);
    });

    test('sınır büyüdükçe kayıt tekrarlamaz ve atlamaz', () async {
      for (var sira = 0; sira < 4; sira++) {
        final cariId = await cariEkle('Borçlu $sira');
        await bakiyeYaz(cariId, (sira + 1) * 100000);
      }

      expect(
        await adlariListele(suzgec: CariSuzgeci.acikHesap, sinir: 2),
        <String>['Borçlu 3', 'Borçlu 2'],
      );
      expect(await adlariListele(suzgec: CariSuzgeci.acikHesap, sinir: 4), [
        'Borçlu 3',
        'Borçlu 2',
        'Borçlu 1',
        'Borçlu 0',
      ]);
    });
  });

  /// Cariyi pasife alır ya da geri açar ve sunucu onayını bekler.
  Future<void> aktifligiYaz(String cariId, {required bool aktif}) async {
    await repository.aktifligiDegistir(cariId, aktif: aktif);
    await sunucudaBekle(
      koleksiyon.doc(cariId),
      kosul: (veri) => veri[Cari.alanAktif] == aktif,
    );
  }

  /// Ayarlar → Kaldırılan Kişiler sayfasının sorgusu. Aynı sorgunun
  /// `aktif == false` hâli; kaldırılan kişinin uygulamadaki tek kapısı.
  group('pasif süzgeci', () {
    test('yalnızca kaldırılmış kişileri döner', () async {
      await cariEkle('Aktif Cari');
      final pasifId = await cariEkle('Kaldırılan Cari');
      await aktifligiYaz(pasifId, aktif: false);

      expect(await adlariListele(suzgec: CariSuzgeci.pasifler), <String>[
        'Kaldırılan Cari',
      ]);
      expect(await adlariListele(suzgec: CariSuzgeci.musteriler), <String>[
        'Aktif Cari',
      ]);
    });

    test('iki gruptan da getirir', () async {
      final musteriId = await cariEkle('Kaldırılan Müşteri');
      final fidanciId = await cariEkle('Kaldırılan Fidancı');
      await grubuYaz(fidanciId, CariGrubu.fidanci);
      await aktifligiYaz(musteriId, aktif: false);
      await aktifligiYaz(fidanciId, aktif: false);

      expect(
        (await adlariListele(suzgec: CariSuzgeci.pasifler)).toSet(),
        <String>{'Kaldırılan Müşteri', 'Kaldırılan Fidancı'},
      );
    });

    test('açık bakiyeli kayıt da listede kalır', () async {
      // Kaldırılmış kişinin borcu Açık Hesaplar sekmesinde görünmüyor; geri
      // almaya karar verebilmek için bakiyenin burada görünmesi gerekiyor.
      final pasifId = await cariEkle('Borçlu Kaldırılan');
      await bakiyeYaz(pasifId, 9400000);
      await aktifligiYaz(pasifId, aktif: false);

      expect(await adlariListele(suzgec: CariSuzgeci.pasifler), <String>[
        'Borçlu Kaldırılan',
      ]);
      expect(await adlariListele(suzgec: CariSuzgeci.acikHesap), isEmpty);
    });

    test('geri alınan kişi kendi listesine döner', () async {
      final cariId = await cariEkle('Geri Alınan');
      await aktifligiYaz(cariId, aktif: false);
      await aktifligiYaz(cariId, aktif: true);

      expect(await adlariListele(suzgec: CariSuzgeci.pasifler), isEmpty);
      expect(await adlariListele(suzgec: CariSuzgeci.musteriler), <String>[
        'Geri Alınan',
      ]);
    });

    test('pasif listede de ada göre arama yapılır', () async {
      final ahmetId = await cariEkle('Ahmet Koyuncu');
      final zeynepId = await cariEkle('Zeynep Ak');
      await aktifligiYaz(ahmetId, aktif: false);
      await aktifligiYaz(zeynepId, aktif: false);

      expect(
        await adlariListele(suzgec: CariSuzgeci.pasifler, arama: 'ahmet'),
        <String>['Ahmet Koyuncu'],
      );
    });
  });

  /// Liste başlığındaki "128 kişi" sayısı.
  ///
  /// Sayı listeden ayrı bir toplama sorgusuyla geliyor; sayılan küme
  /// listelenen kümeyle birebir aynı olmak zorunda.
  group('sayiyiOku', () {
    test('her süzgeç kendi kümesini sayar', () async {
      await cariEkle('Sıradan Müşteri');
      final fidanciId = await cariEkle('Fidancı Meslektaş');
      final borcluId = await cariEkle('Borçlu Müşteri');
      final pasifId = await cariEkle('Kaldırılan Kişi');
      await grubuYaz(fidanciId, CariGrubu.fidanci);
      await bakiyeYaz(borcluId, 9400000);
      await aktifligiYaz(pasifId, aktif: false);

      expect(await repository.sayiyiOku(suzgec: CariSuzgeci.musteriler), 2);
      expect(await repository.sayiyiOku(suzgec: CariSuzgeci.fidancilar), 1);
      expect(await repository.sayiyiOku(suzgec: CariSuzgeci.acikHesap), 1);
      expect(await repository.sayiyiOku(suzgec: CariSuzgeci.pasifler), 1);
    });

    test('grup alanı hiç olmayan eski kayıt müşteri sayısına girer', () async {
      // Sayı `grup == 'musteri'` sorgusuyla bulunsaydı bu kayıt sayılmaz,
      // başlık listede görünen satırlardan azını söylerdi (bkz.
      // `CariSuzgeci.sunucuGrubu`). Aktif kayıtların tamamından fidancılar
      // düşülüyor, sebebi bu.
      final eskiId = await cariEkle('Eski Kayıt');
      await grubuSil(eskiId);
      final fidanciId = await cariEkle('Fidancı Meslektaş');
      await grubuYaz(fidanciId, CariGrubu.fidanci);

      expect(await repository.sayiyiOku(suzgec: CariSuzgeci.musteriler), 1);
      expect(
        await adlariListele(suzgec: CariSuzgeci.musteriler),
        hasLength(1),
        reason: 'sayı listedeki satır sayısını tutmalı',
      );
    });

    test('sayfa sınırından etkilenmez', () async {
      for (var sira = 0; sira < 3; sira++) {
        await cariEkle('Kişi $sira');
      }

      // Başlığın var oluş sebebi bu: liste ilk sayfayı gösterirken sayı
      // listenin tamamını söylüyor.
      expect(await adlariListele(sinir: 1), hasLength(1));
      expect(await repository.sayiyiOku(suzgec: CariSuzgeci.musteriler), 3);
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
