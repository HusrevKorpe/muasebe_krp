import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidancari/domain/cari/cari.dart';
import 'package:fidancari/domain/isletme/isletme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'emulator_yardimcilari.dart';

/// `firestore.rules` doğrulaması.
///
/// Ortak defter modeli: veri kişiye değil işletmeye ait, erişimin tek koşulu
/// açık bir oturum. Bu dosya kuralın gerçekten tuttuğunu sınar — kural
/// dosyasını okumak yetmez, çünkü yanlış yazılmış bir `match` sessizce her şeyi
/// açar (KURALLAR.md §4.1).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore firestore;
  late FirebaseAuth kimlik;

  setUpAll(emulatoreBaglan);

  setUp(() {
    firestore = FirebaseFirestore.instance;
    kimlik = FirebaseAuth.instance;
  });

  tearDown(() => kimlik.signOut());

  CollectionReference<Map<String, dynamic>> carilerYolu(String isletmeId) =>
      firestore
          .collection(Isletme.koleksiyon)
          .doc(isletmeId)
          .collection(Cari.koleksiyon);

  /// Emulator'ün istekleri sunucuda değerlendirmesi gerekiyor: yerel önbellek
  /// kuralları uygulamaz, `Source.server` olmadan test yanlış geçerdi.
  const sunucudan = GetOptions(source: Source.server);

  Matcher yetkiReddi() => throwsA(
    isA<FirebaseException>().having(
      (hata) => hata.code,
      'code',
      'permission-denied',
    ),
  );

  test('giriş yapmış hesap ortak defteri okuyup yazabilir', () async {
    await yeniKullaniciAc(kimlik);

    await carilerYolu(Isletme.ortakId).doc('benim').set(<String, Object?>{
      Cari.alanAd: 'Ortak Cari',
      Cari.alanAktif: true,
    });

    final anlik = await carilerYolu(
      Isletme.ortakId,
    ).doc('benim').get(sunucudan);
    expect(anlik.data()![Cari.alanAd], 'Ortak Cari');
  });

  test('iki hesap aynı veriyi görür', () async {
    // Modelin can alıcı noktası: uygulamayı iki kişi kullanıyor ve ikisi de
    // aynı defteri açmalı. Eski kural (uid == isletmeId) burada düşerdi.
    await yeniKullaniciAc(kimlik);
    await carilerYolu(Isletme.ortakId).doc('paylasilan').set(<String, Object?>{
      Cari.alanAd: 'Paylaşılan Cari',
      Cari.alanAktif: true,
    });
    await kimlik.signOut();

    await yeniKullaniciAc(kimlik);

    final anlik = await carilerYolu(
      Isletme.ortakId,
    ).doc('paylasilan').get(sunucudan);
    expect(anlik.data()![Cari.alanAd], 'Paylaşılan Cari');
  });

  test('oturum açmamış kullanıcı okuyamaz', () async {
    await yeniKullaniciAc(kimlik);
    await carilerYolu(Isletme.ortakId).doc('benim').set(<String, Object?>{
      Cari.alanAd: 'Ortak Cari',
    });
    await kimlik.signOut();

    expect(
      () => carilerYolu(Isletme.ortakId).doc('benim').get(sunucudan),
      yetkiReddi(),
    );
  });

  test('oturum açmamış kullanıcı liste sorgulayamaz', () async {
    expect(
      () => carilerYolu(Isletme.ortakId)
          .where(Cari.alanAktif, isEqualTo: true)
          .get(sunucudan),
      yetkiReddi(),
    );
  });

  test('oturum açmamış kullanıcı yazamaz', () async {
    expect(
      () => carilerYolu(Isletme.ortakId).doc('sizinti').set(<String, Object?>{
        Cari.alanAd: 'Sızıntı',
      }),
      throwsA(isA<FirebaseException>()),
    );
  });

  test('defterin dışındaki yollar giriş yapmış hesaba da kapalı', () async {
    // Kural yalnızca `isletmeler/**` altını açıyor; kök seviyeye yeni bir
    // koleksiyon açılamamalı.
    await yeniKullaniciAc(kimlik);
    final baskaYol = firestore.collection('rastgele');

    expect(
      () => baskaYol.doc('belge').set(<String, Object?>{'a': 1}),
      throwsA(isA<FirebaseException>()),
    );
    expect(() => baskaYol.get(sunucudan), yetkiReddi());
  });
}
