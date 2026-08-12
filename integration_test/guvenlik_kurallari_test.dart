import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fidancari/domain/cari/cari.dart';
import 'package:fidancari/domain/isletme/isletme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'emulator_yardimcilari.dart';

/// `firestore.rules` doğrulaması.
///
/// Tek kullanıcılı model: her kurulum yalnızca kendi verisini görür. Bu dosya
/// kuralın gerçekten tuttuğunu sınar — kural dosyasını okumak yetmez, çünkü
/// yanlış yazılmış bir `match` sessizce her şeyi açar (KURALLAR.md §4.1).
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

  test('kullanıcı başka bir uid altındaki cariyi okuyamaz', () async {
    final baskasininId = await yeniKullaniciAc(kimlik);
    await carilerYolu(baskasininId).doc('gizli').set(<String, Object?>{
      Cari.alanAd: 'Gizli Cari',
      Cari.alanAktif: true,
    });
    await kimlik.signOut();

    await yeniKullaniciAc(kimlik);

    expect(
      () => carilerYolu(baskasininId).doc('gizli').get(sunucudan),
      throwsA(
        isA<FirebaseException>().having(
          (hata) => hata.code,
          'code',
          'permission-denied',
        ),
      ),
    );
  });

  test('kullanıcı başka bir uid altına yazamaz', () async {
    final baskasininId = await yeniKullaniciAc(kimlik);
    await kimlik.signOut();
    await yeniKullaniciAc(kimlik);

    expect(
      () => carilerYolu(baskasininId).doc('sizinti').set(<String, Object?>{
        Cari.alanAd: 'Sızıntı',
      }),
      throwsA(isA<FirebaseException>()),
    );
  });

  test('kullanıcı başka bir uid altındaki listeyi sorgulayamaz', () async {
    final baskasininId = await yeniKullaniciAc(kimlik);
    await kimlik.signOut();
    await yeniKullaniciAc(kimlik);

    expect(
      () => carilerYolu(baskasininId)
          .where(Cari.alanAktif, isEqualTo: true)
          .get(sunucudan),
      throwsA(isA<FirebaseException>()),
    );
  });

  test('kullanıcı kendi verisini okuyup yazabilir', () async {
    final isletmeId = await yeniKullaniciAc(kimlik);

    await carilerYolu(isletmeId).doc('benim').set(<String, Object?>{
      Cari.alanAd: 'Kendi Carim',
      Cari.alanAktif: true,
    });

    final anlik = await carilerYolu(isletmeId).doc('benim').get(sunucudan);
    expect(anlik.data()![Cari.alanAd], 'Kendi Carim');
  });

  test('oturum açmamış kullanıcı hiçbir veriye erişemez', () async {
    final isletmeId = await yeniKullaniciAc(kimlik);
    await carilerYolu(isletmeId).doc('benim').set(<String, Object?>{
      Cari.alanAd: 'Kendi Carim',
    });
    await kimlik.signOut();

    expect(
      () => carilerYolu(isletmeId).doc('benim').get(sunucudan),
      throwsA(isA<FirebaseException>()),
    );
  });
}
