import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidancari/core/hata/hatalar.dart';
import 'package:fidancari/core/para/kurus.dart';
import 'package:fidancari/data/cari/cari_repository.dart';
import 'package:fidancari/data/islem/islem_repository.dart';
import 'package:fidancari/data/islem/islem_sayfasi.dart';
import 'package:fidancari/domain/cari/cari.dart';
import 'package:fidancari/domain/islem/islem.dart';
import 'package:fidancari/domain/islem/islem_kalemi.dart';
import 'package:fidancari/domain/islem/islem_tipi.dart';
import 'package:fidancari/domain/isletme/isletme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'emulator_yardimcilari.dart';

/// `IslemRepository` — emulator testleri.
///
/// Fazın en riskli kısmı burada doğrulanır: işlem kaydı ile cari bakiyesinin
/// aynı atomik yazmada güncellenmesi, düzeltmenin bakiyeye yalnızca farkı
/// işlemesi, iptalin bakiyeyi geri alması ve eşzamanlı yazmalarda bakiyenin
/// bozulmaması.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore firestore;
  late FirebaseAuth kimlik;
  late IslemRepository repository;
  late CariRepository cariRepository;
  late CollectionReference<Map<String, dynamic>> cariler;
  late String cariId;

  setUpAll(emulatoreBaglan);

  setUp(() async {
    firestore = FirebaseFirestore.instance;
    kimlik = FirebaseAuth.instance;

    final isletmeId = await yeniKullaniciAc(kimlik);
    cariler = firestore
        .collection(Isletme.koleksiyon)
        .doc(isletmeId)
        .collection(Cari.koleksiyon);
    cariRepository = CariRepository(
      firestore: firestore,
      isletmeId: isletmeId,
    );
    repository = IslemRepository(firestore: firestore, isletmeId: isletmeId);

    cariId = await cariRepository.ekle(const Cari(id: '', ad: 'Örnek Müşteri'));
    await sunucudaBekle(
      cariler.doc(cariId),
      kosul: (veri) => veri[Cari.alanOlusturmaTarihi] != null,
    );
  });

  tearDown(() => kimlik.signOut());

  CollectionReference<Map<String, dynamic>> islemler() =>
      cariler.doc(cariId).collection(Islem.koleksiyon);

  /// Cari bakiyesi beklenen değere ulaşana kadar sunucuyu yoklar.
  Future<int> bakiyeyiBekle(int beklenen) async {
    final anlik = await sunucudaBekle(
      cariler.doc(cariId),
      kosul: (veri) => veri[Cari.alanBakiyeKurus] == beklenen,
    );
    return anlik.data()![Cari.alanBakiyeKurus] as int;
  }

  Future<String> faturaEkle({
    IslemTipi tip = IslemTipi.satisFaturasi,
    int lira = 1000,
    DateTime? tarih,
  }) async {
    final islemId = await repository.ekle(
      cariId: cariId,
      islem: Islem.fatura(
        tip: tip,
        baslik: 'Test faturası',
        islemTarihi: tarih ?? DateTime(2024, 3, 1),
        kalemler: <IslemKalemi>[
          IslemKalemi.birimFiyattan(
            tur: 'fidan',
            miktar: 1,
            birimFiyat: Kurus.liradan(lira),
          ),
        ],
      ),
    );
    await sunucudaBekle(
      islemler().doc(islemId),
      kosul: (veri) => veri[Islem.alanOlusturmaTarihi] != null,
    );
    return islemId;
  }

  Future<String> tahsilatEkle({int lira = 400, DateTime? tarih}) async {
    final islemId = await repository.ekle(
      cariId: cariId,
      islem: Islem.odeme(
        tip: IslemTipi.tahsilat,
        baslik: 'Müşteriden Tahsilat',
        islemTarihi: tarih ?? DateTime(2024, 3, 2),
        tutar: Kurus.liradan(lira),
      ),
    );
    await sunucudaBekle(
      islemler().doc(islemId),
      kosul: (veri) => veri[Islem.alanOlusturmaTarihi] != null,
    );
    return islemId;
  }

  group('ekle', () {
    test('işlem sunucuya yazılır ve tutarlar int olarak durur', () async {
      final islemId = await faturaEkle(lira: 140625);
      final veri = (await sunucudaBekle(islemler().doc(islemId))).data()!;

      expect(veri[Islem.alanTip], 'satisFaturasi');
      expect(veri[Islem.alanToplamKurus], 14062500);
      expect(veri[Islem.alanToplamKurus], isA<int>());
      expect(veri[Islem.alanIptal], isFalse);
      expect(veri[Islem.alanKalemler], hasLength(1));
    });

    test('satış faturası cari bakiyesini artırır', () async {
      await faturaEkle(lira: 1000);

      expect(await bakiyeyiBekle(100000), 100000);
    });

    test('tahsilat bakiyeyi azaltır', () async {
      await faturaEkle(lira: 1000);
      await bakiyeyiBekle(100000);

      await tahsilatEkle(lira: 400);

      expect(await bakiyeyiBekle(60000), 60000);
    });

    test('alış faturası bakiyeyi negatife düşürür', () async {
      await faturaEkle(tip: IslemTipi.alisFaturasi, lira: 1000);

      expect(await bakiyeyiBekle(-100000), -100000);
    });

    test('son işlem tarihi geriye tarihli kayıtla geri kaymaz', () async {
      await faturaEkle(tarih: DateTime(2024, 6, 1));
      await sunucudaBekle(
        cariler.doc(cariId),
        kosul: (veri) => veri[Cari.alanSonIslemTarihi] != null,
      );

      await tahsilatEkle(tarih: DateTime(2020, 1, 1));
      final veri = (await sunucudaBekle(cariler.doc(cariId))).data()!;

      final sonIslem = (veri[Cari.alanSonIslemTarihi] as Timestamp).toDate();
      expect(sonIslem, DateTime(2024, 6, 1));
    });
  });

  group('listeyiIzle', () {
    /// Akıştan, [kayitSayisi] kadar kayıt taşıyan ilk sayfayı bekler.
    Future<IslemSayfasi> sayfa({
      required int kayitSayisi,
      DateTime? baslangic,
      DateTime? bitis,
      int sinir = IslemRepository.varsayilanSayfaBoyu,
    }) => sayfayiBekle(
      repository.listeyiIzle(
        cariId: cariId,
        baslangic: baslangic,
        bitis: bitis,
        sinir: sinir,
      ),
      kosul: (sayfa) => sayfa.kayitlar.length == kayitSayisi,
    );

    test('en yeniden en eskiye sıralanır', () async {
      await faturaEkle(tarih: DateTime(2024, 1, 1));
      await tahsilatEkle(tarih: DateTime(2024, 3, 1));
      await tahsilatEkle(tarih: DateTime(2024, 2, 1));

      final ilk = await sayfa(kayitSayisi: 3);

      expect(
        ilk.kayitlar.map((kayit) => kayit.islem.islemTarihi),
        <DateTime>[DateTime(2024, 3, 1), DateTime(2024, 2, 1), DateTime(2024, 1, 1)],
      );
    });

    test('aynı güne düşen işlemler giriş sırasını korur', () async {
      final ayniGun = DateTime(2021, 9, 17);
      final faturaId = await faturaEkle(tarih: ayniGun);
      final tahsilatId = await tahsilatEkle(tarih: ayniGun);

      final ilk = await sayfa(kayitSayisi: 2);

      // Liste yeniden eskiye: sonra girilen tahsilat üstte olmalı.
      expect(ilk.kayitlar.map((kayit) => kayit.islem.id), <String>[
        tahsilatId,
        faturaId,
      ]);
    });

    test('yeni işlem akışa kendiliğinden düşer', () async {
      await tahsilatEkle(tarih: DateTime(2024, 4, 1));

      // Akışa abone olunduktan sonra girilen işlem, sorgu yeniden atılmadan
      // listede belirmeli — liste ekranlarının `get()` yerine `snapshots()`
      // dinlemesinin bütün sebebi bu.
      final ikiKayit = sayfa(kayitSayisi: 2);
      await tahsilatEkle(tarih: DateTime(2024, 4, 2));

      expect(
        (await ikiKayit).kayitlar.first.islem.islemTarihi,
        DateTime(2024, 4, 2),
      );
    });

    test('sınır büyüdükçe kayıt tekrarlamaz ve atlamaz', () async {
      for (var gun = 1; gun <= 5; gun++) {
        await tahsilatEkle(lira: gun * 100, tarih: DateTime(2024, 4, gun));
      }

      final ilkSayfa = await sayfa(kayitSayisi: 2, sinir: 2);
      final tamami = await sayfa(kayitSayisi: 5, sinir: 4 + 2);

      expect(ilkSayfa.dahaVar, isTrue);
      expect(tamami.dahaVar, isFalse);
      // Büyüyen sınır ilk sayfayı olduğu gibi kapsamalı: "daha yükle" eldeki
      // kayıtları kaydırırsa kullanıcı satır atlar ya da satırı iki kez görür.
      expect(
        tamami.kayitlar.take(2).map((kayit) => kayit.islem.id),
        ilkSayfa.kayitlar.map((kayit) => kayit.islem.id),
      );
      expect(
        tamami.kayitlar.map((kayit) => kayit.islem.id).toSet(),
        hasLength(5),
      );
    });

    test('tarih aralığı süzgeci yalnızca aralıktakileri döner', () async {
      await tahsilatEkle(tarih: DateTime(2023, 12, 31));
      await tahsilatEkle(tarih: DateTime(2024, 2, 15));
      await tahsilatEkle(tarih: DateTime(2025, 1, 1));

      final aralik = await sayfa(
        kayitSayisi: 1,
        baslangic: DateTime(2024, 1, 1),
        bitis: DateTime(2024, 12, 31),
      );

      expect(aralik.kayitlar.single.islem.islemTarihi, DateTime(2024, 2, 15));
    });
  });

  group('ekstreIcinGetir', () {
    test('işlemleri eskiden yeniye, sayfalamadan döner', () async {
      await tahsilatEkle(tarih: DateTime(2024, 6, 1));
      await faturaEkle(tarih: DateTime(2024, 1, 15));
      await tahsilatEkle(tarih: DateTime(2024, 3, 20));

      final islemler = await repository.ekstreIcinGetir(cariId: cariId);

      expect(
        islemler.map((islem) => islem.islemTarihi),
        <DateTime>[
          DateTime(2024, 1, 15),
          DateTime(2024, 3, 20),
          DateTime(2024, 6, 1),
        ],
        reason: 'ekstrenin doğal yönü eskiden yeniye',
      );
    });

    test('bitiş sınırından sonraki işlemler hiç okunmaz', () async {
      await faturaEkle(tarih: DateTime(2024, 1, 15));
      await tahsilatEkle(tarih: DateTime(2025, 2, 1));

      final islemler = await repository.ekstreIcinGetir(
        cariId: cariId,
        bitis: DateTime(2024, 12, 31, 23, 59, 59, 999),
      );

      expect(islemler, hasLength(1));
      expect(islemler.single.islemTarihi, DateTime(2024, 1, 15));
    });

    test('açılış bakiyesi için aralık öncesi işlemler de gelir', () async {
      // Ekstre, aralıktan önceki kayıtları sorguyla dışlamaz: açılış
      // bakiyesi onlardan toplanır, ayıklamayı domain yapar.
      await faturaEkle(tarih: DateTime(2023, 5, 1));
      await tahsilatEkle(tarih: DateTime(2024, 6, 1));

      final islemler = await repository.ekstreIcinGetir(cariId: cariId);

      expect(islemler, hasLength(2));
    });

    test('iptalli kayıt da döner — ekstrede üstü çizili görünür', () async {
      final islemId = await faturaEkle(tarih: DateTime(2024, 1, 15));
      final kayit = await repository
          .izle(cariId: cariId, islemId: islemId)
          .firstWhere((kayit) => kayit != null);
      await repository.iptalEt(cariId: cariId, islem: kayit!.islem);
      await sunucudaBekle(
        islemler().doc(islemId),
        kosul: (veri) => veri[Islem.alanIptal] == true,
      );

      final ekstreIslemleri = await repository.ekstreIcinGetir(cariId: cariId);

      expect(ekstreIslemleri, hasLength(1));
      expect(ekstreIslemleri.single.iptalMi, isTrue);
      expect(ekstreIslemleri.single.bakiyeEtkisi, Kurus.sifir);
    });
  });

  group('guncelle', () {
    /// Kaydın sunucudaki güncel hâli. Bakiye farkı bunun üzerinden hesaplanır.
    Future<Islem> islemiOku(String islemId) async {
      final kayit = await repository
          .izle(cariId: cariId, islemId: islemId)
          .firstWhere((kayit) => kayit != null);
      return kayit!.islem;
    }

    Islem fiyatiDegistir(Islem eski, int lira) => Islem.fatura(
      id: eski.id,
      tip: eski.tip,
      baslik: eski.baslik,
      islemTarihi: eski.islemTarihi,
      kalemler: <IslemKalemi>[
        IslemKalemi.birimFiyattan(
          tur: 'fidan',
          miktar: 1,
          birimFiyat: Kurus.liradan(lira),
        ),
      ],
    );

    test('fiyat düzeltilince aynı belge güncellenir, yenisi açılmaz', () async {
      final islemId = await faturaEkle(lira: 1000);
      await bakiyeyiBekle(100000);
      final eski = await islemiOku(islemId);

      await repository.guncelle(
        cariId: cariId,
        eski: eski,
        yeni: fiyatiDegistir(eski, 1200),
      );

      final veri = (await sunucudaBekle(
        islemler().doc(islemId),
        kosul: (veri) => veri[Islem.alanToplamKurus] == 120000,
      )).data()!;
      expect(veri[Islem.alanToplamKurus], isA<int>());
      expect(veri[Islem.alanIptal], isFalse, reason: 'iptal alanı korunur');
      expect(veri[Islem.alanOlusturmaTarihi], isNotNull);
      expect((await islemler().get()).docs, hasLength(1));
    });

    test('bakiyeye yalnızca fark işlenir', () async {
      final islemId = await faturaEkle(lira: 1000);
      await bakiyeyiBekle(100000);
      final eski = await islemiOku(islemId);

      await repository.guncelle(
        cariId: cariId,
        eski: eski,
        yeni: fiyatiDegistir(eski, 1200),
      );

      expect(await bakiyeyiBekle(120000), 120000);
    });

    test('tahsilat düzeltmesi bakiyeyi ters yönde kaydırır', () async {
      await faturaEkle(lira: 1000);
      final islemId = await tahsilatEkle(lira: 400);
      await bakiyeyiBekle(60000);
      final eski = await islemiOku(islemId);

      await repository.guncelle(
        cariId: cariId,
        eski: eski,
        yeni: Islem.odeme(
          id: eski.id,
          tip: eski.tip,
          baslik: eski.baslik,
          islemTarihi: eski.islemTarihi,
          tutar: Kurus.liradan(600),
        ),
      );

      expect(await bakiyeyiBekle(40000), 40000);
    });

    test('düzenleme sunucu saatiyle işaretlenir', () async {
      final islemId = await faturaEkle(lira: 1000);
      final eski = await islemiOku(islemId);
      expect(eski.duzenlenmisMi, isFalse);

      await repository.guncelle(
        cariId: cariId,
        eski: eski,
        yeni: fiyatiDegistir(eski, 1200),
      );

      final veri = (await sunucudaBekle(
        islemler().doc(islemId),
        kosul: (veri) => veri[Islem.alanGuncellemeTarihi] != null,
      )).data()!;
      expect(veri[Islem.alanGuncellemeTarihi], isA<Timestamp>());
    });

    test('düzenlenmiş kayıtta yeniden hesaplanan bakiye tutar', () async {
      final islemId = await faturaEkle(lira: 1000);
      await tahsilatEkle(lira: 400);
      await bakiyeyiBekle(60000);
      final eski = await islemiOku(islemId);

      await repository.guncelle(
        cariId: cariId,
        eski: eski,
        yeni: fiyatiDegistir(eski, 1200),
      );
      await bakiyeyiBekle(80000);

      final bakiye = await repository.bakiyeYenidenHesapla(cariId);
      expect(bakiye.deger, 80000);
    });

    test('iptalli kayıt düzenlenmez', () async {
      final islemId = await faturaEkle(lira: 1000);
      await bakiyeyiBekle(100000);
      await repository.iptalEt(cariId: cariId, islem: await islemiOku(islemId));
      await bakiyeyiBekle(0);

      final iptalli = await repository
          .izle(cariId: cariId, islemId: islemId)
          .firstWhere((kayit) => kayit != null && kayit.islem.iptalMi);

      await expectLater(
        repository.guncelle(
          cariId: cariId,
          eski: iptalli!.islem,
          yeni: fiyatiDegistir(iptalli.islem, 1200),
        ),
        throwsA(isA<VeriHatasi>()),
      );
      expect(await bakiyeyiBekle(0), 0);
    });

    test('kaydedilmemiş işlem güncellenmez', () async {
      final yeni = Islem(
        id: '',
        tip: IslemTipi.satisFaturasi,
        baslik: 'Kaydedilmemiş',
        islemTarihi: DateTime(2024, 3, 1),
        toplam: Kurus.sifir,
      );

      await expectLater(
        repository.guncelle(cariId: cariId, eski: yeni, yeni: yeni),
        throwsA(isA<VeriHatasi>()),
      );
    });
  });

  group('iptalEt', () {
    test('kayıt silinmez, iptal işaretlenir ve bakiye geri alınır', () async {
      final islemId = await faturaEkle(lira: 1000);
      await bakiyeyiBekle(100000);

      final kayit = await repository
          .izle(cariId: cariId, islemId: islemId)
          .firstWhere((kayit) => kayit != null);
      await repository.iptalEt(
        cariId: cariId,
        islem: kayit!.islem,
        neden: 'yanlış giriş',
      );

      expect(await bakiyeyiBekle(0), 0);
      final veri = (await sunucudaBekle(islemler().doc(islemId))).data()!;
      expect(veri[Islem.alanIptal], isTrue);
      expect(veri[Islem.alanIptalNedeni], 'yanlış giriş');
      expect(veri[Islem.alanToplamKurus], 100000, reason: 'tutar korunur');
    });

    test('iptalli kayıt ikinci kez iptal edilmez — bakiye iki kez dönmez',
        () async {
      final islemId = await faturaEkle(lira: 1000);
      await bakiyeyiBekle(100000);

      final kayit = await repository
          .izle(cariId: cariId, islemId: islemId)
          .firstWhere((kayit) => kayit != null);
      await repository.iptalEt(cariId: cariId, islem: kayit!.islem);
      await bakiyeyiBekle(0);

      // Aynı (artık bayat) nesneyle ikinci çağrı: kayıt zaten iptalli.
      final iptalli = await repository
          .izle(cariId: cariId, islemId: islemId)
          .firstWhere((kayit) => kayit != null && kayit.islem.iptalMi);
      await repository.iptalEt(cariId: cariId, islem: iptalli!.islem);

      expect(await bakiyeyiBekle(0), 0);
    });
  });

  group('bakiyeYenidenHesapla', () {
    test('sonuç önbelleklenmiş bakiyeyle aynı çıkar', () async {
      await faturaEkle(lira: 1000);
      await tahsilatEkle(lira: 400);
      await faturaEkle(tip: IslemTipi.alisFaturasi, lira: 200);
      await bakiyeyiBekle(40000);

      final bakiye = await repository.bakiyeYenidenHesapla(cariId);

      expect(bakiye.deger, 40000);
      expect(await bakiyeyiBekle(40000), 40000);
    });

    test('bozulmuş önbellek onarılır', () async {
      await faturaEkle(lira: 1000);
      await bakiyeyiBekle(100000);

      // Bakiye alanını kasten bozuyoruz: transaction dışı bir yazmanın ya da
      // eski bir sürümün bırakabileceği tutarsızlık.
      await cariler.doc(cariId).update(<String, Object?>{
        Cari.alanBakiyeKurus: 12345,
      });
      await bakiyeyiBekle(12345);

      final bakiye = await repository.bakiyeYenidenHesapla(cariId);

      expect(bakiye.deger, 100000);
      expect(await bakiyeyiBekle(100000), 100000);
    });

    test('iptal edilmiş işlem yeniden hesaba katılmaz', () async {
      final islemId = await faturaEkle(lira: 1000);
      await tahsilatEkle(lira: 400);
      await bakiyeyiBekle(60000);

      final kayit = await repository
          .izle(cariId: cariId, islemId: islemId)
          .firstWhere((kayit) => kayit != null);
      await repository.iptalEt(cariId: cariId, islem: kayit!.islem);
      await bakiyeyiBekle(-40000);

      expect((await repository.bakiyeYenidenHesapla(cariId)).deger, -40000);
    });
  });

  group('eşzamanlılık', () {
    test('hızlı ardışık işlemler bakiyeyi bozmaz', () async {
      // Beş işlem beklemeden peş peşe yazılır: okuma-değiştirme-yazma olsaydı
      // biri diğerinin artışını ezerdi. `FieldValue.increment` atomik olduğu
      // için hepsi üst üste biner (Faz 2 kabul kriteri 8).
      await Future.wait(<Future<String>>[
        for (var sayac = 0; sayac < 5; sayac++)
          repository.ekle(
            cariId: cariId,
            islem: Islem.odeme(
              tip: IslemTipi.satisFaturasi,
              baslik: 'eşzamanlı $sayac',
              islemTarihi: DateTime(2024, 5, sayac + 1),
              tutar: Kurus.liradan(100),
            ),
          ),
      ]);

      expect(await bakiyeyiBekle(50000), 50000);
      expect((await repository.bakiyeYenidenHesapla(cariId)).deger, 50000);
    });
  });
}
