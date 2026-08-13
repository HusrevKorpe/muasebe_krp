import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/hata/hatalar.dart';
import '../../domain/isletme/isletme.dart';
import '../firebase/firebase_saglayicilar.dart';

/// Google ile oturum açma. Firebase Auth'un tek erişim noktası.
///
/// Uygulamayı birkaç kişi kullanıyor ve hepsi aynı defteri görüyor. Kimin
/// gireceğine uygulama karar vermez: Google girişi kimliği doğrular, veriye
/// erişim iznini `firestore.rules` içindeki `izinliler` listesi verir. Listede
/// olmayan bir hesap oturum açabilir ama tek bir kayıt bile göremez.
///
/// Firebase'in ve Google Sign-In'ın İngilizce hata kodları burada
/// [KimlikHatasi]'na çevrilir; üst katmanlar eklenti hatası görmez.
class KimlikRepository {
  KimlikRepository({required FirebaseAuth kimlik, required GoogleSignIn google})
    : _kimlik = kimlik,
      _google = google;

  final FirebaseAuth _kimlik;
  final GoogleSignIn _google;

  /// [GoogleSignIn.initialize] bir kez çağrılmalı; sonucu burada saklanır.
  Future<void>? _hazirlik;

  /// Açık oturumu izler. Oturum yoksa `null` yayar.
  ///
  /// Firebase oturumu cihazda saklar: ilk yayın saklanan oturum yüklenince
  /// gelir, yani ikinci açılışta ağa hiç çıkılmaz ve uygulama çevrimdışı da
  /// açılır.
  Stream<User?> oturumAkisi() => _kimlik.authStateChanges();

  /// Google hesabı seçtirir ve o kimlikle Firebase oturumu açar.
  ///
  /// Kullanıcı hesap seçmeden vazgeçerse `false` döner — vazgeçmek hata
  /// değildir, ekranda kırmızı bir mesaj çıkmamalı.
  Future<bool> girisYap() async {
    try {
      await _hazirla();

      final hesap = await _google.authenticate();
      final belirtec = hesap.authentication.idToken;
      if (belirtec == null) throw const KimlikHatasi.acilamadi();

      await _kimlik.signInWithCredential(
        GoogleAuthProvider.credential(idToken: belirtec),
      );
      return true;
    } on GoogleSignInException catch (hata) {
      if (hata.code == GoogleSignInExceptionCode.canceled) return false;
      throw _googleHatasi(hata.code);
    } on FirebaseAuthException catch (hata) {
      throw KimlikHatasi.koddan(hata.code);
    }
  }

  /// Hem Firebase oturumunu hem Google seçimini kapatır.
  ///
  /// Google tarafı da kapatılmalı: yalnızca Firebase'den çıkılırsa bir sonraki
  /// girişte hesap seçtirilmeden aynı hesapla devam edilir ve cihazı paylaşan
  /// ikinci kişi kendi hesabına geçemez.
  Future<void> cikisYap() async {
    await _google.signOut();
    await _kimlik.signOut();
  }

  /// Eklentiyi bir kez hazırlar. Hazırlık başarısızsa saklanmaz; sonraki
  /// deneme yeniden çalışır.
  Future<void> _hazirla() {
    final mevcut = _hazirlik;
    if (mevcut != null) return mevcut;

    final yeni = _google.initialize();
    _hazirlik = yeni;
    return yeni.catchError((Object hata) {
      _hazirlik = null;
      throw hata;
    });
  }

  /// Google Sign-In hata kodunu uygulama hatasına çevirir.
  ///
  /// Yapılandırma hataları kullanıcının düzeltebileceği bir şey değil: ya
  /// `Info.plist` eksiktir ya da Firebase Console'da Google sağlayıcısı kapalı.
  KimlikHatasi _googleHatasi(GoogleSignInExceptionCode kod) => switch (kod) {
    GoogleSignInExceptionCode.clientConfigurationError ||
    GoogleSignInExceptionCode.providerConfigurationError =>
      const KimlikHatasi.yapilandirilmamis(),
    _ => const KimlikHatasi.acilamadi(),
  };
}

final googleGirisSaglayici = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance;
});

final kimlikRepositorySaglayici = Provider<KimlikRepository>((ref) {
  return KimlikRepository(
    kimlik: ref.watch(kimlikDogrulamaSaglayici),
    google: ref.watch(googleGirisSaglayici),
  );
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
/// görürdü. Uygulamayı iki kişi kullanmaya başlayınca sabitlendi: ikisi de
/// [Isletme.ortakId] altındaki **aynı** defteri açar.
///
/// Oturum açılana kadar `null`; repository sağlayıcıları bu sürede
/// kurulmamalı, yönlendirici de o ana kadar açılış ekranında bekletir.
final isletmeKimligiSaglayici = Provider<String?>((ref) {
  return ref.watch(oturumSaglayici).value == null ? null : Isletme.ortakId;
});
