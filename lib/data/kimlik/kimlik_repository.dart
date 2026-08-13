import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hata/hatalar.dart';
import '../../domain/isletme/isletme.dart';
import '../firebase/firebase_saglayicilar.dart';

/// E-posta ve şifreyle oturum açma. Firebase Auth'un tek erişim noktası.
///
/// Uygulama hesap **açmaz**: hesaplar Firebase Console → Authentication →
/// Users altında elle açılır ve kullanıcıya e-posta/şifre olarak verilir.
/// Bu yüzden burada kayıt, şifre sıfırlama ya da hesap silme yok — giriş ve
/// çıkış yeter.
///
/// Firebase'in İngilizce hata kodları burada [KimlikHatasi]'na çevrilir;
/// üst katmanlar `FirebaseAuthException` görmez.
class KimlikRepository {
  const KimlikRepository(this._kimlik);

  final FirebaseAuth _kimlik;

  /// Açık oturumu izler. Oturum yoksa `null` yayar.
  ///
  /// Firebase oturumu cihazda saklar: ilk yayın saklanan oturum yüklenince
  /// gelir, yani ikinci açılışta şifre sorulmaz ve uygulama çevrimdışı da
  /// açılır.
  Stream<User?> oturumAkisi() => _kimlik.authStateChanges();

  Future<void> girisYap({required String ePosta, required String sifre}) async {
    try {
      await _kimlik.signInWithEmailAndPassword(
        email: ePosta.trim(),
        password: sifre,
      );
    } on FirebaseAuthException catch (hata) {
      throw KimlikHatasi.koddan(hata.code);
    }
  }

  Future<void> cikisYap() => _kimlik.signOut();
}

final kimlikRepositorySaglayici = Provider<KimlikRepository>((ref) {
  return KimlikRepository(ref.watch(kimlikDogrulamaSaglayici));
});

/// Açık oturum. Yönlendirici bunu izler: `null` ise giriş ekranı gösterilir.
///
/// Oturum uygulama çalışırken de düşebilir (konsoldan hesap devre dışı
/// bırakılırsa); akış olduğu için ekran kendiliğinden girişe döner.
final oturumSaglayici = StreamProvider<User?>((ref) {
  return ref.watch(kimlikRepositorySaglayici).oturumAkisi();
});

/// Açık oturumun e-postası — ayarlarda "kim girmiş" satırında gösterilir.
final oturumEPostasiSaglayici = Provider<String?>((ref) {
  return ref.watch(oturumSaglayici).value?.email;
});

/// Ortak defterin kimliği; oturum açılmadan `null`.
///
/// Eskiden burası oturumun `uid` değeriydi ve her hesap kendi verisini
/// görürdü. Uygulamayı iki kişi kullanmaya başlayınca sabitlendi: hangi hesapla
/// girilirse girilsin [Isletme.ortakId] altındaki **aynı** defter açılır.
///
/// Oturum açılana kadar `null`; repository sağlayıcıları bu sürede
/// kurulmamalı, yönlendirici de o ana kadar açılış ekranında bekletir.
final isletmeKimligiSaglayici = Provider<String?>((ref) {
  return ref.watch(oturumSaglayici).value == null ? null : Isletme.ortakId;
});
