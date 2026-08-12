import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase servislerinin Riverpod sağlayıcıları.
///
/// Repository'ler bu sağlayıcılardan beslenir; hiçbir yerde
/// `FirebaseFirestore.instance` doğrudan çağrılmaz. Testte bu sağlayıcılar
/// emulator'e bağlı örneklerle değiştirilir — bkz. KURALLAR.md §1.4.

final firestoreSaglayici = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final kimlikDogrulamaSaglayici = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Oturum durumunu izler. Kullanıcı çıkış yaptığında `null` yayar.
final oturumDurumuSaglayici = StreamProvider<User?>((ref) {
  return ref.watch(kimlikDogrulamaSaglayici).authStateChanges();
});

/// Giriş yapmış kullanıcının `uid` değeri. Bu aynı zamanda işletme kimliğidir —
/// tüm veri `isletmeler/{uid}` altında yaşar.
final isletmeKimligiSaglayici = Provider<String?>((ref) {
  return ref.watch(oturumDurumuSaglayici).value?.uid;
});

/// Giriş yapmış kullanıcının e-posta adresi.
///
/// Ekranın `User` tipini tanıması gerekmesin diye ayrı sağlayıcı: hesap ekranı
/// yalnızca gösterilecek metni ister.
final kullaniciEPostasiSaglayici = Provider<String?>((ref) {
  return ref.watch(oturumDurumuSaglayici).value?.email;
});
