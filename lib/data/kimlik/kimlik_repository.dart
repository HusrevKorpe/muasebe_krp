import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hata/hatalar.dart';
import '../firebase/firebase_saglayicilar.dart';

/// Kimlik doğrulama işlemleri. Firebase Auth'un tek erişim noktası.
///
/// Firebase'in İngilizce hata kodları burada [KimlikHatasi]'na çevrilir;
/// üst katmanlar `FirebaseAuthException` görmez.
class KimlikRepository {
  const KimlikRepository(this._kimlik);

  final FirebaseAuth _kimlik;

  User? get mevcutKullanici => _kimlik.currentUser;

  Stream<User?> oturumDurumu() => _kimlik.authStateChanges();

  Future<void> girisYap({
    required String ePosta,
    required String sifre,
  }) async {
    try {
      await _kimlik.signInWithEmailAndPassword(
        email: ePosta.trim(),
        password: sifre,
      );
    } on FirebaseAuthException catch (hata) {
      throw KimlikHatasi.koddan(hata.code);
    }
  }

  Future<void> kayitOl({
    required String ePosta,
    required String sifre,
  }) async {
    try {
      await _kimlik.createUserWithEmailAndPassword(
        email: ePosta.trim(),
        password: sifre,
      );
    } on FirebaseAuthException catch (hata) {
      throw KimlikHatasi.koddan(hata.code);
    }
  }

  Future<void> sifreSifirlamaGonder(String ePosta) async {
    try {
      await _kimlik.sendPasswordResetEmail(email: ePosta.trim());
    } on FirebaseAuthException catch (hata) {
      throw KimlikHatasi.koddan(hata.code);
    }
  }

  Future<void> cikisYap() => _kimlik.signOut();

  /// Kullanıcıyı şifresiyle yeniden doğrular.
  ///
  /// Firebase, hesap silme gibi hassas işlemlerde yakın zamanda giriş yapılmış
  /// olmasını şart koşar; aksi hâlde `requires-recent-login` döner. Bu çağrı
  /// sunucuya gider, yani çevrimdışıyken ağ hatasıyla düşer — hesap silme
  /// akışının bağlantı kontrolü de böylece burada yapılmış olur.
  Future<void> yenidenDogrula(String sifre) async {
    final kullanici = _kimlik.currentUser;
    final ePosta = kullanici?.email;
    if (kullanici == null || ePosta == null) {
      throw const KimlikHatasi('Oturum bulunamadı. Tekrar giriş yapın.');
    }

    try {
      await kullanici.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: ePosta, password: sifre),
      );
    } on FirebaseAuthException catch (hata) {
      throw KimlikHatasi.koddan(hata.code);
    }
  }

  /// Firebase Auth kullanıcısını siler.
  ///
  /// Yalnızca kullanıcının Firestore verisi silindikten **sonra** çağrılır:
  /// hesap gittiğinde `isletmeler/{uid}` altına yazma yetkisi de gider ve
  /// arkada erişilemez veri kalır (bkz. `firestore.rules`).
  Future<void> hesabiSil() async {
    final kullanici = _kimlik.currentUser;
    if (kullanici == null) {
      throw const KimlikHatasi('Oturum bulunamadı. Tekrar giriş yapın.');
    }

    try {
      await kullanici.delete();
    } on FirebaseAuthException catch (hata) {
      throw KimlikHatasi.koddan(hata.code);
    }
  }
}

final kimlikRepositorySaglayici = Provider<KimlikRepository>((ref) {
  return KimlikRepository(ref.watch(kimlikDogrulamaSaglayici));
});
