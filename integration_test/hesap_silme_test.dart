import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidancari/core/hata/hatalar.dart';
import 'package:fidancari/data/isletme/isletme_verisi_repository.dart';
import 'package:fidancari/data/kimlik/kimlik_repository.dart';
import 'package:fidancari/domain/cari/cari.dart';
import 'package:fidancari/domain/fidan/fidan.dart';
import 'package:fidancari/domain/islem/islem.dart';
import 'package:fidancari/domain/isletme/isletme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'emulator_yardimcilari.dart';

/// Hesap silme akışı — Apple'ın zorunlu tuttuğu "uygulama içinden hesap silme"
/// (bkz. fazlar/faz-5-magaza.md).
///
/// Sınanan asıl şey sıralama: veri hesaptan **önce** silinmezse Firestore
/// kuralları yazma yetkisini geri çeker ve arkada erişilemez kayıt kalır.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore firestore;
  late FirebaseAuth kimlik;
  late String isletmeId;
  late IsletmeVerisiRepository veriRepository;
  late KimlikRepository kimlikRepository;

  setUpAll(emulatoreBaglan);

  setUp(() async {
    firestore = FirebaseFirestore.instance;
    kimlik = FirebaseAuth.instance;

    isletmeId = await yeniKullaniciAc(kimlik);
    veriRepository = IsletmeVerisiRepository(
      firestore: firestore,
      isletmeId: isletmeId,
    );
    kimlikRepository = KimlikRepository(kimlik);
  });

  tearDown(() async {
    // Hesabı silen testte oturum zaten kapalı; `signOut` yine de güvenli.
    await kimlik.signOut();
  });

  DocumentReference<Map<String, dynamic>> isletmeBelgesi() =>
      firestore.collection(Isletme.koleksiyon).doc(isletmeId);

  /// İki cari, her birinde iki işlem, bir fidan ve işletme profili yazar.
  ///
  /// Yazmalar burada **beklenir** — repository'lerin aksine. Testin silmeden
  /// önce sunucuda gerçekten veri olduğundan emin olması gerekiyor.
  Future<void> ornekVeriYaz() async {
    await isletmeBelgesi().set(<String, Object?>{
      Isletme.alanAd: 'Test Fidancılık',
    });

    for (var sira = 1; sira <= 2; sira++) {
      final cari = isletmeBelgesi().collection(Cari.koleksiyon).doc('cari$sira');
      await cari.set(<String, Object?>{Cari.alanAd: 'Cari $sira'});

      for (var islem = 1; islem <= 2; islem++) {
        await cari
            .collection(Islem.koleksiyon)
            .doc('islem$islem')
            .set(<String, Object?>{Islem.alanBaslik: 'İşlem $islem'});
      }
    }

    await isletmeBelgesi()
        .collection(Fidan.koleksiyon)
        .doc('fidan1')
        .set(<String, Object?>{Fidan.alanTur: 'Elma'});
  }

  Future<int> sunucudakiBelgeSayisi(
    Query<Map<String, dynamic>> sorgu,
  ) async {
    final anlik = await sorgu.get(const GetOptions(source: Source.server));
    return anlik.docs.length;
  }

  testWidgets('tüm veri silinir — cariler, işlemler, fidanlar ve profil', (
    _,
  ) async {
    await ornekVeriYaz();

    final cariler = isletmeBelgesi().collection(Cari.koleksiyon);
    expect(await sunucudakiBelgeSayisi(cariler), 2);

    await veriRepository.tumVeriyiSil();

    expect(await sunucudakiBelgeSayisi(cariler), 0);
    expect(
      await sunucudakiBelgeSayisi(
        isletmeBelgesi().collection(Fidan.koleksiyon),
      ),
      0,
    );

    // Alt koleksiyon üst belge silinince kendiliğinden gitmez; işlemlerin
    // gerçekten dolaşılıp silindiği ayrıca doğrulanıyor.
    expect(
      await sunucudakiBelgeSayisi(
        cariler.doc('cari1').collection(Islem.koleksiyon),
      ),
      0,
    );

    final profil = await isletmeBelgesi().get(
      const GetOptions(source: Source.server),
    );
    expect(profil.exists, isFalse);
  });

  testWidgets('yanlış şifre yeniden doğrulamayı düşürür — veri durur', (
    _,
  ) async {
    await ornekVeriYaz();

    await expectLater(
      kimlikRepository.yenidenDogrula('yanlis-sifre'),
      throwsA(isA<KimlikHatasi>()),
    );

    expect(
      await sunucudakiBelgeSayisi(isletmeBelgesi().collection(Cari.koleksiyon)),
      2,
    );
    expect(kimlik.currentUser, isNotNull);
  });

  testWidgets('tam akış: doğrula → veriyi sil → hesabı sil', (_) async {
    await ornekVeriYaz();

    await kimlikRepository.yenidenDogrula(testSifresi);
    await veriRepository.tumVeriyiSil();
    await kimlikRepository.hesabiSil();

    expect(kimlik.currentUser, isNull);
  });

  testWidgets('boş hesapta silme sessizce geçer', (_) async {
    // Kurulumu yarıda bırakan kullanıcının hesabı da silinebilmeli: ortada
    // ne cari ne işletme profili var.
    await veriRepository.tumVeriyiSil();

    final profil = await isletmeBelgesi().get(
      const GetOptions(source: Source.server),
    );
    expect(profil.exists, isFalse);
  });
}
