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
}

final kimlikRepositorySaglayici = Provider<KimlikRepository>((ref) {
  return KimlikRepository(ref.watch(kimlikDogrulamaSaglayici));
});
